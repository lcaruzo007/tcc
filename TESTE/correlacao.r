# =========================================================================
# PASSO 2: CALCULO DE CORRELACOES POR ESCOLA
# =========================================================================

# Resolve caminhos para manter a execucao dentro de TESTE.
if (file.exists(file.path(getwd(), "correlacao.r"))) {
  base_dir <- getwd()
} else if (file.exists(file.path(getwd(), "TESTE", "correlacao.r"))) {
  base_dir <- file.path(getwd(), "TESTE")
} else {
  arquivo_script <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NA_character_)
  base_dir <- if (!is.na(arquivo_script)) dirname(arquivo_script) else getwd()
}

source(file.path(base_dir, "utils_saeb.r"))   # encontrar_arquivo_mais_recente, arquivo_com_versao_existe

# -------------------------------------------------------------------------
# Configuracao
# -------------------------------------------------------------------------
nota_MT    <- "PROFICIENCIA_MT_SAEB"
nota_LP    <- "PROFICIENCIA_LP_SAEB"
limiar_cor <- 0.30

# Metodo de deteccao de degeneracao:
#   "zero_variancia" - remove apenas colunas sem variacao
#   "near_zero"      - aplica somente nearZeroVar
#   "hibrido"        - zero_variancia + nearZeroVar (quando n >= min_linhas)
metodo_degeneracao        <- "hibrido"
min_linhas_para_near_zero <- 30L

# Parametros do nearZeroVar (substituto base R para survey)
freq_cut_nzv   <- 19
unique_cut_nzv <- 10

arquivo_entrada <- file.path(base_dir, "dados_escola_limpos.csv")
dir_saida_raiz  <- base_dir

if (!file.exists(arquivo_entrada)) {
  stop("Arquivo de entrada nao encontrado: ", arquivo_entrada)
}

inferir_id_escola <- function(df, arquivo) {
  if ("ID_ESCOLA" %in% names(df)) {
    id_val <- unique(na.omit(df$ID_ESCOLA))
    if (length(id_val) > 0L) return(as.character(id_val[1]))
  }

  candidatos <- unique(unlist(lapply(df, function(col) {
    valores <- unique(na.omit(col))
    valores <- valores[grepl("^[0-9]+$", as.character(valores))]
    as.character(valores)
  })))
  candidatos <- candidatos[nchar(candidatos) >= 6L]
  if (length(candidatos) > 0L) {
    return(candidatos[1])
  }

  nome_arquivo <- basename(arquivo)
  extraido <- regmatches(nome_arquivo, regexpr("[0-9]{6,}", nome_arquivo))
  if (length(extraido) > 0L && nzchar(extraido)) return(extraido)

  "desconhecida"
}

# -------------------------------------------------------------------------
# Funcoes auxiliares
# -------------------------------------------------------------------------

detectar_near_zero_variance <- function(df, freq_cut = 19, unique_cut = 10) {
  if (!is.data.frame(df) || ncol(df) == 0L) {
    return(data.frame(nzv = logical(0), row.names = character(0)))
  }

  resultados <- lapply(df, function(col) {
    valores <- col[!is.na(col)]
    n_total <- length(valores)

    if (n_total == 0L) {
      return(c(nzv = TRUE))
    }

    freq <- sort(table(valores), decreasing = TRUE)
    n_unique <- length(freq)
    perc_unique <- 100 * n_unique / n_total

    freq_ratio <- if (length(freq) >= 2L) as.numeric(freq[1]) / as.numeric(freq[2]) else Inf
    zero_var <- n_unique <= 1L
    near_zero <- zero_var || (freq_ratio >= freq_cut && perc_unique <= unique_cut)
    c(nzv = near_zero)
  })

  data.frame(nzv = vapply(resultados, function(x) as.logical(x["nzv"]), logical(1)))
}

