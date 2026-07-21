################################################################################
# SCRIPT: modelos_hierarquicos.r
#
# OBJETIVO: Modelos Hierárquicos Lineares (HLM) para dados aninhados
#           (alunos dentro de escolas)
#
# ENTRADA:
#   - TS_ALUNO_34EM.csv (dados brutos nível aluno)
#   - TS_ESCOLA.csv (metadados nível escola)
#
# SAÍDA:
#   - outputs/tabelas/resumo_hlm_*.csv (comparação de modelos)
#   - outputs/tabelas/icc_*.csv (coeficiente de correlação intraclasse)
#   - outputs/figuras/icc_varianca.png (Figura 19)
#   - outputs/figuras/efeitos_aleatorios.png (Figura 20)
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
DIR_MICRODADOS <- file.path(RAIZ, "MICRODADOS_SAEB_2023/DADOS")

DIR_BASE <- file.path(DIR_TESTE, "7_MODELOS_HIERARQUICOS")
DIR_FIGURAS <- file.path(DIR_BASE, "outputs/figuras")
DIR_TABELAS <- file.path(DIR_BASE, "outputs/tabelas")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_TABELAS, showWarnings = FALSE, recursive = TRUE)

ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSÁRIOS
# =========================================================================

pacotes_necessarios <- c("lme4", "performance", "lmerTest")
for (pkg in pacotes_necessarios) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Instalando pacote: ", pkg)
    install.packages(pkg, dependencies = TRUE)
  }
}

library(lme4)
library(performance)
library(lmerTest)

# =========================================================================
# PASSO 1: CARREGAR E PREPARAR DADOS
# =========================================================================

message(strrep("=", 70))
message("MODELOS HIERÁRQUICOS LINEARES (HLM)")
message(strrep("=", 70))

message("\n>>> Carregando dados brutos...")

dados_alunos <- fread(file.path(DIR_MICRODADOS, "TS_ALUNO_34EM.csv"))
message("Alunos carregados: ", nrow(dados_alunos))

# Selecionar colunas relevantes
dados_hlm <- dados_alunos %>%
  select(ID_ESCOLA, PROFICIENCIA_MT_SAEB, PROFICIENCIA_LP_SAEB,
         INSE_ALUNO, TX_RESP_Q01, TX_RESP_Q04) %>%
  mutate(
    PROFICIENCIA_MT_SAEB = as.numeric(PROFICIENCIA_MT_SAEB),
    PROFICIENCIA_LP_SAEB = as.numeric(PROFICIENCIA_LP_SAEB),
    INSE_ALUNO = as.numeric(INSE_ALUNO)
  ) %>%
  filter(!is.na(PROFICIENCIA_MT_SAEB), !is.na(PROFICIENCIA_LP_SAEB)) %>%
  filter(!is.na(ID_ESCOLA))

message("Alunos válidos: ", nrow(dados_hlm))
message("Escolas: ", length(unique(dados_hlm$ID_ESCOLA)))

# =========================================================================
# PASSO 2: MODELO NULO (APENAS INTERCEPTO ALEATÓRIO)
# =========================================================================

message("\n", strrep("-", 50))
message("MODELO NULO: Variância entre escolas")
message(strrep("-", 50))

# Modelo nulo para Matemática
modelo_nulo_mt <- lmer(PROFICIENCIA_MT_SAEB ~ 1 + (1 | ID_ESCOLA), data = dados_hlm)

# Modelo nulo para LP
modelo_nulo_lp <- lmer(PROFICIENCIA_LP_SAEB ~ 1 + (1 | ID_ESCOLA), data = dados_hlm)

# Calcular ICC (Intraclass Correlation Coefficient)
icc_mt <- performance::icc(modelo_nulo_mt)
icc_lp <- performance::icc(modelo_nulo_lp)

message("\n>>> ICC (Coeficiente de Correlação Intraclasse):")
message("  MT: ", round(icc_mt$ICC_adjusted, 4), " (", 
        round(icc_mt$ICC_adjusted * 100, 1), "% da variância entre escolas)")
message("  LP: ", round(icc_lp$ICC_adjusted, 4), " (", 
        round(icc_lp$ICC_adjusted * 100, 1), "% da variância entre escolas)")

message("\nInterpretação:")
if (icc_mt$ICC_adjusted > 0.20) {
  message("  ✓ ICC alto (>20%): estrutura hierárquica importante — HLM necessário")
} else if (icc_mt$ICC_adjusted > 0.10) {
  message("  ⚠ ICC moderado (10-20%): HLM recomendado")
} else {
  message("  ✗ ICC baixo (<10%): estrutura hierárquica menos relevante")
}

# =========================================================================
# PASSO 3: MODELO 1 (INSE COMO PREDITOR FIXO)
# =========================================================================

message("\n", strrep("-", 50))
message("MODELO 1: INSE como preditor fixo")
message(strrep("-", 50))

modelo1_mt <- lmer(PROFICIENCIA_MT_SAEB ~ INSE_ALUNO + (1 | ID_ESCOLA), data = dados_hlm)
modelo1_lp <- lmer(PROFICIENCIA_LP_SAEB ~ INSE_ALUNO + (1 | ID_ESCOLA), data = dados_hlm)

