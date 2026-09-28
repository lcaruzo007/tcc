################################################################################
# SCRIPT: validar_pipeline.r
#
# OBJETIVO: Validar sintaxe, caminhos e invariantes basicos do pipeline.
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

RAIZ <- detectar_raiz()
scripts <- list.files(
  file.path(RAIZ, "TESTE"), pattern = "[.]r$", recursive = TRUE,
  full.names = TRUE
)
scripts <- c(file.path(RAIZ, "executar_pipeline.r"), scripts)

erros_sintaxe <- character()
for (script in scripts) {
  erro <- tryCatch({
    parse(script)
    NULL
  }, error = function(e) conditionMessage(e))
  if (!is.null(erro)) erros_sintaxe[script] <- erro
}

if (length(erros_sintaxe) > 0L) {
  print(erros_sintaxe)
  stop("Foram encontrados erros de sintaxe.")
}
message("OK Sintaxe: ", length(scripts), " scripts.")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))
dir_outputs <- file.path(RAIZ, "TESTE", "3_ANALISE_DE_GRUPOS", "outputs")
arquivo_meta <- encontrar_arquivo_mais_recente(
  dir_outputs, "metadados_escolas", "metadados"
)

if (is.null(arquivo_meta)) {
  message("AVISO Metadados nao encontrados; invariantes de dados foram ignorados.")
} else {
  metadados <- read.csv(arquivo_meta, check.names = FALSE)
  colunas <- c(
    "ID_ESCOLA", "TIPO_ESCOLA", "AREA", "LOCALIZACAO", "AREA_LOCAL",
    "MEDIA_MT", "MEDIA_LP", "INSE_MEDIO"
  )
  ausentes <- setdiff(colunas, names(metadados))
  if (length(ausentes) > 0L) {
    stop("Colunas ausentes nos metadados: ", paste(ausentes, collapse = ", "))
  }
  if (anyDuplicated(metadados$ID_ESCOLA)) {
    stop("ID_ESCOLA duplicado na base agregada.")
  }
  categorias_validas <- c(
    "Urbana_Capital", "Urbana_Interior", "Rural_Capital", "Rural_Interior"
  )
  categorias_invalidas <- setdiff(na.omit(unique(metadados$AREA_LOCAL)), categorias_validas)
  if (length(categorias_invalidas) > 0L) {
    stop("Categorias AREA_LOCAL invalidas: ", paste(categorias_invalidas, collapse = ", "))
  }
  invalido_mt <- !is.na(metadados$MEDIA_MT) & !is.finite(metadados$MEDIA_MT)
  invalido_lp <- !is.na(metadados$MEDIA_LP) & !is.finite(metadados$MEDIA_LP)
  if (any(invalido_mt) || any(invalido_lp)) {
    stop("Medias de proficiencia contem valores nao finitos.")
  }
  fora_faixa_mt <- !is.na(metadados$MEDIA_MT) &
    (metadados$MEDIA_MT < 150 | metadados$MEDIA_MT > 800)
  fora_faixa_lp <- !is.na(metadados$MEDIA_LP) &
    (metadados$MEDIA_LP < 150 | metadados$MEDIA_LP > 800)
  if (any(fora_faixa_mt) || any(fora_faixa_lp)) {
    stop(
      "Medias fora da faixa plausivel 150-800: MT=", sum(fora_faixa_mt),
      ", LP=", sum(fora_faixa_lp), "."
    )
  }
  n_ausentes <- sum(is.na(metadados$MEDIA_MT) | is.na(metadados$MEDIA_LP))
  if (n_ausentes > 0L) {
    message("AVISO Escolas com media de proficiencia ausente: ", n_ausentes, ".")
  }
  message("OK Invariantes: ", nrow(metadados), " escolas em ", basename(arquivo_meta), ".")
}

message("Validacao concluida sem erros.")
