################################################################################
# SCRIPT: validar_pipeline.r
# ENTRADA: Scripts, testes sinteticos e metadados locais opcionais.
# SAIDA: Validacao distinguindo verificacoes de codigo e de dados reais.
# VERSAO: 2.0 - Outubro 2026
################################################################################

detectar_raiz <- function() {
  pasta <- normalizePath(getwd(), winslash = "/")
  while (pasta != dirname(pasta)) {
    if (dir.exists(file.path(pasta, "TESTE"))) return(pasta)
    pasta <- dirname(pasta)
  }
  stop("Pasta TESTE nao encontrada.")
}
RAIZ <- detectar_raiz()
args <- commandArgs(trailingOnly = TRUE)
if (any(!args %in% c("--exigir-dados", "--somente-sintaxe"))) stop("Argumento desconhecido.")
scripts <- c(file.path(RAIZ, "executar_pipeline.r"),
             list.files(file.path(RAIZ, "TESTE"), pattern = "[.]r$", recursive = TRUE, full.names = TRUE))
scripts <- scripts[!grepl("/arquivo/", gsub("\\", "/", scripts, fixed = TRUE))]
for (script in scripts) parse(script)
message("OK Sintaxe: ", length(scripts), " scripts ativos e auxiliares locais.")
if (!"--somente-sintaxe" %in% args) {
  source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "testar_contratos.r"))
  dir_outputs <- file.path(RAIZ, "TESTE", "3_ANALISE_DE_GRUPOS", "outputs")
  arquivo <- encontrar_arquivo_mais_recente(dir_outputs, "metadados_escolas", "metadados")
  if (is.null(arquivo)) {
    if ("--exigir-dados" %in% args) stop("Dados reais obrigatorios nao encontrados.")
    message("PARCIAL: codigo validado; dados reais NAO verificados (sem metadados).")
  } else {
    dados <- read_csv(arquivo, show_col_types = FALSE)
    validar_metadados_saeb(dados)
    message("OK Metadados reais: ", nrow(dados), " escolas em ", arquivo)
    message("Validacao de codigo e metadados concluida.")
  }
}