message("\n>>> Modelo 1 — MT:")
message("  R² marginal (INSE): ", round(performance::r2(modelo1_mt)$R2_marginal, 4))
message("  R² condicional (INSE + escola): ", round(performance::r2(modelo1_mt)$R2_conditional, 4))

message("\n>>> Modelo 1 — LP:")
message("  R² marginal (INSE): ", round(performance::r2(modelo1_lp)$R2_marginal, 4))
message("  R² condicional (INSE + escola): ", round(performance::r2(modelo1_lp)$R2_conditional, 4))

# =========================================================================
# PASSO 4: MODELO 2 (+ VARIÁVEIS DE CONTEXTO)
# =========================================================================

message("\n", strrep("-", 50))
message("MODELO 2: + Variáveis de contexto")
message(strrep("-", 50))

# Preparar variáveis de contexto (agregar por escola)
contexto_escola <- dados_hlm %>%
  group_by(ID_ESCOLA) %>%
  summarise(
    INSE_MEDIO = mean(INSE_ALUNO, na.rm = TRUE),
    N_ALUNOS = n(),
    .groups = "drop"
  )

dados_hlm2 <- dados_hlm %>%
  left_join(contexto_escola, by = "ID_ESCOLA")

# Modelo 2: INSE individual + INSE médio da escola
modelo2_mt <- lmer(PROFICIENCIA_MT_SAEB ~ INSE_ALUNO + INSE_MEDIO + (1 | ID_ESCOLA), data = dados_hlm2)
modelo2_lp <- lmer(PROFICIENCIA_LP_SAEB ~ INSE_ALUNO + INSE_MEDIO + (1 | ID_ESCOLA), data = dados_hlm2)

message("\n>>> Modelo 2 — MT:")
message("  R² marginal: ", round(performance::r2(modelo2_mt)$R2_marginal, 4))
message("  R² condicional: ", round(performance::r2(modelo2_mt)$R2_conditional, 4))

message("\n>>> Modelo 2 — LP:")
message("  R² marginal: ", round(performance::r2(modelo2_lp)$R2_marginal, 4))
message("  R² condicional: ", round(performance::r2(modelo2_lp)$R2_conditional, 4))

# =========================================================================
# PASSO 5: COMPARAR MODELOS
# =========================================================================

message("\n", strrep("-", 50))
message("COMPARAÇÃO DE MODELOS (Likelihood Ratio Test)")
message(strrep("-", 50))

# Comparar modelos MT
comp_mt <- anova(modelo_nulo_mt, modelo1_mt, modelo2_mt)
message("\n>>> Comparação — Matemática:")
print(comp_mt)

# Comparar modelos LP
comp_lp <- anova(modelo_nulo_lp, modelo1_lp, modelo2_lp)
message("\n>>> Comparação — Língua Portuguesa:")
print(comp_lp)

# =========================================================================
# PASSO 6: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

# Tabela de ICC
icc_df <- tibble(
  Disciplina = c("Matemática", "Língua Portuguesa"),
  ICC = c(icc_mt$ICC_adjusted, icc_lp$ICC_adjusted),
  Variância_Entre_Escolas = c(icc_mt$ICC_adjusted * 100, icc_lp$ICC_adjusted * 100),
  Variância_Dentro_Escola = c((1 - icc_mt$ICC_adjusted) * 100, (1 - icc_lp$ICC_adjusted) * 100),
  Interpretação = c(
    ifelse(icc_mt$ICC_adjusted > 0.20, "Alto", ifelse(icc_mt$ICC_adjusted > 0.10, "Moderado", "Baixo")),
    ifelse(icc_lp$ICC_adjusted > 0.20, "Alto", ifelse(icc_lp$ICC_adjusted > 0.10, "Moderado", "Baixo"))
  )
)

write_csv(icc_df, file.path(DIR_TABELAS, paste0("icc_", ts_global, ".csv")))

# Tabela de comparação de modelos
resumo_modelos <- tibble(
  Modelo = c("Nulo", "Modelo 1 (INSE)", "Modelo 2 (INSE + Contexto)"),
  AIC_MT = c(AIC(modelo_nulo_mt), AIC(modelo1_mt), AIC(modelo2_mt)),
  BIC_MT = c(BIC(modelo_nulo_mt), BIC(modelo1_mt), BIC(modelo2_mt)),
  R2_Marginal_MT = c(NA, performance::r2(modelo1_mt)$R2_marginal, performance::r2(modelo2_mt)$R2_marginal),
  R2_Condicional_MT = c(performance::r2(modelo_nulo_mt)$R2_conditional, 
                        performance::r2(modelo1_mt)$R2_conditional,
                        performance::r2(modelo2_mt)$R2_conditional),
  AIC_LP = c(AIC(modelo_nulo_lp), AIC(modelo1_lp), AIC(modelo2_lp)),
  BIC_LP = c(BIC(modelo_nulo_lp), BIC(modelo1_lp), BIC(modelo2_lp)),
  R2_Marginal_LP = c(NA, performance::r2(modelo1_lp)$R2_marginal, performance::r2(modelo2_lp)$R2_marginal),
  R2_Condicional_LP = c(performance::r2(modelo_nulo_lp)$R2_conditional,
                        performance::r2(modelo1_lp)$R2_conditional,
                        performance::r2(modelo2_lp)$R2_conditional)
)

