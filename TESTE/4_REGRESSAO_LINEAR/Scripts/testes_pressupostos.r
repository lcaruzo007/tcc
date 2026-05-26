################################################################################
# SCRIPT: testes_pressupostos.r
#
# FUNCIONALIDADE:
#   Validação dos pressupostos de regressão linear:
#   - Normalidade (Shapiro-Wilk)
#   - Homocedasticidade (Breusch-Pagan)
#   - Multicolinearidade (VIF)
#   - Independência (Durbin-Watson)
#   - Detecção de outliers e pontos influentes
#
# ENTRADA:
#   - Modelos ajustados (modelo_MT/LP_*.rds) ou executa regressao_linear_multipla.r
#
# SAÍDA:
#   - testes_pressupostos_MT_<ts>.csv
#   - testes_pressupostos_LP_<ts>.csv
#   - vif_MT_<ts>.csv
#   - vif_LP_<ts>.csv
#   - plot_multicolinearidade_<ts>.png
#   - plot_outliers_MT_<ts>.png
#   - plot_outliers_LP_<ts>.png
#
# VERSÃO: 1.0 — Maio 2026
################################################################################

library(tidyverse)
library(car)
library(lmtest)
library(patchwork)

# =============================================================================
# DETECCAO AUTOMATICA DE CAMINHOS
# =============================================================================

detectar_raiz <- function() {
  cwd <- getwd()
  
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") {
      stop("Caminho não selecionado. Encerrando.")
    }
    return(raiz)
  } else {
    stop("Script não pode rodar em modo não-interativo.")
  }
}

RAIZ <- detectar_raiz()
DIR_MODELOS <- file.path(RAIZ, "TESTE/4_REGRESSAO_LINEAR/outputs_modelos")
DIR_DIAGNOSTICOS <- file.path(RAIZ, "TESTE/4_REGRESSAO_LINEAR/outputs_diagnosticos")
DIR_FIGURAS <- file.path(RAIZ, "TESTE/4_REGRESSAO_LINEAR/outputs_figuras")

# =============================================================================
# FUNCOES UTILITARIAS
# =============================================================================

arquivo_mais_recente <- function(pasta, padrao) {
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE)
  if (length(arqs) == 0L) return(NULL)
  arqs[which.max(file.info(arqs)$mtime)]
}

tema_saeb <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2, colour = "#1A1A1A"),
      plot.background = element_rect(fill = "#FFFFFF", colour = NA),
      panel.background = element_rect(fill = "#F5F5F5", colour = NA),
      panel.grid.major = element_line(colour = "#D0D0D0", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      plot.margin = margin(16, 16, 8, 16)
    )
}

# =============================================================================
# INICIALIZACAO
# =============================================================================

ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

message(strrep("=", 70))
message("TESTES DE PRESSUPOSTOS — REGRESSAO LINEAR")
message(strrep("=", 70))

# =============================================================================
# CARREGAR MODELOS
# =============================================================================

message("\nCarregando modelos ajustados...")

arq_mt <- arquivo_mais_recente(DIR_MODELOS, "^modelo_MT_.*\\.rds$")
arq_lp <- arquivo_mais_recente(DIR_MODELOS, "^modelo_LP_.*\\.rds$")

if (is.null(arq_mt) || is.null(arq_lp)) {
  stop("Modelos não encontrados. Execute regressao_linear_multipla.r primeiro.")
}

modelo_mt <- readRDS(arq_mt)
modelo_lp <- readRDS(arq_lp)

message("✓ Modelo MT: ", basename(arq_mt))
message("✓ Modelo LP: ", basename(arq_lp))

# =============================================================================
# TESTE 1: NORMALIDADE (Shapiro-Wilk)
# =============================================================================

message("\n", strrep("-", 50))
message("TESTE 1: NORMALIDADE DOS RESIDUOS")
message(strrep("-", 50))

# MT
shapiro_mt <- shapiro.test(residuals(modelo_mt))
msg_normal_mt <- ifelse(shapiro_mt$p.value < 0.05, 
                        "REJEITA normalidade", 
                        "NÃO REJEITA normalidade")

message("\nMedia_MT:")
message("  Estatística W: ", round(shapiro_mt$statistic, 4))
message("  P-valor: ", round(shapiro_mt$p.value, 4))
message("  Conclusão: ", msg_normal_mt)

# LP
shapiro_lp <- shapiro.test(residuals(modelo_lp))
msg_normal_lp <- ifelse(shapiro_lp$p.value < 0.05,
                        "REJEITA normalidade",
                        "NÃO REJEITA normalidade")

