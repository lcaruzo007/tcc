# =========================================================================
# PASSO 2: CALCULO DE CORRELACOES POR ESCOLA
# Com tratamento diferenciado por tipo de variável
# =========================================================================

library(tidyverse)
library(caret)

# =========================================================================
# Configuração de Caminhos
# =========================================================================
RAIZ <- "C:/Users/13756596699/tcc"
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE_2 <- file.path(DIR_TESTE, "2_ANALISE_POR_ESCOLA")
DIR_ENTRADA_ESCOLAS <- file.path(DIR_ANALISE_2, "dados_por_escola")
DIR_SAIDA_RAIZ <- file.path(DIR_ANALISE_2, "outputs_correlacoes")

# Criar diretório de saída se não existir
if (!dir.exists(DIR_SAIDA_RAIZ)) {
  dir.create(DIR_SAIDA_RAIZ, showWarnings = FALSE, recursive = TRUE)
}

source(file.path(RAIZ, "DOCUMENTACAO", "utils_saeb.r"))

# -------------------------------------------------------------------------
# Configuracao — importa padrões de utils_saeb.r
# -------------------------------------------------------------------------
nota_MT    <- "PROFICIENCIA_MT_SAEB"
nota_LP    <- "PROFICIENCIA_LP_SAEB"

# Importar de utils_saeb.r (mudança centralizada afeta ambos scripts)
limiar_cor              <- LIMIAR_COR_PADRAO          # 0.30
metodo_degeneracao      <- METODO_DEGENERACAO_PADRAO  # "zero_variancia"
min_linhas_para_near_zero <- MIN_LINHAS_NEAR_ZERO     # 30
freq_cut_nzv            <- FREQ_CUT_NZV              # 19
unique_cut_nzv          <- UNIQUE_CUT_NZV            # 10

# Atalhos para os dicionários centralizados
ordinais      <- ORDINAIS_SAEB
nominais_info <- NOMINAIS_SAEB
continuas     <- CONTINUAS_SAEB

dir_entrada_escolas <- DIR_ENTRADA_ESCOLAS
dir_saida_raiz      <- DIR_SAIDA_RAIZ

# Modo de execucao:
#   "pendentes"   - escolas sem resultados completos
#   "todas"       - todas as escolas encontradas
#   "especificas" - apenas as listadas em escolas_especificas
modo_execucao       <- "todas"
escolas_especificas <- character(0)

# =========================================================================
# TRATAMENTO DE NaN E VALIDACAO DE CORRELACOES
# =========================================================================
# 
# PROBLEMA: Correlações podem retornar NaN em três cenários:
#   1. Variância zero: cor(c(5,5,5), c(1,2,3)) → NaN (divisão por zero)
#   2. Sem pares válidos: cor(c(NA,NA), c(1,2)) → NaN (n < 3)
#   3. Erro no cálculo: tryCatch captura exceções inesperadas
#
# SOLUÇÃO: Validação em dois níveis:
#   A) PRÉ-CÁLCULO: verificar variância antes de chamar cor()
#   B) PÓS-CÁLCULO: capturar NaN/Inf e registrar motivo em Status_Calculo
#
# RESULTADO:
#   Coluna Status_Calculo em todas_correlacoes_calculadas.csv:
#   - "OK"              : correlação válida (não é NA, NaN, Inf)
#   - "SEM_VARIANCIA_X" : coluna X não tem variação
#   - "SEM_VARIANCIA_Y" : coluna Y não tem variação
#   - "SEM_PARES"       : n < 3 pares válidos após remover NAs
#   - "NA_RESULTADO"    : cor() retornou NA (raro)
#   - "NaN_RESULTADO"   : cor() retornou NaN (raro, shouldn't happen)
#   - "ERRO: ..."       : exceção capturada durante cálculo
#   - "AVISO: ..."      : aviso durante cálculo
#
# INTERPRETACAO:
#   - Não use variáveis com Status != "OK" em análises
#   - SEM_VARIANCIA: significa que uma das colunas é constante
#   - SEM_PARES: muitos valores ausentes (NAs), n < 3 observações válidas
#   - NA/NaN_RESULTADO: investigar dados (shouldn't happen com validação)
#   - ERRO/AVISO: exceções capturadas, revisar manualmente
# =========================================================================

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

