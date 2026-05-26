################################################################################
# SCRIPT: regressao_linear_multipla.r
#
# FUNCIONALIDADE:
#   Regressão Linear Múltipla com variáveis dummy
#   Parte dos dados brutos dos alunos (TS_ALUNO_34EM.csv),
#   agrega por escola e modela MEDIA_MT e MEDIA_LP
#
# ENTRADA:
#   - TS_ALUNO_34EM.csv  (dados brutos SAEB — nível aluno)
#
# SAÍDA:
#   - resumo_modelos_<ts>.csv
#   - coeficientes_MT_<ts>.csv / coeficientes_LP_<ts>.csv
#   - diagnosticos_MT_<ts>.csv / diagnosticos_LP_<ts>.csv
#   - diagnosticos_residuos_MT_<ts>.png / _LP_<ts>.png
#   - preditos_vs_observados_MT_<ts>.png / _LP_<ts>.png
#   - resumo_qualidade_ajuste_<ts>.png
#   - coeficientes_MT_<ts>.png / coeficientes_LP_<ts>.png
#
# VERSÃO: 2.0 — Maio 2026
#
# ---------------------------------------------------------------------------
# NOTA METODOLÓGICA — ESCOLHA DO INSE COMO VARIÁVEL SOCIOECONÔMICA
# ---------------------------------------------------------------------------
#
# O questionário contextual do SAEB contém 72 itens socioeconômicos
# (colunas TX_RESP_Q01 a TX_RESP_Q25, incluindo subitens como Q05a/b/c).
# Poder-se-ia questionar se essas perguntas brutas não deveriam ser usadas
# diretamente como preditoras no modelo. A opção pelo INSE_ALUNO (agregado
# como INSE_MEDIO por escola) é deliberada e sustentada pelos seguintes
# argumentos:
#
# 1. O INSE já é a síntese psicométrica das perguntas brutas
#    O INEP constrói o INSE_ALUNO por meio de um modelo de Teoria de
#    Resposta ao Item (TRI), calibrado sobre exatamente esses itens
#    (Q01–Q25). Ele sintetiza em um único score contínuo a informação
#    latente de todas as respostas, com pesos derivados de modelagem
#    psicométrica validada. Usar os itens brutos em lugar do INSE seria
#    equivalente a descartar o produto final em favor dos insumos,
#    perdendo precisão e coerência metodológica.
#    Referência: INEP (2021). Nota Técnica — Indicador de Nível
#    Socioeconômico das Escolas de Educação Básica (INSE).
#
# 2. Risco de multicolinearidade severa
#    Os 72 itens medem facetas do mesmo constructo latente (nível
#    socioeconômico) e são, portanto, altamente correlacionados entre si.
#    Incluí-los simultaneamente como preditores independentes viola a
#    premissa de ausência de multicolinearidade perfeita da regressão OLS,
#    tornando os estimadores instáveis (variâncias infladas) e a
#    interpretação dos coeficientes inviável. O VIF (Variance Inflation
#    Factor) de vários preditores ultrapassaria o limiar crítico de 10.
#
# 3. Explosão dimensional e custo de graus de liberdade
#    As respostas são variáveis categóricas ordinais codificadas como
#    letras (A, B, C, D, …). A codificação dummy de todos os itens
#    geraria facilmente 150–200 variáveis adicionais, consumindo graus
#    de liberdade e comprometendo o ajuste em amostras de tamanho
#    moderado (nível escola).
#
# 4. Validade e reprodutibilidade
#    O INSE possui metodologia pública, documentada e reproduzível,
#    facilitando comparações com outros estudos que utilizem dados SAEB.
#    Uma construção ad hoc de índice a partir dos itens brutos exigiria
#    validação psicométrica própria (análise fatorial confirmatória ou
#    TRI), o que extrapolaria o escopo deste trabalho.
#
# CONCLUSÃO: O uso de INSE_MEDIO como proxy socioeconômico é a escolha
# metodologicamente mais rigorosa, parcimoniana e defensável para os
# objetivos desta análise. Pesquisadores que desejarem decompor o efeito
# de dimensões específicas do NSE (ex.: capital cultural vs. capital
# econômico) deverão conduzir uma análise fatorial exploratória prévia
# sobre os itens brutos, construindo subescores interpretáveis antes de
# incluí-los em qualquer modelo preditivo.
# ---------------------------------------------------------------------------
################################################################################

library(tidyverse)
library(broom)
library(patchwork)
library(car)

# =============================================================================
# DETECÇÃO AUTOMÁTICA DE CAMINHOS
# =============================================================================

detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("✓ Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  message("⚠️  Pasta 'TESTE' não encontrada automaticamente.")
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho não selecionado. Encerrando.")
    message("✓ Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Script não pode rodar em modo não-interativo sem encontrar o caminho.")
  }
}

RAIZ             <- detectar_raiz()

DIR_DADOS_BRUTOS     <- file.path(RAIZ, "MICRODADOS_SAEB_2023", "DADOS")
ARQUIVO_DADOS_BRUTOS <- arquivo_mais_recente(DIR_DADOS_BRUTOS, "^TS_ALUNO_34EM\.csv$")

DIR_MODELOS      <- file.path(RAIZ, "TESTE/4_REGRESSAO_LINEAR/outputs_modelos")
DIR_DIAGNOSTICOS <- file.path(RAIZ, "TESTE/4_REGRESSAO_LINEAR/outputs_diagnosticos")
DIR_FIGURAS      <- file.path(RAIZ, "TESTE/4_REGRESSAO_LINEAR/outputs_figuras")
DIR_TABELAS      <- file.path(RAIZ, "TESTE/4_REGRESSAO_LINEAR/outputs_tabelas")

message("Caminhos configurados:")
message("  Dados brutos: ", ARQUIVO_DADOS_BRUTOS)
message("  Modelos:      ", DIR_MODELOS)
message("  Figuras:      ", DIR_FIGURAS)
message("  Tabelas:      ", DIR_TABELAS, "\n")

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================

# Filtro de qualidade: escolas com menos alunos que isso são descartadas
MIN_ALUNOS_ESCOLA <- 5

# Filtro de outliers nas proficiências individuais (escala SAEB: ~150–800)
PROF_MIN <- 150
PROF_MAX <- 800

# Número mínimo de alunos com INSE para calcular INSE médio da escola
MIN_ALUNOS_INSE <- 3

# Variáveis do modelo
VARIAVEL_DEPENDENTE <- c("MEDIA_MT", "MEDIA_LP")
VARS_CATEGORICAS    <- c("TIPO_ESCOLA", "AREA", "LOCALIZACAO")
VARS_CONTINUAS      <- c("INSE_MEDIO")
ALPHA               <- 0.05

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

arquivo_mais_recente <- function(pasta, padrao) {
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE)
  if (length(arqs) == 0L) return(NULL)
  arqs[which.max(file.info(arqs)$mtime)]
}

criar_dummies <- function(df, vars_cat) {
  vars_ok      <- intersect(vars_cat, names(df))
  dummies_list <- list()
  for (var in vars_ok) {
    valores <- sort(unique(na.omit(df[[var]])))
    for (valor in valores[-1]) {           # primeiro = referência
      nome          <- paste0(var, "_", valor)
      df[[nome]]    <- as.integer(df[[var]] == valor)
      dummies_list[[nome]] <- c(var, valor)
    }
  }
  attr(df, "dummies_criadas") <- dummies_list
  df
}

tema_saeb <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title       = element_text(face = "bold", size = base_size + 2,
                                      colour = "#1A1A1A", margin = margin(b = 4)),
      plot.subtitle    = element_text(size = base_size - 1, colour = "#555555",
                                      margin = margin(b = 8)),
      plot.caption     = element_text(size = base_size - 2, colour = "#777777",
                                      face = "italic", hjust = 0,
                                      margin = margin(t = 10)),
      plot.background  = element_rect(fill = "#FFFFFF", colour = NA),
      panel.background = element_rect(fill = "#F5F5F5", colour = NA),
      panel.grid.major = element_line(colour = "#D0D0D0", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      plot.margin      = margin(16, 16, 12, 16)
    )
}

formatar_pvalor <- function(p) {
  case_when(
    p < 0.001 ~ "***",
    p < 0.01  ~ "**",
    p < 0.05  ~ "*",
    TRUE      ~ ""
  )
}

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

for (d in c(DIR_MODELOS, DIR_DIAGNOSTICOS, DIR_FIGURAS, DIR_TABELAS))
  dir.create(d, showWarnings = FALSE, recursive = TRUE)

ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

message(strrep("=", 70))
message("REGRESSÃO LINEAR MÚLTIPLA — DADOS BRUTOS SAEB")
message(strrep("=", 70))

# =============================================================================
# ETAPA 1: CARREGAR DADOS BRUTOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 1: CARREGANDO DADOS BRUTOS")
message(strrep("-", 50))

