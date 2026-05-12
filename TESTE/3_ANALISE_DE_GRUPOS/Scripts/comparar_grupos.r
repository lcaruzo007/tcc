################################################################################
# SCRIPT: comparar_grupos.r
#
# OBJETIVO: Comparar pares de grupos (pública vs privada, urbana vs rural, etc)
#           com teste não-paramétrico (Wilcoxon) + tamanho de efeito (r rank-biserial)
#           e visualizações (boxplots)
#
# ENTRADA: metadados_escolas_*.csv (saída de classificar_escolas.r)
#
# SAÍDA: 
#   - resultados_comparacao_YYYYMMDD_HHMMSS.csv (tabela de testes)
#   - boxplot_tipo_escola.pdf / boxplot_urbano_rural.pdf / etc
#
# VERSÃO: 1.0 — Maio 2026
################################################################################

# ============================================================================
# PASSO 0: CARREGAR PACOTES E DEFINIR CAMINHOS
# ============================================================================

library(tidyverse)
library(data.table)

# Paths
RAIZ <- "C:/Users/Usuario/Desktop/tcc"
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_PROCESSADOS <- file.path(DIR_TESTE, "processados")
DIR_FIGURAS <- file.path(DIR_PROCESSADOS, "figuras_comparacao")

# Criar diretório de figuras se não existir
if (!dir.exists(DIR_FIGURAS)) {
  dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
}

# Timestamp para versionamento
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

# ============================================================================
# PASSO 1: CARREGAR METADADOS
# ============================================================================

cat(">>> Carregando metadados das escolas...\n")

# Encontrar arquivo mais recente de metadados
arquivos_meta <- list.files(DIR_PROCESSADOS, 
                             pattern = "^metadados_escolas_.*\\.csv$",
                             full.names = TRUE)

if (length(arquivos_meta) == 0) {
  stop("❌ Nenhum arquivo de metadados encontrado! Execute classificar_escolas.r primeiro.")
}

# Usar o mais recente
arquivo_meta <- sort(arquivos_meta, decreasing = TRUE)[1]
cat(sprintf("   Usando: %s\n", basename(arquivo_meta)))

metadados <- read_csv(arquivo_meta, show_col_types = FALSE)

cat(sprintf("   ✓ Metadados carregados: %d escolas\n", nrow(metadados)))

# ============================================================================
# PASSO 2: DEFINIR FUNÇÃO PARA TESTE DE WILCOXON + TAMANHO DE EFEITO
# ============================================================================

# Teste Wilcoxon com tamanho de efeito (rank-biserial r)
# Fórmula: r = Z / sqrt(N), onde Z é o valor padronizado
fazer_wilcoxon <- function(x, y, nome_x, nome_y, variavel) {
  
  # Remover NAs
  x_clean <- x[!is.na(x)]
  y_clean <- y[!is.na(y)]
  
  if (length(x_clean) == 0 | length(y_clean) == 0) {
    return(tibble(
      Variável = variavel,
      Grupo1 = nome_x,
      Grupo2 = nome_y,
      N1 = NA,
      N2 = NA,
      Mediana1 = NA,
      Mediana2 = NA,
      U = NA,
      p_valor = NA,
      r_rank_biserial = NA,
      Significância = NA
    ))
  }
  
  # Teste Wilcoxon
  teste <- wilcox.test(x_clean, y_clean, alternative = "two.sided")
  
  # Calcular rank-biserial r
  # r = 1 - (2U) / (n1 * n2)
  n1 <- length(x_clean)
  n2 <- length(y_clean)
  U <- teste$statistic
  r <- 1 - (2 * U) / (n1 * n2)
  
  # Interpretação de significância
  sig <- case_when(
    teste$p.value < 0.001 ~ "***",
    teste$p.value < 0.01 ~ "**",
    teste$p.value < 0.05 ~ "*",
    TRUE ~ "ns"
  )
  
  tibble(
    Variável = variavel,
    Grupo1 = nome_x,
    Grupo2 = nome_y,
    N1 = n1,
    N2 = n2,
    Mediana1 = median(x_clean),
    Mediana2 = median(y_clean),
    U = round(U, 2),
    p_valor = format(teste$p.value, digits = 4, scientific = TRUE),
    r_rank_biserial = round(r, 4),
    Significância = sig
  )
}

