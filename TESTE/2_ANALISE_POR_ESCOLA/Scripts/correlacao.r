################################################################################
# SCRIPT: correlacao.r
# ENTRADA: Dados transformados por escola (layout datado ou legado).
# SAIDA: outputs/<data>/tabelas/<ID_ESCOLA>/*_<hora>.csv e diagnosticos.
# VERSAO: 3.0 - Outubro 2026
################################################################################

library(tidyverse)
library(caret)

detectar_raiz <- function() {
  pasta <- normalizePath(getwd(), winslash = "/")
  while (pasta != dirname(pasta)) {
    if (dir.exists(file.path(pasta, "TESTE"))) return(pasta)
    pasta <- dirname(pasta)
  }
  stop("Pasta TESTE nao encontrada.")
}

RAIZ <- detectar_raiz()
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))
DIR_BASE <- file.path(RAIZ, "TESTE", "2_ANALISE_POR_ESCOLA")
DIR_ENTRADA <- file.path(RAIZ, "TESTE", "1_LIMPEZA_E_TRANSFORMACAO", "outputs")
modo_execucao <- "todas"
limiar_cor <- LIMIAR_COR_PADRAO
metodo_degeneracao <- METODO_DEGENERACAO_PADRAO
ids <- escolas_solicitadas_saeb(listar_escolas_saeb(DIR_ENTRADA))
if (!length(ids)) stop("Nenhuma escola encontrada para correlacao.")
resumos <- list()
erros <- list()

for (id in ids) {
  arquivo <- encontrar_arquivo_escola_saeb(DIR_ENTRADA, id, "dados_escola_em_numeros")
  dados <- data.table::fread(arquivo, showProgress = FALSE) |> as_tibble()
  validar_recorte_saeb(dados)
  dados <- dados |>
    limpar_indicadores_saeb() |>
    transformar_respostas_saeb()
  if (nrow(dados) < 5L) {
    erros[[id]] <- tibble(ID_ESCOLA = id, Motivo = "POUCOS_REGISTROS")
    next
  }
  colunas <- colunas_analiticas_saeb(dados)
  analiticos <- dados[colunas]
  preditores <- setdiff(colunas, c("PROFICIENCIA_MT_SAEB", "PROFICIENCIA_LP_SAEB"))
  motivos <- vapply(analiticos[preditores], function(x) {
    x <- x[is.finite(x)]
    if (!length(x)) return("somente_na")
    if (length(x) < 2L || var(x) == 0) return("variancia_zero")
    "mantida"
  }, character(1))
  mantidos <- names(motivos)[motivos == "mantida"]
  if (metodo_degeneracao %in% c("near_zero", "hibrido") &&
      nrow(dados) >= MIN_LINHAS_NEAR_ZERO && length(mantidos)) {
    nzv <- caret::nearZeroVar(analiticos[mantidos], freqCut = FREQ_CUT_NZV,
                             uniqueCut = UNIQUE_CUT_NZV, names = TRUE)
    motivos[nzv] <- "near_zero_var"
    mantidos <- setdiff(mantidos, nzv)
  }
  if (!length(mantidos)) {
    erros[[id]] <- tibble(ID_ESCOLA = id, Motivo = "SEM_PREDITORES_COM_VARIACAO")
    next
  }
  correlacoes <- map_dfr(mantidos, function(variavel) {
    metodo <- if (grepl("_num$|^Q01_|^Q04_", variavel) ||
                   variavel == "NU_TIPO_NIVEL_INSE") "Spearman" else "Pearson"
    mt <- correlacao_segura_saeb(dados[[variavel]], dados$PROFICIENCIA_MT_SAEB, metodo)
    lp <- correlacao_segura_saeb(dados[[variavel]], dados$PROFICIENCIA_LP_SAEB, metodo)
    tibble(Variavel = variavel, Metodo = metodo,
           Correlacao_Matematica = mt$valor, Correlacao_Portugues = lp$valor,
           Status_MT = mt$status, Status_LP = lp$status,
           N_Pares_MT = mt$n, N_Pares_LP = lp$n,
           Status_Calculo = if_else(mt$status == "OK" & lp$status == "OK", "OK", "PARCIAL"))
  })
  fortes_mt <- correlacoes |>
    filter(Status_MT == "OK", abs(Correlacao_Matematica) >= limiar_cor)
  fortes_lp <- correlacoes |>
    filter(Status_LP == "OK", abs(Correlacao_Portugues) >= limiar_cor)
  escalar <- function(x) {
    if (sum(is.finite(x)) < 2L || var(x, na.rm = TRUE) == 0) return(rep(NA_real_, length(x)))
    as.numeric(scale(x))
  }
  escalados <- analiticos |>
    mutate(across(everything(), escalar))
  salvar <- function(df, nome) {
    data.table::fwrite(df, caminho_saida(DIR_BASE, file.path("tabelas", id), nome, "csv"), na = "NA")
  }
  salvar(tibble(Variavel = names(motivos), Motivo = unname(motivos)) |>
           filter(Motivo != "mantida"), "variaveis_degeneradas")
  salvar(tibble(metrica = c("n_linhas", "n_colunas_entrada", "n_colunas_validas", "n_degeneradas"),
                valor = c(nrow(dados), length(colunas), length(mantidos), sum(motivos != "mantida"))),
         "diagnostico_degeneracao")
  salvar(escalados[c("PROFICIENCIA_MT_SAEB", fortes_mt$Variavel)], "dados_FINAL_MT_Filtrado")
  salvar(escalados[c("PROFICIENCIA_LP_SAEB", fortes_lp$Variavel)], "dados_FINAL_LP_Filtrado")
  salvar(correlacoes, "todas_correlacoes_calculadas")
  salvar(fortes_mt, "correlacoes_mantidas_MT")
  salvar(fortes_lp, "correlacoes_mantidas_LP")
  resumos[[id]] <- tibble(ID_ESCOLA = id, n_alunos = nrow(dados),
                         n_variaveis_total = length(colunas), n_validas = length(mantidos),
                         n_degeneradas = sum(motivos != "mantida"),
                         n_cor_MT = nrow(fortes_mt), n_cor_LP = nrow(fortes_lp))
}
write_csv(bind_rows(resumos), caminho_saida(DIR_BASE, "diagnosticos", "resumo_processamento", "csv"))
if (length(erros)) {
  write_csv(bind_rows(erros), caminho_saida(DIR_BASE, "diagnosticos", "escolas_nao_processadas", "csv"))
}
if (!length(resumos)) stop("Nenhuma escola produziu correlacoes.")
message("Correlacoes: ", length(resumos), " escolas; ", length(erros), " escolas sem analise.")