write_csv(resumo_modelos, file.path(DIR_TABELAS, paste0("resumo_hlm_", ts_global, ".csv")))

message("   ✓ icc_", ts_global, ".csv")
message("   ✓ resumo_hlm_", ts_global, ".csv")

# =========================================================================
# PASSO 7: VISUALIZAÇÕES
# =========================================================================

message("\n>>> Gerando figuras...")

# -------------------------------------------------------------------------
# Figura 19: Decomposição da Variância (ICC)
# -------------------------------------------------------------------------
dados_icc <- icc_df %>%
  pivot_longer(cols = c(Variância_Entre_Escolas, Variância_Dentro_Escola),
               names_to = "Componente", values_to = "Percentual") %>%
  mutate(Componente = recode(Componente,
                             "Variância_Entre_Escolas" = "Entre Escolas",
                             "Variância_Dentro_Escola" = "Dentro de Escolas"))

p_icc <- dados_icc %>%
  ggplot(aes(x = Disciplina, y = Percentual, fill = Componente)) +
  geom_bar(stat = "identity", position = "stack", width = 0.5) +
  scale_fill_manual(values = c("Entre Escolas" = "#E74C3C", "Dentro de Escolas" = "#3498DB")) +
  geom_text(aes(label = paste0(round(Percentual, 1), "%")),
            position = position_stack(vjust = 0.5), size = 5, fontface = "bold") +
  labs(
    title = "Figura 19 — Decomposição da Variância (ICC)",
    subtitle = "Proporção da variância da proficiência entre e dentro de escolas",
    x = NULL,
    y = "Percentual da Variância (%)",
    fill = "Componente"
  ) +
  tema_saeb() +
  theme(legend.position = "bottom")

ggsave(file.path(DIR_FIGURAS, paste0("icc_varianca_", ts_global, ".png")),
       plot = p_icc, width = 10, height = 7, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 19: icc_varianca_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 20: Efeitos Aleatórios por Escola (Top 20)
# -------------------------------------------------------------------------
efeitos_mt <- ranef(modelo_nulo_mt)$ID_ESCOLA %>%
  as.data.frame() %>%
  rownames_to_column("ID_ESCOLA") %>%
  rename(Efeito = `(Intercept)`) %>%
  arrange(desc(abs(Efeito))) %>%
  head(20) %>%
  mutate(Disciplina = "Matemática")

efeitos_lp <- ranef(modelo_nulo_lp)$ID_ESCOLA %>%
  as.data.frame() %>%
  rownames_to_column("ID_ESCOLA") %>%
  rename(Efeito = `(Intercept)`) %>%
  arrange(desc(abs(Efeito))) %>%
  head(20) %>%
  mutate(Disciplina = "Língua Portuguesa")

efeitos_plot <- bind_rows(efeitos_mt, efeitos_lp) %>%
  mutate(
    ID_ESCOLA = factor(ID_ESCOLA, levels = ID_ESCOLA[order(Efeito)]),
    Direção = ifelse(Efeito > 0, "Acima da média", "Abaixo da média")
  )

p_efeitos <- efeitos_plot %>%
  ggplot(aes(x = Efeito, y = ID_ESCOLA, fill = Direção)) +
  geom_col(width = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  scale_fill_manual(values = c("Acima da média" = "#27AE60", "Abaixo da média" = "#E74C3C")) +
  facet_wrap(~Disciplina, scales = "free_y") +
  labs(
    title = "Figura 20 — Efeitos Aleatórios por Escola (Top 20)",
    subtitle = "Desvio da proficiência média geral para cada escola",
    x = "Efeito Aleatório (desvio da média geral)",
    y = "Escola (ID)",
    fill = "Direção"
  ) +
  tema_saeb() +
  theme(legend.position = "bottom")

ggsave(file.path(DIR_FIGURAS, paste0("efeitos_aleatorios_", ts_global, ".png")),
       plot = p_efeitos, width = 14, height = 10, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 20: efeitos_aleatorios_", ts_global, ".png")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("MODELOS HIERÁRQUICOS CONCLUÍDOS")
message(strrep("=", 70))
message("Alunos analisados: ", nrow(dados_hlm))
message("Escolas: ", length(unique(dados_hlm$ID_ESCOLA)))
message("\nICC:")
message("  MT: ", round(icc_mt$ICC_adjusted * 100, 1), "% da variância entre escolas")
message("  LP: ", round(icc_lp$ICC_adjusted * 100, 1), "% da variância entre escolas")
message("\nFiguras geradas:")
message("  • Figura 19: icc_varianca_", ts_global, ".png")
message("  • Figura 20: efeitos_aleatorios_", ts_global, ".png")
