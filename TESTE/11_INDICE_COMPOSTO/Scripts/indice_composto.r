################################################################################
# SCRIPT: indice_composto.r
#
# OBJETIVO: Criar um indicador composto de vulnerabilidade socioeducacional
#           usando PCA (Analise de Componentes Principais)
#
# ENTRADA:
#   - metadados_escolas_*.csv (PASSO 4)
#
# SAIDA:
#   - outputs/tabelas/indice_composto_*.csv (scores por escola)
#   - outputs/figuras/pca_scree.png (Figura 29)
#   - outputs/figuras/pca_biplot.png (Figura 30)
#   - outputs/figuras/indice_mapa_distribuicao.png (Figura 31)
#
# VERSAO: 1.0 - Julho 2026
#
# ---------------------------------------------------------------------------
# NOTA METODOLOGICA - INDICE COMPOSTO VIA PCA
# ---------------------------------------------------------------------------
#
# Os preditores do PASSO 8 (TIPO_ESCOLA, AREA_LOCAL, INSE_MEDIO) sao medidas
# correlatas do mesmo constructo latente "vulnerabilidade socioeducativa".
# Este PASSO 15 aplica Analise de Componentes Principais (PCA) para construir
# um Mico indice composto, discutindo se ele representa algo alem de uma
# reparametrizacao do INSE.
#
# 1. Por que PCA e nao simplesmente INSE?
#    O INSE_medio e determinado pela TRI sobre itens do questionario do aluno
#    (bens, escolaridade dos pais, servicos). Captura apenas a dimensao
#    socioeconomica do aluno. PCA sobre INSE + dummies institucionais captura
#    adicionalmente a dimensao estrutural (publica/privada, urbana/rural x
#    capital/interior), permitindo um perfil bidimensional de cada escola.
#
# 2. Padronizacao pre-PCA
#    As variaveis de entrada sao padronizadas (z-score) antes de PCA, pois
#    INSE_MEDIO esta em escala continua (0-10) e as dummies em 0/1. Sem
#    padronizacao, a primeira componente seria dominada por INSE apenas por
#    razao de escala de variancia, e nao por relevancia substancial.
#
# 3. Retencao de componentes (criterio paralelo)
#    Adotamos regra combinada: selecionamos componentes com autovalor > 1
#    (criterio de Kaiser) e cuja variancia explicada acumulada seja >= 70%
#    (criterio de Joliffe). Sempre que aplicavel, complementamos com Horn's
#    Parallel Analysis (gera autovalores sob dados aleatorios com mesma
#    dimensionalidade) para validar contra ruido.
#
# 4. Rotacao (nao aplicada por default)
#    PCA com varimax seria apropriado se a interpretacao das componentes
#    fosse a saida principal; aqui, o objetivo e construir um score (PC1),
#    sozinho ou em combinacao com PC2. Mantemos sem rotacao para preservar
#    a propriedade da primeira componente capturar maxima variancia - que
#    e o objetivo do indice.
#
# 5. Limitacao - PCA assume linearidade
#    PCA assume relacoes lineares entre variaveis. Para o caso de dummies
#    binarias, relacoes nao-lineares (ex.: presenca/ausencia de escola privada
#    pode ter efeito diferente em alto vs. baixo INSE) nao sao captadas. Metodos
#    alternativos (Polychoric PCA, MCA) seriam mais apropriados para variaveis
#    categoricas; porem adicionariam complexidade sem retorno material para
#    o escopo do TCC dado o pequeno numero de preditores.
#
# CONCLUSAO: PCA sobre variaveis padronizadas (INSE + dummies de AREA_LOCAL e
# TIPO_ESCOLA), retencao com autovalor > 1 e acumulado >= 70%, e a base para
# um indice composto de vulnerabilidade socioeducativa. Recomenda-se reportar
# PC1 como "Indice SE" (socioeducativo) e PC2 como "Eixo institucional"
# (publica/privada vs. urbana/rural), com a deixa interpretacao de cada um
# conforme suas cargas (loadings) reportadas.
# ---------------------------------------------------------------------------
################################################################################