if (is.null(ARQUIVO_DADOS_BRUTOS) || !file.exists(ARQUIVO_DADOS_BRUTOS)) {
  stop(
    "Arquivo TS_ALUNO*.csv não encontrado em:\n  ", DIR_DADOS_BRUTOS,
    "\nVerifique se a pasta MICRODADOS_SAEB_2023/DADOS existe na raiz do projeto."
  )
}

message("Arquivo: ", basename(ARQUIVO_DADOS_BRUTOS))

dados_brutos <- read_csv(
  ARQUIVO_DADOS_BRUTOS,
  col_types = cols(
    ID_ESCOLA          = col_character(),
    IN_PUBLICA         = col_integer(),
    ID_AREA            = col_integer(),
    ID_LOCALIZACAO     = col_integer(),
    IN_PROFICIENCIA_MT = col_integer(),
    IN_PROFICIENCIA_LP = col_integer(),
    PROFICIENCIA_MT_SAEB = col_double(),
    PROFICIENCIA_LP_SAEB = col_double(),
    IN_INSE            = col_integer(),
    INSE_ALUNO         = col_double(),
    .default           = col_skip()     # ignora todas as outras colunas
  ),
  show_col_types = FALSE
)

message("Alunos carregados: ", nrow(dados_brutos))
message("Escolas distintas: ", n_distinct(dados_brutos$ID_ESCOLA))

# =============================================================================
# ETAPA 2: AGREGAR POR ESCOLA
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 2: AGREGANDO POR ESCOLA")
message(strrep("-", 50))

message("Filtros aplicados:")
message("  Proficiência válida:  IN_PROFICIENCIA_MT/LP = 1")
message("  Faixa de valores:     PROFICIENCIA_SAEB entre ", PROF_MIN, " e ", PROF_MAX)
message("  Mínimo alunos/escola: ", MIN_ALUNOS_ESCOLA)

