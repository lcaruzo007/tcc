################################################################################
# SCRIPT: validacao_cruzada.r
#
# OBJETIVO: Validação cruzada K-fold + curva ROC para avaliar qualidade
#           preditiva dos modelos de regressão
#
# ENTRADA:
#   - metadados_escolas_*.csv (PASSO 4)
#
# SAÍDA:
#   - outputs/tabelas/cv_resultados_*.csv (métricas por fold)
#   - outputs/figuras/roc_curve_MT.png (Figura 23)
#   - outputs/figuras/roc_curve_LP.png (Figura 24)
#   - outputs/figuras/cv_metricas.png (Figura 25)
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

DIR_BASE <- file.path(DIR_TESTE, "9_VALIDACAO_CRUZADA")
DIR_FIGURAS <- file.path(DIR_BASE, "outputs/figuras")
DIR_TABELAS <- file.path(DIR_BASE, "outputs/tabelas")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_TABELAS, showWarnings = FALSE, recursive = TRUE)

ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSÁRIOS
# =========================================================================

pacotes_necessarios <- c("caret", "pROC")
for (pkg in pacotes_necessarios) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Instalando pacote: ", pkg)
    install.packages(pkg, dependencies = TRUE)
  }
}

library(caret)
library(pROC)

# =========================================================================
# PASSO 1: CARREGAR E PREPARAR DADOS
# =========================================================================

message(strrep("=", 70))
message("VALIDAÇÃO CRUZADA + CURVA ROC")
message(strrep("=", 70))

arq_meta <- encontrar_arquivo_mais_recente(DIR_METADADOS, "metadados_escolas")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv não encontrado.")

metadados <- read_csv(arq_meta, show_col_types = FALSE) %>%
  filter(!is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO)) %>%
  filter(TIPO_ESCOLA %in% c("Pública", "Privada")) %>%
  filter(LOCALIZACAO %in% c("Urbana", "Rural")) %>%
  filter(AREA %in% c("Capital", "Interior")) %>%
  mutate(
    TIPO_PRIVADA = as.integer(TIPO_ESCOLA == "Privada"),
    LOCAL_RURAL = as.integer(LOCALIZACAO == "Rural"),
    AREA_INTERIOR = as.integer(AREA == "Interior"),
    INSE_norm = as.numeric(scale(INSE_MEDIO))
  )

message("Escolas válidas: ", nrow(metadados))

# =========================================================================
# PASSO 2: VALIDAÇÃO CRUZADA K-FOLD (REGRESSÃO)
# =========================================================================

message("\n", strrep("-", 50))
message("VALIDAÇÃO CRUZADA 10-FOLD")
message(strrep("-", 50))

K_FOLDS <- 10

# Preparar dados para regressão
dados_reg <- metadados %>%
  select(MEDIA_MT, MEDIA_LP, INSE_norm, TIPO_PRIVADA, LOCAL_RURAL, AREA_INTERIOR)

# Criar folds estratificados por TIPO_ESCOLA
set.seed(42)
folds <- createFolds(metadados$TIPO_ESCOLA, k = K_FOLDS, list = TRUE, returnTrain = FALSE)

# Resultados da validação cruzada
cv_resultados_mt <- list()
cv_resultados_lp <- list()

