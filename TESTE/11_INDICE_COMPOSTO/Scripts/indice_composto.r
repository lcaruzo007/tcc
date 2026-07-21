################################################################################
# SCRIPT: indice_composto.r
#
# OBJETIVO: Criar um indicador composto de vulnerabilidade socioeducacional
#           usando PCA (Análise de Componentes Principais)
#
# ENTRADA:
#   - metadados_escolas_*.csv (PASSO 4)
#
# SAÍDA:
#   - outputs/tabelas/indice_composto_*.csv (scores por escola)
#   - outputs/figuras/pca_scree.png (Figura 29)
#   - outputs/figuras/pca_biplot.png (Figura 30)
#   - outputs/figuras/indice_mapa_distribuicao.png (Figura 31)
#
# VERSÃO: 1.0 — Julho 2026
################################################################################

library(tidyverse)
library(data.table)

# =========================================================================
# CAMINHOS
# =========================================================================

RAIZ <- detectar_raiz()
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_METADADOS <- file.path(DIR_ANALISE, "outputs/metadados")

DIR_BASE <- file.path(DIR_TESTE, "11_INDICE_COMPOSTO")
DIR_FIGURAS <- file.path(DIR_BASE, "outputs/figuras")
DIR_TABELAS <- file.path(DIR_BASE, "outputs/tabelas")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_TABELAS, showWarnings = FALSE, recursive = TRUE)

ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSÁRIOS
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
message("ÍNDICE COMPOSTO DE VULNERABILIDADE SOCIOEDUCACIONAL (PCA)")
message(strrep("=", 70))

arq_meta <- encontrar_arquivo_mais_recente(DIR_METADADOS, "metadados_escolas")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv não encontrado.")

metadados <- read_csv(arq_meta, show_col_types = FALSE) %>%
  filter(!is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO)) %>%
  filter(TIPO_ESCOLA %in% c("Pública", "Privada")) %>%
  filter(LOCALIZACAO %in% c("Urbana", "Rural"))

message("Escolas válidas: ", nrow(metadados))

# =========================================================================
# PASSO 2: PREPARAR VARIÁVEIS PARA PCA
# =========================================================================

message("\n>>> Preparando variáveis para PCA...")

# Variáveis para o índice composto
# (inversão: menor proficiência = maior vulnerabilidade)
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

# Matriz para PCA (apenas variáveis numéricas)
matriz_pca <- dados_pca %>%
  select(INV_MT, INV_LP, INV_INSE, TIPO_PRIVADA, LOCAL_RURAL) %>%
  scale()

message("Variáveis no PCA: ", paste(colnames(matriz_pca), collapse = ", "))
message("Escolas: ", nrow(matriz_pca))

# =========================================================================
# PASSO 3: EXECUTAR PCA
# =========================================================================

message("\n>>> Executando PCA...")

pca_resultado <- PCA(matriz_pca, ncp = 5, graph = FALSE)

# Variância explicada
var_exp <- pca_resultado$eig[, 1:3]
message("\nVariância explicada por componente:")
for (i in 1:min(5, nrow(var_exp))) {
  message("  PC", i, ": ", round(var_exp[i, 1], 2), "% (acumulado: ", 
          round(var_exp[i, 3], 2), "%)")
}

# Determinar número de componentes (reter > 80% da variância)
n_componentes <- which(var_exp[, 3] >= 80)[1]
if (is.na(n_componentes)) n_componentes <- 3
message("\nComponentes retidos: ", n_componentes, " (explicam ", 
        round(var_exp[n_componentes, 3], 1), "% da variância)")

# =========================================================================
# PASSO 4: CALCULAR SCORES DO ÍNDICE COMPOSTO
# =========================================================================

message("\n>>> Calculando scores do índice composto...")

# Usar o primeiro componente principal como índice
scores <- pca_resultado$ind$coord[, 1:n_componentes]

# Índice composto = PC1 (primeiro componente = maior variância)
dados_pca$IC_VULN <- scores[, 1]

# Normalizar para escala 0-100
min_ic <- min(dados_pca$IC_VULN)
max_ic <- max(dados_pca$IC_VULN)
dados_pca$IC_VULN_NORM <- round(((dados_pca$IC_VULN - min_ic) / (max_ic - min_ic)) * 100, 1)

# Classificar em níveis
dados_pca <- dados_pca %>%
  mutate(
    NIVEL_VULN = case_when(
      IC_VULN_NORM < 25 ~ "Muito Baixa",
      IC_VULN_NORM < 50 ~ "Baixa",
      IC_VULN_NORM < 75 ~ "Alta",
      TRUE ~ "Muito Alta"
    )
  )

message("Distribuição do índice:")
dados_pca %>%
  count(NIVEL_VULN) %>%
  mutate(Percentual = round(n / sum(n) * 100, 1)) %>%
  print(n = Inf)

# =========================================================================
# PASSO 5: VALIDAÇÃO — CORRELAÇÃO COM PROFICIÊNCIA
# =========================================================================

message("\n>>> Validação: Correlação com proficiência...")

cor_mt <- cor(dados_pca$IC_VULN_NORM, dados_pca$MEDIA_MT, use = "complete.obs")
cor_lp <- cor(dados_pca$IC_VULN_NORM, dados_pca$MEDIA_LP, use = "complete.obs")
cor_inse <- cor(dados_pca$IC_VULN_NORM, dados_pca$INSE_MEDIO, use = "complete.obs")

message("  IC vs Proficiência MT: r = ", round(cor_mt, 4))
message("  IC vs Proficiência LP: r = ", round(cor_lp, 4))
message("  IC vs INSE: r = ", round(cor_inse, 4))

