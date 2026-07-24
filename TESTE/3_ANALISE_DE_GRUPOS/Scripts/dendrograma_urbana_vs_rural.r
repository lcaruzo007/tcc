################################################################################
# SCRIPT: dendrograma_urbana_vs_rural.r
#
# OBJETIVO: Clustering hierarquico comparando escolas URBANAS vs RURAIS
#           Responde: o algoritmo consegue separar naturalmente as duas localizacoes?
#
# VARIAVEL: LOCALIZACAO (valores esperados: "Urbana" e "Rural")
#
# SAIDA:
#   outputs_figuras/urbana_vs_rural/
#     dendrograma_urbana_vs_rural_<ts>.png
#     tabela_urbana_vs_rural_<ts>.csv
#
# VERSAO: 1.0 — Mai 2026
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
DIR_SAIDA       <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs/figuras/urbana_vs_rural")

VARS_CLUSTER <- c("MEDIA_MT", "MEDIA_LP", "INSE_MEDIO")
N_CLUSTERS   <- 2

# NULL = usa todas; numero = seleciona as mais extremas de cada grupo
N_ESCOLAS_POR_GRUPO <- 20

COR_URBANA <- "#1B4F9A"   # azul
COR_RURAL  <- "#2CA02C"   # verde

# =============================================================================
# EXECUCAO
# =============================================================================

ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
message(strrep("=", 70))
message("DENDROGRAMA: Urbana vs Rural")
message(strrep("=", 70))

metadados <- carregar_metadados(DIR_PROCESSADOS)

if (!"LOCALIZACAO" %in% names(metadados)) {
  stop("Coluna 'LOCALIZACAO' nao encontrada nos metadados.\n",
       "Colunas disponiveis: ", paste(names(metadados), collapse = ", "))
}

message("\nDistribuicao por LOCALIZACAO:")
metadados |> count(LOCALIZACAO) |> print()

dados_urbana <- metadados |>
  filter(LOCALIZACAO == "Urbana", !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))
dados_rural  <- metadados |>
  filter(LOCALIZACAO == "Rural",  !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))

message("\nEscolas validas  —  Urbana: ", nrow(dados_urbana),
        "  |  Rural: ", nrow(dados_rural))

selecionar_extremas <- function(df, n) {
  if (is.null(n) || nrow(df) <= n) return(df)
  df |>
    mutate(SCORE = (scale(MEDIA_MT)[,1] + scale(MEDIA_LP)[,1]) / 2) |>
    arrange(SCORE) |>
    slice(c(1:ceiling(n/2), (n() - floor(n/2) + 1):n())) |>
    select(-SCORE)
}

dados_urbana <- selecionar_extremas(dados_urbana, N_ESCOLAS_POR_GRUPO)
dados_rural  <- selecionar_extremas(dados_rural,  N_ESCOLAS_POR_GRUPO)

dados_cluster <- bind_rows(dados_urbana, dados_rural) |>
  mutate(cor_grupo = if_else(LOCALIZACAO == "Urbana", COR_URBANA, COR_RURAL))

message("Escolas no dendrograma  —  Urbana: ", sum(dados_cluster$LOCALIZACAO == "Urbana"),
        "  |  Rural: ", sum(dados_cluster$LOCALIZACAO == "Rural"))

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

altura_corte <- sort(hc$height, decreasing = TRUE)[N_CLUSTERS]

# — Painel 1: Dendrograma —
lab_cores <- dados_cluster |>
  transmute(label = sprintf("%d", ID_ESCOLA), cor = cor_grupo)

legenda_df <- tibble(
  cor    = c(COR_URBANA, COR_RURAL),
  rotulo = c("Urbana", "Rural")
)

p_dend <- painel_dendrograma(
  hc,
  lab_cores    = lab_cores,
  y_expand     = 0.28,
  titulo       = paste0("Clustering: Urbana vs Rural  (n = ", nrow(dados_cluster), ")"),
  subtitulo    = paste0("Variaveis: ", paste(VARS_CLUSTER, collapse = ", "),
                        "  |  Metodo: Ward.D2  |  Corte: ", N_CLUSTERS, " clusters"),
  altura_corte = altura_corte,
  annot_texto  = paste0("Corte: ", N_CLUSTERS, " clusters  |  altura = ",
                        round(altura_corte, 2)),
  legenda_df   = legenda_df
)

# — Painel 2: Estatisticas —
resumo_grupos <- dados_cluster |>
  group_by(GRUPO = LOCALIZACAO) |>
  summarise(
    N         = n(),
    MT_medio  = round(mean(MEDIA_MT),   1),
    MT_dp     = round(sd(MEDIA_MT),     1),
    LP_medio  = round(mean(MEDIA_LP),   1),
    LP_dp     = round(sd(MEDIA_LP),     1),
    INSE_medio= round(mean(INSE_MEDIO), 2),
    INSE_dp   = round(sd(INSE_MEDIO),   2),
    .groups   = "drop"
  ) |>
  mutate(cor_grupo = if_else(GRUPO == "Urbana", COR_URBANA, COR_RURAL))

p_stats <- painel_estatisticas(
  resumo_grupos,
  titulo = "Estatisticas por Localizacao"
)

# — Painel 3: Scatter —
p_scatter <- painel_scatter(
  dados_cluster,
  var_forma  = "AREA",
  titulo     = "Validacao: MT x LP  (Urbana vs Rural)",
  subtitulo  = "Cor = Localizacao  |  Forma = Area (Capital/Interior)  |  Tamanho = INSE"
)

# — Composicao —
caption <- paste0(
  "Localizacao: Urbana (n=", sum(dados_cluster$LOCALIZACAO == "Urbana"),
  ")  vs  Rural (n=", sum(dados_cluster$LOCALIZACAO == "Rural"), ")",
  "\nClustering hierarquico — distancia euclidiana, metodo Ward.D2",
  "  |  Gerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M")
)

nome_fig <- paste0("dendrograma_urbana_vs_rural_", ts, ".png")

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
  arrange(CLUSTER, LOCALIZACAO, desc(MEDIA_MT)) |>
  select(ID_ESCOLA, LOCALIZACAO, AREA, TIPO_ESCOLA, AREA_LOCAL, CLUSTER,
         MEDIA_MT, MEDIA_LP, INSE_MEDIO,
         FAIXA_MT, FAIXA_LP, GRUPO_INSE) |>
  mutate(across(c(MEDIA_MT, MEDIA_LP, INSE_MEDIO), ~ round(., 2)))

write_csv(tabela,
          file.path(DIR_SAIDA, paste0("tabela_urbana_vs_rural_", ts, ".csv")))

message("\nResumo por cluster:")
tabela |>
  group_by(CLUSTER, LOCALIZACAO) |>
  summarise(N = n(), MT = round(mean(MEDIA_MT), 1),
            LP = round(mean(MEDIA_LP), 1),
            INSE = round(mean(INSE_MEDIO), 2), .groups = "drop") |>
  arrange(CLUSTER) |>
  print(width = Inf)

message("\n", strrep("=", 70))
message("CONCLUIDO. Saida: ", DIR_SAIDA)
message(strrep("=", 70))