for (i in 1:K_FOLDS) {
  teste_idx <- folds[[i]]
  treino <- dados_reg[-teste_idx, ]
  teste <- dados_reg[teste_idx, ]
  
  # Treinar modelo
  modelo_mt <- lm(MEDIA_MT ~ INSE_norm + TIPO_PRIVADA + LOCAL_RURAL + AREA_INTERIOR, data = treino)
  modelo_lp <- lm(MEDIA_LP ~ INSE_norm + TIPO_PRIVADA + LOCAL_RURAL + AREA_INTERIOR, data = treino)
  
  # Prever no fold de teste
  pred_mt <- predict(modelo_mt, newdata = teste)
  pred_lp <- predict(modelo_lp, newdata = teste)
  
  # Métricas
  rmse_mt <- sqrt(mean((teste$MEDIA_MT - pred_mt)^2))
  mae_mt <- mean(abs(teste$MEDIA_MT - pred_mt))
  r2_mt <- cor(teste$MEDIA_MT, pred_mt)^2
  
  rmse_lp <- sqrt(mean((teste$MEDIA_LP - pred_lp)^2))
  mae_lp <- mean(abs(teste$MEDIA_LP - pred_lp))
  r2_lp <- cor(teste$MEDIA_LP, pred_lp)^2
  
  cv_resultados_mt[[i]] <- tibble(Fold = i, RMSE = rmse_mt, MAE = mae_mt, R2 = r2_mt)
  cv_resultados_lp[[i]] <- tibble(Fold = i, RMSE = rmse_lp, MAE = mae_lp, R2 = r2_lp)
  
  message("  Fold ", i, "/", K_FOLDS, " — MT: RMSE=", round(rmse_mt, 2), 
          " | LP: RMSE=", round(rmse_lp, 2))
}

# Consolidar resultados
cv_mt <- bind_rows(cv_resultados_mt)
cv_lp <- bind_rows(cv_resultados_lp)

message("\n>>> Resultados Médios (", K_FOLDS, "-fold CV):")
message("  MT — RMSE: ", round(mean(cv_mt$RMSE), 2), " ± ", round(sd(cv_mt$RMSE), 2),
        " | MAE: ", round(mean(cv_mt$MAE), 2), " | R²: ", round(mean(cv_mt$R2), 4))
message("  LP — RMSE: ", round(mean(cv_lp$RMSE), 2), " ± ", round(sd(cv_lp$RMSE), 2),
        " | MAE: ", round(mean(cv_lp$MAE), 2), " | R²: ", round(mean(cv_lp$R2), 4))

# =========================================================================
# PASSO 3: CURVA ROC (CLASSIFICAÇÃO BINÁRIA)
# =========================================================================

message("\n", strrep("-", 50))
message("CURVA ROC — Classificação de Alto Desempenho")
message(strrep("-", 50))

# Definir "alto desempenho" como top 25% de proficiência
q75_mt <- quantile(metadados$MEDIA_MT, 0.75)
q75_lp <- quantile(metadados$MEDIA_LP, 0.75)

metadados <- metadados %>%
  mutate(
    ALTO_MT = factor(ifelse(MEDIA_MT >= q75_mt, "Alto", "Baixo"), levels = c("Baixo", "Alto")),
    ALTO_LP = factor(ifelse(MEDIA_LP >= q75_lp, "Alto", "Baixo"), levels = c("Baixo", "Alto"))
  )

message("Alto desempenho MT: ", sum(metadados$ALTO_MT == "Alto"), " escolas (", 
        round(mean(metadados$ALTO_MT == "Alto") * 100, 1), "%)")
message("Alto desempenho LP: ", sum(metadados$ALTO_LP == "Alto"), " escolas (", 
        round(mean(metadados$ALTO_LP == "Alto") * 100, 1), "%)")

# Modelo de classificação com validação cruzada
# Usar predições do modelo de regressão como scores

dados_class <- metadados %>%
  select(MEDIA_MT, MEDIA_LP, ALTO_MT, ALTO_LP, INSE_norm, TIPO_PRIVADA, LOCAL_RURAL, AREA_INTERIOR)

# Treinar modelo de classificação (logístico) usando CV
set.seed(42)
folds_class <- createFolds(dados_class$ALTO_MT, k = K_FOLDS, list = TRUE, returnTrain = FALSE)

pred_probs_mt <- numeric(nrow(dados_class))
pred_probs_lp <- numeric(nrow(dados_class))

