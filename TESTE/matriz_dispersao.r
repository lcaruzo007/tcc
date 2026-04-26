# =========================================================================
# PASSO 4: MATRIZ DE DISPERSÃO POR ESCOLA
# =========================================================================

source("utils_saeb.r")   # encontrar_arquivo_mais_recente

# -------------------------------------------------------------------------
# Configuração — ajuste antes de executar
# -------------------------------------------------------------------------
id_escola      <- NULL    # NULL = escolha interativa; ou ex.: "61432986"
materia        <- "MT"    # "MT" ou "LP"
top_n          <- 8L      # máximo de variáveis explicativas na matriz
raiz_escolas   <- "C:/Users/Usuario/Desktop/tcc/TESTE/dados_por_escola"

# -------------------------------------------------------------------------
# Validação de diretório e seleção da escola
# -------------------------------------------------------------------------
if (!dir.exists(raiz_escolas)) {
  stop("Diretorio nao encontrado: ", raiz_escolas)
}

escolas_disponiveis <- list.dirs(raiz_escolas, full.names = FALSE, recursive = FALSE)
escolas_disponiveis <- escolas_disponiveis[nzchar(escolas_disponiveis)]

if (length(escolas_disponiveis) == 0L) {
  stop("Nenhuma pasta de escola encontrada em: ", raiz_escolas)
}

if (is.null(id_escola) || !nzchar(id_escola)) {
  if (interactive()) {
    idx <- utils::menu(escolas_disponiveis,
                       title = "Escolha a escola para gerar a matriz:")
    if (idx == 0L) stop("Seleção cancelada.")
    id_escola <- escolas_disponiveis[idx]
  } else {
    stop("Defina id_escola para execucao nao interativa.")
  }
}

if (!(id_escola %in% escolas_disponiveis)) {
  stop("Escola nao encontrada em dados_por_escola: ", id_escola)
}

# -------------------------------------------------------------------------
# Localizar arquivos de acordo com a matéria
# -------------------------------------------------------------------------
materia <- match.arg(toupper(materia), c("MT", "LP"))

pasta_escola <- file.path(raiz_escolas, id_escola)

prefixo_dados <- paste0("dados_FINAL_", materia, "_Filtrado")
prefixo_corr  <- paste0("correlacoes_mantidas_", materia)
nome_nota     <- if (materia == "MT") "PROFICIENCIA_MT_SAEB" else "PROFICIENCIA_LP_SAEB"

arquivo_dados <- encontrar_arquivo_mais_recente(pasta_escola, prefixo_dados)
arquivo_corr  <- encontrar_arquivo_mais_recente(pasta_escola, prefixo_corr)

if (is.null(arquivo_dados)) stop("Arquivo de dados filtrados nao encontrado.")
if (is.null(arquivo_corr))  stop("Arquivo de correlacoes mantidas nao encontrado.")

# -------------------------------------------------------------------------
# Leitura e seleção das top-N variáveis
# -------------------------------------------------------------------------
dados <- read.csv(arquivo_dados, stringsAsFactors = FALSE)
corr  <- read.csv(arquivo_corr,  stringsAsFactors = FALSE)

if (nrow(corr) == 0L) {
  stop("Nenhuma variavel mantida — impossivel gerar a matriz.")
}

coluna_corr <- grep("Correlacao", names(corr), ignore.case = TRUE, value = TRUE)
if (length(coluna_corr) == 0L) {
  stop("Coluna de correlacao nao encontrada no arquivo de correlacoes.")
}

corr_ord <- corr[order(-abs(corr[[coluna_corr[1L]]])), , drop = FALSE]
vars_top  <- head(corr_ord$Variavel, top_n)
vars_top  <- intersect(vars_top, names(dados))   # garante que existem em `dados`

if (!(nome_nota %in% names(dados))) {
  stop("Variavel de nota nao encontrada: ", nome_nota)
}

if (length(vars_top) == 0L) {
  stop("Nenhuma variavel explicativa valida encontrada para a matriz.")
}

# -------------------------------------------------------------------------
# Preparação do data frame para plotagem
# -------------------------------------------------------------------------
vars_plot <- unique(c(nome_nota, vars_top))
df_plot   <- dados[, vars_plot, drop = FALSE]

# Remove colunas constantes
constantes <- names(df_plot)[vapply(df_plot, function(x) {
  v <- var(x, na.rm = TRUE)
  is.na(v) || v == 0
}, logical(1))]

if (length(constantes) > 0L) {
  message("Colunas constantes removidas: ", paste(constantes, collapse = ", "))
  df_plot <- df_plot[, setdiff(names(df_plot), constantes), drop = FALSE]
}

df_plot <- df_plot[complete.cases(df_plot), , drop = FALSE]

if (ncol(df_plot) < 2L) stop("Colunas insuficientes apos limpeza.")
if (nrow(df_plot) < 5L) stop("Observacoes insuficientes apos limpeza.")

# -------------------------------------------------------------------------
# Gerar e salvar a matriz de dispersão
# -------------------------------------------------------------------------
n_vars_explicativas <- length(setdiff(names(df_plot), nome_nota))
arquivo_saida <- file.path(
  pasta_escola,
  paste0("matriz_dispersao_", materia, "_top", n_vars_explicativas, ".png")
)

png(filename = arquivo_saida, width = 2400L, height = 2400L, res = 220L)

pairs(
  df_plot,
  pch  = 19,
  cex  = 0.35,
  col  = rgb(0.1, 0.3, 0.7, 0.35),
  main = paste0("Matriz de Dispersão — Escola ", id_escola, " (", materia, ")")
)

dev.off()

message("Matriz gerada: ", arquivo_saida)
message("Variáveis incluídas: ", paste(names(df_plot), collapse = ", "))
