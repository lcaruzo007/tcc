################################################################################
# SCRIPT: dendrogramas_artigo.r
#
# OBJETIVO: Gerar somente os dendrogramas para uso em artigo cientifico.
#           Cada arquivo contem o dendrograma, os rotulos das escolas e a
#           legenda de cores, sem painel de estatisticas, dispersao ou tabela.
#
# SAIDA:
#   outputs/<YYYY-MM-DD>/figuras/dendrogramas_artigo/
#     dendrograma_artigo_<tipo>_<HHMMSS>.png
#
# VERSAO: 1.0 - Ago 2026
################################################################################

library(tidyverse)

detectar_raiz <- function() {
  cwd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) return(cwd)
    cwd <- dirname(cwd)
  }
  stop("Nao foi possivel localizar a pasta TESTE.")
}

RAIZ <- detectar_raiz()
DIR_MODULO <- file.path(RAIZ, "TESTE", "3_ANALISE_DE_GRUPOS")
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))
source(file.path(DIR_MODULO, "Scripts", "base_dendrograma_artigo.r"))

VARS_CLUSTER <- c("MEDIA_MT", "MEDIA_LP", "INSE_MEDIO")
N_CLUSTERS <- 2L
N_ESCOLAS_POR_GRUPO <- 20L

PALETAS <- list(
  tipo_escola = c(Publica = "#1B4F9A", Privada = "#A23B72"),
  localizacao = c(Urbana = "#1B4F9A", Rural = "#2CA02C"),
  area = c(Capital = "#1B4F9A", Interior = "#D62728"),
  area_local = c(
    Urbana_Capital = "#1B7837",
    Urbana_Interior = "#66C2A5",
    Rural_Capital = "#B35806",
    Rural_Interior = "#E08214"
  ),
  desempenho = c(ALTO = "#2CA02C", BAIXO = "#D62728")
)

selecionar_extremas <- function(df, n) {
  if (is.null(n) || nrow(df) <= n) return(df)
  df |>
    mutate(.score = (scale(MEDIA_MT)[, 1] + scale(MEDIA_LP)[, 1]) / 2) |>
    arrange(.score) |>
    slice(c(1:ceiling(n / 2), (n() - floor(n / 2) + 1):n())) |>
    select(-.score)
}

gerar_comparativo <- function(metadados, coluna, grupos, paleta, nome, titulo,
                              n_clusters = N_CLUSTERS) {
  dados <- metadados |>
    filter(.data[[coluna]] %in% grupos,
           !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO)) |>
    group_by(.data[[coluna]]) |>
    group_modify(~ selecionar_extremas(.x, N_ESCOLAS_POR_GRUPO)) |>
    ungroup() |>
    mutate(.cor = unname(paleta[as.character(.data[[coluna]])]))

  if (nrow(dados) < 3L || any(is.na(dados$.cor))) {
    stop("Dados insuficientes ou grupo sem cor para: ", nome)
  }

  mat <- dados |>
    select(all_of(VARS_CLUSTER)) |>
    mutate(across(everything(), ~ as.numeric(scale(.)))) |>
    as.matrix()
  rownames(mat) <- sprintf("%d", dados$ID_ESCOLA)
  hc <- hclust(dist(mat, method = "euclidean"), method = "ward.D2")
  altura_corte <- sort(hc$height, decreasing = TRUE)[n_clusters]

  lab_cores <- dados |>
    transmute(label = sprintf("%d", ID_ESCOLA), cor = .cor)
  legenda_df <- tibble(cor = unname(paleta[grupos]), rotulo = grupos)

  p <- painel_dendrograma(
    hc,
    lab_cores = lab_cores,
    y_expand = 0.30,
    titulo = paste0(titulo, " (n = ", nrow(dados), ")"),
    subtitulo = paste0("Variaveis: ", paste(VARS_CLUSTER, collapse = ", "),
                       " | Metodo: Ward.D2 | Corte: ", n_clusters, " clusters"),
    altura_corte = altura_corte,
    annot_texto = paste0("Corte: ", n_clusters, " clusters | altura = ",
                         round(altura_corte, 2)),
    legenda_df = legenda_df
  )

  caminho <- caminho_saida(
    DIR_MODULO,
    "figuras/dendrogramas_artigo",
    paste0("dendrograma_artigo_", nome),
    "png"
  )
  largura <- max(14, nrow(dados) * 0.48)
  ggsave(caminho, p, width = largura, height = 9, units = "in",
         dpi = 300, bg = "#F8F9FA", limitsize = FALSE)
  message("Figura salva: ", caminho)
  invisible(caminho)
}

