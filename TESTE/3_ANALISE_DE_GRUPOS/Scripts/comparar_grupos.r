################################################################################
# SCRIPT: comparar_grupos.r
#
# OBJETIVO: Comparar pares de grupos (publica vs privada, urbana vs rural, etc)
#           com teste nao-parametrico (Wilcoxon) + tamanho de efeito (r rank-biserial)
#           e visualizacoes (boxplots) com qualidade para documentos academicos
#
# ENTRADA: metadados_escolas_*.csv (saida de classificar_escolas.r)
#
# SAIDA: 
#   - resultados_comparacao_YYYYMMDD_HHMMSS.csv (tabela de testes)
#   - 01_boxplot_tipo_escola.png (Figura 1)
#   - 02_boxplot_urbano_rural.png (Figura 2)
#   - 03_boxplot_capital_interior.png (Figura 3)
#   - 04_boxplot_inse.png (Figura 4)
#   - 05_boxplot_area_local.png (Figura 5 - Urbana_Capital/Urbana_Interior/
#     Rural_Capital/Rural_Interior, combinacao de LOCALIZACAO x AREA)
#
# VERSAO: 2.0 - Julho 2026 (melhorias visuais para TCC)
################################################################################

library(tidyverse)
library(data.table)

# =========================================================================
# CAMINHOS
# =========================================================================

RAIZ <- detectar_raiz()
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_PROCESSADOS <- file.path(DIR_ANALISE, "outputs/metadados")
DIR_FIGURAS <- file.path(DIR_ANALISE, "outputs/figuras")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

# =========================================================================
# CARREGAR METADADOS
# =========================================================================

cat(">>> Carregando metadados das escolas...\n")

arquivos_meta <- list.files(DIR_PROCESSADOS, 
                             pattern = "^metadados_escolas_.*\\.csv$",
                             full.names = TRUE)

if (length(arquivos_meta) == 0) {
  stop("? Nenhum arquivo de metadados encontrado! Execute classificar_escolas.r primeiro.")
}

arquivo_meta <- sort(arquivos_meta, decreasing = TRUE)[1]
cat(sprintf("   Usando: %s\n", basename(arquivo_meta)))

metadados <- read_csv(arquivo_meta, show_col_types = FALSE)
cat(sprintf("   OK Metadados carregados: %d escolas\n", nrow(metadados)))

# =========================================================================
# FUNCAO: WILCOXON + TAMANHO DE EFEITO
# =========================================================================

fazer_wilcoxon <- function(x, y, nome_x, nome_y, variavel) {
  x_clean <- x[!is.na(x)]
  y_clean <- y[!is.na(y)]
  
  if (length(x_clean) == 0 | length(y_clean) == 0) {
    return(tibble(
      Variavel = variavel,
      Grupo1 = nome_x,
      Grupo2 = nome_y,
      N1 = NA, N2 = NA,
      Mediana1 = NA, Mediana2 = NA,
      U = NA, p_valor = NA,
      r_rank_biserial = NA,
      Significancia = NA
    ))
  }
  
  teste <- wilcox.test(x_clean, y_clean, alternative = "two.sided")
  
  n1 <- length(x_clean)
  n2 <- length(y_clean)
  U <- teste$statistic
  r <- 1 - (2 * U) / (n1 * n2)
  
  sig <- case_when(
    teste$p.value < 0.001 ~ "***",
    teste$p.value < 0.01 ~ "**",
    teste$p.value < 0.05 ~ "*",
    TRUE ~ "ns"
  )
  
  tibble(
    Variavel = variavel,
    Grupo1 = nome_x,
    Grupo2 = nome_y,
    N1 = n1, N2 = n2,
    Mediana1 = median(x_clean),
    Mediana2 = median(y_clean),
    U = round(U, 2),
    p_valor = format(teste$p.value, digits = 4, scientific = TRUE),
    r_rank_biserial = round(r, 4),
    Significancia = sig
  )
}

# =========================================================================
# COMPARACOES
# =========================================================================

cat("\n>>> COMPARACAO 1: PUBLICA vs PRIVADA\n")

publica_mt <- metadados %>% filter(TIPO_ESCOLA == "Publica") %>% pull(MEDIA_MT)
privada_mt <- metadados %>% filter(TIPO_ESCOLA == "Privada") %>% pull(MEDIA_MT)
publica_lp <- metadados %>% filter(TIPO_ESCOLA == "Publica") %>% pull(MEDIA_LP)
privada_lp <- metadados %>% filter(TIPO_ESCOLA == "Privada") %>% pull(MEDIA_LP)

