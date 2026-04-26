# =========================================================================
# PASSO 2: CALCULO DE CORRELACOES POR ESCOLA
# =========================================================================

library(tidyverse)
library(caret)
source("utils_saeb.r")   # encontrar_arquivo_mais_recente, arquivo_com_versao_existe

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

# Parametros do nearZeroVar (padrao caret para dados de survey)
# freq_cut_nzv  : razao freq(1a categoria) / freq(2a). 19 = padrao 95/5 do caret.
#                 Menor valor = mais rigoroso (descarta mais).
# unique_cut_nzv: % minima de valores unicos. Menor = mais rigoroso.
freq_cut_nzv   <- 19
unique_cut_nzv <- 10

dir_entrada_escolas <- "C:/Users/Usuario/Desktop/tcc/TESTE/dados_por_escola"
dir_saida_raiz      <- dir_entrada_escolas

# Modo de execucao:
#   "pendentes"   - escolas sem resultados completos
#   "todas"       - todas as escolas encontradas
#   "especificas" - apenas as listadas em escolas_especificas
modo_execucao       <- "pendentes"
escolas_especificas <- character(0)

# -------------------------------------------------------------------------
# Funcoes auxiliares
# -------------------------------------------------------------------------

pasta_tem_resultados_completos <- function(pasta) {
  arquivos_esperados <- c(
    "variaveis_degeneradas",
    "dados_FINAL_MT_Filtrado",
    "dados_FINAL_LP_Filtrado",
    "todas_correlacoes_calculadas",
    "correlacoes_mantidas_MT",
    "correlacoes_mantidas_LP"
  )
  all(vapply(arquivos_esperados, arquivo_com_versao_existe,
             logical(1), pasta = pasta))
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
      nzv_metrics <- nearZeroVar(
        df_tmp[, colunas_validas, drop = FALSE],
        freqCut     = freq_cut_nzv,
        uniqueCut   = unique_cut_nzv,
        saveMetrics = TRUE
      )
      vars_nzv        <- rownames(nzv_metrics[nzv_metrics$nzv, , drop = FALSE])
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
# Validacao de diretorios e selecao de escolas
# -------------------------------------------------------------------------
if (!dir.exists(dir_entrada_escolas)) {
  stop("Diretorio nao encontrado: ", dir_entrada_escolas)
}

pastas_escola <- list.dirs(dir_entrada_escolas, recursive = FALSE, full.names = TRUE)

if (length(pastas_escola) == 0L) {
  stop("Nenhuma pasta de escola encontrada em: ", dir_entrada_escolas)
}

if (modo_execucao == "especificas") {
  if (length(escolas_especificas) == 0L) {
    stop("modo_execucao = 'especificas', mas escolas_especificas esta vazio.")
  }
  pastas_escola <- pastas_escola[basename(pastas_escola) %in% escolas_especificas]
}

if (modo_execucao == "pendentes") {
  pastas_escola <- pastas_escola[
    !vapply(pastas_escola, pasta_tem_resultados_completos, logical(1))
  ]
}

if (length(pastas_escola) == 0L) {
  stop("Nenhuma escola para processar no modo: ", modo_execucao)
}

message("Modo: ", modo_execucao, " | Escolas a processar: ", length(pastas_escola))

# -------------------------------------------------------------------------
# Loop principal
# -------------------------------------------------------------------------
escolas_com_erro <- list()
resumo_escolas   <- list()

for (pasta_escola in sort(pastas_escola)) {
  id_escola <- basename(pasta_escola)
  message("\n===== ESCOLA ", id_escola, " =====")

  arquivo_entrada_escola <- encontrar_arquivo_mais_recente(
    pasta_escola, "dados_escola_em_numeros"
  )
  if (is.null(arquivo_entrada_escola)) {
    escolas_com_erro[[id_escola]] <- "dados_escola_em_numeros.csv nao encontrado"
    next
  }

  dados_escola <- read.csv(arquivo_entrada_escola, stringsAsFactors = FALSE)

  if ("ID_ESCOLA" %in% names(dados_escola)) {
    dados_escola <- filter(dados_escola, ID_ESCOLA == as.numeric(id_escola))
  }

  if (nrow(dados_escola) < 5L) {
    escolas_com_erro[[id_escola]] <- "Poucos registros para calcular correlacao"
    next
  }

  dados_filtrados <- select(dados_escola,
                            all_of(c(nota_MT, nota_LP)),
                            starts_with("TX_RESP_Q"))

  resultado_filtro <- obter_colunas_validas(dados_filtrados)
  colunas_validas  <- resultado_filtro$colunas_validas
  df_motivos       <- resultado_filtro$df_motivos

  if (!all(c(nota_MT, nota_LP) %in% colunas_validas)) {
    escolas_com_erro[[id_escola]] <- "Notas de proficiencia ausentes apos filtragem"
    next
  }

  if (length(colunas_validas) < 3L) {
    escolas_com_erro[[id_escola]] <- "Variaveis insuficientes para correlacao"
    next
  }

  # Correlacoes
  dados_validos   <- dados_filtrados[, colunas_validas, drop = FALSE]
  matriz_cor      <- suppressWarnings(
    cor(dados_validos, use = "pairwise.complete.obs", method = "pearson")
  )
  dados_escalados <- as.data.frame(scale(dados_validos))

  cor_MT <- matriz_cor[, nota_MT]
  cor_LP <- matriz_cor[, nota_LP]

  fortes_MT <- names(cor_MT[abs(cor_MT) >= limiar_cor])
  fortes_LP <- names(cor_LP[abs(cor_LP) >= limiar_cor])

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

  # Acumula resumo consolidado
  resumo_escolas[[id_escola]] <- data.frame(
    ID_ESCOLA         = id_escola,
    n_alunos          = nrow(dados_filtrados),
    n_variaveis_total = ncol(dados_filtrados),
    n_validas         = length(colunas_validas),
    n_degeneradas     = nrow(df_motivos),
    n_cor_MT          = nrow(df_fortes_MT),
    n_cor_LP          = nrow(df_fortes_LP),
    stringsAsFactors  = FALSE
  )

  # Gravar resultados
  salvar <- function(df, nome) {
    write.csv(df, file.path(pasta_escola, paste0(nome, ".csv")), row.names = FALSE)
  }

  salvar(df_motivos,      "variaveis_degeneradas")   # agora inclui coluna Motivo
  salvar(diagnostico,     "diagnostico_degeneracao")
  salvar(dados_finais_MT, "dados_FINAL_MT_Filtrado")
  salvar(dados_finais_LP, "dados_FINAL_LP_Filtrado")
  salvar(df_todas,        "todas_correlacoes_calculadas")
  salvar(df_fortes_MT,    "correlacoes_mantidas_MT")
  salvar(df_fortes_LP,    "correlacoes_mantidas_LP")

  message("  n_alunos=",     nrow(dados_filtrados),
          " | validas=",     length(colunas_validas),
          " | degeneradas=", nrow(df_motivos),
          " | cor_MT=",      nrow(df_fortes_MT),
          " | cor_LP=",      nrow(df_fortes_LP))
}

# -------------------------------------------------------------------------
# Relatorio consolidado de todas as escolas
# -------------------------------------------------------------------------
if (length(resumo_escolas) > 0L) {
  df_resumo      <- do.call(rbind, resumo_escolas)
  rownames(df_resumo) <- NULL
  caminho_resumo <- file.path(dir_saida_raiz, "resumo_processamento.csv")
  write.csv(df_resumo, caminho_resumo, row.names = FALSE)
  message("\nResumo consolidado salvo em: ", caminho_resumo)
  print(df_resumo, row.names = FALSE)
}

# -------------------------------------------------------------------------
# Relatorio de erros
# -------------------------------------------------------------------------
if (length(escolas_com_erro) > 0L) {
  df_erros <- data.frame(
    ID_ESCOLA = names(escolas_com_erro),
    Motivo    = unlist(escolas_com_erro),
    row.names = NULL
  )
  caminho_erros <- file.path(dir_saida_raiz, "escolas_nao_processadas.csv")
  write.csv(df_erros, caminho_erros, row.names = FALSE)
  message("Escolas com erro: ", nrow(df_erros),
          ". Detalhes em: ", caminho_erros)
}

message("\nProcessamento concluido.")