# ===== Validacao de variancia =====
# Verifica se uma coluna tem variância > 0 (pré-requisito para cor())
# Retorna FALSE se: variância = NA, NaN, ou = 0 (coluna constante)
# Argumentos:
#   x : vetor numérico
# Retorno: TRUE se tem variância positiva, FALSE caso contrário
tem_variancia <- function(x) {
  v <- var(x, na.rm = TRUE)
  !is.na(v) && v > 0
}

# ===== Calculo seguro de correlacao =====
# Encapsula cor() com validação pré-cálculo e captura de erros pós-cálculo.
# Evita NaN retornando status informativo sobre o que deu errado.
#
# Argumentos:
#   x, y   : vetores numéricos (podem ter NAs)
#   metodo : "pearson", "spearman", ou "kendall"
#
# Retorno:
#   list(valor = NA ou número, status = "OK"|"SEM_VARIANCIA_*"|"SEM_PARES"|...)
#   - valor : correlação calculada (NA se não conseguiu calcular)
#   - status : diagnóstico do cálculo (ver comentário no topo do arquivo)
#
# Fluxo:
#   1. Verificar se x tem variância > 0
#   2. Verificar se y tem variância > 0
#   3. Verificar se há >= 3 pares completos (sem NA)
#   4. Calcular cor() com use="na.or.complete"
#   5. Validar resultado (não é NA, NaN, ou Inf)
calcular_cor_segura <- function(x, y, metodo = "pearson") {
  
  # Pré-validação 1: x precisa ter variância
  if (!tem_variancia(x)) {
    return(list(valor = NA, status = "SEM_VARIANCIA_X"))
  }
  
  # Pré-validação 2: y precisa ter variância
  if (!tem_variancia(y)) {
    return(list(valor = NA, status = "SEM_VARIANCIA_Y"))
  }
  
  # Pré-validação 3: precisam de >= 3 pares válidos
  # (cor() precisa de pelo menos 3 observações para ser estável)
  pares_completos <- sum(!is.na(x) & !is.na(y))
  if (pares_completos < 3L) {
    return(list(valor = NA, status = "SEM_PARES"))
  }
  
  # Calcular com tratamento de erros explícito (sem suppressWarnings)
  resultado <- tryCatch(
    {
      cor_valor <- cor(
        x, y,
        method = tolower(metodo),
        use = "na.or.complete"
      )
      
      # Validação pós-cálculo: resultado precisa ser número válido
      if (is.na(cor_valor)) {
        return(list(valor = NA, status = "NA_RESULTADO"))
      }
      if (is.nan(cor_valor)) {
        return(list(valor = NA, status = "NaN_RESULTADO"))
      }
      if (is.infinite(cor_valor)) {
        return(list(valor = NA, status = "INFINITO_RESULTADO"))
      }
      
      # Sucesso: retornar correlação com status OK
      list(valor = cor_valor, status = "OK")
    },
    error = function(e) {
      # Capturar erro inesperado e reportar
      list(valor = NA, status = paste0("ERRO: ", conditionMessage(e)))
    },
    warning = function(w) {
      # Capturar aviso inesperado e reportar
      list(valor = NA, status = paste0("AVISO: ", conditionMessage(w)))
    }
  )
  
  return(resultado)
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

  # ===== Correlacoes com metodo apropriado por tipo de variável =====
  # IMPORTANTE: dados_filtrados já vem de dados_escola_em_numeros.csv (transformado em PASSO 1)
  # Contém colunas _num (ordinais transformadas) e dummies (nominais), sem retransformação
  dados_cor <- dados_filtrados[, colunas_validas, drop = FALSE]
  
  # Calcular correlações com método apropriado e validação robusta
  # Usa: calcular_cor_segura() que valida variância e captura erros
  # Resultado: cada linha inclui Status_Calculo para diagnóstico
  df_cor_lista <- list()
  
  for (var in setdiff(colnames(dados_cor), c(nota_MT, nota_LP))) {
    # PASSO 1: Determinar método baseado no tipo de variável
    # Isto garante análise estatisticamente apropriada
    usar_spearman <- FALSE
    
    # ORDINAIS: reconhecer pelo sufixo _num (adicionado no processamento acima)
    # Exemplo: TX_RESP_Q10a_num (ordem: Nunca < Às vezes < Sempre)
    if (grepl("_num$", var) || var %in% paste0(names(ordinais), "_num")) {
      usar_spearman <- TRUE
    }
    
    # NOMINAIS: reconhecer pelo padrão Q##_* (dummies criadas)
    # Exemplo: Q01_masculino, Q04_Preta (variáveis binárias, 0/1)
    if (var %in% unlist(lapply(nominais_info, function(x) 
        paste0(x$prefix, "_", x$mapping)))) {
      usar_spearman <- TRUE
    }
    
    # CONTÍNUAS: tudo que não é ordinais nem nominais → Pearson
    # Exemplo: INSE_ALUNO, NU_TIPO_NIVEL_INSE (escalas contínuas)
    metodo <- if (usar_spearman) "Spearman" else "Pearson"
    
    # PASSO 2: Converter para numérico (necessário para função cor())
    x_num <- as.numeric(dados_cor[[var]])
    mt_num <- as.numeric(dados_cor[[nota_MT]])
    lp_num <- as.numeric(dados_cor[[nota_LP]])
    
    # PASSO 3: Calcular correlações com validação robusta
    # Cada chamada retorna list(valor=número, status="OK"|...)
    res_MT <- calcular_cor_segura(x_num, mt_num, metodo)
    res_LP <- calcular_cor_segura(x_num, lp_num, metodo)
    
    # PASSO 4: Consolidar status
    # Se ambos OK, status = OK. Senão, relatar o primeiro problema
    status_final <- if (res_MT$status == "OK" && res_LP$status == "OK") {
      "OK"
    } else {
      # Prioridade: Matemática > Português (relatar problema mais importante)
      if (res_MT$status != "OK") res_MT$status else res_LP$status
    }
    
    # PASSO 5: Acumular resultado
    df_cor_lista[[var]] <- data.frame(
      Variavel                 = var,
      Metodo                   = metodo,
      Correlacao_Matematica    = as.numeric(res_MT$valor),
      Correlacao_Portugues     = as.numeric(res_LP$valor),
      Status_Calculo           = status_final,
      stringsAsFactors         = FALSE
    )
  }
  
  # Consolidar todas as correlações calculadas
  df_todas <- do.call(rbind, df_cor_lista)
  rownames(df_todas) <- NULL
  
  # Filtrar por limiar (apenas variáveis com Status = "OK")
  # Isto garante que só usamos correlações válidas na análise final
  # Variáveis com problemas (SEM_VARIANCIA, SEM_PARES, etc) são excluídas
  df_validas <- df_todas[df_todas$Status_Calculo == "OK", , drop = FALSE]
  
  # Aplicar filtro de correlação mínima (limiar_cor = 0.30)
  # Mantém apenas correlações fortes (moderadas ou maiores)
  df_fortes <- df_validas[abs(df_validas$Correlacao_Matematica) >= limiar_cor | 
                          abs(df_validas$Correlacao_Portugues) >= limiar_cor, , drop = FALSE]
  
  # Separar por disciplina para análise específica
  df_fortes_MT <- df_validas[abs(df_validas$Correlacao_Matematica) >= limiar_cor & 
                             df_validas$Variavel != nota_MT, , drop = FALSE]
  df_fortes_LP <- df_validas[abs(df_validas$Correlacao_Portugues) >= limiar_cor & 
                             df_validas$Variavel != nota_LP, , drop = FALSE]
  
  # Preparar dados escalados (apenas variáveis válidas originais)
  dados_escalados <- as.data.frame(scale(dados_filtrados[, colunas_validas, drop = FALSE]))
  
  fortes_MT <- df_fortes_MT$Variavel
  fortes_LP <- df_fortes_LP$Variavel
  
  # Garantir que os dados finais SEMPRE tenham pelo menos a coluna de proficiência
  # Mesmo se não houver variáveis correlacionadas, o arquivo não fica vazio
  colunas_MT <- c(nota_MT, intersect(fortes_MT, colnames(dados_escalados)))
  colunas_LP <- c(nota_LP, intersect(fortes_LP, colnames(dados_escalados)))
  
  dados_finais_MT <- dados_escalados[, colunas_MT, drop = FALSE]
  dados_finais_LP <- dados_escalados[, colunas_LP, drop = FALSE]

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

  salvar(df_motivos,      "variaveis_degeneradas")
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
