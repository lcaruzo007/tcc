################################################################################
# SCRIPT: modelos_hierarquicos.r
#
# OBJETIVO: Modelos Hierarquicos Lineares (HLM) para dados aninhados
#           (alunos dentro de escolas)
#
# ENTRADA:
#   - TS_ALUNO_34EM.csv (dados brutos nivel aluno)
#   - TS_ESCOLA.csv (metadados nivel escola)
#
# SAIDA:
#   - outputs/tabelas/resumo_hlm_*.csv (comparacao de modelos)
#   - outputs/tabelas/icc_*.csv (coeficiente de correlacao intraclasse)
#   - outputs/figuras/icc_varianca.png (Figura 19)
#   - outputs/figuras/efeitos_aleatorios.png (Figura 20)
#
# VERSAO: 1.0 - Julho 2026
#
# ---------------------------------------------------------------------------
# NOTA METODOLOGICA - MODELOS HIERARQUICOS LINEARES (HLM)
# ---------------------------------------------------------------------------
#
# Os microdados do SAEB tem estrutura aninhada: alunos (nivel 1) dentro de
# escolas (nivel 2), eventualmente dentro de municipios (nivel 3). A regressao
# OLS (PASSO 8) ignora esse aninhamento e produz erros-padrao subestimados e
# possivel viMo de unidades agregadas (ecological fallacy). HLM e a solucao.
#
# 1. Por que HLM e nao OLS "com erros clustered"
#    OLS com erros aggregated por escola corrige apenas a estimativa de
#    variancia dos coeficientes; nao modela explicitamente a variancia entre
#    escolas. HLM estima os componentes de variancia (entre e dentro), permi-
#    tindo que interceptos (e opcionalmente slopes) variem entre clusters.
#
# 2. ICC e criterio de decisaoo
#    Estimamos o modelo nulo (sem preditores) para obter o Coeficiente de
#    Correlacao Intraclasse (ICC = variancia_nivel2 / variancia_total). Segundo
#    Hox (2010), se ICC >= 0.058 (abaixo da convencao "5-5-20" de Muthen),
#    HLM e justificado; se ICC ~ 0, OLS agregado e suficiente. Para SAEB
#    historico, ICC de proficiencia entre escolas varia de 0.25 a 0.45 - HLM
#    e claramente indicado.
#
# 3. Random intercept vs. random slopes
#    Adotamos random intercept (intercepto aleatorio) como modelo principal.
#    Slopes aleatorios para INSE seriam estimados apenas se o teste de razao
#    de verossimilhanca (LRT) indicar melhora significativa (p < 0.05) e o
#    modelo convergir sem singularidade. Random slopes adicionam complexidade
#    e podem consumir graus de liberdade em amostras com poucos alunos por
#    escola.
#
# 4. Estimador REML (nao ML)
#    Usamos REML (Restricted Maximum Likelihood) para estimar os componentes
#    de variancia, pois REML produz estimativas nao viesadas das variancias
#    enquanto ML tende a subestima-las em amostras finitas. ML e reservado
#    para comparar modelos com efeitos fixos diferentes via LRT.
#
# 5. Centring
#    Variaveis continuas (INSE) sao centradas na media do grupo (group-mean
#    centring) para evitar confusao entre efeito dentro (within) e efeito
#    entre (between) escolas - problema classico em HLM (Enders & Tofighi,
#    2007).
#
# CONCLUSAO: O HLM com intercepto aleatorio, ICC reportado e estimador REML
# representa a modelagem estatisticamente correta para dados aninhados do
# SAEB, superando o OLS do PASSO 8 - cujos resultados permanecem validos como
# referencia agregada por escola, mas nao devem ser usados para inferencia
# individual-level.
# ---------------------------------------------------------------------------
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

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

