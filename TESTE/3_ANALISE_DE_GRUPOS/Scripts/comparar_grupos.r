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
# PASSO 0: CARREGAR PACOTES E DEFINIR CAMINHOS (DETECÇÃO AUTOMÁTICA)
# ============================================================================

library(tidyverse)
library(data.table)

# Detectar raiz automaticamente
detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("✓ Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho não selecionado.")
    message("✓ Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Não foi possível detectar o caminho automaticamente.")
  }
}

# Paths
RAIZ <- detectar_raiz()
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_OUTPUTS_ESCOLAS <- file.path(DIR_ANALISE, "outputs/metadados")
DIR_PROCESSADOS <- file.path(DIR_ANALISE, "outputs/metadados")
DIR_FIGURAS <- file.path(DIR_ANALISE, "outputs/figuras")

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
  filter(TIPO_ESCOLA == "Pública") %>%
  pull(MEDIA_MT)

privada_mt <- metadados %>%
  filter(TIPO_ESCOLA == "Privada") %>%
  pull(MEDIA_MT)

publica_lp <- metadados %>%
  filter(TIPO_ESCOLA == "Pública") %>%
  pull(MEDIA_LP)

privada_lp <- metadados %>%
  filter(TIPO_ESCOLA == "Privada") %>%
  pull(MEDIA_LP)