for (i in 1:K_FOLDS) {
  teste_idx <- folds_class[[i]]
  treino <- dados_class[-teste_idx, ]
  
  # Modelo logístico para MT
  modelo_log_mt <- glm(ALTO_MT ~ INSE_norm + TIPO_PRIVADA + LOCAL_RURAL + AREA_INTERIOR,
                        data = treino, family = "binomial")
  pred_probs_mt[teste_idx] <- predict(modelo_log_mt, newdata = dados_class[teste_idx, ], type = "response")
  
  # Modelo logístico para LP
  modelo_log_lp <- glm(ALTO_LP ~ INSE_norm + TIPO_PRIVADA + LOCAL_RURAL + AREA_INTERIOR,
                        data = treino, family = "binomial")
  pred_probs_lp[teste_idx] <- predict(modelo_log_lp, newdata = dados_class[teste_idx, ], type = "response")
}

# Calcular ROC
roc_mt <- roc(dados_class$ALTO_MT, pred_probs_mt, direction = "<")
roc_lp <- roc(dados_class$ALTO_LP, pred_probs_lp, direction = "<")

message("\n>>> AUC (Area Under the Curve):")
message("  MT: AUC = ", round(auc(roc_mt), 4), 
        " IC 95% [", round(ci.auc(roc_mt)$ci[1], 4), ", ", round(ci.auc(roc_mt)$ci[3], 4), "]")
message("  LP: AUC = ", round(auc(roc_lp), 4),
        " IC 95% [", round(ci.auc(roc_lp)$ci[1], 4), ", ", round(ci.auc(roc_lp)$ci[3], 4), "]")

# =========================================================================
# PASSO 4: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

# Tabela de CV
cv_completo <- bind_rows(
  cv_mt %>% mutate(Disciplina = "Matemática"),
  cv_lp %>% mutate(Disciplina = "Língua Portuguesa")
)

write_csv(cv_completo, file.path(DIR_TABELAS, paste0("cv_resultados_", ts_global, ".csv")))

# Tabela de resumo
resumo_cv <- tibble(
  Disciplina = c("Matemática", "Língua Portuguesa"),
  RMSE_Medio = c(mean(cv_mt$RMSE), mean(cv_lp$RMSE)),
  RMSE_SD = c(sd(cv_mt$RMSE), sd(cv_lp$RMSE)),
  MAE_Medio = c(mean(cv_mt$MAE), mean(cv_lp$MAE)),
  R2_Medio = c(mean(cv_mt$R2), mean(cv_lp$R2)),
  R2_SD = c(sd(cv_mt$R2), sd(cv_lp$R2)),
  AUC = c(auc(roc_mt), auc(roc_lp)),
  AUC_IC_inf = c(ci.auc(roc_mt)$ci[1], ci.auc(roc_lp)$ci[1]),
  AUC_IC_sup = c(ci.auc(roc_mt)$ci[3], ci.auc(roc_lp)$ci[3])
) %>%
  mutate(across(where(is.numeric), ~ round(., 4)))

write_csv(resumo_cv, file.path(DIR_TABELAS, paste0("cv_resumo_", ts_global, ".csv")))

message("   ✓ cv_resultados_", ts_global, ".csv")
message("   ✓ cv_resumo_", ts_global, ".csv")

# =========================================================================
# PASSO 5: VISUALIZAÇÕES
# =========================================================================

message("\n>>> Gerando figuras...")

# -------------------------------------------------------------------------
# Figura 23: Curva ROC — Matemática
# -------------------------------------------------------------------------
roc_df_mt <- data.frame(
  FPR = 1 - roc_mt$specificities,
  TPR = roc_mt$sensitivities
)

