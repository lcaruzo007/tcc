################################################################################
# SCRIPT: ambiente_saeb.r
# ENTRADA: renv.lock e bibliotecas R disponiveis.
# SAIDA: Ativacao de biblioteca restaurada e conferencia exata das versoes.
# VERSAO: 1.0 - Outubro 2026
################################################################################

ativar_ambiente_saeb <- function(raiz) {
  if (dir.exists(file.path(raiz, "renv", "library"))) {
    if (!requireNamespace("renv", quietly = TRUE)) stop("Instale renv para carregar o ambiente restaurado.")
    renv::load(project = raiz, quiet = TRUE)
  }
  lockfile <- file.path(raiz, "renv.lock")
  if (!file.exists(lockfile)) stop("renv.lock ausente.")
  lock <- jsonlite::read_json(lockfile, simplifyVector = FALSE)
  if (as.character(getRversion()) != lock$R$Version) {
    stop("Versao R diferente de renv.lock: esperado ", lock$R$Version)
  }
  instalados <- installed.packages()
  divergentes <- names(lock$Packages)[vapply(lock$Packages, function(p) {
    !p$Package %in% rownames(instalados) || instalados[p$Package, "Version"] != p$Version
  }, logical(1))]
  if (length(divergentes)) {
    stop("Ambiente diferente de renv.lock: ", paste(divergentes, collapse = ", "),
         ". Execute renv::restore() e reinicie a sessao.")
  }
  invisible(TRUE)
}