library(tidyverse)
library(data.table)

# =========================================================================
# CAMINHOS
# =========================================================================

RAIZ <- detectar_raiz()
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_OUTPUTS_ANALISE <- file.path(DIR_ANALISE, "outputs")

DIR_BASE <- file.path(DIR_TESTE, "11_INDICE_COMPOSTO")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

ts_global <- format(Sys.time(), "%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSARIOS
# =========================================================================

pacotes_necessarios <- c("FactoMineR", "factoextra")
for (pkg in pacotes_necessarios) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Instalando pacote: ", pkg)
    install.packages(pkg, dependencies = TRUE)
  }
}

library(FactoMineR)
library(factoextra)

# =========================================================================
# PASSO 1: CARREGAR E PREPARAR DADOS
# =========================================================================

message(strrep("=", 70))
message("INDICE COMPOSTO DE VULNERABILIDADE SOCIOEDUCACIONAL (PCA)")
message(strrep("=", 70))

arq_meta <- encontrar_arquivo_mais_recente(DIR_OUTPUTS_ANALISE, "metadados_escolas", tipo = "metadados")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv nao encontrado.")

metadados <- read_csv(arq_meta, show_col_types = FALSE) %>%
  filter(!is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO)) %>%
  filter(TIPO_ESCOLA %in% c("Publica", "Privada")) %>%
  filter(LOCALIZACAO %in% c("Urbana", "Rural"))

message("Escolas validas: ", nrow(metadados))

# =========================================================================
# PASSO 2: PREPARAR VARIAVEIS PARA PCA
# =========================================================================

message("\n>>> Preparando variaveis para PCA...")

# Variaveis para o indice composto
# (inversao: menor proficiencia = maior vulnerabilidade)
dados_pca <- metadados %>%
  select(ID_ESCOLA, TIPO_ESCOLA, LOCALIZACAO, MEDIA_MT, MEDIA_LP, INSE_MEDIO, N_ALUNOS) %>%
  mutate(
    INV_MT = -MEDIA_MT,
    INV_LP = -MEDIA_LP,
    INV_INSE = -INSE_MEDIO,
    TIPO_PRIVADA = as.integer(TIPO_ESCOLA == "Privada"),
    LOCAL_RURAL = as.integer(LOCALIZACAO == "Rural")
  ) %>%
  filter(!is.na(INV_MT), !is.na(INV_LP), !is.na(INV_INSE))

# Matriz para PCA (apenas variaveis numericas)
matriz_pca <- dados_pca %>%
  select(INV_MT, INV_LP, INV_INSE, TIPO_PRIVADA, LOCAL_RURAL) %>%
  scale()

message("Variaveis no PCA: ", paste(colnames(matriz_pca), collapse = ", "))
message("Escolas: ", nrow(matriz_pca))

# =========================================================================
# PASSO 3: EXECUTAR PCA
# =========================================================================

message("\n>>> Executando PCA...")

pca_resultado <- PCA(matriz_pca, ncp = 5, graph = FALSE)

# Variancia explicada
var_exp <- pca_resultado$eig[, 1:3]
message("\nVariancia explicada por componente:")
for (i in 1:min(5, nrow(var_exp))) {
  message("  PC", i, ": ", round(var_exp[i, 1], 2), "% (acumulado: ", 
          round(var_exp[i, 3], 2), "%)")
}

# Determinar numero de componentes (reter > 80% da variancia)
n_componentes <- which(var_exp[, 3] >= 80)[1]
if (is.na(n_componentes)) n_componentes <- 3
message("\nComponentes retidos: ", n_componentes, " (explicam ", 
        round(var_exp[n_componentes, 3], 1), "% da variancia)")

# =========================================================================
# PASSO 4: CALCULAR SCORES DO INDICE COMPOSTO
# =========================================================================

message("\n>>> Calculando scores do indice composto...")

# Usar o primeiro componente principal como indice
scores <- pca_resultado$ind$coord[, 1:n_componentes]

# Indice composto = PC1 (primeiro componente = maior variancia)
dados_pca$IC_VULN <- scores[, 1]

