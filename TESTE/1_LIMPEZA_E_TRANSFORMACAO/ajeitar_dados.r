################################################################################
# SCRIPT: ajeitar_dados.r
# ENTRADA: TS_ALUNO_34EM.csv, recorte SAEB 2023, MG, series 12/13.
# SAIDA: outputs/<data>/{tabelas,diagnosticos}/<ID_ESCOLA>/*_<hora>.csv
# VERSAO: 3.0 - Outubro 2026
################################################################################

library(tidyverse)

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
DIR_BASE <- file.path(RAIZ, "TESTE", "1_LIMPEZA_E_TRANSFORMACAO")
arquivo <- file.path(RAIZ, "MICRODADOS_SAEB_2023", "DADOS", "TS_ALUNO_34EM.csv")
brutos <- ler_microdados_saeb(arquivo)
dados <- transformar_respostas_saeb(brutos)
itens <- intersect(names(DICT_ROTULOS_SAEB), names(brutos))
linhas_escolas <- split(seq_len(nrow(dados)), dados$ID_ESCOLA)
ids <- escolas_solicitadas_saeb(names(linhas_escolas))
if (!length(ids)) stop("Nenhuma escola selecionada.")

for (id in ids) {
  indices <- linhas_escolas[[id]]
  escola <- dados[indices, ]
  originais <- lapply(brutos[indices, itens], function(x) trimws(as.character(x)))
  ausentes <- vapply(originais, function(x) sum(is.na(x) | x == ""), integer(1))
  n_na <- colSums(is.na(escola[itens]))
  nao_informados <- vapply(itens, function(item) {
    rotulos <- DICT_ROTULOS_SAEB[[item]]
    codigos <- names(rotulos)[grepl("Nao sei|Nao quero declarar", rotulos)]
    sum(originais[[item]] %in% codigos)
  }, integer(1))
  relatorio <- tibble(
    Variavel = itens, N_Total = length(indices),
    N_Ausente_Original = unname(ausentes), N_Invalido = unname(n_na - ausentes),
    N_Nao_Informado = unname(nao_informados), N_NA = unname(n_na),
    Pct_NA = 100 * unname(n_na) / length(indices)
  ) |>
    arrange(desc(Pct_NA))
  data.table::fwrite(escola, caminho_saida(DIR_BASE, file.path("tabelas", id),
                                          "dados_escola_em_numeros", "csv"), na = "NA")
  data.table::fwrite(relatorio, caminho_saida(DIR_BASE, file.path("diagnosticos", id),
                                             "resumo_missings", "csv"), na = "NA")
}
message("Limpeza concluida: ", length(ids), " escolas. Dados e ausencias preservados por execucao.")