# ============================================================================
# PASSO 3: COMPARAÇÃO 1 — TIPO DE ESCOLA (Pública vs Privada)
# ============================================================================

cat("\n>>> COMPARAÇÃO 1: PÚBLICA vs PRIVADA\n")

publica_mt <- metadados %>%
  filter(GRUPO_TIPO == "Pública") %>%
  pull(MEDIA_MT)

privada_mt <- metadados %>%
  filter(GRUPO_TIPO == "Privada") %>%
  pull(MEDIA_MT)

publica_lp <- metadados %>%
  filter(GRUPO_TIPO == "Pública") %>%
  pull(MEDIA_LP)

privada_lp <- metadados %>%
  filter(GRUPO_TIPO == "Privada") %>%
  pull(MEDIA_LP)

comparacoes <- bind_rows(
  fazer_wilcoxon(publica_mt, privada_mt, "Pública", "Privada", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(publica_lp, privada_lp, "Pública", "Privada", "PROFICIÊNCIA_LP")
)

print(comparacoes)

# ============================================================================
# PASSO 4: COMPARAÇÃO 2 — LOCALIZAÇÃO (Urbana vs Rural)
# ============================================================================

cat("\n>>> COMPARAÇÃO 2: URBANA vs RURAL\n")

urbana_mt <- metadados %>%
  filter(LOCALIZACAO == "Urbana") %>%
  pull(MEDIA_MT)

rural_mt <- metadados %>%
  filter(LOCALIZACAO == "Rural") %>%
  pull(MEDIA_MT)

urbana_lp <- metadados %>%
  filter(LOCALIZACAO == "Urbana") %>%
  pull(MEDIA_LP)

rural_lp <- metadados %>%
  filter(LOCALIZACAO == "Rural") %>%
  pull(MEDIA_LP)

comparacoes <- bind_rows(
  comparacoes,
  fazer_wilcoxon(urbana_mt, rural_mt, "Urbana", "Rural", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(urbana_lp, rural_lp, "Urbana", "Rural", "PROFICIÊNCIA_LP")
)

# ============================================================================
# PASSO 5: COMPARAÇÃO 3 — ÁREA (Capital vs Interior)
# ============================================================================

cat("\n>>> COMPARAÇÃO 3: CAPITAL vs INTERIOR\n")

capital_mt <- metadados %>%
  filter(AREA == "Capital") %>%
  pull(MEDIA_MT)

interior_mt <- metadados %>%
  filter(AREA == "Interior") %>%
  pull(MEDIA_MT)

capital_lp <- metadados %>%
  filter(AREA == "Capital") %>%
  pull(MEDIA_LP)

interior_lp <- metadados %>%
  filter(AREA == "Interior") %>%
  pull(MEDIA_LP)

comparacoes <- bind_rows(
  comparacoes,
  fazer_wilcoxon(capital_mt, interior_mt, "Capital", "Interior", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(capital_lp, interior_lp, "Capital", "Interior", "PROFICIÊNCIA_LP")
)

# ============================================================================
# PASSO 6: COMPARAÇÃO 4 — INSE (Alto vs Baixo)
# ============================================================================

cat("\n>>> COMPARAÇÃO 4: ALTO INSE vs BAIXO INSE\n")

alto_inse_mt <- metadados %>%
  filter(GRUPO_INSE == "Alto_INSE") %>%
  pull(MEDIA_MT)

baixo_inse_mt <- metadados %>%
  filter(GRUPO_INSE == "Baixo_INSE") %>%
  pull(MEDIA_MT)

alto_inse_lp <- metadados %>%
  filter(GRUPO_INSE == "Alto_INSE") %>%
  pull(MEDIA_LP)

baixo_inse_lp <- metadados %>%
  filter(GRUPO_INSE == "Baixo_INSE") %>%
  pull(MEDIA_LP)

comparacoes <- bind_rows(
  comparacoes,
  fazer_wilcoxon(alto_inse_mt, baixo_inse_mt, "Alto_INSE", "Baixo_INSE", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(alto_inse_lp, baixo_inse_lp, "Alto_INSE", "Baixo_INSE", "PROFICIÊNCIA_LP")
)

# ============================================================================
# PASSO 7: EXPORTAR TABELA DE COMPARAÇÕES
# ============================================================================

cat("\n>>> Exportando tabela de comparações...\n")

nome_saida_tabela <- file.path(DIR_PROCESSADOS,
                                paste0("resultados_comparacao_", timestamp, ".csv"))

write_csv(comparacoes, nome_saida_tabela)

cat(sprintf("   ✓ Tabela salva: resultados_comparacao_%s.csv\n", timestamp))

# ============================================================================
# PASSO 8: BOXPLOTS
# ============================================================================

cat("\n>>> Gerando boxplots...\n")

# Preparar dados para ggplot
dados_plot <- metadados %>%
  select(ID_ESCOLA, MEDIA_MT, MEDIA_LP, GRUPO_TIPO, LOCALIZACAO, AREA, GRUPO_INSE) %>%
  pivot_longer(
    cols = c(MEDIA_MT, MEDIA_LP),
    names_to = "Disciplina",
    values_to = "Proficiência"
  ) %>%
  mutate(Disciplina = recode(Disciplina, 
                              MEDIA_MT = "Matemática",
                              MEDIA_LP = "Língua Portuguesa"))

# Boxplot 1: Tipo de Escola
p1 <- dados_plot %>%
  ggplot(aes(x = GRUPO_TIPO, y = Proficiência, fill = GRUPO_TIPO)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
  facet_wrap(~Disciplina) +
  labs(
    title = "Proficiência por Tipo de Escola",
    subtitle = "Pública vs Privada",
    x = "Tipo de Escola",
    y = "Proficiência Média",
    fill = "Tipo"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave(file.path(DIR_FIGURAS, "01_boxplot_tipo_escola.png"),
       plot = p1, width = 8, height = 5, dpi = 300)

cat("   ✓ Boxplot 1: Tipo de Escola\n")

# Boxplot 2: Localização
p2 <- dados_plot %>%
  ggplot(aes(x = LOCALIZACAO, y = Proficiência, fill = LOCALIZACAO)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
  facet_wrap(~Disciplina) +
  labs(
    title = "Proficiência por Localização",
    subtitle = "Urbana vs Rural",
    x = "Localização",
    y = "Proficiência Média",
    fill = "Localização"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave(file.path(DIR_FIGURAS, "02_boxplot_urbano_rural.png"),
       plot = p2, width = 8, height = 5, dpi = 300)

cat("   ✓ Boxplot 2: Localização\n")

# Boxplot 3: Área
p3 <- dados_plot %>%
  ggplot(aes(x = AREA, y = Proficiência, fill = AREA)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
  facet_wrap(~Disciplina) +
  labs(
    title = "Proficiência por Área",
    subtitle = "Capital vs Interior",
    x = "Área",
    y = "Proficiência Média",
    fill = "Área"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave(file.path(DIR_FIGURAS, "03_boxplot_capital_interior.png"),
       plot = p3, width = 8, height = 5, dpi = 300)

cat("   ✓ Boxplot 3: Capital vs Interior\n")

# Boxplot 4: INSE
p4 <- dados_plot %>%
  filter(!is.na(GRUPO_INSE)) %>%
  ggplot(aes(x = GRUPO_INSE, y = Proficiência, fill = GRUPO_INSE)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
  facet_wrap(~Disciplina) +
  labs(
    title = "Proficiência por Nível Socioeconômico (INSE)",
    subtitle = "Baixo, Médio, Alto",
    x = "Grupo INSE",
    y = "Proficiência Média",
    fill = "Grupo INSE"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(DIR_FIGURAS, "04_boxplot_inse.png"),
       plot = p4, width = 8, height = 5, dpi = 300)

cat("   ✓ Boxplot 4: INSE\n")

# ============================================================================
# PASSO 9: RESUMO FINAL
# ============================================================================

cat("\n" %&% strrep("=", 80) %&% "\n")
cat("RESUMO GERAL DA ANÁLISE\n")
cat(strrep("=", 80) %&% "\n\n")

cat("Tabela de Resultados:\n")
print(comparacoes, n = Inf)

cat(sprintf("\n✅ Testes concluídos! Arquivos salvos em: %s\n", DIR_PROCESSADOS))
cat("   📊 Tabela: resultados_comparacao_%s.csv\n", timestamp)
cat("   📈 Figuras:\n")
cat("      • 01_boxplot_tipo_escola.png\n")
cat("      • 02_boxplot_urbano_rural.png\n")
cat("      • 03_boxplot_capital_interior.png\n")
cat("      • 04_boxplot_inse.png\n")