comparacoes <- bind_rows(
  fazer_wilcoxon(publica_mt, privada_mt, "Publica", "Privada", "PROFICIENCIA_MT"),
  fazer_wilcoxon(publica_lp, privada_lp, "Publica", "Privada", "PROFICIENCIA_LP"),
  fazer_wilcoxon(privada_mt, publica_mt, "Privada", "Publica", "PROFICIENCIA_MT"),
  fazer_wilcoxon(privada_lp, publica_lp, "Privada", "Publica", "PROFICIENCIA_LP")
)

print(comparacoes)

cat("\n>>> COMPARACAO 2: URBANA vs RURAL\n")

urbana_mt <- metadados %>% filter(LOCALIZACAO == "Urbana") %>% pull(MEDIA_MT)
rural_mt <- metadados %>% filter(LOCALIZACAO == "Rural") %>% pull(MEDIA_MT)
urbana_lp <- metadados %>% filter(LOCALIZACAO == "Urbana") %>% pull(MEDIA_LP)
rural_lp <- metadados %>% filter(LOCALIZACAO == "Rural") %>% pull(MEDIA_LP)

comparacoes <- bind_rows(
  comparacoes,
  fazer_wilcoxon(urbana_mt, rural_mt, "Urbana", "Rural", "PROFICIENCIA_MT"),
  fazer_wilcoxon(urbana_lp, rural_lp, "Urbana", "Rural", "PROFICIENCIA_LP"),
  fazer_wilcoxon(rural_mt, urbana_mt, "Rural", "Urbana", "PROFICIENCIA_MT"),
  fazer_wilcoxon(rural_lp, urbana_lp, "Rural", "Urbana", "PROFICIENCIA_LP")
)

cat("\n>>> COMPARACAO 3: CAPITAL vs INTERIOR\n")

capital_mt <- metadados %>% filter(AREA == "Capital") %>% pull(MEDIA_MT)
interior_mt <- metadados %>% filter(AREA == "Interior") %>% pull(MEDIA_MT)
capital_lp <- metadados %>% filter(AREA == "Capital") %>% pull(MEDIA_LP)
interior_lp <- metadados %>% filter(AREA == "Interior") %>% pull(MEDIA_LP)

comparacoes <- bind_rows(
  comparacoes,
  fazer_wilcoxon(capital_mt, interior_mt, "Capital", "Interior", "PROFICIENCIA_MT"),
  fazer_wilcoxon(capital_lp, interior_lp, "Capital", "Interior", "PROFICIENCIA_LP"),
  fazer_wilcoxon(interior_mt, capital_mt, "Interior", "Capital", "PROFICIENCIA_MT"),
  fazer_wilcoxon(interior_lp, capital_lp, "Interior", "Capital", "PROFICIENCIA_LP")
)

cat("\n>>> COMPARACAO 4: ALTO INSE vs BAIXO INSE\n")

alto_inse_mt <- metadados %>% filter(GRUPO_INSE == "Alto_INSE") %>% pull(MEDIA_MT)
baixo_inse_mt <- metadados %>% filter(GRUPO_INSE == "Baixo_INSE") %>% pull(MEDIA_MT)
alto_inse_lp <- metadados %>% filter(GRUPO_INSE == "Alto_INSE") %>% pull(MEDIA_LP)
baixo_inse_lp <- metadados %>% filter(GRUPO_INSE == "Baixo_INSE") %>% pull(MEDIA_LP)

comparacoes <- bind_rows(
  comparacoes,
  fazer_wilcoxon(alto_inse_mt, baixo_inse_mt, "Alto_INSE", "Baixo_INSE", "PROFICIENCIA_MT"),
  fazer_wilcoxon(alto_inse_lp, baixo_inse_lp, "Alto_INSE", "Baixo_INSE", "PROFICIENCIA_LP"),
  fazer_wilcoxon(baixo_inse_mt, alto_inse_mt, "Baixo_INSE", "Alto_INSE", "PROFICIENCIA_MT"),
  fazer_wilcoxon(baixo_inse_lp, alto_inse_lp, "Baixo_INSE", "Alto_INSE", "PROFICIENCIA_LP")
)

cat("\n>>> COMPARACAO 5: AREA_LOCAL (Urbana_Capital x Urbana_Interior x Rural_Capital x Rural_Interior)\n")

# AREA_LOCAL ja vem pronta de classificar_escolas.r (LOCALIZACAO + "_" + AREA).
# Aqui comparamos as 4 combinacoes par a par, nas duas direcoes, assim como
# as demais comparacoes deste script.