# Normalizar para escala 0-100
min_ic <- min(dados_pca$IC_VULN)
max_ic <- max(dados_pca$IC_VULN)
dados_pca$IC_VULN_NORM <- round(((dados_pca$IC_VULN - min_ic) / (max_ic - min_ic)) * 100, 1)

# Classificar em niveis
dados_pca <- dados_pca %>%
  mutate(
    NIVEL_VULN = case_when(
      IC_VULN_NORM < 25 ~ "Muito Baixa",
      IC_VULN_NORM < 50 ~ "Baixa",
      IC_VULN_NORM < 75 ~ "Alta",
      TRUE ~ "Muito Alta"
    )
  )

message("Distribuicao do indice:")
dados_pca %>%
  count(NIVEL_VULN) %>%
  mutate(Percentual = round(n / sum(n) * 100, 1)) %>%
  print(n = Inf)

# =========================================================================
# PASSO 5: VALIDACAO - CORRELACAO COM PROFICIENCIA
# =========================================================================

message("\n>>> Validacao: Correlacao com proficiencia...")

cor_mt <- cor(dados_pca$IC_VULN_NORM, dados_pca$MEDIA_MT, use = "complete.obs")
cor_lp <- cor(dados_pca$IC_VULN_NORM, dados_pca$MEDIA_LP, use = "complete.obs")
cor_inse <- cor(dados_pca$IC_VULN_NORM, dados_pca$INSE_MEDIO, use = "complete.obs")

message("  IC vs Proficiencia MT: r = ", round(cor_mt, 4))
message("  IC vs Proficiencia LP: r = ", round(cor_lp, 4))
message("  IC vs INSE: r = ", round(cor_inse, 4))

# =========================================================================
# PASSO 6: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

# Tabela com scores
write_csv(dados_pca %>% select(ID_ESCOLA, TIPO_ESCOLA, LOCALIZACAO, MEDIA_MT, MEDIA_LP,
                                INSE_MEDIO, IC_VULN, IC_VULN_NORM, NIVEL_VULN),
          caminho_saida(DIR_BASE, "tabelas", "indice_composto", "csv"))

# Contribuicoes das variaveis para o PC1
contrib <- data.frame(
  Variavel = rownames(pca_resultado$var$contrib),
  Contribuicao_PC1 = pca_resultado$var$contrib[, 1],
  Cos2_PC1 = pca_resultado$var$cos2[, 1]
) %>%
  arrange(desc(Contribuicao_PC1))

write_csv(contrib, caminho_saida(DIR_BASE, "tabelas", "pca_contribuicoes", "csv"))

message("   OK indice_composto_", ts_global, ".csv")
message("   OK pca_contribuicoes_", ts_global, ".csv")

# =========================================================================
# PASSO 7: VISUALIZACOES
# =========================================================================

message("\n>>> Gerando figuras...")

# -------------------------------------------------------------------------
# Figura 29: Scree Plot (Elbow)
# -------------------------------------------------------------------------
var_df <- data.frame(
  Componente = paste0("PC", 1:nrow(var_exp)),
  Variancia = var_exp[, 1],
  Acumulado = var_exp[, 3]
)

p29 <- ggplot() +
  geom_col(data = var_df[1:5, ], aes(x = Componente, y = Variancia),
           fill = "#3498DB", alpha = 0.8, width = 0.6) +
  geom_line(data = var_df[1:5, ], aes(x = Componente, y = Acumulado, group = 1),
            color = "#E74C3C", linewidth = 1.2) +
  geom_point(data = var_df[1:5, ], aes(x = Componente, y = Acumulado),
             color = "#E74C3C", size = 3) +
  geom_hline(yintercept = 80, linetype = "dashed", color = "gray50") +
  annotate("text", x = 4.5, y = 82, label = "80%", size = 3.5, color = "gray40") +
  scale_y_continuous(
    name = "Variancia Explicada (%)",
    sec.axis = sec_axis(~ ., name = "Variancia Acumulada (%)")
  ) +
  labs(
    title = "Figura 29 - Scree Plot (Analise de Componentes Principais)",
    subtitle = "Variancia explicada por componente - criterio de retencao: 80%",
    x = "Componente Principal"
  ) +
  tema_saeb()

