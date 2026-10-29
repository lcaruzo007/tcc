################################################################################
# SCRIPT: testar_contratos.r
# ENTRADA: Casos sinteticos; nao depende de microdados locais.
# SAIDA: Verificacoes de regressao dos contratos analiticos.
# VERSAO: 1.0 - Outubro 2026
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
source(file.path(detectar_raiz(), "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

esperar_erro <- function(expr) {
  stopifnot(inherits(tryCatch({
    force(expr)
    NULL
  }, error = identity), "error"))
}

teste <- function() {
  dados <- tibble(
    ID_SAEB = 2023L, ID_UF = 31L, ID_SERIE = 12L,
    ID_ALUNO = seq_len(6), ID_MUNICIPIO = 1L,
    ID_ESCOLA = c(rep(1L, 5), 2L), IN_PUBLICA = 1L,
    ID_AREA = 1L, ID_LOCALIZACAO = 1L,
    IN_PROFICIENCIA_MT = c(1, 1, 0, 1, 1, 0),
    IN_PROFICIENCIA_LP = c(1, 0, 1, 1, 1, 0),
    PROFICIENCIA_MT_SAEB = c(200, 250, 999, 1000, 350, 999),
    PROFICIENCIA_LP_SAEB = c(210, 999, 230, 240, 310, 999),
    IN_INSE = c(1, 1, 1, 0, 1, 0), INSE_ALUNO = c(1, 2, 3, 999, 4, 999),
    NU_TIPO_NIVEL_INSE = 2L
  )
  validar_recorte_saeb(dados)
  esperar_erro(validar_recorte_saeb(mutate(dados, ID_UF = 35L)))
  esperar_erro(validar_recorte_saeb(select(dados, -ID_SERIE)))
  limpos <- limpar_indicadores_saeb(dados)
  stopifnot(is.na(limpos$PROFICIENCIA_MT_SAEB[3]), is.na(limpos$PROFICIENCIA_MT_SAEB[4]),
            is.na(limpos$INSE_ALUNO[4]))
  independente <- agregar_escolas_saeb(dados)
  pareada <- agregar_escolas_saeb(dados, pareadas = TRUE)
  stopifnot(independente$N_ALUNOS_MT_VALIDOS[1] == 3L,
            independente$N_ALUNOS_LP_VALIDOS[1] == 4L,
            pareada$N_ALUNOS_PAREADOS[1] == 2L,
            abs(independente$MEDIA_MT[1] - 800 / 3) < 1e-10,
            pareada$MEDIA_MT[1] == 275, is.na(independente$MEDIA_MT[2]),
            !is.nan(independente$MEDIA_MT[2]))
  faixas <- classificar_quantis_saeb(c(NA, NaN, 1, 2), 0.5, c("baixo", "alto"))
  stopifnot(all(is.na(faixas[1:2])), is.na(classificar_quantis_saeb(NA_real_, .5, c("b", "a"))))
  meta <- independente |>
    mutate(FAIXA_MT = classificar_quantis_saeb(MEDIA_MT, .5, c("baixo", "alto")),
           FAIXA_LP = classificar_quantis_saeb(MEDIA_LP, .5, c("baixo", "alto")),
           GRUPO_INSE = classificar_quantis_saeb(INSE_MEDIO, .5, c("baixo", "alto")))
  validar_metadados_saeb(meta)
  meta$FAIXA_MT[2] <- "Q4_Alto"
  esperar_erro(validar_metadados_saeb(meta))
  stopifnot(identical(limpar_resposta_saeb(c("F", ".", "*", "X", " A "), "TX_RESP_Q02"),
                      c("F", NA_character_, NA_character_, NA_character_, "A")))
  for (item in names(DICT_ROTULOS_SAEB)) limpos[[item]] <- "A"
  transformados <- transformar_respostas_saeb(limpos)
  analiticas <- colunas_analiticas_saeb(transformados)
  stopifnot(all(c("Q01_masculino", "Q04_Nao_declarada", "INSE_ALUNO",
                  "NU_TIPO_NIVEL_INSE", "TX_RESP_Q10a_num") %in% analiticas),
            !"TX_RESP_Q10a" %in% analiticas)
  exemplo <- tibble(AREA_LOCAL = c("Urbana_Capital", "Rural_Interior", "Urbana_Interior"))
  contraste <- preparar_contraste_area_saeb(exemplo, "Rural_Interior")
  stopifnot(nrow(contraste) == 2L, !"Urbana_Interior" %in% contraste$AREA_LOCAL)
  esperar_erro(preparar_contraste_area_saeb(exemplo, "Rural_Capital"))
  stopifnot(correlacao_segura_saeb(c(1, 2, 3, NA), c(3, 2, 1, 10), "Pearson")$valor == -1,
            correlacao_segura_saeb(c(1, 1, 2), c(2, 3, NA), "Pearson")$status == "SEM_PARES")
  pasta <- tempfile("saeb_contratos_")
  dir.create(file.path(pasta, "outputs", "2026-01-01", "tabelas"), recursive = TRUE)
  cwd_teste <- getwd()
  dispositivo <- grDevices::dev.cur()
  tryCatch({
    setwd(pasta)
    arvore <- hclust(dist(matrix(seq_len(12), ncol = 3)))
    desenho <- dados_dendrograma_saeb(arvore)
    stopifnot(nrow(desenho$segments) > 0L, grDevices::dev.cur() == dispositivo,
              !file.exists("Rplots.pdf"))
  }, finally = setwd(cwd_teste))
  datado <- file.path(pasta, "outputs", "2026-01-01", "tabelas", "base_010101.csv")
  legado <- file.path(pasta, "outputs", "base.csv")
  writeLines("x", datado)
  writeLines("x", legado)
  Sys.setFileTime(legado, Sys.time() + 3600)
  stopifnot(normalizePath(encontrar_arquivo_mais_recente(file.path(pasta, "outputs"), "base", "tabelas")) == normalizePath(datado))
  copia9 <- file.path(dirname(datado), "base_010101_9.csv")
  copia10 <- file.path(dirname(datado), "base_010101_10.csv")
  writeLines("x", copia9)
  writeLines("x", copia10)
  stopifnot(normalizePath(encontrar_arquivo_mais_recente(file.path(pasta, "outputs"), "base", "tabelas")) == normalizePath(copia10))
  escolar <- file.path(dirname(datado), "123", "dados_escola_em_numeros_010101.csv")
  dir.create(dirname(escolar))
  writeLines("x", escolar)
  stopifnot("123" %in% listar_escolas_saeb(file.path(pasta, "outputs")),
            normalizePath(encontrar_arquivo_escola_saeb(file.path(pasta, "outputs"), "123", "dados_escola_em_numeros")) == normalizePath(escolar))
  a <- caminho_saida(pasta, "tabelas", "colisao", "csv")
  writeLines("x", a)
  b <- caminho_saida(pasta, "tabelas", "colisao", "csv")
  stopifnot(a != b, file.exists(a))
  antigo <- Sys.getenv(c("SAEB_REGISTRO", "SAEB_ENTRADAS", "SAEB_LEITURA_ESTRITA"), unset = NA_character_)
  on.exit({
    for (nome in names(antigo)) {
      if (is.na(antigo[[nome]])) Sys.unsetenv(nome) else do.call(Sys.setenv, setNames(list(antigo[[nome]]), nome))
    }
    options(saeb.artefatos_cache = NULL)
    unlink(pasta, recursive = TRUE)
  }, add = TRUE)
  Sys.setenv(SAEB_REGISTRO = file.path(pasta, "registro.csv"), SAEB_ENTRADAS = "", SAEB_LEITURA_ESTRITA = "1")
  esperar_erro(encontrar_arquivo_mais_recente(file.path(pasta, "outputs"), "base", "tabelas"))
  registrar_artefato_saeb(datado, pasta, "base", "tabelas")
  stopifnot(normalizePath(encontrar_arquivo_mais_recente(file.path(pasta, "outputs"), "base", "tabelas")) == normalizePath(datado))
  message("OK Contratos sinteticos: recorte, validade, medias, ausentes, itens, contrastes e rastreabilidade.")
}
teste()
