# =========================================================================
# utils_saeb.r — Funções utilitárias compartilhadas entre os scripts SAEB
# =========================================================================
# Fonte: source("utils_saeb.r")  (use caminho absoluto se necessário)

# -------------------------------------------------------------------------
# Retorna o arquivo mais recente que corresponde a nome_base (com ou sem
# sufixo de timestamp) dentro de `pasta`.
# -------------------------------------------------------------------------
encontrar_arquivo_mais_recente <- function(pasta, nome_base) {
  padrao <- paste0("^", nome_base, "(_[0-9]{8}_[0-9]{6}(_[0-9]+)?)?\\.csv$")
  arquivos <- list.files(pasta, pattern = padrao, full.names = TRUE)

  if (length(arquivos) == 0L) return(NULL)

  arquivos[which.max(file.info(arquivos)$mtime)]
}

# -------------------------------------------------------------------------
# Verifica se já existe ao menos um arquivo com o padrão de nome_base.
# -------------------------------------------------------------------------
arquivo_com_versao_existe <- function(pasta, nome_base) {
  padrao <- paste0("^", nome_base, "(_[0-9]{8}_[0-9]{6}(_[0-9]+)?)?\\.csv$")
  length(list.files(pasta, pattern = padrao)) > 0L
}

# -------------------------------------------------------------------------
# Gera caminho de saída sem sobrescrever arquivos já existentes.
# Quando sobrescrever = FALSE, acrescenta timestamp (e contador se necessário).
# -------------------------------------------------------------------------
gerar_caminho_sem_sobrescrever <- function(caminho_base, sobrescrever = FALSE) {
  if (sobrescrever || !file.exists(caminho_base)) return(caminho_base)

  pasta    <- dirname(caminho_base)
  nome     <- tools::file_path_sans_ext(basename(caminho_base))
  extensao <- tools::file_ext(caminho_base)
  sufixo   <- format(Sys.time(), "%Y%m%d_%H%M%S")

  montar <- function(contador = NULL) {
    parte_cnt <- if (!is.null(contador)) paste0("_", contador) else ""
    arquivo   <- paste0(nome, "_", sufixo, parte_cnt)
    if (nzchar(extensao)) arquivo <- paste0(arquivo, ".", extensao)
    file.path(pasta, arquivo)
  }

  candidato <- montar()
  contador  <- 1L
  while (file.exists(candidato)) {
    candidato <- montar(contador)
    contador  <- contador + 1L
  }
  candidato
}