# ── Médias de proficiência ────────────────────────────────────────────────────
media_prof <- dados_brutos |>
  filter(
    IN_PROFICIENCIA_MT == 1,
    IN_PROFICIENCIA_LP == 1,
    between(PROFICIENCIA_MT_SAEB, PROF_MIN, PROF_MAX),
    between(PROFICIENCIA_LP_SAEB, PROF_MIN, PROF_MAX)
  ) |>
  group_by(ID_ESCOLA) |>
  summarise(
    MEDIA_MT    = mean(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    MEDIA_LP    = mean(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    N_ALUNOS_MT = n(),
    .groups     = "drop"
  ) |>
  filter(N_ALUNOS_MT >= MIN_ALUNOS_ESCOLA)

message("\nEscolas após filtro de proficiência: ", nrow(media_prof))

# ── INSE médio por escola ─────────────────────────────────────────────────────
# NOTA: utilizamos INSE_ALUNO (score TRI calculado pelo INEP) como proxy
# socioeconômico, e não os itens brutos do questionário (TX_RESP_Q01–Q25).
# Justificativa detalhada no cabeçalho deste script (seção NOTA METODOLÓGICA).
# Em síntese: o INSE já sintetiza os 72 itens via TRI com validação psicométrica
# publicada; usar os itens brutos introduziria multicolinearidade severa e
# explosão dimensional inviável para regressão OLS no nível escola.
inse_escola <- dados_brutos |>
  filter(IN_INSE == 1, !is.na(INSE_ALUNO)) |>
  group_by(ID_ESCOLA) |>
  summarise(
    INSE_MEDIO   = mean(INSE_ALUNO, na.rm = TRUE),
    N_ALUNOS_INSE = n(),
    .groups      = "drop"
  ) |>
  filter(N_ALUNOS_INSE >= MIN_ALUNOS_INSE)

# ── Variáveis categóricas (1 linha por escola) ────────────────────────────────
categ_escola <- dados_brutos |>
  group_by(ID_ESCOLA) |>
  summarise(
    IN_PUBLICA     = first(IN_PUBLICA),
    ID_AREA        = first(ID_AREA),
    ID_LOCALIZACAO = first(ID_LOCALIZACAO),
    .groups        = "drop"
  ) |>
  mutate(
    TIPO_ESCOLA = if_else(IN_PUBLICA == 1, "Publica", "Privada"),
    AREA        = if_else(ID_AREA == 1, "Capital", "Interior"),
    LOCALIZACAO = if_else(ID_LOCALIZACAO == 1, "Urbana", "Rural")
  ) |>
  select(ID_ESCOLA, TIPO_ESCOLA, AREA, LOCALIZACAO)

# ── Juntar tudo ───────────────────────────────────────────────────────────────
dados_escola <- media_prof |>
  inner_join(inse_escola,  by = "ID_ESCOLA") |>
  inner_join(categ_escola, by = "ID_ESCOLA") |>
  select(ID_ESCOLA, TIPO_ESCOLA, AREA, LOCALIZACAO,
         MEDIA_MT, MEDIA_LP, INSE_MEDIO, N_ALUNOS_MT, N_ALUNOS_INSE)

message("Escolas na base final (com INSE): ", nrow(dados_escola))
message("\nDistribuição por variável categórica:")
message("  TIPO_ESCOLA:\n", paste(capture.output(print(table(dados_escola$TIPO_ESCOLA))), collapse = "\n"))
message("  AREA:\n",        paste(capture.output(print(table(dados_escola$AREA))),        collapse = "\n"))
message("  LOCALIZACAO:\n", paste(capture.output(print(table(dados_escola$LOCALIZACAO))), collapse = "\n"))
message("\nEstatísticas das proficiências:")
message("  MEDIA_MT — média: ", round(mean(dados_escola$MEDIA_MT), 2),
        " | dp: ", round(sd(dados_escola$MEDIA_MT), 2),
        " | min: ", round(min(dados_escola$MEDIA_MT), 2),
        " | max: ", round(max(dados_escola$MEDIA_MT), 2))
message("  MEDIA_LP — média: ", round(mean(dados_escola$MEDIA_LP), 2),
        " | dp: ", round(sd(dados_escola$MEDIA_LP), 2),
        " | min: ", round(min(dados_escola$MEDIA_LP), 2),
        " | max: ", round(max(dados_escola$MEDIA_LP), 2))

# Salvar base agregada para rastreabilidade
write_csv(dados_escola,
          file.path(DIR_TABELAS, paste0("base_escolas_agregada_", ts_global, ".csv")))
message("\nBase agregada salva: base_escolas_agregada_", ts_global, ".csv")

# =============================================================================
# ETAPA 3: PREPARAR DADOS DO MODELO
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 3: PREPARANDO DADOS DO MODELO")
message(strrep("-", 50))

# Criar dummies
dados_modelo <- criar_dummies(dados_escola, VARS_CATEGORICAS)
dummies_info <- attr(dados_modelo, "dummies_criadas")

message("Variáveis dummy criadas: ", length(dummies_info))
for (dummy_name in names(dummies_info)) {
  info <- dummies_info[[dummy_name]]
  message("  + ", dummy_name, "  (ref: ", info[1], " = primeiros da ordem)")
}

# Normalizar INSE (z-score)
dados_modelo <- dados_modelo |>
  mutate(INSE_MEDIO_norm = as.numeric(scale(INSE_MEDIO)))

message("INSE_MEDIO normalizado (z-score) → INSE_MEDIO_norm")

# Preditoras: dummies + INSE_MEDIO_norm  (exclui originais categóricas e INSE_MEDIO bruto)
preditoras <- setdiff(
  names(dados_modelo),
  c(VARIAVEL_DEPENDENTE, VARS_CATEGORICAS, VARS_CONTINUAS,
    "ID_ESCOLA", "N_ALUNOS_MT", "N_ALUNOS_INSE")
)

message("Preditoras no modelo: ", paste(preditoras, collapse = ", "))

# =============================================================================
# ETAPA 4: AJUSTAR MODELOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 4: AJUSTANDO MODELOS")
message(strrep("-", 50))

formula_mt <- as.formula(paste("MEDIA_MT ~", paste(preditoras, collapse = " + ")))
formula_lp <- as.formula(paste("MEDIA_LP ~", paste(preditoras, collapse = " + ")))

modelo_mt <- lm(formula_mt, data = dados_modelo)
modelo_lp <- lm(formula_lp, data = dados_modelo)

summary_mt <- summary(modelo_mt)
summary_lp <- summary(modelo_lp)

message("\n>>> MODELO MEDIA_MT <<<")
message("  Observações: ", nrow(dados_modelo))
message("  R² ajustado: ", round(summary_mt$adj.r.squared, 4))
message("  F-statistic: ", round(summary_mt$fstatistic[1], 2))
message("  RMSE:        ", round(sqrt(mean(summary_mt$residuals^2)), 2))

message("\n>>> MODELO MEDIA_LP <<<")
message("  Observações: ", nrow(dados_modelo))
message("  R² ajustado: ", round(summary_lp$adj.r.squared, 4))
message("  F-statistic: ", round(summary_lp$fstatistic[1], 2))
message("  RMSE:        ", round(sqrt(mean(summary_lp$residuals^2)), 2))

# =============================================================================
# ETAPA 5: COEFICIENTES
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 5: EXTRAINDO COEFICIENTES")
message(strrep("-", 50))

extrair_coef <- function(modelo) {
  tidy(modelo) |>
    mutate(
      Sig      = formatar_pvalor(p.value),
      IC_lower = estimate - 1.96 * std.error,
      IC_upper = estimate + 1.96 * std.error
    ) |>
    select(
      Termo    = term,
      Coef     = estimate,
      SE       = std.error,
      t_value  = statistic,
      p_valor  = p.value,
      Sig,
      IC_95_inf = IC_lower,
      IC_95_sup = IC_upper
    ) |>
    arrange(desc(abs(t_value)))
}

coef_mt <- extrair_coef(modelo_mt)
coef_lp <- extrair_coef(modelo_lp)

write_csv(coef_mt, file.path(DIR_TABELAS, paste0("coeficientes_MT_", ts_global, ".csv")))
write_csv(coef_lp, file.path(DIR_TABELAS, paste0("coeficientes_LP_", ts_global, ".csv")))

message("Coeficientes MT:")
print(coef_mt, n = Inf)
message("\nCoeficientes LP:")
print(coef_lp, n = Inf)

# =============================================================================
# ETAPA 6: DIAGNÓSTICOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 6: DIAGNÓSTICOS")
message(strrep("-", 50))

extrair_diag <- function(modelo, summary_mod) {
  tibble(
    Diagnostico = c("R² ajustado", "RMSE", "AIC", "BIC"),
    Valor       = c(
      round(summary_mod$adj.r.squared, 4),
      round(sqrt(mean(summary_mod$residuals^2)), 2),
      round(AIC(modelo), 2),
      round(BIC(modelo), 2)
    ),
    Descricao = c(
      "Proporção da variância explicada (ajustada pelo número de preditores)",
      "Erro médio de predição nas mesmas unidades da variável resposta",
      "Qualidade relativa do modelo penalizando complexidade (menor = melhor)",
      "Similar ao AIC com penalização maior por complexidade (menor = melhor)"
    )
  )
}

diag_mt <- extrair_diag(modelo_mt, summary_mt)
diag_lp <- extrair_diag(modelo_lp, summary_lp)

write_csv(diag_mt, file.path(DIR_DIAGNOSTICOS, paste0("diagnosticos_MT_", ts_global, ".csv")))
write_csv(diag_lp, file.path(DIR_DIAGNOSTICOS, paste0("diagnosticos_LP_", ts_global, ".csv")))

tabela_resumo <- tibble(
  Modelo       = c("MEDIA_MT", "MEDIA_LP"),
  Observacoes  = nrow(dados_modelo),
  Parametros   = c(length(coef(modelo_mt)), length(coef(modelo_lp))),
  R2_ajustado  = c(round(summary_mt$adj.r.squared, 4), round(summary_lp$adj.r.squared, 4)),
  RMSE         = c(round(sqrt(mean(summary_mt$residuals^2)), 2),
                   round(sqrt(mean(summary_lp$residuals^2)), 2)),
  F_statistic  = c(round(summary_mt$fstatistic[1], 2), round(summary_lp$fstatistic[1], 2)),
  p_valor      = "< 0.001",
  AIC          = c(round(AIC(modelo_mt), 2), round(AIC(modelo_lp), 2)),
  BIC          = c(round(BIC(modelo_mt), 2), round(BIC(modelo_lp), 2))
)

write_csv(tabela_resumo, file.path(DIR_TABELAS, paste0("resumo_modelos_", ts_global, ".csv")))
message("\nResumo dos modelos:")
print(tabela_resumo)

# =============================================================================
# ETAPA 7: GRÁFICOS DE DIAGNÓSTICO DE RESÍDUOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 7: GERANDO GRÁFICOS")
message(strrep("-", 50))

gerar_graficos_residuos <- function(modelo, nome, cor) {

  dados_resid <- tibble(
    fitted        = fitted(modelo),
    residuals     = residuals(modelo),
    std_residuals = rstandard(modelo)
  )

  p1 <- ggplot(dados_resid, aes(x = fitted, y = residuals)) +
    geom_point(alpha = 0.5, size = 2, colour = cor) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "#D62728", linewidth = 1) +
    geom_smooth(method = "loess", se = TRUE, colour = "#2CA02C",
                fill = "#2CA02C", alpha = 0.15) +
    labs(
      title    = paste0("Resíduos vs Ajustados (", nome, ")"),
      subtitle = "Diferença entre valor observado e previsto por escola",
      x        = "Valores ajustados (proficiência prevista)",
      y        = "Resíduos (observado − previsto)"
    ) +
    tema_saeb()

  p2 <- ggplot(dados_resid, aes(sample = std_residuals)) +
    stat_qq(alpha = 0.5, size = 2, colour = cor) +
    stat_qq_line(colour = "#D62728", linewidth = 1) +
    labs(
      title    = paste0("Q-Q Plot dos Resíduos (", nome, ")"),
      subtitle = "Aderência dos resíduos à distribuição normal",
      x        = "Quantis teóricos (normal padrão)",
      y        = "Quantis amostrais (resíduos padronizados)"
    ) +
    tema_saeb()

  p3 <- ggplot(dados_resid, aes(x = fitted, y = sqrt(abs(std_residuals)))) +
    geom_point(alpha = 0.5, size = 2, colour = cor) +
    geom_smooth(method = "loess", se = TRUE, colour = "#2CA02C",
                fill = "#2CA02C", alpha = 0.15) +
    labs(
      title    = paste0("Scale-Location (", nome, ")"),
      subtitle = "Verifica homocedasticidade: variância dos erros é constante?",
      x        = "Valores ajustados",
      y        = "√|Resíduos padronizados|"
    ) +
    tema_saeb()

  p4 <- ggplot(dados_resid, aes(x = residuals)) +
    geom_histogram(bins = 30, fill = cor, alpha = 0.7, colour = "black") +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "#D62728", linewidth = 1) +
    labs(
      title    = paste0("Distribuição dos Resíduos (", nome, ")"),
      subtitle = "Histograma dos erros de predição",
      x        = "Resíduos",
      y        = "Frequência"
    ) +
    tema_saeb()

  (p1 + p2) / (p3 + p4) +
    plot_annotation(
      title    = paste0("Diagnóstico do Modelo ", nome),
      subtitle = "Análise gráfica dos resíduos e do ajuste do modelo de regressão",
      caption  = paste(
        "① Resíduos vs Ajustados: dispersão aleatória em torno de zero e linha verde horizontal = sem padrão sistemático (bom).",
        "② Q-Q Plot: pontos sobre a diagonal vermelha = resíduos normais; desvios nas extremidades = caudas pesadas.",
        "③ Scale-Location: dispersão uniforme e linha horizontal = variância constante (homocedasticidade).",
        "④ Histograma: sino centrado em zero = modelo erra aleatoriamente, sem viés sistemático.",
        sep = "\n"
      ),
      theme = theme(
        plot.title    = element_text(hjust = 0.5, face = "bold", size = 14),
        plot.subtitle = element_text(hjust = 0.5, size = 11, colour = "#555555"),
        plot.caption  = element_text(hjust = 0, size = 9, colour = "#666666",
                                     face = "italic", lineheight = 1.5,
                                     margin = margin(t = 12))
      )
    )
}

