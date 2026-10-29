################################################################################
# SCRIPT: executar_etapa.r
# ENTRADA: Caminho de um script do pipeline passado pelo executor.
# SAIDA: Execucao isolada com ambiente conferido contra renv.lock.
# VERSAO: 1.0 - Outubro 2026
################################################################################

detectar_raiz <- function() {
  pasta <- normalizePath(getwd(), winslash = "/")
  while (pasta != dirname(pasta)) {
    if (dir.exists(file.path(pasta, "TESTE"))) return(pasta)
    pasta <- dirname(pasta)
  }
  stop("Pasta TESTE nao encontrada.")
}
raiz_etapa <- detectar_raiz()
source(file.path(raiz_etapa, "TESTE", "DOCUMENTACAO", "ambiente_saeb.r"))
ativar_ambiente_saeb(raiz_etapa)
script_etapa <- commandArgs(trailingOnly = TRUE)
if (length(script_etapa) != 1L) stop("Informe exatamente um script.")
script_etapa <- normalizePath(script_etapa, winslash = "/", mustWork = TRUE)
if (!startsWith(script_etapa, paste0(raiz_etapa, "/TESTE/"))) stop("Script fora de TESTE.")
source(script_etapa, chdir = FALSE)