gerar_geral <- function(metadados) {
  dados <- metadados |>
    mutate(MEDIA_PROFICIENCIA = (MEDIA_MT + MEDIA_LP) / 2) |>
    mutate(CATEGORIA_DESEMPENHO = case_when(
      MEDIA_PROFICIENCIA >= quantile(MEDIA_PROFICIENCIA, 0.75, na.rm = TRUE) ~ "ALTO",
      MEDIA_PROFICIENCIA <= quantile(MEDIA_PROFICIENCIA, 0.25, na.rm = TRUE) ~ "BAIXO",
      TRUE ~ "INTERMEDIARIO"
    )) |>
    filter(CATEGORIA_DESEMPENHO %in% c("ALTO", "BAIXO"),
           between(MEDIA_MT, 150, 500), between(MEDIA_LP, 150, 500),
           !is.na(INSE_MEDIO)) |>
    group_by(CATEGORIA_DESEMPENHO) |>
    group_modify(~ selecionar_extremas(.x, N_ESCOLAS_POR_GRUPO)) |>
    ungroup() |>
    mutate(.cor = unname(PALETAS$desempenho[CATEGORIA_DESEMPENHO]))

  mat <- dados |>
    transmute(MEDIA_MT = as.numeric(scale(MEDIA_MT)),
              MEDIA_LP = as.numeric(scale(MEDIA_LP)),
              INSE_MEDIO = as.numeric(scale(INSE_MEDIO))) |>
    as.matrix()
  rownames(mat) <- sprintf("%d", dados$ID_ESCOLA)
  hc <- hclust(dist(mat, method = "euclidean"), method = "ward.D2")
  altura_corte <- sort(hc$height, decreasing = TRUE)[N_CLUSTERS]

  p <- painel_dendrograma(
    hc,
    lab_cores = dados |>
      transmute(label = sprintf("%d", ID_ESCOLA), cor = .cor),
    y_expand = 0.30,
    titulo = paste0("Dendrograma geral: ALTO e BAIXO desempenho (n = ",
                    nrow(dados), ")"),
    subtitulo = paste0("Variaveis: ", paste(VARS_CLUSTER, collapse = ", "),
                       " | Metodo: Ward.D2 | Corte: ", N_CLUSTERS, " clusters"),
    altura_corte = altura_corte,
    annot_texto = paste0("Corte: ", N_CLUSTERS, " clusters | altura = ",
                         round(altura_corte, 2)),
    legenda_df = tibble(
      cor = unname(PALETAS$desempenho[c("ALTO", "BAIXO")]),
      rotulo = paste0(c("ALTO", "BAIXO"), " (n=", as.integer(table(dados$CATEGORIA_DESEMPENHO)[c("ALTO", "BAIXO")]), ")")
    )
  )
  caminho <- caminho_saida(DIR_MODULO, "figuras/dendrogramas_artigo",
                           "dendrograma_artigo_geral_alto_baixo", "png")
  ggsave(caminho, p, width = max(14, nrow(dados) * 0.48), height = 9,
         units = "in", dpi = 300, bg = "#F8F9FA", limitsize = FALSE)
  message("Figura salva: ", caminho)
}

DIR_PROCESSADOS <- file.path(DIR_MODULO, "outputs", "metadados")
metadados <- carregar_metadados(DIR_PROCESSADOS)

gerar_geral(metadados)
metadados_tipo <- metadados |>
  mutate(TIPO_ESCOLA = case_when(
    str_detect(TIPO_ESCOLA, regex("priv", ignore_case = TRUE)) ~ "Privada",
    TRUE ~ "Publica"
  ))
gerar_comparativo(metadados_tipo, "TIPO_ESCOLA", c("Publica", "Privada"),
                  PALETAS$tipo_escola, "publica_vs_particular", "Publica vs Privada")
gerar_comparativo(metadados, "LOCALIZACAO", c("Urbana", "Rural"),
                  PALETAS$localizacao, "urbana_vs_rural", "Urbana vs Rural")
gerar_comparativo(metadados, "AREA", c("Capital", "Interior"),
                  PALETAS$area, "capital_vs_interior", "Capital vs Interior")
gerar_comparativo(metadados, "AREA_LOCAL", names(PALETAS$area_local),
                  PALETAS$area_local, "area_local", "AREA_LOCAL", n_clusters = 4L)

message("Dendrogramas para artigo concluidos.")