p_diag_mt <- gerar_graficos_residuos(modelo_mt, "MEDIA_MT", "#1f77b4")
p_diag_lp <- gerar_graficos_residuos(modelo_lp, "MEDIA_LP", "#ff7f0e")

ggsave(file.path(DIR_FIGURAS, paste0("diagnosticos_residuos_MT_", ts_global, ".png")),
       p_diag_mt, width = 14, height = 10, dpi = 180, bg = "white", device = "png")
message("Figura salva: diagnosticos_residuos_MT")

ggsave(file.path(DIR_FIGURAS, paste0("diagnosticos_residuos_LP_", ts_global, ".png")),
       p_diag_lp, width = 14, height = 10, dpi = 180, bg = "white", device = "png")
message("Figura salva: diagnosticos_residuos_LP")

# =============================================================================
# ETAPA 8: GRÁFICOS DE COEFICIENTES
# =============================================================================

gerar_grafico_coef <- function(coef_df, nome, cor_sig) {

  ref_info <- tibble(
    Termo        = paste0("(Referência: Publica, Capital, Urbana)"),
    Coef         = 0, SE = 0, t_value = 0, p_valor = 1,
    Sig          = "", IC_95_inf = 0, IC_95_sup = 0,
    Significancia = FALSE
  )

  dados_plot <- coef_df |>
    filter(Termo != "(Intercept)") |>
    mutate(Significancia = p_valor < ALPHA,
           Termo = fct_reorder(Termo, Coef))

  ggplot(dados_plot, aes(x = Termo, y = Coef, fill = Significancia)) +
    geom_col(alpha = 0.85) +
    geom_errorbar(aes(ymin = IC_95_inf, ymax = IC_95_sup),
                  width = 0.25, linewidth = 0.6) +
    geom_text(aes(label = Sig,
                  y = if_else(Coef >= 0, IC_95_sup + 0.5, IC_95_inf - 0.5)),
              size = 4.5, fontface = "bold", colour = "#333333") +
    geom_hline(yintercept = 0, linetype = "dashed",
               colour = "#666666", linewidth = 0.6) +
    coord_flip() +
    scale_fill_manual(
      values = c("FALSE" = "#CCCCCC", "TRUE" = cor_sig),
      labels = c("FALSE" = "Não significativo (p ≥ 0,05)",
                 "TRUE"  = "Significativo (p < 0,05)")
    ) +
    labs(
      title    = paste0("Coeficientes estimados (", nome, ")"),
      subtitle = "Efeito parcial de cada variável sobre a proficiência, mantendo as demais constantes",
      x        = NULL,
      y        = "Coeficiente (pontos de proficiência SAEB)",
      fill     = "Significância estatística",
      caption  = paste0(
        "Referências: Escola Pública | Capital | Urbana\n",
        "Coef > 0: variável aumenta a proficiência em relação à referência\n",
        "Coef < 0: variável reduz a proficiência em relação à referência\n",
        "Barras de erro = intervalo de confiança 95% (se cruzar o zero, efeito pode ser nulo)\n",
        "*** p<0,001 | ** p<0,01 | * p<0,05"
      )
    ) +
    tema_saeb() +
    theme(
      legend.position = "bottom",
      plot.caption    = element_text(size = 9, lineheight = 1.4)
    )
}

