# =========================================================================
# PASSO 3: RANKING DE ESCOLAS POR QUALIDADE DAS CORRELACOES
# Consolida os resultados do PASSO 2 (uma pasta por escola) e ordena
# as escolas pela forca das correlacoes encontradas, sem precisar
# abrir pasta por pasta manualmente.
# =========================================================================

library(tidyverse)

# -------------------------------------------------------------------------
# Reaproveita a mesma deteccao de caminhos do PASSO 2
# -------------------------------------------------------------------------

detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message(" Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  message("  Nao consegui encontrar a pasta 'TESTE' automaticamente.")
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC (onde esta a pasta TESTE)")
    if (is.na(raiz) || raiz == "") stop("Caminho nao selecionado. Encerrando.")
    return(raiz)
  } else {
    stop("Script nao pode rodar em modo nao-interativo sem encontrar o caminho.")
  }
}

RAIZ            <- detectar_raiz()
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))
DIR_TESTE       <- file.path(RAIZ, "TESTE")
DIR_ANALISE_2   <- file.path(DIR_TESTE, "2_ANALISE_POR_ESCOLA")
DIR_SAIDA_RAIZ  <- file.path(DIR_ANALISE_2, "outputs")   # onde o PASSO 2 gravou os resultados

if (!dir.exists(DIR_SAIDA_RAIZ)) {
  stop("Diretorio de saida do PASSO 2 nao encontrado: ", DIR_SAIDA_RAIZ)
}

# -------------------------------------------------------------------------
# Localizar pastas de escola ja processadas pelo PASSO 2
# (cada pasta tem correlacoes_mantidas_MT.csv e correlacoes_mantidas_LP.csv)
# -------------------------------------------------------------------------

pastas_escola <- file.path(DIR_SAIDA_RAIZ, listar_escolas_saeb(DIR_SAIDA_RAIZ))
pastas_escola <- pastas_escola[basename(pastas_escola) != ""]

if (length(pastas_escola) == 0L) {
  stop("Nenhuma pasta de escola encontrada em: ", DIR_SAIDA_RAIZ,
       "\nRode o PASSO 2 antes deste script.")
}

message("Escolas encontradas: ", length(pastas_escola))

# ===== Funcao auxiliar: encontra o arquivo mais recente com um prefixo =====
# (mesma logica usada no PASSO 2, para o caso de haver versoes com timestamp)
encontrar_arquivo <- function(pasta, prefixo) {
  encontrar_arquivo_escola_saeb(DIR_SAIDA_RAIZ, basename(pasta), prefixo)
}

# -------------------------------------------------------------------------
# Calcular metricas de qualidade das correlacoes por escola
# -------------------------------------------------------------------------
#
# Metricas usadas para o ranking (uma escola "melhor" tem):
#   - maior numero de correlacoes fortes (n_cor_MT + n_cor_LP)
#   - maior correlacao maxima em modulo (melhor_correlacao_abs)
#   - maior media das correlacoes em modulo (media_correlacao_abs)
#
# Assim, da pra escolher o criterio de "melhor" que fizer mais sentido
# para o TCC (mais variaveis correlacionadas vs. correlacoes mais fortes).

calcular_metricas_escola <- function(pasta_escola) {
  id_escola <- basename(pasta_escola)

  arq_mt <- encontrar_arquivo(pasta_escola, "correlacoes_mantidas_MT")
  arq_lp <- encontrar_arquivo(pasta_escola, "correlacoes_mantidas_LP")

  cor_mt <- if (!is.null(arq_mt)) read.csv(arq_mt, stringsAsFactors = FALSE) else
              data.frame(Correlacao_Matematica = numeric(0))
  cor_lp <- if (!is.null(arq_lp)) read.csv(arq_lp, stringsAsFactors = FALSE) else
              data.frame(Correlacao_Portugues = numeric(0))

  vals_mt <- abs(cor_mt$Correlacao_Matematica)
  vals_lp <- abs(cor_lp$Correlacao_Portugues)
  todos_vals <- c(vals_mt, vals_lp)

  # tentar pegar n_alunos do diagnostico, se existir
  arq_diag <- encontrar_arquivo(pasta_escola, "diagnostico_degeneracao")
  n_alunos <- NA_integer_
  if (!is.null(arq_diag)) {
    diag <- read.csv(arq_diag, stringsAsFactors = FALSE)
    linha_n <- diag[diag$metrica == "n_linhas", "valor"]
    if (length(linha_n) == 1L) n_alunos <- suppressWarnings(as.integer(linha_n))
  }

  data.frame(
    ID_ESCOLA               = id_escola,
    n_alunos                = n_alunos,
    n_cor_MT                = nrow(cor_mt),
    n_cor_LP                = nrow(cor_lp),
    n_cor_total              = nrow(cor_mt) + nrow(cor_lp),
    melhor_correlacao_abs    = if (length(todos_vals) > 0) max(todos_vals, na.rm = TRUE) else NA_real_,
    media_correlacao_abs     = if (length(todos_vals) > 0) mean(todos_vals, na.rm = TRUE) else NA_real_,
    stringsAsFactors = FALSE
  )
}

# -------------------------------------------------------------------------
# Rodar para todas as escolas e montar o ranking
# -------------------------------------------------------------------------

lista_metricas <- lapply(sort(pastas_escola), calcular_metricas_escola)
df_ranking <- do.call(rbind, lista_metricas)
rownames(df_ranking) <- NULL

# Ordena por criterio composto:
#   1 maior numero de correlacoes fortes
#   2 (empate) maior correlacao mais forte encontrada
#   3 (empate) maior media das correlacoes
df_ranking <- df_ranking %>%
  arrange(desc(n_cor_total), desc(melhor_correlacao_abs), desc(media_correlacao_abs))

df_ranking$posicao <- seq_len(nrow(df_ranking))
df_ranking <- df_ranking %>% relocate(posicao, .before = ID_ESCOLA)

# -------------------------------------------------------------------------
# Salvar e exibir o resultado
# -------------------------------------------------------------------------

caminho_ranking <- caminho_saida(DIR_ANALISE_2, "tabelas", "ranking_escolas_correlacoes", "csv")
write.csv(df_ranking, caminho_ranking, row.names = FALSE)

message("\nRanking salvo em: ", caminho_ranking)
message("\n===== TOP 5 ESCOLAS COM MELHORES CORRELACOES =====")
print(head(df_ranking, 5), row.names = FALSE)

melhor_escola <- df_ranking$ID_ESCOLA[1]
message("\n>>> Escola com melhores correlacoes no geral: ", melhor_escola, " <<<")
message("    (", df_ranking$n_cor_total[1], " correlacoes fortes | ",
        "correlacao maxima = ", round(df_ranking$melhor_correlacao_abs[1], 3), " | ",
        "media = ", round(df_ranking$media_correlacao_abs[1], 3), ")")