message("\nMedia_LP:")
message("  Estatística W: ", round(shapiro_lp$statistic, 4))
message("  P-valor: ", round(shapiro_lp$p.value, 4))
message("  Conclusão: ", msg_normal_lp)

# =============================================================================
# TESTE 2: HOMOCEDASTICIDADE (Breusch-Pagan)
# =============================================================================

message("\n", strrep("-", 50))
message("TESTE 2: HOMOCEDASTICIDADE (Breusch-Pagan)")
message(strrep("-", 50))

# MT
bp_mt <- bptest(modelo_mt)
msg_homo_mt <- ifelse(bp_mt$p.value < 0.05,
                      "REJEITA homocedasticidade (variância não-constante)",
                      "NÃO REJEITA homocedasticidade")

message("\nMedia_MT:")
message("  Estatística LM: ", round(bp_mt$statistic, 4))
message("  P-valor: ", round(bp_mt$p.value, 4))
message("  Conclusão: ", msg_homo_mt)

# LP
bp_lp <- bptest(modelo_lp)
msg_homo_lp <- ifelse(bp_lp$p.value < 0.05,
                      "REJEITA homocedasticidade (variância não-constante)",
                      "NÃO REJEITA homocedasticidade")

message("\nMedia_LP:")
message("  Estatística LM: ", round(bp_lp$statistic, 4))
message("  P-valor: ", round(bp_lp$p.value, 4))
message("  Conclusão: ", msg_homo_lp)

# =============================================================================
# TESTE 3: MULTICOLINEARIDADE (VIF)
# =============================================================================

message("\n", strrep("-", 50))
message("TESTE 3: MULTICOLINEARIDADE (Variance Inflation Factor)")
message(strrep("-", 50))

# Calcular VIF (excluindo intercept)
vif_mt <- vif(modelo_mt)
vif_lp <- vif(modelo_lp)

# Interpretação: VIF > 10 indica multicolinearidade severa; 5-10 é moderada
vif_mt_df <- tibble(
  Variavel = names(vif_mt),
  VIF = as.numeric(vif_mt),
  Severidade = case_when(
    VIF > 10 ~ "SEVERA",
    VIF > 5 ~ "MODERADA",
    TRUE ~ "Aceitável"
  )
) |> arrange(desc(VIF))

vif_lp_df <- tibble(
  Variavel = names(vif_lp),
  VIF = as.numeric(vif_lp),
  Severidade = case_when(
    VIF > 10 ~ "SEVERA",
    VIF > 5 ~ "MODERADA",
    TRUE ~ "Aceitável"
  )
) |> arrange(desc(VIF))

message("\nMedia_MT:")
print(vif_mt_df)

message("\nMedia_LP:")
print(vif_lp_df)

# Salvar VIF
write_csv(vif_mt_df, file.path(DIR_DIAGNOSTICOS, paste0("vif_MT_", ts_global, ".csv")))
write_csv(vif_lp_df, file.path(DIR_DIAGNOSTICOS, paste0("vif_LP_", ts_global, ".csv")))

# =============================================================================
# TESTE 4: INDEPENDENCIA (Durbin-Watson)
# =============================================================================

message("\n", strrep("-", 50))
message("TESTE 4: INDEPENDENCIA DOS RESIDUOS (Durbin-Watson)")
message(strrep("-", 50))

# MT: valor ideal é 2; se < 2 = autocorrelação positiva; se > 2 = negativa
dw_mt <- durbinWatsonTest(modelo_mt)
msg_indep_mt <- case_when(
  dw_mt[1] < 1.5 ~ "Autocorrelação POSITIVA",
  dw_mt[1] > 2.5 ~ "Autocorrelação NEGATIVA",
  TRUE ~ "Independência aceitável"
)

message("\nMedia_MT:")
message("  Estatística DW: ", round(dw_mt[1], 4))
message("  P-valor (lag 1): ", round(dw_mt[2], 4))
message("  Conclusão: ", msg_indep_mt)

# LP
dw_lp <- durbinWatsonTest(modelo_lp)
msg_indep_lp <- case_when(
  dw_lp[1] < 1.5 ~ "Autocorrelação POSITIVA",
  dw_lp[1] > 2.5 ~ "Autocorrelação NEGATIVA",
  TRUE ~ "Independência aceitável"
)

message("\nMedia_LP:")
message("  Estatística DW: ", round(dw_lp[1], 4))
message("  P-valor (lag 1): ", round(dw_lp[2], 4))
message("  Conclusão: ", msg_indep_lp)