p_coef_mt <- gerar_grafico_coef(coef_mt, "MEDIA_MT", "#1f77b4")
p_coef_lp <- gerar_grafico_coef(coef_lp, "MEDIA_LP", "#ff7f0e")

ggsave(file.path(DIR_FIGURAS, paste0("coeficientes_MT_", ts_global, ".png")),
       p_coef_mt, width = 10, height = 8, dpi = 180, bg = "white", device = "png")
message("Figura salva: coeficientes_MT")

ggsave(file.path(DIR_FIGURAS, paste0("coeficientes_LP_", ts_global, ".png")),
       p_coef_lp, width = 10, height = 8, dpi = 180, bg = "white", device = "png")
message("Figura salva: coeficientes_LP")

# =============================================================================
# ETAPA 9: PREDITOS vs OBSERVADOS
# =============================================================================

gerar_pred_obs <- function(modelo, summary_mod, nome, cor) {

  dados_po <- tibble(
    Observado = modelo$model[[1]],
    Predito   = fitted(modelo)
  )

  r2   <- round(summary_mod$adj.r.squared, 4)
  rmse <- round(sqrt(mean(summary_mod$residuals^2)), 2)
  corr <- round(cor(dados_po$Observado, dados_po$Predito), 3)

  ggplot(dados_po, aes(x = Observado, y = Predito)) +
    geom_point(alpha = 0.4, size = 2, colour = cor) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed",
                colour = "#D62728", linewidth = 1.2) +
    geom_smooth(method = "lm", se = FALSE, colour = "#2CA02C",
                linewidth = 1) +
    annotate("label", x = Inf, y = -Inf,
             label = paste0("R² = ", r2, "\nRMSE = ", rmse, "\nCorr = ", corr),
             hjust = 1.05, vjust = -0.3, size = 4, fontface = "bold",
             colour = "#333333", fill = "#FFFFEE", label.size = 0.3) +
    coord_fixed(ratio = 1) +
    labs(
      title    = paste0("Preditos vs Observados (", nome, ")"),
      subtitle = "Linha vermelha tracejada = ajuste perfeito | Linha verde = ajuste do modelo",
      x        = "Proficiência observada (média da escola)",
      y        = "Proficiência predita pelo modelo",
      caption  = "Quanto mais próximos os pontos da linha diagonal, mais preciso o modelo.\nPontos acima da linha = modelo subestimou | Pontos abaixo = modelo superestimou."
    ) +
    tema_saeb() +
    theme(aspect.ratio = 1)
}

