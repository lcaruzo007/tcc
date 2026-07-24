################################################################################
# SCRIPT: dendrograma_area_local.r
#
# OBJETIVO: Clustering hierarquico comparando as 4 categorias de AREA_LOCAL
#           (Urbana_Capital, Urbana_Interior, Rural_Capital, Rural_Interior).
#           Responde: o algoritmo separa naturalmente as 4 combinacoes de
#           area x localizacao? Substitui a analise separada de
#           Capital-vs-Interior e Urbana-vs-Rural pela variavel combinada
#           que o restante do projeto ja usa (comparar_grupos.r - COMPARACAO 5,
#           e modelo de regressao linear multipla).
#
# VARIAVEL: AREA_LOCAL (combinacao de LOCALIZACAO + "_" + AREA, criada em
#           classificar_escolas.r)
#
# SAIDA:
#   outputs/figuras/area_local/
#     dendrograma_area_local_<ts>.png
#     tabela_area_local_<ts>.csv
#
# VERSAO: 1.0 — Jul 2026
################################################################################

# Carrega funcoes compartilhadas (ajuste o caminho se necessario)
get_script_dir <- function() {
  # Metodo 1: RStudio (funciona quando ha um editor de codigo aberto)
  path <- tryCatch(
    rstudioapi::getSourceEditorContext()$path,
    error = function(e) NULL
  )
  if (!is.null(path) && nzchar(path)) {
    return(dirname(normalizePath(path)))
  }

  # Metodo 2: quando o script foi chamado via source()
  path <- tryCatch(
    normalizePath(sys.frame(1)$ofile),
    error = function(e) NULL
  )
  if (!is.null(path) && nzchar(path)) {
    return(dirname(path))
  }

  # Metodo 3: execucao via linha de comando (Rscript arquivo.r)
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0L) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
  }

  # Metodo 4 (ultimo recurso): os 3 metodos acima falham quando o script e
  # executado linha a linha / trecho selecionado fora do RStudio, ou em IDEs
  # que nao implementam rstudioapi. Nesses casos getwd() pode nao ser a pasta
  # do script - por isso procuramos base_dendrograma.r a partir do diretorio
  # de trabalho atual (e, se preciso, subindo na arvore de pastas).
  cwd <- getwd()
  repeat {
    achado <- list.files(cwd, pattern = "^base_dendrograma\\.r$",
                          recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
    if (length(achado) > 0L) {
      return(dirname(achado[1]))
    }
    pai <- dirname(cwd)
    if (pai == cwd) break
    cwd <- pai
  }

  stop(
    "Nao foi possivel localizar 'base_dendrograma.r' automaticamente.\n",
    "Solucao definitiva: defina o caminho manualmente substituindo a linha\n",
    "'source(file.path(get_script_dir(), \"base_dendrograma.r\"))' por, por exemplo:\n",
    "  source(\"C:/Users/13756596699/tcc/TESTE/3_ANALISE_DE_GRUPOS/Scripts/base_dendrograma.r\")"
  )
}
source(file.path(get_script_dir(), "base_dendrograma.r"))

# =============================================================================
# CONFIGURACAO
# =============================================================================

RAIZ            <- detectar_raiz()
DIR_PROCESSADOS <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs/metadados")
DIR_SAIDA       <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs/figuras/area_local")

VARS_CLUSTER <- c("MEDIA_MT", "MEDIA_LP", "INSE_MEDIO")
N_CLUSTERS   <- 4L    # um cluster-alvo por categoria de AREA_LOCAL

# NULL = usa todas; numero = seleciona as mais extremas de cada categoria
# Com 4 grupos, um numero baixo mantem o dendrograma legivel
N_ESCOLAS_POR_GRUPO <- 15

# Mesma paleta usada em comparar_grupos.r (COMPARACAO 5 / boxplot AREA_LOCAL)
# para manter a identidade visual consistente entre os graficos do projeto
PALETA_AREA_LOCAL <- c(
  "Urbana_Capital"  = "#1B7837",
  "Urbana_Interior" = "#66C2A5",
  "Rural_Capital"   = "#B35806",
  "Rural_Interior"  = "#E08214"
)

# =============================================================================
# EXECUCAO
# =============================================================================

ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
message(strrep("=", 70))
message("DENDROGRAMA: AREA_LOCAL (Urbana_Capital / Urbana_Interior / Rural_Capital / Rural_Interior)")
message(strrep("=", 70))

metadados <- carregar_metadados(DIR_PROCESSADOS)

if (!"AREA_LOCAL" %in% names(metadados)) {
  stop("Coluna 'AREA_LOCAL' nao encontrada nos metadados.\n",
       "Execute classificar_escolas.r (versao atual) primeiro.\n",
       "Colunas disponiveis: ", paste(names(metadados), collapse = ", "))
}

message("\nDistribuicao por AREA_LOCAL:")
metadados |> count(AREA_LOCAL) |> print()

# — Filtrar dados validos —
dados_validos <- metadados |>
  filter(!is.na(AREA_LOCAL),
         !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))

message("\nEscolas validas por categoria:")
dados_validos |> count(AREA_LOCAL) |> print()

# — Selecao de representativas por categoria (mesma logica dos outros 3 scripts) —
selecionar_extremas <- function(df, n) {
  if (is.null(n) || nrow(df) <= n) return(df)
  df |>
    mutate(SCORE = (scale(MEDIA_MT)[,1] + scale(MEDIA_LP)[,1]) / 2) |>
    arrange(SCORE) |>
    slice(c(1:ceiling(n/2), (n() - floor(n/2) + 1):n())) |>
    select(-SCORE)
}