# =============================================================================
# TABELA RESUMO DOS TESTES
# =============================================================================

resumo_testes <- tibble(
  Modelo = c("MEDIA_MT", "MEDIA_LP"),
  Normalidade_W = c(round(shapiro_mt$statistic, 4), round(shapiro_lp$statistic, 4)),
  Normalidade_p = c(round(shapiro_mt$p.value, 4), round(shapiro_lp$p.value, 4)),
  Homocedasticidade_LM = c(round(bp_mt$statistic, 4), round(bp_lp$statistic, 4)),
  Homocedasticidade_p = c(round(bp_mt$p.value, 4), round(bp_lp$p.value, 4)),
  VIF_max = c(max(vif_mt), max(vif_lp)),
  DW = c(round(dw_mt[1], 4), round(dw_lp[1], 4)),
  DW_p = c(round(dw_mt[2], 4), round(dw_lp[2], 4))
)

write_csv(resumo_testes, file.path(DIR_DIAGNOSTICOS, paste0("resumo_testes_", ts_global, ".csv")))

message("\n", strrep("-", 50))
message("RESUMO DE TODOS OS TESTES")
message(strrep("-", 50))
print(resumo_testes)

# =============================================================================
# DETECCAO DE OUTLIERS E PONTOS INFLUENTES
# =============================================================================

message("\n", strrep("-", 50))
message("DETECCAO DE OUTLIERS E PONTOS INFLUENTES")
message(strrep("-", 50))

# Cook's Distance MT
cook_mt <- cooks.distance(modelo_mt)
outliers_mt <- which(cook_mt > 4/nobs(modelo_mt))

message("\nMedia_MT:")
message("  Limiar de Cook's D: ", round(4/nobs(modelo_mt), 4))
message("  Observações influentes: ", length(outliers_mt))

if (length(outliers_mt) > 0) {
  message("  Índices: ", paste(head(outliers_mt, 10), collapse = ", "))
  if (length(outliers_mt) > 10) message("    ... e mais ", length(outliers_mt) - 10)
}

# Cook's Distance LP
cook_lp <- cooks.distance(modelo_lp)
outliers_lp <- which(cook_lp > 4/nobs(modelo_lp))

message("\nMedia_LP:")
message("  Limiar de Cook's D: ", round(4/nobs(modelo_lp), 4))
message("  Observações influentes: ", length(outliers_lp))

if (length(outliers_lp) > 0) {
  message("  Índices: ", paste(head(outliers_lp, 10), collapse = ", "))
  if (length(outliers_lp) > 10) message("    ... e mais ", length(outliers_lp) - 10)
}

# =============================================================================
# VISUALIZACOES: MULTICOLINEARIDADE
# =============================================================================

message("\nGerando gráficos de diagnóstico...")

# Combinar VIFs
vif_combined <- bind_rows(
  vif_mt_df |> mutate(Modelo = "MEDIA_MT"),
  vif_lp_df |> mutate(Modelo = "MEDIA_LP")
) |>
  mutate(
    Variavel = fct_reorder_within(Variavel, VIF, Modelo),
    Cor = case_when(
      VIF > 10 ~ "#D62728",
      VIF > 5 ~ "#FF7F0E",
      TRUE ~ "#2CA02C"
    )
  )

p_vif <- ggplot(vif_combined, aes(x = Variavel, y = VIF, fill = Cor)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = 5, linetype = "dashed", colour = "#FF7F0E", linewidth = 0.8) +
  geom_hline(yintercept = 10, linetype = "dashed", colour = "#D62728", linewidth = 0.8) +
  facet_wrap(~Modelo, scales = "free_x") +
  coord_flip() +
  scale_fill_identity() +
  labs(
    title = "Variance Inflation Factor (VIF) — Multicolinearidade",
    subtitle = "Linha laranja: VIF = 5 (moderada); Vermelha: VIF = 10 (severa)",
    x = "Variáveis",
    y = "VIF"
  ) +
  tema_saeb() +
  theme(axis.text.x = element_text(scales::label_number(accuracy = 0.1)))

ggsave(file.path(DIR_FIGURAS, paste0("multicolinearidade_VIF_", ts_global, ".png")),
       p_vif, width = 12, height = 8, dpi = 180, bg = "white")
message("Figura: multicolinearidade_VIF_", ts_global, ".png")

# =============================================================================
# VISUALIZACOES: OUTLIERS (Cook's Distance)
# =============================================================================