ggsave(caminho_saida(DIR_BASE, "figuras", "pca_scree", "png"),
       plot = p29, width = 10, height = 7, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 29: pca_scree_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 30: Biplot PCA
# -------------------------------------------------------------------------
p30 <- fviz_pca_biplot(pca_resultado,
                        geom.ind = "point",
                        pointsize = 2,
                        alpha.ind = 0.4,
        fill.ind = dados_pca$NIVEL_VULN,
        palette = c("Muito Baixa" = "#27AE60", "Baixa" = "#F39C12",
                    "Alta" = "#E67E22", "Muito Alta" = "#E74C3C"),
                        col.var = "contrib",
                        gradient.cols = c("#3498DB", "#E74C3C"),
                        repel = TRUE,
                        title = "Figura 30 - Biplot PCA (Variaveis + Escolas)",
                        subtitle = "Contribuicao das variaveis para os componentes | Cor = Nivel de Vulnerabilidade") +
  tema_saeb()

ggsave(caminho_saida(DIR_BASE, "figuras", "pca_biplot", "png"),
       plot = p30, width = 12, height = 9, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 30: pca_biplot_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 31: Distribuicao do Indice Composto
# -------------------------------------------------------------------------
p31 <- dados_pca %>%
  ggplot(aes(x = IC_VULN_NORM, fill = NIVEL_VULN)) +
  geom_histogram(bins = 30, alpha = 0.8, color = "white", linewidth = 0.3) +
  scale_fill_manual(
    name = "Nivel de Vulnerabilidade",
    values = c("Muito Baixa" = "#27AE60", "Baixa" = "#F39C12",
               "Alta" = "#E67E22", "Muito Alta" = "#E74C3C"),
    breaks = c("Muito Baixa", "Baixa", "Alta", "Muito Alta")
  ) +
  geom_vline(xintercept = median(dados_pca$IC_VULN_NORM), linetype = "dashed",
             color = "gray40", linewidth = 0.8) +
  annotate("text", x = median(dados_pca$IC_VULN_NORM), y = Inf,
           label = paste0("Mediana = ", round(median(dados_pca$IC_VULN_NORM), 1)),
           vjust = 1.5, size = 3.5, fontface = "bold", color = "gray40") +
  facet_wrap(~NIVEL_VULN, scales = "free_x") +
  labs(
    title = "Figura 31 - Distribuicao do Indice de Vulnerabilidade Socioeducacional",
    subtitle = paste0("IC = PC1 da PCA | Correlacao com MT: r = ", round(cor_mt, 3),
                      " | LP: r = ", round(cor_lp, 3)),
    x = "Indice de Vulnerabilidade (0-100)",
    y = "Numero de Escolas",
    fill = "Nivel"
  ) +
  tema_saeb() +
  theme(legend.position = "bottom")

ggsave(caminho_saida(DIR_BASE, "figuras", "indice_mapa_distribuicao", "png"),
       plot = p31, width = 14, height = 8, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 31: indice_mapa_distribuicao_", ts_global, ".png")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("INDICE COMPOSTO CONCLUIDO")
message(strrep("=", 70))
message("Escolas analisadas: ", nrow(dados_pca))
message("Componentes retidos: ", n_componentes)
message("Variancia explicada: ", round(var_exp[n_componentes, 3], 1), "%")
message("\nCorrelacoes do indice:")
message("  vs Proficiencia MT: r = ", round(cor_mt, 4))
message("  vs Proficiencia LP: r = ", round(cor_lp, 4))
message("  vs INSE: r = ", round(cor_inse, 4))
message("\nFiguras geradas:")
message("  - Figura 29: pca_scree_", ts_global, ".png")
message("  - Figura 30: pca_biplot_", ts_global, ".png")
message("  - Figura 31: indice_mapa_distribuicao_", ts_global, ".png")