grupos_area_local <- c("Urbana_Capital", "Urbana_Interior", "Rural_Capital", "Rural_Interior")

pares_area_local <- combn(grupos_area_local, 2, simplify = FALSE)

for (par in pares_area_local) {
  g1 <- par[1]
  g2 <- par[2]

  g1_mt <- metadados %>% filter(AREA_LOCAL == g1) %>% pull(MEDIA_MT)
  g2_mt <- metadados %>% filter(AREA_LOCAL == g2) %>% pull(MEDIA_MT)
  g1_lp <- metadados %>% filter(AREA_LOCAL == g1) %>% pull(MEDIA_LP)
  g2_lp <- metadados %>% filter(AREA_LOCAL == g2) %>% pull(MEDIA_LP)

  comparacoes <- bind_rows(
    comparacoes,
    fazer_wilcoxon(g1_mt, g2_mt, g1, g2, "PROFICIENCIA_MT"),
    fazer_wilcoxon(g1_lp, g2_lp, g1, g2, "PROFICIENCIA_LP"),
    fazer_wilcoxon(g2_mt, g1_mt, g2, g1, "PROFICIENCIA_MT"),
    fazer_wilcoxon(g2_lp, g1_lp, g2, g1, "PROFICIENCIA_LP")
  )
}

# =========================================================================
# EXPORTAR TABELA
# =========================================================================

cat("\n>>> Exportando tabela de comparacoes...\n")

nome_saida_tabela <- file.path(DIR_PROCESSADOS,
                                paste0("resultados_comparacao_", timestamp, ".csv"))

write_csv(comparacoes, nome_saida_tabela)
cat(sprintf("   OK Tabela salva: resultados_comparacao_%s.csv\n", timestamp))

# =========================================================================
# BOXPLOTS - DESIGN PROFISSIONAL PARA TCC
# =========================================================================

cat("\n>>> Gerando boxplots com visual profissional...\n")

# Paleta para AREA_LOCAL (4 categorias combinadas) - nao existe em utils_saeb.r,
# definida localmente seguindo o mesmo espirito das demais paletas (urbana em
# tons de verde, rural em tons de laranja/marrom; capital mais escuro que interior)
PALETA_AREA_LOCAL <- c(
  "Urbana_Capital"  = "#1B7837",
  "Urbana_Interior" = "#66C2A5",
  "Rural_Capital"   = "#B35806",
  "Rural_Interior"  = "#E08214"
)

dados_plot <- metadados %>%
  select(ID_ESCOLA, MEDIA_MT, MEDIA_LP, TIPO_ESCOLA, LOCALIZACAO, AREA, AREA_LOCAL, GRUPO_INSE) %>%
  pivot_longer(
    cols = c(MEDIA_MT, MEDIA_LP),
    names_to = "Disciplina",
    values_to = "Proficiencia"
  ) %>%
  mutate(Disciplina = dplyr::case_when(
                              Disciplina == "MEDIA_MT" ~ "Matematica",
                              Disciplina == "MEDIA_LP" ~ "Lingua Portuguesa",
                              TRUE ~ Disciplina))

