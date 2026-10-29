################################################################################
# SCRIPT: executar_pipeline.r
# ENTRADA: --passos=1,2,4,5,7,8,9,10; --auxiliares; --escolas=ID,ID.
# SAIDA: Manifesto, ambiente, logs e registro em DOCUMENTACAO/outputs/<data>/.
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
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "ambiente_saeb.r"))
ativar_ambiente_saeb(RAIZ)
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))
args <- commandArgs(trailingOnly = TRUE)
if (any(!grepl("^--(passos=|escolas=|auxiliares$)", args))) stop("Argumento desconhecido.")
arg_passos <- grep("^--passos=", args, value = TRUE)
arg_escolas <- grep("^--escolas=", args, value = TRUE)
if (length(arg_passos) > 1L || length(arg_escolas) > 1L) stop("Argumentos duplicados.")
padrao <- c(1L, 2L, 4L, 5L, 7L, 8L, 9L, 10L)
passos <- if (!length(arg_passos) || arg_passos == "--passos=todos") padrao else {
  suppressWarnings(as.integer(strsplit(sub("^--passos=", "", arg_passos), ",")[[1]]))
}
if (!length(passos) || anyNA(passos) || any(!passos %in% 1:10)) stop("Passos invalidos.")
solicitados <- sort(unique(passos))
if (3L %in% passos || 6L %in% passos) message("Passos 3 e 6 sao manuais e foram ignorados.")
passos <- setdiff(passos, c(3L, 6L))
if (2L %in% passos) passos <- c(passos, 1L)
if (any(c(5L, 7L, 10L) %in% passos)) passos <- c(passos, 4L)
passos <- sort(unique(passos))
if (!length(passos)) stop("Nenhum passo nao interativo selecionado.")
escolas <- if (length(arg_escolas)) sub("^--escolas=", "", arg_escolas) else ""
if (nzchar(escolas) && !grepl("^[0-9]+(,[0-9]+)*$", escolas)) stop("IDs de escolas invalidos.")

scripts <- list(
  "1" = "TESTE/1_LIMPEZA_E_TRANSFORMACAO/ajeitar_dados.r",
  "2" = "TESTE/2_ANALISE_POR_ESCOLA/Scripts/correlacao.r",
  "4" = "TESTE/3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r",
  "5" = "TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_grupos.r",
  "7" = paste0("TESTE/3_ANALISE_DE_GRUPOS/Scripts/", c(
    "dendrograma_analise_completa.r", "dendrograma_publica_vs_particular.r",
    "dendrograma_urbana_vs_rural.r", "dendrograma_capital_vs_interior.r", "dendrograma_area_local.r")),
  "8" = "TESTE/4_REGRESSAO_LINEAR/Scripts/regressao_linear_multipla.r",
  "9" = "TESTE/5_REGRESSAO_ITENS_BRUTOS/Scripts/regressao_itens_brutos_dummy.r",
  "10" = "TESTE/6_ANALISE_MEDIACAO/Scripts/analise_mediacao.r"
)
if ("--auxiliares" %in% args && 8L %in% passos) {
  scripts[["8"]] <- c(scripts[["8"]], paste0("TESTE/4_REGRESSAO_LINEAR/Scripts/", c(
    "grafico_coeficientes_referencia_oposta.r", "analise_sensibilidade_regressao.r")))
}
plano <- bind_rows(lapply(passos, function(p) {
  tibble(Passo = p, Script = scripts[[as.character(p)]], Status = "PENDENTE",
         Inicio = NA_character_, Fim = NA_character_, Log = NA_character_)
}))
DIR_BASE <- file.path(RAIZ, "TESTE", "DOCUMENTACAO")
execucao <- paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), "_", Sys.getpid())
manifesto_arquivo <- caminho_saida(DIR_BASE, "metadados", paste0("manifesto_", execucao), "rds")
registro <- caminho_saida(DIR_BASE, "metadados", paste0("artefatos_", execucao), "csv")
entradas <- caminho_saida(DIR_BASE, "metadados", paste0("entradas_", execucao), "rds")
ambiente <- caminho_saida(DIR_BASE, "metadados", paste0("ambiente_", execucao), "csv")
pacotes <- installed.packages()
write_csv(as_tibble(pacotes[, c("Package", "Version", "Built")]), ambiente)
bruto <- file.path(RAIZ, "MICRODADOS_SAEB_2023", "DADOS", "TS_ALUNO_34EM.csv")
codigo <- c(file.path(RAIZ, "executar_pipeline.r"),
            list.files(file.path(RAIZ, "TESTE"), pattern = "[.]r$", recursive = TRUE, full.names = TRUE))
git <- function(args) tryCatch(system2("git", args, stdout = TRUE, stderr = FALSE), error = function(e) NA_character_)
manifesto <- list(
  Execucao = execucao, Inicio = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  Fim = NULL, Status = "EM_EXECUCAO", Solicitados = solicitados, Passos = passos,
  Escolas_Ramo_Individual = escolas, Argumentos = args, R = R.version.string,
  Git = git(c("rev-parse", "HEAD")), Git_Status = git(c("status", "--short")),
  MD5_Entrada = tools::md5sum(bruto), MD5_Codigo = tools::md5sum(codigo),
  Ambiente = ambiente, Registro = registro, Etapas = plano, Sessao = sessionInfo()
)
atualizar <- function() saveRDS(manifesto, manifesto_arquivo)
atualizar()
Sys.setenv(SAEB_EXECUCAO_ID = execucao, SAEB_REGISTRO = registro,
           SAEB_LEITURA_ESTRITA = "1", SAEB_ESCOLAS = escolas, SAEB_ENTRADAS = entradas)
rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
message("Execucao: ", execucao, "; passos: ", paste(passos, collapse = ", "))
message("Manifesto: ", manifesto_arquivo)
for (i in seq_len(nrow(plano))) {
  Sys.setenv(SAEB_ETAPA = as.character(plano$Passo[i]))
  log <- caminho_saida(DIR_BASE, "diagnosticos", paste0("etapa_", plano$Passo[i], "_", i), "log")
  atuais <- if (file.exists(registro)) read.csv(registro, stringsAsFactors = FALSE) else data.frame()
  saveRDS(atuais, entradas)
  manifesto$Etapas$Status[i] <- "EM_EXECUCAO"
  manifesto$Etapas$Inicio[i] <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  manifesto$Etapas$Log[i] <- log
  atualizar()
  message("Executando: ", plano$Script[i])
  status <- tryCatch(system2(rscript, c("--vanilla",
                             shQuote(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "executar_etapa.r")),
                             shQuote(file.path(RAIZ, plano$Script[i]))),
                             stdout = log, stderr = log), error = function(e) 1L)
  manifesto$Etapas$Fim[i] <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  manifesto$Etapas$Status[i] <- if (status == 0L) "CONCLUIDA" else "FALHOU"
  atualizar()
  if (status != 0L) {
    manifesto$Fim <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
    manifesto$Status <- "FALHOU"
    atualizar()
    message(paste(tail(readLines(log, warn = FALSE), 15), collapse = "\n"))
    stop("Falha em ", plano$Script[i], ". Consulte ", log)
  }
}
manifesto$Fim <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
manifesto$Status <- "CONCLUIDA"
artefatos <- read.csv(registro, stringsAsFactors = FALSE)
arquivos <- unique(artefatos$Arquivo[file.exists(artefatos$Arquivo)])
manifesto$MD5_Artefatos <- tools::md5sum(arquivos)
atualizar()
message("Pipeline concluido. Manifesto: ", manifesto_arquivo)
