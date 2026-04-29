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

# Parametros do nearZeroVar (padrao caret para dados de survey)
# freq_cut_nzv  : razao freq(1a categoria) / freq(2a). 19 = padrao 95/5 do caret.
#                 Menor valor = mais rigoroso (descarta mais).
# unique_cut_nzv: % minima de valores unicos. Menor = mais rigoroso.
freq_cut_nzv   <- 19
unique_cut_nzv <- 10

dir_entrada_escolas <- file.path(base_dir, "dados_por_escola")
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
gerar_relatorio_diagnostico <- function(pasta_escola, diagnostico, df_motivos,
                                        colunas_validas, usou_nzv) {
  # Extrair valores do diagnostico
  n_linhas         <- as.integer(diagnostico[diagnostico$metrica == "n_linhas", "valor"])
  n_entrada        <- as.integer(diagnostico[diagnostico$metrica == "n_colunas_entrada", "valor"])
  n_validas        <- as.integer(diagnostico[diagnostico$metrica == "n_colunas_validas", "valor"])
  n_degen          <- as.integer(diagnostico[diagnostico$metrica == "n_degeneradas", "valor"])
  n_somente_na     <- as.integer(diagnostico[diagnostico$metrica == "n_somente_na", "valor"])
  n_var_zero       <- as.integer(diagnostico[diagnostico$metrica == "n_variancia_zero", "valor"])
  n_near_zero      <- as.integer(diagnostico[diagnostico$metrica == "n_near_zero_var", "valor"])
  nzv_aplicado     <- diagnostico[diagnostico$metrica == "nzv_aplicado", "valor"]

  # Lista de variaveis descartadas por motivo
  vars_near_zero <- df_motivos[df_motivos$Motivo == "near_zero_var", "Variavel"]
  vars_var_zero  <- df_motivos[df_motivos$Motivo == "variancia_zero", "Variavel"]
  vars_so_na     <- df_motivos[df_motivos$Motivo == "somente_na", "Variavel"]

  # Formatacao de listas
  format_list <- function(v) {
    if (length(v) == 0) return("(nenhuma)")
    paste(v, collapse = ", ")
  }

  # Criar conteudo do relatorio
  conteudo <- sprintf(
"================================================================================
DIAGNÓSTICO DE DEGENERAÇÃO - ESCOLA %s
================================================================================

RESUMO EXECUTIVO:
  • %d alunos responderam ao questionário
  • %d variáveis (perguntas) foram coletadas
  • %d variáveis foram descartadas (degeneradas)
  • %d variáveis restantes para análise de correlação

================================================================================
MÉTRICAS DETALHADAS:
================================================================================

1. n_linhas = %d
   └─ Número total de observações (alunos da escola)
   └─ Relevância: Determina qual método de detecção de degeneração é usado

2. n_colunas_entrada = %d
   └─ Número inicial de variáveis carregadas do arquivo CSV
   └─ Inclui: ID_ESCOLA, PROFICIENCIA_MT_SAEB, PROFICIENCIA_LP_SAEB + outras respostas

3. n_colunas_validas = %d
   └─ Variáveis que passaram em TODOS os critérios de validação
   └─ Essas %d serão usadas para calcular correlações com as notas

4. n_degeneradas = %d
   └─ Total de variáveis removidas por falta de variação
   └─ Cálculo: %d - %d = %d variáveis descartadas

5. n_somente_na = %d
   └─ Variáveis 100%% vazias (nenhum aluno respondeu)
   └─ Status: %s
   └─ Lista: %s

6. n_variancia_zero = %d
   └─ Variáveis onde TODOS os alunos deram a MESMA resposta
   └─ Exemplo: Se todos marcassem \"Sim\" na Q01, teria var = 0
   └─ Status: %s
   └─ Lista: %s

7. n_near_zero_var = %d
   └─ Variáveis com variação MUITO pequena (dominadas por 1 resposta)
   └─ Critério: freq_cut=19 (razão 95/5) e unique_cut=10%% (mínimo de valores únicos)
   └─ Exemplo: 95 alunos marcaram \"Sim\", 5 marcaram \"Não\" → 95/5=19 → DESCARTA
   └─ Status: %s
   └─ Lista: %s

8. nzv_aplicado = %s
   └─ Indica que o teste nearZeroVar foi %s executado
   └─ Condição: n_linhas (%d) >= min_linhas_para_near_zero (30) %s
   └─ Se fosse \"nao\" significaria que havia poucos alunos para usar este método

================================================================================
INTERPRETAÇÃO:
================================================================================

%s

✓ CONCLUSÃO:
  - %d variáveis válidas é uma %s base para análise
  - Correlações serão calculadas apenas com essas %d
  - Variáveis descartadas não afetam a qualidade das análises

================================================================================
Gerado automaticamente pelo script correlacao.r
================================================================================",
    basename(pasta_escola),
    n_linhas, n_entrada, n_degen, n_validas,
    n_linhas, n_entrada, n_validas, n_validas, n_entrada, n_validas, n_entrada - n_validas,
    n_somente_na, ifelse(n_somente_na == 0, "NENHUMA (0) neste diagnóstico", "ENCONTRADA(S)"),
    format_list(vars_so_na),
    n_var_zero, ifelse(n_var_zero == 0, "NENHUMA (0) neste diagnóstico", "ENCONTRADA(S)"),
    format_list(vars_var_zero),
    n_near_zero, ifelse(n_near_zero == 0, "NENHUMA (0) neste diagnóstico" ,
                        sprintf("ENCONTRADA(S) (%d descartadas)", n_near_zero)),
    format_list(vars_near_zero),
    nzv_aplicado, ifelse(nzv_aplicado == "sim", "REALMENTE", "NÃO foi"),
    n_linhas, ifelse(n_linhas >= 30, "✓" , "✗"),
    # Interpretacao
    if (n_degen == 0) {
      "✓ PONTO FORTE:\n  - Nenhuma variável foi descartada\n  - Excelente capacidade de discriminação de todas as perguntas"
    } else if (n_degen <= 5) {
      sprintf("⚠ PONTO DE ATENÇÃO:\n  - %d de %d variáveis foram descartadas (%.1f%%)\n  - Essas questões não discriminaram bem os alunos desta escola\n  - Possíveis causas:\n    a) Questões muito fáceis (maioria acertou)\n    b) Questões muito difíceis (maioria errou)\n    c) Enunciados confusos ou mal interpretados",
              n_degen, n_entrada, 100 * n_degen / n_entrada)
    } else {
      sprintf("⚠ ATENÇÃO:\n  - %d de %d variáveis foram descartadas (%.1f%%)\n  - Percentual elevado de questões com baixa discriminação\n  - Investigar se há padrões sistemáticos nas respostas",
              n_degen, n_entrada, 100 * n_degen / n_entrada)
    },
    n_validas, if (n_validas >= 50) "excelente" else if (n_validas >= 30) "boa" else "limitada",
    n_validas
  )

  # Salvar arquivo
  arquivo_saida <- file.path(pasta_escola, "LEIA_DIAGNOSTICO.txt")
  writeLines(conteudo, arquivo_saida)
  invisible(arquivo_saida)
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

  if (length(pastas_escola) == 0L) {
    message("Nenhuma escola pendente encontrada; processando todas as escolas da pasta de entrada.")
    pastas_escola <- list.dirs(dir_entrada_escolas, recursive = FALSE, full.names = TRUE)
  }
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
    dados_escola <- dados_escola[dados_escola$ID_ESCOLA == as.numeric(id_escola), , drop = FALSE]
  }

  if (nrow(dados_escola) < 5L) {
    escolas_com_erro[[id_escola]] <- "Poucos registros para calcular correlacao"
    next
  }

  colunas_necessarias <- intersect(c(nota_MT, nota_LP, grep("^TX_RESP_Q", names(dados_escola), value = TRUE)),
                                   names(dados_escola))
  dados_filtrados <- dados_escola[, colunas_necessarias, drop = FALSE]

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

  # Gerar relatorio em TXT com explicacoes
  tryCatch(
    gerar_relatorio_diagnostico(pasta_escola, diagnostico, df_motivos,
                                colunas_validas, resultado_filtro$usou_nzv),
    error = function(e) message("  Falha ao gerar relatorio: ", e$message)
  )
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