# =========================================================================
# PASSO 6: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

# Tabela com scores
write_csv(dados_pca %>% select(ID_ESCOLA, TIPO_ESCOLA, LOCALIZACAO, MEDIA_MT, MEDIA_LP,
                                INSE_MEDIO, IC_VULN, IC_VULN_NORM, NIVEL_VULN),
          file.path(DIR_TABELAS, paste0("indice_composto_", ts_global, ".csv")))

# Contribuições das variáveis para o PC1
contrib <- data.frame(
  Variavel = rownames(pca_resultado$var$contrib),
  Contribuicao_PC1 = pca_resultado$var$contrib[, 1],
  Cos2_PC1 = pca_resultado$var$cos2[, 1]
) %>%
  arrange(desc(Contribuicao_PC1))

write_csv(contrib, file.path(DIR_TABELAS, paste0("pca_contribuicoes_", ts_global, ".csv")))

message("   ✓ indice_composto_", ts_global, ".csv")
message("   ✓ pca_contribuicoes_", ts_global, ".csv")

# =========================================================================
# PASSO 7: VISUALIZAÇÕES
# =========================================================================

message("\n>>> Gerando figuras...")

# -------------------------------------------------------------------------
# Figura 29: Scree Plot (Elbow)
# -------------------------------------------------------------------------
var_df <- data.frame(
  Componente = paste0("PC", 1:nrow(var_exp)),
  Variância = var_exp[, 1],
  Acumulado = var_exp[, 3]
)

p29 <- ggplot() +
  geom_col(data = var_df[1:5, ], aes(x = Componente, y = Variância),
           fill = "#3498DB", alpha = 0.8, width = 0.6) +
  geom_line(data = var_df[1:5, ], aes(x = Componente, y = Acumulado, group = 1),
            color = "#E74C3C", linewidth = 1.2) +
  geom_point(data = var_df[1:5, ], aes(x = Componente, y = Acumulado),
             color = "#E74C3C", size = 3) +
  geom_hline(yintercept = 80, linetype = "dashed", color = "gray50") +
  annotate("text", x = 4.5, y = 82, label = "80%", size = 3.5, color = "gray40") +
  scale_y_continuous(
    name = "Variância Explicada (%)",
    sec.axis = sec_axis(~ ., name = "Variância Acumulada (%)")
  ) +
  labs(
    title = "Figura 29 — Scree Plot (Análise de Componentes Principais)",
    subtitle = "Variância explicada por componente — critério de retenção: 80%",
    x = "Componente Principal"
  ) +
  tema_saeb()

ggsave(file.path(DIR_FIGURAS, paste0("pca_scree_", ts_global, ".png")),
       plot = p29, width = 10, height = 7, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 29: pca_scree_", ts_global, ".png")

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
                        title = "Figura 30 — Biplot PCA (Variáveis + Escolas)",
                        subtitle = "Contribuição das variáveis para os componentes | Cor = Nível de Vulnerabilidade") +
  tema_saeb()

ggsave(file.path(DIR_FIGURAS, paste0("pca_biplot_", ts_global, ".png")),
       plot = p30, width = 12, height = 9, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 30: pca_biplot_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 31: Distribuição do Índice Composto
# -------------------------------------------------------------------------
p31 <- dados_pca %>%
  ggplot(aes(x = IC_VULN_NORM, fill = NIVEL_VULN)) +
  geom_histogram(bins = 30, alpha = 0.8, color = "white", linewidth = 0.3) +
  scale_fill_manual(values = c("Muito Baixa" = "#27AE60", "Baixa" = "#F39C12",
                               "Alta" = "#E67E22", "Muito Alta" = "#E74C3C")) +
  geom_vline(xintercept = median(dados_pca$IC_VULN_NORM), linetype = "dashed",
             color = "gray40", linewidth = 0.8) +
  annotate("text", x = median(dados_pca$IC_VULN_NORM), y = Inf,
           label = paste0("Mediana = ", round(median(dados_pca$IC_VULN_NORM), 1)),
           vjust = 1.5, size = 3.5, fontface = "bold", color = "gray40") +
  facet_wrap(~NIVEL_VULN, scales = "free_x") +
  labs(
    title = "Figura 31 — Distribuição do Índice de Vulnerabilidade Socioeducacional",
    subtitle = paste0("IC = PC1 da PCA | Correlação com MT: r = ", round(cor_mt, 3),
                      " | LP: r = ", round(cor_lp, 3)),
    x = "Índice de Vulnerabilidade (0-100)",
    y = "Número de Escolas",
    fill = "Nível"
  ) +
  tema_saeb() +
  theme(legend.position = "none")

ggsave(file.path(DIR_FIGURAS, paste0("indice_mapa_distribuicao_", ts_global, ".png")),
       plot = p31, width = 14, height = 8, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 31: indice_mapa_distribuicao_", ts_global, ".png")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("ÍNDICE COMPOSTO CONCLUÍDO")
message(strrep("=", 70))
message("Escolas analisadas: ", nrow(dados_pca))
message("Componentes retidos: ", n_componentes)
message("Variância explicada: ", round(var_exp[n_componentes, 3], 1), "%")
message("\nCorrelações do índice:")
message("  vs Proficiência MT: r = ", round(cor_mt, 4))
message("  vs Proficiência LP: r = ", round(cor_lp, 4))
message("  vs INSE: r = ", round(cor_inse, 4))
message("\nFiguras geradas:")
message("  • Figura 29: pca_scree_", ts_global, ".png")
message("  • Figura 30: pca_biplot_", ts_global, ".png")
message("  • Figura 31: indice_mapa_distribuicao_", ts_global, ".png")
