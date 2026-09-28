################################################################################
# SCRIPT: verificar_dependencias.r
#
# OBJETIVO: Verificar dependencias sem instalar ou alterar o ambiente R.
#
# VERSAO: 1.0 - Setembro 2026
################################################################################

pacotes_obrigatorios <- c(
  "tidyverse", "data.table", "caret", "broom", "patchwork", "car",
  "lmtest", "sandwich", "ggdendro", "mediation", "boot"
)
pacotes_opcionais <- c("shiny", "dendextend", "readxl")

verificar <- function(pacotes) {
  vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)
}

status_obrigatorios <- verificar(pacotes_obrigatorios)
status_opcionais <- verificar(pacotes_opcionais)

resultado <- data.frame(
  pacote = c(pacotes_obrigatorios, pacotes_opcionais),
  tipo = c(
    rep("obrigatorio", length(pacotes_obrigatorios)),
    rep("opcional", length(pacotes_opcionais))
  ),
  instalado = c(status_obrigatorios, status_opcionais)
)
print(resultado, row.names = FALSE)

ausentes <- names(status_obrigatorios)[!status_obrigatorios]
if (length(ausentes) > 0L) {
  stop(
    "Pacotes obrigatorios ausentes: ", paste(ausentes, collapse = ", "),
    ". Consulte requisitos.md."
  )
}

message("Dependencias obrigatorias disponiveis.")