# Retorna colunas validas e data frame com motivo de descarte por variavel.
obter_colunas_validas <- function(df) {

  # Passo 1: colunas inteiramente NA
  colunas_somente_na <- names(df)[colSums(!is.na(df)) == 0L]
  colunas_iniciais   <- setdiff(names(df), colunas_somente_na)
  df_tmp             <- df[, colunas_iniciais, drop = FALSE]

  # Passo 2: variancia zero
  variancia_zero <- names(df_tmp)[vapply(df_tmp, function(col) {
    v <- var(col, na.rm = TRUE)
    is.na(v) || v == 0
  }, logical(1))]

  colunas_validas <- setdiff(colunas_iniciais, variancia_zero)

  usou_nzv <- FALSE
  vars_nzv <- character(0)

  # Passo 3: near-zero variance
  if (metodo_degeneracao %in% c("near_zero", "hibrido")) {
    if (nrow(df_tmp) >= min_linhas_para_near_zero && length(colunas_validas) > 0L) {
      nzv_metrics <- detectar_near_zero_variance(
        df_tmp[, colunas_validas, drop = FALSE],
        freq_cut = freq_cut_nzv,
        unique_cut = unique_cut_nzv
      )
      vars_nzv        <- names(nzv_metrics)[nzv_metrics$nzv]
      colunas_validas <- setdiff(colunas_validas, vars_nzv)
      usou_nzv        <- TRUE
    }
  }

  if (metodo_degeneracao == "near_zero" && !usou_nzv) {
    colunas_validas <- setdiff(colunas_iniciais, colunas_somente_na)
    vars_nzv        <- character(0)
  }

  # Monta tabela com motivo de descarte por variavel
  partes <- list(
    if (length(colunas_somente_na) > 0L)
      data.frame(Variavel = colunas_somente_na, Motivo = "somente_na",
                 stringsAsFactors = FALSE),
    if (length(variancia_zero) > 0L)
      data.frame(Variavel = variancia_zero, Motivo = "variancia_zero",
                 stringsAsFactors = FALSE),
    if (length(vars_nzv) > 0L)
      data.frame(Variavel = vars_nzv, Motivo = "near_zero_var",
                 stringsAsFactors = FALSE)
  )
  partes     <- Filter(Negate(is.null), partes)
  df_motivos <- if (length(partes) > 0L) do.call(rbind, partes) else
                  data.frame(Variavel = character(0), Motivo = character(0),
                             stringsAsFactors = FALSE)
  df_motivos <- df_motivos[!duplicated(df_motivos$Variavel), ]

  list(
    colunas_validas    = colunas_validas,
    df_motivos         = df_motivos,
    usou_nzv           = usou_nzv,
    colunas_somente_na = colunas_somente_na,
    variancia_zero     = variancia_zero
  )
}

# -------------------------------------------------------------------------
# Funcao para gerar relatorio em TXT com comentarios do diagnostico
# -------------------------------------------------------------------------
gerar_relatorio_diagnostico <- function(arquivo_saida, diagnostico, df_motivos,
                                        colunas_validas, usou_nzv) {
  linhas <- c(
    paste0("ESCOLA: ", basename(dirname(arquivo_saida))),
    paste0("n_linhas: ", diagnostico$valor[diagnostico$metrica == "n_linhas"]),
    paste0("n_colunas_entrada: ", diagnostico$valor[diagnostico$metrica == "n_colunas_entrada"]),
    paste0("n_colunas_validas: ", diagnostico$valor[diagnostico$metrica == "n_colunas_validas"]),
    paste0("n_degeneradas: ", diagnostico$valor[diagnostico$metrica == "n_degeneradas"]),
    paste0("n_somente_na: ", diagnostico$valor[diagnostico$metrica == "n_somente_na"]),
    paste0("n_variancia_zero: ", diagnostico$valor[diagnostico$metrica == "n_variancia_zero"]),
    paste0("n_near_zero_var: ", diagnostico$valor[diagnostico$metrica == "n_near_zero_var"]),
    paste0("nzv_aplicado: ", diagnostico$valor[diagnostico$metrica == "nzv_aplicado"])
  )

  writeLines(linhas, arquivo_saida)
  invisible(arquivo_saida)
}

# -------------------------------------------------------------------------
# Processamento de um unico arquivo limpo
# -------------------------------------------------------------------------
dados_escola <- read.csv(arquivo_entrada, stringsAsFactors = FALSE)

id_escola <- inferir_id_escola(dados_escola, arquivo_entrada)
if (!"ID_ESCOLA" %in% names(dados_escola)) {
  dados_escola$ID_ESCOLA <- id_escola
}

message("Processando arquivo limpo da escola: ", id_escola)

if (nrow(dados_escola) < 5L) {
  stop("Poucos registros para calcular correlacao no arquivo limpo.")
}

colunas_necessarias <- intersect(c(nota_MT, nota_LP, grep("^TX_RESP_Q", names(dados_escola), value = TRUE)),
                                 names(dados_escola))