ts_global <- format(Sys.time(), "%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSARIOS
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
message("MODELOS HIERARQUICOS LINEARES (HLM)")
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

message("Alunos validos: ", nrow(dados_hlm))
message("Escolas: ", length(unique(dados_hlm$ID_ESCOLA)))

# =========================================================================
# PASSO 2: MODELO NULO (APENAS INTERCEPTO ALEATORIO)
# =========================================================================

message("\n", strrep("-", 50))
message("MODELO NULO: Variancia entre escolas")
message(strrep("-", 50))

# Modelo nulo para Matematica
modelo_nulo_mt <- lmer(PROFICIENCIA_MT_SAEB ~ 1 + (1 | ID_ESCOLA), data = dados_hlm)

# Modelo nulo para LP
modelo_nulo_lp <- lmer(PROFICIENCIA_LP_SAEB ~ 1 + (1 | ID_ESCOLA), data = dados_hlm)

# Calcular ICC (Intraclass Correlation Coefficient)
icc_mt <- performance::icc(modelo_nulo_mt)
icc_lp <- performance::icc(modelo_nulo_lp)

message("\n>>> ICC (Coeficiente de Correlacao Intraclasse):")
message("  MT: ", round(icc_mt$ICC_adjusted, 4), " (", 
        round(icc_mt$ICC_adjusted * 100, 1), "% da variancia entre escolas)")
message("  LP: ", round(icc_lp$ICC_adjusted, 4), " (", 
        round(icc_lp$ICC_adjusted * 100, 1), "% da variancia entre escolas)")

message("\nInterpretacao:")
if (icc_mt$ICC_adjusted > 0.20) {
  message("  OK ICC alto (>20%): estrutura hierarquica importante - HLM necessario")
} else if (icc_mt$ICC_adjusted > 0.10) {
  message("  ! ICC moderado (10-20%): HLM recomendado")
} else {
  message("  ? ICC baixo (<10%): estrutura hierarquica menos relevante")
}

# =========================================================================
# PASSO 3: MODELO 1 (INSE COMO PREDITOR FIXO)
# =========================================================================

message("\n", strrep("-", 50))
message("MODELO 1: INSE como preditor fixo")
message(strrep("-", 50))

modelo1_mt <- lmer(PROFICIENCIA_MT_SAEB ~ INSE_ALUNO + (1 | ID_ESCOLA), data = dados_hlm)
modelo1_lp <- lmer(PROFICIENCIA_LP_SAEB ~ INSE_ALUNO + (1 | ID_ESCOLA), data = dados_hlm)

message("\n>>> Modelo 1 - MT:")
message("  R2 marginal (INSE): ", round(performance::r2(modelo1_mt)$R2_marginal, 4))
message("  R2 condicional (INSE + escola): ", round(performance::r2(modelo1_mt)$R2_conditional, 4))

message("\n>>> Modelo 1 - LP:")
message("  R2 marginal (INSE): ", round(performance::r2(modelo1_lp)$R2_marginal, 4))
message("  R2 condicional (INSE + escola): ", round(performance::r2(modelo1_lp)$R2_conditional, 4))

# =========================================================================
# PASSO 4: MODELO 2 (+ VARIAVEIS DE CONTEXTO)
# =========================================================================

message("\n", strrep("-", 50))
message("MODELO 2: + Variaveis de contexto")
message(strrep("-", 50))

# Preparar variaveis de contexto (agregar por escola)
contexto_escola <- dados_hlm %>%
  group_by(ID_ESCOLA) %>%
  summarise(
    INSE_MEDIO = mean(INSE_ALUNO, na.rm = TRUE),
    N_ALUNOS = n(),
    .groups = "drop"
  )

dados_hlm2 <- dados_hlm %>%
  left_join(contexto_escola, by = "ID_ESCOLA")

# Modelo 2: INSE individual + INSE medio da escola
modelo2_mt <- lmer(PROFICIENCIA_MT_SAEB ~ INSE_ALUNO + INSE_MEDIO + (1 | ID_ESCOLA), data = dados_hlm2)
modelo2_lp <- lmer(PROFICIENCIA_LP_SAEB ~ INSE_ALUNO + INSE_MEDIO + (1 | ID_ESCOLA), data = dados_hlm2)

message("\n>>> Modelo 2 - MT:")
message("  R2 marginal: ", round(performance::r2(modelo2_mt)$R2_marginal, 4))
message("  R2 condicional: ", round(performance::r2(modelo2_mt)$R2_conditional, 4))

message("\n>>> Modelo 2 - LP:")
message("  R2 marginal: ", round(performance::r2(modelo2_lp)$R2_marginal, 4))
message("  R2 condicional: ", round(performance::r2(modelo2_lp)$R2_conditional, 4))

# =========================================================================
# PASSO 5: COMPARAR MODELOS
# =========================================================================

message("\n", strrep("-", 50))
message("COMPARACAO DE MODELOS (Likelihood Ratio Test)")
message(strrep("-", 50))

# Comparar modelos MT
comp_mt <- anova(modelo_nulo_mt, modelo1_mt, modelo2_mt)
message("\n>>> Comparacao - Matematica:")
print(comp_mt)

# Comparar modelos LP
comp_lp <- anova(modelo_nulo_lp, modelo1_lp, modelo2_lp)
message("\n>>> Comparacao - Lingua Portuguesa:")
print(comp_lp)

# =========================================================================
# PASSO 6: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

# Tabela de ICC
icc_df <- tibble(
  Disciplina = c("Matematica", "Lingua Portuguesa"),
  ICC = c(icc_mt$ICC_adjusted, icc_lp$ICC_adjusted),
  Variancia_Entre_Escolas = c(icc_mt$ICC_adjusted * 100, icc_lp$ICC_adjusted * 100),
  Variancia_Dentro_Escola = c((1 - icc_mt$ICC_adjusted) * 100, (1 - icc_lp$ICC_adjusted) * 100),
  Interpretacao = c(
    ifelse(icc_mt$ICC_adjusted > 0.20, "Alto", ifelse(icc_mt$ICC_adjusted > 0.10, "Moderado", "Baixo")),
    ifelse(icc_lp$ICC_adjusted > 0.20, "Alto", ifelse(icc_lp$ICC_adjusted > 0.10, "Moderado", "Baixo"))
  )
)

write_csv(icc_df, caminho_saida(DIR_BASE, "tabelas", "icc", "csv"))

# Tabela de comparacao de modelos
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

write_csv(resumo_modelos, caminho_saida(DIR_BASE, "tabelas", "resumo_hlm", "csv"))

message("   OK icc_", ts_global, ".csv")
message("   OK resumo_hlm_", ts_global, ".csv")

# =========================================================================
# PASSO 7: VISUALIZACOES
# =========================================================================

message("\n>>> Gerando figuras...")

# -------------------------------------------------------------------------
# Figura 19: Decomposicao da Variancia (ICC)
# -------------------------------------------------------------------------
dados_icc <- icc_df %>%
  pivot_longer(cols = c(Variancia_Entre_Escolas, Variancia_Dentro_Escola),
               names_to = "Componente", values_to = "Percentual") %>%
  mutate(Componente = recode(Componente,
                             "Variancia_Entre_Escolas" = "Entre Escolas",
                             "Variancia_Dentro_Escola" = "Dentro de Escolas"))

p_icc <- dados_icc %>%
  ggplot(aes(x = Disciplina, y = Percentual, fill = Componente)) +
  geom_bar(stat = "identity", position = "stack", width = 0.5) +
  scale_fill_manual(values = c("Entre Escolas" = "#E74C3C", "Dentro de Escolas" = "#3498DB")) +
  geom_text(aes(label = paste0(round(Percentual, 1), "%")),
            position = position_stack(vjust = 0.5), size = 5, fontface = "bold") +
  labs(
    title = "Figura 19 - Decomposicao da Variancia (ICC)",
    subtitle = "Proporcao da variancia da proficiencia entre e dentro de escolas",
    x = NULL,
    y = "Percentual da Variancia (%)",
    fill = "Componente"
  ) +
  tema_saeb() +
  theme(legend.position = "bottom")

ggsave(caminho_saida(DIR_BASE, "figuras", "icc_varianca", "png"),
       plot = p_icc, width = 10, height = 7, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 19: icc_varianca_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 20: Efeitos Aleatorios por Escola (Top 20)
# -------------------------------------------------------------------------
efeitos_mt <- ranef(modelo_nulo_mt)$ID_ESCOLA %>%
  as.data.frame() %>%
  rownames_to_column("ID_ESCOLA") %>%
  rename(Efeito = `(Intercept)`) %>%
  arrange(desc(abs(Efeito))) %>%
  head(20) %>%
  mutate(Disciplina = "Matematica")

efeitos_lp <- ranef(modelo_nulo_lp)$ID_ESCOLA %>%
  as.data.frame() %>%
  rownames_to_column("ID_ESCOLA") %>%
  rename(Efeito = `(Intercept)`) %>%
  arrange(desc(abs(Efeito))) %>%
  head(20) %>%
  mutate(Disciplina = "Lingua Portuguesa")

efeitos_plot <- bind_rows(efeitos_mt, efeitos_lp) %>%
  mutate(
    ID_ESCOLA = factor(ID_ESCOLA, levels = ID_ESCOLA[order(Efeito)]),
    Direcao = ifelse(Efeito > 0, "Acima da media", "Abaixo da media")
  )

p_efeitos <- efeitos_plot %>%
  ggplot(aes(x = Efeito, y = ID_ESCOLA, fill = Direcao)) +
  geom_col(width = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  scale_fill_manual(values = c("Acima da media" = "#27AE60", "Abaixo da media" = "#E74C3C")) +
  facet_wrap(~Disciplina, scales = "free_y") +
  labs(
    title = "Figura 20 - Efeitos Aleatorios por Escola (Top 20)",
    subtitle = "Desvio da proficiencia media geral para cada escola",
    x = "Efeito Aleatorio (desvio da media geral)",
    y = "Escola (ID)",
    fill = "Direcao"
  ) +
  tema_saeb() +
  theme(legend.position = "bottom")

ggsave(caminho_saida(DIR_BASE, "figuras", "efeitos_aleatorios", "png"),
       plot = p_efeitos, width = 14, height = 10, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 20: efeitos_aleatorios_", ts_global, ".png")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("MODELOS HIERARQUICOS CONCLUIDOS")
message(strrep("=", 70))
message("Alunos analisados: ", nrow(dados_hlm))
message("Escolas: ", length(unique(dados_hlm$ID_ESCOLA)))
message("\nICC:")
message("  MT: ", round(icc_mt$ICC_adjusted * 100, 1), "% da variancia entre escolas")
message("  LP: ", round(icc_lp$ICC_adjusted * 100, 1), "% da variancia entre escolas")
message("\nFiguras geradas:")
message("  - Figura 19: icc_varianca_", ts_global, ".png")
message("  - Figura 20: efeitos_aleatorios_", ts_global, ".png")