# -------------------------------------------------------------------------
# FUNCAO AUXILIAR: Criar boxplot com anotacoes estatisticas
# -------------------------------------------------------------------------
criar_boxplot <- function(dados, var_x, paleta, titulo, fig_num,
                          mostrar_jitter = TRUE, max_jitter = 500) {
  
  n_total <- nrow(dados)
  n_grupos <- dados %>% group_by(!!sym(var_x)) %>% summarise(n = n())
  n_txt <- paste(n_grupos[[var_x]], "(n=", n_grupos$n, ")", sep = "", collapse = " | ")
  
  # Obter resultados estatisticos para anotacao
  comp_filtradas <- comparacoes %>%
    filter(Variavel == "PROFICIENCIA_MT") %>%
    filter(Grupo1 %in% dados[[var_x]] & Grupo2 %in% dados[[var_x]])
  
  if (nrow(comp_filtradas) > 0) {
    p_val <- comp_filtradas$p_valor[1]
    r_val <- comp_filtradas$r_rank_biserial[1]
    sig_txt <- comp_filtradas$Significancia[1]
    
    annot_texto <- paste0(
      formatar_p_annot(as.numeric(p_val)),
      " | Efeito ", interpretar_efeito(r_val),
      " (r = ", format(round(r_val, 3), nsmall = 3), ")",
      " ", sig_txt
    )
  } else {
    annot_texto <- NULL
  }
  
  # Calcular mediana geral para linha de referencia
  mediana_geral <- median(dados$Proficiencia, na.rm = TRUE)
  
  # Construir grafico
  p <- dados %>%
    ggplot(aes(x = !!sym(var_x), y = Proficiencia, fill = !!sym(var_x))) +
    geom_violin(alpha = 0.25, size = 0.8, color = NA, trim = FALSE) +
    geom_boxplot(alpha = 0.8, width = 0.3, outlier.alpha = 0.5, outlier.size = 1.8,
                 outlier.color = "#666666", color = "#333333") +
    geom_hline(aes(yintercept = mediana_geral, linetype = "Mediana geral"),
               color = "#999999", linewidth = 0.7) +
    facet_wrap(~Disciplina, scales = "free_y") +
    scale_fill_manual(values = paleta) +
    scale_linetype_manual(name = NULL, values = c("Mediana geral" = "dashed")) +
    labs(
      title = paste0("Figura ", fig_num, " - ", titulo),
      subtitle = paste0(n_txt, " | Mediana geral = ", round(mediana_geral, 1)),
      x = NULL,
      y = "Proficiencia Media (escala SAEB 0-500)",
      caption = if (!is.null(annot_texto)) paste0("Wilcoxon: ", annot_texto) else NULL
    ) +
    tema_saeb(base_size = 12) +
    theme(
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.key.size = grid::unit(0.6, "cm"),
      legend.margin = margin(t = 2, b = 0, unit = "pt"),
      panel.grid.major.x = element_blank(),
      plot.caption = element_text(size = 9, face = "bold", colour = "#555555")
    )
  
  # Adicionar jitter apenas se N for pequeno
  if (mostrar_jitter && n_total <= max_jitter) {
    p <- p + geom_jitter(width = 0.15, alpha = 0.25, size = 1.2, color = "#555555")
  }
  
  return(p)
}

# -------------------------------------------------------------------------
# Figura 1: Tipo de Escola
# -------------------------------------------------------------------------
p1 <- criar_boxplot(
  dados_plot, "TIPO_ESCOLA", PALETA_PUBLICA_PRIVADA,
  "Distribuicao de Proficiencia por Tipo de Escola",
  fig_num = 1
)

ggsave(file.path(DIR_FIGURAS, "01_boxplot_tipo_escola.png"),
       plot = p1, width = LARGURA_PADRAO, height = ALTURA_PADRAO, 
       dpi = DPI_PADRAO, bg = "white")

cat("   OK Figura 1: Tipo de Escola\n")

# -------------------------------------------------------------------------
# Figura 2: Localizacao
# -------------------------------------------------------------------------
p2 <- criar_boxplot(
  dados_plot %>% filter(!is.na(LOCALIZACAO)), "LOCALIZACAO", PALETA_URBANA_RURAL,
  "Distribuicao de Proficiencia por Localizacao",
  fig_num = 2
)

ggsave(file.path(DIR_FIGURAS, "02_boxplot_urbano_rural.png"),
       plot = p2, width = LARGURA_PADRAO, height = ALTURA_PADRAO, 
       dpi = DPI_PADRAO, bg = "white")

cat("   OK Figura 2: Localizacao\n")

# -------------------------------------------------------------------------
# Figura 3: Area
# -------------------------------------------------------------------------
p3 <- criar_boxplot(
  dados_plot %>% filter(!is.na(AREA)), "AREA", PALETA_CAPITAL_INTERIOR,
  "Distribuicao de Proficiencia por Area Geografica",
  fig_num = 3
)

ggsave(file.path(DIR_FIGURAS, "03_boxplot_capital_interior.png"),
       plot = p3, width = LARGURA_PADRAO, height = ALTURA_PADRAO, 
       dpi = DPI_PADRAO, bg = "white")

cat("   OK Figura 3: Area\n")

# -------------------------------------------------------------------------
# Figura 4: INSE
# -------------------------------------------------------------------------
p4 <- criar_boxplot(
  dados_plot %>% filter(!is.na(GRUPO_INSE)), "GRUPO_INSE", PALETA_INSE,
  "Distribuicao de Proficiencia por Nivel Socioeconomico (INSE)",
  fig_num = 4,
  mostrar_jitter = FALSE
) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave(file.path(DIR_FIGURAS, "04_boxplot_inse.png"),
       plot = p4, width = LARGURA_PADRAO, height = ALTURA_PADRAO, 
       dpi = DPI_PADRAO, bg = "white")