# MT
cook_mt_df <- tibble(
  obs = seq_along(cook_mt),
  cooks_d = cook_mt,
  eh_outlier = cook_mt > 4/nobs(modelo_mt)
) |>
  arrange(desc(cooks_d)) |>
  mutate(obs = as.factor(obs))

p_cook_mt <- ggplot(cook_mt_df |> slice(1:50), aes(x = reorder(obs, -cooks_d), y = cooks_d, fill = eh_outlier)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = 4/nobs(modelo_mt), linetype = "dashed", colour = "#D62728", linewidth = 1) +
  coord_flip() +
  scale_fill_manual(values = c("TRUE" = "#D62728", "FALSE" = "#1f77b4"),
                    labels = c("TRUE" = "Influente", "FALSE" = "Normal")) +
  labs(
    title = "Cook's Distance — 50 Observações com Maior Influência (MEDIA_MT)",
    x = "Índice da Observação",
    y = "Cook's Distance",
    fill = ""
  ) +
  tema_saeb() +
  theme(legend.position = "bottom")

ggsave(file.path(DIR_FIGURAS, paste0("outliers_cooks_MT_", ts_global, ".png")),
       p_cook_mt, width = 10, height = 10, dpi = 180, bg = "white")
message("Figura: outliers_cooks_MT_", ts_global, ".png")

# LP
cook_lp_df <- tibble(
  obs = seq_along(cook_lp),
  cooks_d = cook_lp,
  eh_outlier = cook_lp > 4/nobs(modelo_lp)
) |>
  arrange(desc(cooks_d)) |>
  mutate(obs = as.factor(obs))

p_cook_lp <- ggplot(cook_lp_df |> slice(1:50), aes(x = reorder(obs, -cooks_d), y = cooks_d, fill = eh_outlier)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = 4/nobs(modelo_lp), linetype = "dashed", colour = "#D62728", linewidth = 1) +
  coord_flip() +
  scale_fill_manual(values = c("TRUE" = "#D62728", "FALSE" = "#ff7f0e"),
                    labels = c("TRUE" = "Influente", "FALSE" = "Normal")) +
  labs(
    title = "Cook's Distance — 50 Observações com Maior Influência (MEDIA_LP)",
    x = "Índice da Observação",
    y = "Cook's Distance",
    fill = ""
  ) +
  tema_saeb() +
  theme(legend.position = "bottom")

ggsave(file.path(DIR_FIGURAS, paste0("outliers_cooks_LP_", ts_global, ".png")),
       p_cook_lp, width = 10, height = 10, dpi = 180, bg = "white")
message("Figura: outliers_cooks_LP_", ts_global, ".png")

# =============================================================================
# RELATORIO FINAL
# =============================================================================

message("\n", strrep("=", 70))
message("RESUMO DOS PRESSUPOSTOS")
message(strrep("=", 70))

message("\n✓ NORMALIDADE (Shapiro-Wilk):")
message("    MT: p = ", round(shapiro_mt$p.value, 4), " — ", msg_normal_mt)
message("    LP: p = ", round(shapiro_lp$p.value, 4), " — ", msg_normal_lp)

message("\n✓ HOMOCEDASTICIDADE (Breusch-Pagan):")
message("    MT: p = ", round(bp_mt$p.value, 4), " — ", msg_homo_mt)
message("    LP: p = ", round(bp_lp$p.value, 4), " — ", msg_homo_lp)

message("\n✓ MULTICOLINEARIDADE (VIF):")
message("    MT: max VIF = ", round(max(vif_mt), 2))
message("    LP: max VIF = ", round(max(vif_lp), 2))

message("\n✓ INDEPENDENCIA (Durbin-Watson):")
message("    MT: DW = ", round(dw_mt[1], 4), " — ", msg_indep_mt)
message("    LP: DW = ", round(dw_lp[1], 4), " — ", msg_indep_lp)

message("\n✓ OUTLIERS (Cook's Distance):")
message("    MT: ", length(outliers_mt), " observações influentes")
message("    LP: ", length(outliers_lp), " observações influentes")

message("\n", strrep("=", 70))
message("ARQUIVOS GERADOS")
message(strrep("=", 70))
message("  - resumo_testes_", ts_global, ".csv")
message("  - vif_MT_", ts_global, ".csv")
message("  - vif_LP_", ts_global, ".csv")
message("  - multicolinearidade_VIF_", ts_global, ".png")
message("  - outliers_cooks_MT_", ts_global, ".png")
message("  - outliers_cooks_LP_", ts_global, ".png")

message("\n", strrep("=", 70))
message("TESTES DE PRESSUPOSTOS CONCLUIDOS!")
message(strrep("=", 70))