p23 <- ggplot(roc_df_mt, aes(x = FPR, y = TPR)) +
  geom_line(color = "#1B4F9A", linewidth = 1.5) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
  geom_area(alpha = 0.15, fill = "#1B4F9A") +
  annotate("text", x = 0.6, y = 0.3,
           label = paste0("AUC = ", round(auc(roc_mt), 3),
                          "\nIC 95% [", round(ci.auc(roc_mt)$ci[1], 3),
                          ", ", round(ci.auc(roc_mt)$ci[3], 3), "]"),
           size = 5, fontface = "bold", color = "#1B4F9A",
           hjust = 0) +
  labs(
    title = "Figura 23 — Curva ROC (Matemática)",
    subtitle = "Classificação de escolas com alto desempenho (top 25%)",
    x = "Taxa de Falsos Positivos (1 - Especificidade)",
    y = "Taxa de Verdadeiros Positivos (Sensibilidade)"
  ) +
  tema_saeb() +
  coord_equal()

ggsave(file.path(DIR_FIGURAS, paste0("roc_curve_MT_", ts_global, ".png")),
       plot = p23, width = 9, height = 9, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 23: roc_curve_MT_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 24: Curva ROC — Língua Portuguesa
# -------------------------------------------------------------------------
roc_df_lp <- data.frame(
  FPR = 1 - roc_lp$specificities,
  TPR = roc_lp$sensitivities
)

p24 <- ggplot(roc_df_lp, aes(x = FPR, y = TPR)) +
  geom_line(color = "#1A6B3A", linewidth = 1.5) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
  geom_area(alpha = 0.15, fill = "#1A6B3A") +
  annotate("text", x = 0.6, y = 0.3,
           label = paste0("AUC = ", round(auc(roc_lp), 3),
                          "\nIC 95% [", round(ci.auc(roc_lp)$ci[1], 3),
                          ", ", round(ci.auc(roc_lp)$ci[3], 3), "]"),
           size = 5, fontface = "bold", color = "#1A6B3A",
           hjust = 0) +
  labs(
    title = "Figura 24 — Curva ROC (Língua Portuguesa)",
    subtitle = "Classificação de escolas com alto desempenho (top 25%)",
    x = "Taxa de Falsos Positivos (1 - Especificidade)",
    y = "Taxa de Verdadeiros Positivos (Sensibilidade)"
  ) +
  tema_saeb() +
  coord_equal()

ggsave(file.path(DIR_FIGURAS, paste0("roc_curve_LP_", ts_global, ".png")),
       plot = p24, width = 9, height = 9, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 24: roc_curve_LP_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 25: Métricas de CV por Fold
# -------------------------------------------------------------------------
cv_plot <- cv_completo %>%
  pivot_longer(cols = c(RMSE, MAE, R2), names_to = "Métrica", values_to = "Valor") %>%
  ggplot(aes(x = factor(Fold), y = Valor, fill = Disciplina)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.8) +
  facet_wrap(~Métrica, scales = "free_y") +
  scale_fill_manual(values = PALETA_DISCIPLINA) +
  labs(
    title = "Figura 25 — Métricas de Validação Cruzada por Fold",
    subtitle = paste0(K_FOLDS, "-fold CV estratificado por tipo de escola"),
    x = "Fold",
    y = "Valor da Métrica",
    fill = "Disciplina"
  ) +
  tema_saeb() +
  theme(legend.position = "bottom")

ggsave(file.path(DIR_FIGURAS, paste0("cv_metricas_", ts_global, ".png")),
       plot = cv_plot, width = 14, height = 8, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 25: cv_metricas_", ts_global, ".png")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("VALIDAÇÃO CRUZADA CONCLUÍDA")
message(strrep("=", 70))
message("Escolas analisadas: ", nrow(metadados))
message("Folds: ", K_FOLDS)
message("\nResumo:")
print(resumo_cv)
message("\nFiguras geradas:")
message("  • Figura 23: roc_curve_MT_", ts_global, ".png")
message("  • Figura 24: roc_curve_LP_", ts_global, ".png")
message("  • Figura 25: cv_metricas_", ts_global, ".png")
