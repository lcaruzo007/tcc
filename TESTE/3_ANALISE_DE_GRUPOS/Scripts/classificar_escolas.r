################################################################################
# SCRIPT: classificar_escolas.r
# ENTRADA: TS_ALUNO_34EM.csv, recorte SAEB 2023, MG, series 12/13.
# SAIDA: outputs/<data>/metadados/metadados_escolas_<hora>.csv
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
DIR_ANALISE <- file.path(RAIZ, "TESTE", "3_ANALISE_DE_GRUPOS")
alunos <- ler_microdados_saeb(file.path(
  RAIZ, "MICRODADOS_SAEB_2023", "DADOS", "TS_ALUNO_34EM.csv"
))
metadados <- agregar_escolas_saeb(alunos, pareadas = FALSE) |>
  mutate(
    FAIXA_MT = classificar_quantis_saeb(MEDIA_MT, c(0.25, 0.5, 0.75),
      c("Q1_Baixo", "Q2_Medio-Baixo", "Q3_Medio-Alto", "Q4_Alto")),
    FAIXA_LP = classificar_quantis_saeb(MEDIA_LP, c(0.25, 0.5, 0.75),
      c("Q1_Baixo", "Q2_Medio-Baixo", "Q3_Medio-Alto", "Q4_Alto")),
    GRUPO_INSE = classificar_quantis_saeb(INSE_MEDIO, c(0.33, 0.67),
      c("Baixo_INSE", "Medio_INSE", "Alto_INSE"))
  ) |>
  arrange(desc(MEDIA_MT))
validar_metadados_saeb(metadados)
arquivo <- caminho_saida(DIR_ANALISE, "metadados", "metadados_escolas", "csv")
write_csv(metadados, arquivo)
write_csv(
  metadados |>
    select(ID_ESCOLA, N_ALUNOS, N_ALUNOS_MT_VALIDOS, N_ALUNOS_LP_VALIDOS,
           N_ALUNOS_PAREADOS, N_ALUNOS_INSE, MEDIAS_PAREADAS),
  caminho_saida(DIR_ANALISE, "diagnosticos", "denominadores_escolas", "csv")
)
message("Metadados: ", nrow(metadados), " escolas. Arquivo: ", arquivo)