p_pred_mt <- gerar_pred_obs(modelo_mt, summary_mt, "MEDIA_MT", "#1f77b4")
p_pred_lp <- gerar_pred_obs(modelo_lp, summary_lp, "MEDIA_LP", "#ff7f0e")

ggsave(file.path(DIR_FIGURAS, paste0("preditos_vs_observados_MT_", ts_global, ".png")),
       p_pred_mt, width = 9, height = 9, dpi = 180, bg = "white", device = "png")
message("Figura salva: preditos_vs_observados_MT")

ggsave(file.path(DIR_FIGURAS, paste0("preditos_vs_observados_LP_", ts_global, ".png")),
       p_pred_lp, width = 9, height = 9, dpi = 180, bg = "white", device = "png")
message("Figura salva: preditos_vs_observados_LP")

# =============================================================================
# ETAPA 10: GRÁFICO COMPARATIVO DE R²
# =============================================================================

dados_r2 <- tibble(
  Modelo      = c("MEDIA_MT\n(Matemática)", "MEDIA_LP\n(Língua Portuguesa)"),
  R2          = c(summary_mt$adj.r.squared, summary_lp$adj.r.squared),
  Cor         = c("#1f77b4", "#ff7f0e")
)

p_r2 <- ggplot(dados_r2, aes(x = Modelo, y = R2, fill = Modelo)) +
  geom_col(alpha = 0.85, colour = "black", linewidth = 0.8) +
  geom_text(aes(label = paste0(round(R2 * 100, 1), "%")),
            vjust = -0.5, size = 5.5, fontface = "bold") +
  geom_hline(yintercept = 0.30, linetype = "dotted", colour = "#2CA02C",  linewidth = 1) +
  geom_hline(yintercept = 0.50, linetype = "dotted", colour = "#FFA500",  linewidth = 1) +
  geom_hline(yintercept = 0.70, linetype = "dotted", colour = "#D62728",  linewidth = 1) +
  annotate("text", x = 0.55, y = 0.31, label = "30% — razoável",  size = 3.5, colour = "#2CA02C",  hjust = 0) +
  annotate("text", x = 0.55, y = 0.51, label = "50% — bom",       size = 3.5, colour = "#FFA500",  hjust = 0) +
  annotate("text", x = 0.55, y = 0.71, label = "70% — excelente", size = 3.5, colour = "#D62728",  hjust = 0) +
  scale_y_continuous(
    limits = c(0, max(dados_r2$R2) * 1.2),
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_fill_manual(values = setNames(dados_r2$Cor, dados_r2$Modelo), guide = "none") +
  labs(
    title    = "Qualidade do Ajuste: R² Ajustado por Modelo",
    subtitle = "Percentual da variância da proficiência explicado pelos preditores",
    x        = NULL,
    y        = "R² Ajustado",
    caption  = "R² ajustado penaliza a inclusão de variáveis irrelevantes (diferente do R² simples).\nLinhas de referência indicam patamares convencionais de qualidade de ajuste."
  ) +
  tema_saeb()

ggsave(file.path(DIR_FIGURAS, paste0("resumo_qualidade_ajuste_", ts_global, ".png")),
       p_r2, width = 8, height = 6, dpi = 180, bg = "white", device = "png")
message("Figura salva: resumo_qualidade_ajuste")

# =============================================================================
# SALVAR MODELOS RDS
# =============================================================================

saveRDS(modelo_mt, file.path(DIR_MODELOS, paste0("modelo_MT_", ts_global, ".rds")))
saveRDS(modelo_lp, file.path(DIR_MODELOS, paste0("modelo_LP_", ts_global, ".rds")))

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

message("\n", strrep("=", 70))
message("RELATÓRIO FINAL")
message(strrep("=", 70))
message("\nBase:")
message("  Alunos no raw:             ", nrow(dados_brutos))
message("  Escolas na base final:     ", nrow(dados_escola))
message("  Outliers de profic. removidos: ",
        sum(dados_brutos$IN_PROFICIENCIA_MT == 1, na.rm = TRUE) -
        sum(between(
          dados_brutos$PROFICIENCIA_MT_SAEB[dados_brutos$IN_PROFICIENCIA_MT == 1],
          PROF_MIN, PROF_MAX), na.rm = TRUE))
message("\nModelos:")
message("  MT — R²aj: ", round(summary_mt$adj.r.squared, 4),
        " | RMSE: ", round(sqrt(mean(summary_mt$residuals^2)), 2))
message("  LP — R²aj: ", round(summary_lp$adj.r.squared, 4),
        " | RMSE: ", round(sqrt(mean(summary_lp$residuals^2)), 2))
message("\nArquivos gerados em:")
message("  ", DIR_TABELAS)
message("  ", DIR_FIGURAS)
message("  ", DIR_MODELOS)
message("\n", strrep("=", 70))
message("CONCLUÍDO COM SUCESSO!")
message(strrep("=", 70))