comparacoes <- bind_rows(
  fazer_wilcoxon(publica_mt, privada_mt, "Pública", "Privada", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(publica_lp, privada_lp, "Pública", "Privada", "PROFICIÊNCIA_LP"),
  fazer_wilcoxon(privada_mt, publica_mt, "Privada", "Pública", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(privada_lp, publica_lp, "Privada", "Pública", "PROFICIÊNCIA_LP")
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
  fazer_wilcoxon(urbana_lp, rural_lp, "Urbana", "Rural", "PROFICIÊNCIA_LP"),
  fazer_wilcoxon(rural_mt, urbana_mt, "Rural", "Urbana", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(rural_lp, urbana_lp, "Rural", "Urbana", "PROFICIÊNCIA_LP")
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
  fazer_wilcoxon(capital_lp, interior_lp, "Capital", "Interior", "PROFICIÊNCIA_LP"),
  fazer_wilcoxon(interior_mt, capital_mt, "Interior", "Capital", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(interior_lp, capital_lp, "Interior", "Capital", "PROFICIÊNCIA_LP")
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
  fazer_wilcoxon(alto_inse_lp, baixo_inse_lp, "Alto_INSE", "Baixo_INSE", "PROFICIÊNCIA_LP"),
  fazer_wilcoxon(baixo_inse_mt, alto_inse_mt, "Baixo_INSE", "Alto_INSE", "PROFICIÊNCIA_MT"),
  fazer_wilcoxon(baixo_inse_lp, alto_inse_lp, "Baixo_INSE", "Alto_INSE", "PROFICIÊNCIA_LP")
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
# PASSO 8: BOXPLOTS COM DESIGN APRIMORADO
# ============================================================================

cat("\n>>> Gerando boxplots com visual profissional...\n")

# Preparar dados para ggplot
dados_plot <- metadados %>%
  select(ID_ESCOLA, MEDIA_MT, MEDIA_LP, TIPO_ESCOLA, LOCALIZACAO, AREA, GRUPO_INSE) %>%
  pivot_longer(
    cols = c(MEDIA_MT, MEDIA_LP),
    names_to = "Disciplina",
    values_to = "Proficiência"
  ) %>%
  mutate(Disciplina = recode(Disciplina, 
                              MEDIA_MT = "Matemática",
                              MEDIA_LP = "Língua Portuguesa"))

# Paleta de cores profissionais
paleta_pública_privada <- c("Pública" = "#2E86AB", "Privada" = "#A23B72")
paleta_localização <- c("Urbana" = "#06A77D", "Rural" = "#D5622B")
paleta_área <- c("Capital" = "#4A90E2", "Interior" = "#F5A623")
paleta_inse <- c("Baixo_INSE" = "#E74C3C", "Medio_INSE" = "#F39C12", "Alto_INSE" = "#27AE60")

# Boxplot 1: Tipo de Escola
p1 <- dados_plot %>%
  ggplot(aes(x = TIPO_ESCOLA, y = Proficiência, fill = TIPO_ESCOLA)) +
  geom_violin(alpha = 0.3, size = 0.7, color = NA) +
  geom_boxplot(alpha = 0.7, width = 0.25, outlier.alpha = 0.4, outlier.size = 1.5) +
  geom_jitter(width = 0.15, alpha = 0.2, size = 1) +
  facet_wrap(~Disciplina, scales = "free_y") +
  scale_fill_manual(values = paleta_pública_privada) +
  labs(
    title = "Distribuição de Proficiência por Tipo de Escola",
    subtitle = "Comparação: Públicas (n=2297) vs Privadas (n=41)",
    x = "Tipo de Escola",
    y = "Proficiência Média (Escala 0-500)",
    fill = "Tipo"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold", color = "#1A1A1A"),
    plot.subtitle = element_text(size = 11, color = "#666666", margin = margin(b = 10)),
    axis.title = element_text(size = 11, face = "bold", color = "#1A1A1A"),
    axis.text = element_text(size = 10, color = "#333333"),
    strip.text = element_text(size = 11, face = "bold"),
    panel.grid.major.y = element_line(color = "#E8E8E8", size = 0.3),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "#F8F9FA", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(12, 12, 12, 12)
  )

ggsave(file.path(DIR_FIGURAS, "01_boxplot_tipo_escola.png"),
       plot = p1, width = 10, height = 6, dpi = 300, bg = "#F8F9FA")

cat("   ✓ Boxplot 1: Tipo de Escola (design aprimorado)\n")

# Boxplot 2: Localização
p2 <- dados_plot %>%
  ggplot(aes(x = LOCALIZACAO, y = Proficiência, fill = LOCALIZACAO)) +
  geom_violin(alpha = 0.3, size = 0.7, color = NA) +
  geom_boxplot(alpha = 0.7, width = 0.25, outlier.alpha = 0.4, outlier.size = 1.5) +
  geom_jitter(width = 0.15, alpha = 0.2, size = 1) +
  facet_wrap(~Disciplina, scales = "free_y") +
  scale_fill_manual(values = paleta_localização) +
  labs(
    title = "Distribuição de Proficiência por Localização",
    subtitle = "Comparação: Urbana (n=2144) vs Rural (n=153) + NA",
    x = "Localização",
    y = "Proficiência Média (Escala 0-500)",
    fill = "Localização"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold", color = "#1A1A1A"),
    plot.subtitle = element_text(size = 11, color = "#666666", margin = margin(b = 10)),
    axis.title = element_text(size = 11, face = "bold", color = "#1A1A1A"),
    axis.text = element_text(size = 10, color = "#333333"),
    strip.text = element_text(size = 11, face = "bold"),
    panel.grid.major.y = element_line(color = "#E8E8E8", size = 0.3),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "#F8F9FA", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(12, 12, 12, 12)
  )

ggsave(file.path(DIR_FIGURAS, "02_boxplot_urbano_rural.png"),
       plot = p2, width = 10, height = 6, dpi = 300, bg = "#F8F9FA")

cat("   ✓ Boxplot 2: Localização (design aprimorado)\n")

# Boxplot 3: Área
p3 <- dados_plot %>%
  filter(!is.na(AREA)) %>%
  ggplot(aes(x = AREA, y = Proficiência, fill = AREA)) +
  geom_violin(alpha = 0.3, size = 0.7, color = NA) +
  geom_boxplot(alpha = 0.7, width = 0.25, outlier.alpha = 0.4, outlier.size = 1.5) +
  geom_jitter(width = 0.15, alpha = 0.2, size = 1) +
  facet_wrap(~Disciplina, scales = "free_y") +
  scale_fill_manual(values = paleta_área) +
  labs(
    title = "Distribuição de Proficiência por Área",
    subtitle = "Comparação: Capital (n=132) vs Interior (n=2163)",
    x = "Área",
    y = "Proficiência Média (Escala 0-500)",
    fill = "Área"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold", color = "#1A1A1A"),
    plot.subtitle = element_text(size = 11, color = "#666666", margin = margin(b = 10)),
    axis.title = element_text(size = 11, face = "bold", color = "#1A1A1A"),
    axis.text = element_text(size = 10, color = "#333333"),
    strip.text = element_text(size = 11, face = "bold"),
    panel.grid.major.y = element_line(color = "#E8E8E8", size = 0.3),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "#F8F9FA", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(12, 12, 12, 12)
  )

ggsave(file.path(DIR_FIGURAS, "03_boxplot_capital_interior.png"),
       plot = p3, width = 10, height = 6, dpi = 300, bg = "#F8F9FA")

cat("   ✓ Boxplot 3: Capital vs Interior (design aprimorado)\n")

# Boxplot 4: INSE
p4 <- dados_plot %>%
  filter(!is.na(GRUPO_INSE)) %>%
  ggplot(aes(x = GRUPO_INSE, y = Proficiência, fill = GRUPO_INSE)) +
  geom_violin(alpha = 0.3, size = 0.7, color = NA) +
  geom_boxplot(alpha = 0.7, width = 0.25, outlier.alpha = 0.4, outlier.size = 1.5) +
  geom_jitter(width = 0.15, alpha = 0.2, size = 1) +
  facet_wrap(~Disciplina, scales = "free_y") +
  scale_fill_manual(values = paleta_inse) +
  labs(
    title = "Distribuição de Proficiência por Nível Socioeconômico (INSE)",
    subtitle = "Comparação: Baixo, Médio e Alto INSE",
    x = "Grupo INSE",
    y = "Proficiência Média (Escala 0-500)",
    fill = "Grupo INSE"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(size = 14, face = "bold", color = "#1A1A1A"),
    plot.subtitle = element_text(size = 11, color = "#666666", margin = margin(b = 10)),
    axis.title = element_text(size = 11, face = "bold", color = "#1A1A1A"),
    axis.text = element_text(size = 10, color = "#333333"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(size = 11, face = "bold"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    panel.grid.major.y = element_line(color = "#E8E8E8", size = 0.3),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "#F8F9FA", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(12, 12, 12, 12)
  )

ggsave(file.path(DIR_FIGURAS, "04_boxplot_inse.png"),
       plot = p4, width = 10, height = 6, dpi = 300, bg = "#F8F9FA")

cat("   ✓ Boxplot 4: INSE (design aprimorado)\n")

# ============================================================================
# PASSO 9: RESUMO FINAL
# ============================================================================

cat("\n" , strrep("=", 80) , "\n", sep="")
cat("RESUMO GERAL DA ANÁLISE\n")
cat(strrep("=", 80), "\n\n", sep="")

cat("Tabela de Resultados:\n")
print(comparacoes, n = Inf)

cat(sprintf("\n✅ Testes concluídos! Arquivos salvos em: %s\n", DIR_PROCESSADOS))
cat("   📊 Tabela: resultados_comparacao_%s.csv\n", timestamp)
cat("   📈 Figuras:\n")
cat("      • 01_boxplot_tipo_escola.png\n")
cat("      • 02_boxplot_urbano_rural.png\n")
cat("      • 03_boxplot_capital_interior.png\n")
cat("      • 04_boxplot_inse.png\n")