dados_filtrados <- dados_escola[, colunas_necessarias, drop = FALSE]

resultado_filtro <- obter_colunas_validas(dados_filtrados)
colunas_validas  <- resultado_filtro$colunas_validas
df_motivos       <- resultado_filtro$df_motivos

if (!all(c(nota_MT, nota_LP) %in% colunas_validas)) {
  stop("Notas de proficiencia ausentes apos filtragem.")
}

if (length(colunas_validas) < 3L) {
  stop("Variaveis insuficientes para correlacao.")
}

# Correlacoes
dados_validos   <- dados_filtrados[, colunas_validas, drop = FALSE]
matriz_cor      <- suppressWarnings(
  cor(dados_validos, use = "pairwise.complete.obs", method = "pearson")
)
dados_escalados <- as.data.frame(scale(dados_validos))

cor_MT <- matriz_cor[, nota_MT]
cor_LP <- matriz_cor[, nota_LP]

fortes_MT <- names(cor_MT)[!is.na(cor_MT) & abs(cor_MT) >= limiar_cor]
fortes_LP <- names(cor_LP)[!is.na(cor_LP) & abs(cor_LP) >= limiar_cor]
fortes_MT <- intersect(fortes_MT, names(dados_escalados))
fortes_LP <- intersect(fortes_LP, names(dados_escalados))

dados_finais_MT <- dados_escalados[, fortes_MT, drop = FALSE]
dados_finais_LP <- dados_escalados[, fortes_LP, drop = FALSE]

df_cor_MT <- data.frame(Variavel              = names(cor_MT),
                        Correlacao_Matematica = as.numeric(cor_MT))
df_cor_LP <- data.frame(Variavel             = names(cor_LP),
                        Correlacao_Portugues = as.numeric(cor_LP))
df_todas  <- merge(df_cor_MT, df_cor_LP, by = "Variavel")

df_fortes_MT <- subset(df_cor_MT,
                       abs(Correlacao_Matematica) >= limiar_cor & Variavel != nota_MT)
df_fortes_LP <- subset(df_cor_LP,
                       abs(Correlacao_Portugues)  >= limiar_cor & Variavel != nota_LP)

diagnostico <- data.frame(
  metrica = c("n_linhas", "n_colunas_entrada", "n_colunas_validas",
              "n_degeneradas", "n_somente_na", "n_variancia_zero",
              "n_near_zero_var", "nzv_aplicado"),
  valor = c(
    nrow(dados_filtrados),
    ncol(dados_filtrados),
    length(colunas_validas),
    nrow(df_motivos),
    length(resultado_filtro$colunas_somente_na),
    length(resultado_filtro$variancia_zero),
    sum(df_motivos$Motivo == "near_zero_var"),
    ifelse(resultado_filtro$usou_nzv, "sim", "nao")
  )
)

salvar <- function(df, nome) {
  write.csv(df, file.path(dir_saida_raiz, paste0(nome, ".csv")), row.names = FALSE)
}

salvar(df_motivos,      "variaveis_degeneradas")
salvar(diagnostico,     "diagnostico_degeneracao")
tryCatch(
  gerar_relatorio_diagnostico(file.path(dir_saida_raiz, "LEIA_DIAGNOSTICO.txt"),
                              diagnostico, df_motivos, colunas_validas, resultado_filtro$usou_nzv),
  error = function(e) message("Falha ao gerar relatorio: ", e$message)
)
salvar(dados_finais_MT, "dados_FINAL_MT_Filtrado")
salvar(dados_finais_LP, "dados_FINAL_LP_Filtrado")
salvar(df_todas,        "todas_correlacoes_calculadas")
salvar(df_fortes_MT,    "correlacoes_mantidas_MT")
salvar(df_fortes_LP,    "correlacoes_mantidas_LP")

df_resumo <- data.frame(
  ID_ESCOLA         = id_escola,
  n_alunos          = nrow(dados_filtrados),
  n_variaveis_total = ncol(dados_filtrados),
  n_validas         = length(colunas_validas),
  n_degeneradas     = nrow(df_motivos),
  n_cor_MT          = nrow(df_fortes_MT),
  n_cor_LP          = nrow(df_fortes_LP),
  stringsAsFactors  = FALSE
)

write.csv(df_resumo, file.path(dir_saida_raiz, "resumo_processamento.csv"), row.names = FALSE)
message("Processamento concluido para a escola ", id_escola)
