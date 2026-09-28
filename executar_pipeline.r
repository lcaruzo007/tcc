################################################################################
# SCRIPT: executar_pipeline.r
#
# OBJETIVO: Executar o pipeline SAEB em sessoes R isoladas e na ordem correta.
#
# USO:
#   Rscript executar_pipeline.r
#   Rscript executar_pipeline.r --passos=1,2,4,5
#   Rscript executar_pipeline.r --passos=8,9,10 --auxiliares
#
# VERSAO: 1.0 - Setembro 2026
################################################################################

detectar_raiz <- function() {
  cwd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) return(cwd)
    cwd <- dirname(cwd)
  }
  stop("Nao foi possivel localizar a pasta TESTE.")
}

argumentos <- commandArgs(trailingOnly = TRUE)
arg_passos <- grep("^--passos=", argumentos, value = TRUE)
executar_auxiliares <- "--auxiliares" %in% argumentos

passos_padrao <- c(1L, 2L, 4L, 5L, 7L, 8L, 9L, 10L)
if (length(arg_passos) == 0L || sub("^--passos=", "", arg_passos[1]) == "todos") {
  passos <- passos_padrao
} else {
  passos <- as.integer(strsplit(sub("^--passos=", "", arg_passos[1]), ",")[[1]])
  if (anyNA(passos) || any(!passos %in% 1:10)) {
    stop("Use --passos com numeros de 1 a 10 separados por virgula.")
  }
}

RAIZ <- detectar_raiz()
R_SCRIPT <- file.path(
  R.home("bin"),
  if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"
)
if (!file.exists(R_SCRIPT)) stop("Rscript nao encontrado em: ", R_SCRIPT)

scripts <- list(
  `1` = "TESTE/1_LIMPEZA_E_TRANSFORMACAO/ajeitar_dados.r",
  `2` = "TESTE/2_ANALISE_POR_ESCOLA/Scripts/correlacao.r",
  `4` = "TESTE/3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r",
  `5` = "TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_grupos.r",
  `7` = c(
    "TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_analise_completa.r",
    "TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_publica_vs_particular.r",
    "TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_urbana_vs_rural.r",
    "TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_capital_vs_interior.r",
    "TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_area_local.r"
  ),
  `8` = "TESTE/4_REGRESSAO_LINEAR/Scripts/regressao_linear_multipla.r",
  `9` = "TESTE/5_REGRESSAO_ITENS_BRUTOS/Scripts/regressao_itens_brutos_dummy.r",
  `10` = "TESTE/6_ANALISE_MEDIACAO/Scripts/analise_mediacao.r"
)

if (3L %in% passos) {
  message("Passo 3 e interativo e nao sera iniciado pelo executor.")
  message("Use shiny::runApp('TESTE/2_ANALISE_POR_ESCOLA/Scripts/graficos.r').")
}
if (6L %in% passos) {
  message("Passo 6 depende da escolha de duas escolas e nao sera executado automaticamente.")
  message("Configure comparar_duas_escolas.r e execute-o separadamente.")
}

executar_script <- function(caminho_relativo) {
  caminho <- file.path(RAIZ, caminho_relativo)
  if (!file.exists(caminho)) stop("Script nao encontrado: ", caminho)
  message("\n", strrep("=", 72))
  message("Executando: ", caminho_relativo)
  message(strrep("=", 72))
  status <- system2(R_SCRIPT, c("--vanilla", shQuote(caminho)))
  if (!identical(status, 0L)) {
    stop("Falha ao executar: ", caminho_relativo, " (status ", status, ")")
  }
}

for (passo in sort(intersect(unique(passos), as.integer(names(scripts))))) {
  for (script in scripts[[as.character(passo)]]) executar_script(script)
  if (passo == 8L && executar_auxiliares) {
    executar_script(
      "TESTE/4_REGRESSAO_LINEAR/Scripts/grafico_coeficientes_referencia_oposta.r"
    )
    executar_script(
      "TESTE/4_REGRESSAO_LINEAR/Scripts/analise_sensibilidade_regressao.r"
    )
  }
}

message("\nPipeline concluido para os passos: ", paste(passos, collapse = ", "))