cat("   OK Figura 4: INSE\n")

# -------------------------------------------------------------------------
# Figura 5: Area x Localizacao combinadas (4 categorias)
# -------------------------------------------------------------------------
# Com 4 grupos, a anotacao de par unico usada nas figuras anteriores nao faz
# sentido (existem 6 pares possiveis - ver tabela resultados_comparacao_*.csv
# para os testes de Wilcoxon par a par). Aqui anotamos com Kruskal-Wallis
# (teste global de diferenca entre as 4 medianas).

dados_area_local <- dados_plot %>% filter(!is.na(AREA_LOCAL))

kw_mt <- kruskal.test(Proficiencia ~ AREA_LOCAL,
                       data = dados_area_local %>% filter(Disciplina == "Matematica"))
kw_lp <- kruskal.test(Proficiencia ~ AREA_LOCAL,
                       data = dados_area_local %>% filter(Disciplina == "Lingua Portuguesa"))

annot_kw <- sprintf(
  "Kruskal-Wallis: MT %s | LP %s",
  formatar_p_annot(kw_mt$p.value),
  formatar_p_annot(kw_lp$p.value)
)

n_grupos5 <- dados_area_local %>% group_by(AREA_LOCAL) %>% summarise(n = n())
n_txt5 <- paste(n_grupos5$AREA_LOCAL, "(n=", n_grupos5$n, ")", sep = "", collapse = " | ")
mediana_geral5 <- median(dados_area_local$Proficiencia, na.rm = TRUE)

p5 <- dados_area_local %>%
  ggplot(aes(x = AREA_LOCAL, y = Proficiencia, fill = AREA_LOCAL)) +
  geom_violin(alpha = 0.25, size = 0.8, color = NA, trim = FALSE) +
  geom_boxplot(alpha = 0.8, width = 0.3, outlier.alpha = 0.5, outlier.size = 1.8,
               outlier.color = "#666666", color = "#333333") +
  geom_hline(aes(yintercept = mediana_geral5, linetype = "Mediana geral"),
             color = "#999999", linewidth = 0.7) +
  facet_wrap(~Disciplina, scales = "free_y") +
  scale_fill_manual(values = PALETA_AREA_LOCAL) +
  scale_linetype_manual(name = NULL, values = c("Mediana geral" = "dashed")) +
  labs(
    title = "Figura 5 - Distribuicao de Proficiencia por Area x Localizacao (4 categorias)",
    subtitle = paste0(n_txt5, " | Mediana geral = ", round(mediana_geral5, 1)),
    x = NULL,
    y = "Proficiencia Media (escala SAEB 0-500)",
    caption = paste0("Kruskal-Wallis: ", annot_kw, "  |  comparacoes par a par na tabela")
  ) +
  tema_saeb(base_size = 12) +
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.key.size = grid::unit(0.6, "cm"),
    legend.margin = margin(t = 2, b = 0, unit = "pt"),
    panel.grid.major.x = element_blank(),
    plot.caption = element_text(size = 9, face = "bold", colour = "#555555"),
    axis.text.x = element_text(angle = 20, hjust = 1)
  )

if (nrow(dados_area_local) <= 500) {
  p5 <- p5 + geom_jitter(width = 0.15, alpha = 0.25, size = 1.2, color = "#555555")
}

ggsave(file.path(DIR_FIGURAS, "05_boxplot_area_local.png"),
       plot = p5, width = LARGURA_PADRAO, height = ALTURA_PADRAO,
       dpi = DPI_PADRAO, bg = "white")

cat("   OK Figura 5: Area x Localizacao (4 categorias)\n")

# =========================================================================
# RESUMO FINAL
# =========================================================================

cat("\n", strrep("=", 80), "\n", sep = "")
cat("RESUMO GERAL DA ANALISE\n")
cat(strrep("=", 80), "\n\n", sep = "")

cat("Tabela de Resultados:\n")
print(comparacoes, n = Inf)

cat(sprintf("\n? Testes concluidos! Arquivos salvos em: %s\n", DIR_PROCESSADOS))
cat("   ?? Tabela: resultados_comparacao_%s.csv\n", timestamp)
cat("   ?? Figuras (DPI = %d):\n", DPI_PADRAO)
cat("      - 01_boxplot_tipo_escola.png\n")
cat("      - 02_boxplot_urbano_rural.png\n")
cat("      - 03_boxplot_capital_interior.png\n")
cat("      - 04_boxplot_inse.png\n")
cat("      - 05_boxplot_area_local.png\n")