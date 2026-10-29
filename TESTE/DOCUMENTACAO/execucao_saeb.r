################################################################################
# SCRIPT: execucao_saeb.r
# ENTRADA: Contexto da execucao e caminhos dos artefatos.
# SAIDA: Registro de entradas/saidas e leitura vinculada a uma execucao.
# VERSAO: 1.0 - Outubro 2026
################################################################################

registrar_artefato_saeb <- function(arquivo, modulo, nome, tipo, direcao = "saida") {
  registro <- Sys.getenv("SAEB_REGISTRO", "")
  if (!nzchar(registro)) return(invisible(NULL))
  linha <- data.frame(
    Execucao = Sys.getenv("SAEB_EXECUCAO_ID"), Etapa = Sys.getenv("SAEB_ETAPA"),
    Direcao = direcao, Modulo = normalizePath(modulo, winslash = "/", mustWork = FALSE),
    Nome = nome, Tipo = tipo,
    Arquivo = normalizePath(arquivo, winslash = "/", mustWork = FALSE),
    Horario = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
  write.table(linha, registro, sep = ",", row.names = FALSE,
              col.names = !file.exists(registro), append = file.exists(registro),
              qmethod = "double")
  invisible(arquivo)
}

registrar_entrada_saeb <- function(arquivo) {
  registrar_artefato_saeb(arquivo, dirname(arquivo), basename(arquivo), "entrada", "entrada")
  invisible(arquivo)
}

artefatos_execucao_saeb <- function() {
  entradas <- Sys.getenv("SAEB_ENTRADAS", "")
  if (nzchar(entradas) && file.exists(entradas)) {
    cache <- getOption("saeb.artefatos_cache")
    if (is.null(cache)) {
      cache <- readRDS(entradas)
      options(saeb.artefatos_cache = cache)
    }
    return(cache)
  }
  registro <- Sys.getenv("SAEB_REGISTRO", "")
  if (!nzchar(registro) || !file.exists(registro)) return(NULL)
  read.csv(registro, stringsAsFactors = FALSE)
}

resolver_artefato_execucao_saeb <- function(pasta, nome, tipo = NULL) {
  if (Sys.getenv("SAEB_LEITURA_ESTRITA", "0") != "1") return(NULL)
  registro <- artefatos_execucao_saeb()
  raiz <- normalizePath(pasta, winslash = "/", mustWork = FALSE)
  if (!is.null(registro)) {
    ok <- registro$Direcao == "saida" & registro$Nome == nome &
      startsWith(registro$Arquivo, paste0(raiz, "/"))
    if (!is.null(tipo)) ok <- ok & registro$Tipo == gsub("\\", "/", tipo, fixed = TRUE)
    candidatos <- registro$Arquivo[ok]
    candidatos <- candidatos[file.exists(candidatos)]
    if (length(candidatos)) return(tail(candidatos, 1))
  }
  stop("Artefato ausente na execucao atual: ", nome, " em ", pasta)
}

encontrar_arquivo_escola_saeb <- function(pasta, id, nome) {
  tipo <- file.path("tabelas", as.character(id))
  if (Sys.getenv("SAEB_LEITURA_ESTRITA", "0") == "1") {
    arquivo <- resolver_artefato_execucao_saeb(pasta, nome, tipo)
  } else {
    arquivo <- encontrar_arquivo_mais_recente(pasta, nome, tipo)
    if (is.null(arquivo)) {
      arquivo <- encontrar_arquivo_mais_recente(file.path(pasta, as.character(id)), nome)
    }
  }
  if (!is.null(arquivo)) registrar_entrada_saeb(arquivo)
  arquivo
}

listar_escolas_saeb <- function(pasta) {
  if (Sys.getenv("SAEB_LEITURA_ESTRITA", "0") == "1") {
    registro <- artefatos_execucao_saeb()
    if (is.null(registro)) return(character())
    raiz <- normalizePath(pasta, winslash = "/", mustWork = FALSE)
    tipos <- registro$Tipo[registro$Direcao == "saida" &
      startsWith(registro$Arquivo, paste0(raiz, "/")) & file.exists(registro$Arquivo)]
    return(sort(unique(sub("^tabelas/", "", tipos[grepl("^tabelas/[0-9]+$", tipos)]))))
  }
  datas <- list.dirs(pasta, full.names = TRUE, recursive = FALSE)
  datas <- sort(datas[grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", basename(datas))], decreasing = TRUE)
  for (data in datas) {
    pasta_tabelas <- file.path(data, "tabelas")
    ids <- basename(list.dirs(pasta_tabelas, full.names = TRUE, recursive = FALSE))
    ids <- ids[grepl("^[0-9]+$", ids)]
    if (length(ids)) return(sort(unique(ids)))
  }
  ids <- basename(list.dirs(pasta, full.names = TRUE, recursive = FALSE))
  sort(unique(ids[grepl("^[0-9]+$", ids)]))
}

escolas_solicitadas_saeb <- function(ids) {
  filtro <- Sys.getenv("SAEB_ESCOLAS", "")
  if (!nzchar(filtro)) return(ids)
  intersect(as.character(ids), strsplit(filtro, ",", fixed = TRUE)[[1]])
}
