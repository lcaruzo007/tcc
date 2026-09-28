################################################################################
# SCRIPT: analise_sensibilidade_regressao.r
#
# OBJETIVO: Comparar OLS e WLS por numero de alunos com inferencia robusta HC3.
#           Este script nao substitui nem altera o modelo principal.
#
# ENTRADA: base_escolas_agregada_*.csv do PASSO 8
# SAIDA: outputs/<YYYY-MM-DD>/tabelas/sensibilidade_*.csv
#
# VERSAO: 1.0 - Setembro 2026
################################################################################

library(tidyverse)
library(broom)

detectar_raiz <- function() {
  cwd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) return(cwd)
    cwd <- dirname(cwd)
  }
  stop("Nao foi possivel localizar a pasta TESTE.")
}

pacotes_necessarios <- c("lmtest", "sandwich")
pacotes_ausentes <- pacotes_necessarios[
  !vapply(pacotes_necessarios, requireNamespace, logical(1), quietly = TRUE)
]
if (length(pacotes_ausentes) > 0L) {
  stop(
    "Pacotes ausentes: ", paste(pacotes_ausentes, collapse = ", "),
    ". Consulte TESTE/DOCUMENTACAO/requisitos.md."
  )
}

RAIZ <- detectar_raiz()
DIR_BASE <- file.path(RAIZ, "TESTE", "4_REGRESSAO_LINEAR")
DIR_OUTPUTS <- file.path(DIR_BASE, "outputs")
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

arquivo_base <- encontrar_arquivo_mais_recente(
  DIR_OUTPUTS, "base_escolas_agregada", "tabelas"
)
if (is.null(arquivo_base)) {
  stop("Base agregada nao encontrada. Execute regressao_linear_multipla.r primeiro.")
}

dados <- read_csv(arquivo_base, show_col_types = FALSE) |>
  filter(
    !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO),
    !is.na(TIPO_ESCOLA), !is.na(AREA_LOCAL),
    is.finite(N_ALUNOS_MT), N_ALUNOS_MT > 0
  ) |>
  mutate(
    TIPO_ESCOLA = relevel(factor(TIPO_ESCOLA), ref = "Publica"),
    AREA_LOCAL = relevel(factor(AREA_LOCAL), ref = "Urbana_Capital"),
    INSE_MEDIO_norm = as.numeric(scale(INSE_MEDIO))
  )

extrair_hc3 <- function(modelo, disciplina, metodo) {
  matriz <- lmtest::coeftest(
    modelo, vcov. = sandwich::vcovHC(modelo, type = "HC3")
  )
  critico <- qt(0.975, df = df.residual(modelo))
  tibble(
    Disciplina = disciplina,
    Metodo = metodo,
    Termo = rownames(matriz),
    Estimativa = matriz[, 1],
    Erro_padrao_HC3 = matriz[, 2],
    Estatistica = matriz[, 3],
    p_valor_HC3 = matriz[, 4],
    IC95_inferior_HC3 = Estimativa - critico * Erro_padrao_HC3,
    IC95_superior_HC3 = Estimativa + critico * Erro_padrao_HC3
  )
}

ajustar_disciplina <- function(resposta) {
  formula <- reformulate(
    c("INSE_MEDIO_norm", "TIPO_ESCOLA", "AREA_LOCAL"), response = resposta
  )
  modelo_ols <- lm(formula, data = dados)
  modelo_wls <- lm(formula, data = dados, weights = N_ALUNOS_MT)
  list(OLS = modelo_ols, WLS_N_ALUNOS = modelo_wls)
}

modelos <- list(
  MT = ajustar_disciplina("MEDIA_MT"),
  LP = ajustar_disciplina("MEDIA_LP")
)

coeficientes <- imap_dfr(modelos, function(modelos_disciplina, disciplina) {
  imap_dfr(modelos_disciplina, function(modelo, metodo) {
    extrair_hc3(modelo, disciplina, metodo)
  })
})

ajustes <- imap_dfr(modelos, function(modelos_disciplina, disciplina) {
  imap_dfr(modelos_disciplina, function(modelo, metodo) {
    resumo <- broom::glance(modelo)
    pesos <- weights(modelo)
    if (is.null(pesos)) pesos <- rep(1, nobs(modelo))
    tibble(
      Disciplina = disciplina,
      Metodo = metodo,
      N = nobs(modelo),
      R2 = resumo$r.squared,
      R2_ajustado = resumo$adj.r.squared,
      RMSE = sqrt(mean(residuals(modelo)^2)),
      RMSE_ponderado = sqrt(weighted.mean(residuals(modelo)^2, pesos))
    )
  })
})

write_csv(
  coeficientes,
  caminho_saida(DIR_BASE, "tabelas", "sensibilidade_coeficientes_HC3", "csv")
)
write_csv(
  ajustes,
  caminho_saida(DIR_BASE, "tabelas", "sensibilidade_ajustes_OLS_WLS", "csv")
)

message("Analise de sensibilidade concluida com ", nrow(dados), " escolas.")