dados_cluster <- dados_validos |>
  group_by(AREA_LOCAL) |>
  group_modify(~ selecionar_extremas(.x, N_ESCOLAS_POR_GRUPO)) |>
  ungroup() |>
  mutate(cor_grupo = PALETA_AREA_LOCAL[AREA_LOCAL])

message("\nEscolas no dendrograma por categoria:")
dados_cluster |> count(AREA_LOCAL) |> print()

# — Clustering —
mat <- dados_cluster |>
  select(all_of(VARS_CLUSTER)) |>
  mutate(across(everything(), ~ as.numeric(scale(.)))) |>
  as.matrix()

rownames(mat) <- sprintf("%d", dados_cluster$ID_ESCOLA)

dist_mat <- dist(mat, method = "euclidean")
hc       <- hclust(dist_mat, method = "ward.D2")

dados_cluster <- dados_cluster |>
  mutate(CLUSTER = as.character(cutree(hc, k = N_CLUSTERS)))

# Avaliar pureza dos clusters (quanto % de cada categoria caiu em cada cluster)
pureza <- dados_cluster |>
  count(CLUSTER, AREA_LOCAL) |>
  group_by(CLUSTER) |>
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  ungroup()

message("\nPureza dos clusters (quanto o algoritmo separou as 4 categorias):")
print(pureza, n = Inf, width = Inf)

altura_corte <- sort(hc$height, decreasing = TRUE)[N_CLUSTERS]

# — Painel 1: Dendrograma —
lab_cores <- dados_cluster |>
  transmute(label = sprintf("%d", ID_ESCOLA), cor = cor_grupo)

legenda_df <- tibble(
  cor    = unname(PALETA_AREA_LOCAL),
  rotulo = names(PALETA_AREA_LOCAL)
)

p_dend <- painel_dendrograma(
  hc,
  lab_cores    = lab_cores,
  y_expand     = 0.20,
  titulo       = paste0("Clustering: AREA_LOCAL  (n = ", nrow(dados_cluster), ")"),
  subtitulo    = paste0("Variaveis: ", paste(VARS_CLUSTER, collapse = ", "),
                        "  |  Metodo: Ward.D2  |  Corte: ", N_CLUSTERS, " clusters"),
  altura_corte = altura_corte,
  annot_texto  = paste0("Corte: ", N_CLUSTERS, " clusters  |  altura = ",
                        round(altura_corte, 2)),
  legenda_df   = legenda_df
)

# — Painel 2: Estatisticas —
resumo_grupos <- dados_cluster |>
  group_by(GRUPO = AREA_LOCAL) |>
  summarise(
    N          = n(),
    MT_medio   = round(mean(MEDIA_MT),   1),
    MT_dp      = round(sd(MEDIA_MT),     1),
    LP_medio   = round(mean(MEDIA_LP),   1),
    LP_dp      = round(sd(MEDIA_LP),     1),
    INSE_medio = round(mean(INSE_MEDIO), 2),
    INSE_dp    = round(sd(INSE_MEDIO),   2),
    .groups    = "drop"
  ) |>
  mutate(cor_grupo = PALETA_AREA_LOCAL[GRUPO])

p_stats <- painel_estatisticas(
  resumo_grupos,
  titulo = "Estatisticas por AREA_LOCAL"
)

# — Painel 3: Scatter —
p_scatter <- painel_scatter(
  dados_cluster,
  var_forma  = "TIPO_ESCOLA",
  titulo     = "Validacao: MT x LP  (AREA_LOCAL)",
  subtitulo  = "Cor = AREA_LOCAL  |  Forma = Tipo de escola  |  Tamanho = INSE"
)

# — Composicao —
n_por_grupo <- dados_cluster |> count(AREA_LOCAL) |> deframe()
caption <- paste0(
  "AREA_LOCAL: ",
  paste(names(n_por_grupo), " (n=", n_por_grupo, ")", sep = "", collapse = "  |  "),
  "\nClustering hierarquico — distancia euclidiana, metodo Ward.D2",
  "  |  Gerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M")
)

nome_fig <- paste0("dendrograma_area_local_", ts, ".png")

salvar_figura_completa(
  p_dend       = p_dend,
  p_stats      = p_stats,
  p_scatter    = p_scatter,
  dir_saida    = DIR_SAIDA,
  nome_arquivo = nome_fig,
  caption_txt  = caption
)

# — Tabela —
tabela <- dados_cluster |>
  arrange(CLUSTER, AREA_LOCAL, desc(MEDIA_MT)) |>
  select(ID_ESCOLA, AREA_LOCAL, AREA, LOCALIZACAO, TIPO_ESCOLA, CLUSTER,
         MEDIA_MT, MEDIA_LP, INSE_MEDIO,
         FAIXA_MT, FAIXA_LP, GRUPO_INSE) |>
  mutate(across(c(MEDIA_MT, MEDIA_LP, INSE_MEDIO), ~ round(., 2)))

write_csv(tabela,
          file.path(DIR_SAIDA, paste0("tabela_area_local_", ts, ".csv")))

message("\nResumo por cluster:")
tabela |>
  group_by(CLUSTER, AREA_LOCAL) |>
  summarise(N = n(), MT = round(mean(MEDIA_MT), 1),
            LP = round(mean(MEDIA_LP), 1),
            INSE = round(mean(INSE_MEDIO), 2), .groups = "drop") |>
  arrange(CLUSTER) |>
  print(width = Inf)

message("\n", strrep("=", 70))
message("CONCLUIDO. Saida: ", DIR_SAIDA)
message(strrep("=", 70))
