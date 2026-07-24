################################################################################
# SCRIPT: dendrograma_capital_vs_interior.r
#
# OBJETIVO: Clustering hierarquico comparando escolas de CAPITAL vs INTERIOR
#           Responde: o algoritmo consegue separar naturalmente as duas areas?
#
# VARIAVEL: AREA (valores esperados: "Capital" e "Interior")
#
# SAIDA:
#   outputs_figuras/capital_vs_interior/
#     dendrograma_capital_vs_interior_<ts>.png
#     tabela_capital_vs_interior_<ts>.csv
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
DIR_SAIDA       <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs/figuras/capital_vs_interior")

# Variaveis de clustering (escaladas internamente)
VARS_CLUSTER <- c("MEDIA_MT", "MEDIA_LP", "INSE_MEDIO")

# Numero de clusters para corte visual
N_CLUSTERS <- 2

# Percentil para selecionar escolas representativas de cada grupo
# (usa as mais extremas para o dendrograma ficar mais claro)
# NULL = usa TODAS as escolas das duas areas
N_ESCOLAS_POR_GRUPO <- 20     # ex: 20 pega as 20 mais extremas de cada area

# Cores dos dois grupos
COR_CAPITAL  <- "#1B4F9A"   # azul
COR_INTERIOR <- "#D62728"   # vermelho

# =============================================================================
# EXECUCAO
# =============================================================================

ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
message(strrep("=", 70))
message("DENDROGRAMA: Capital vs Interior")
message(strrep("=", 70))

# — Carregar dados —
metadados <- carregar_metadados(DIR_PROCESSADOS)

# Verificar coluna AREA
if (!"AREA" %in% names(metadados)) {
  stop("Coluna 'AREA' nao encontrada nos metadados.\n",
       "Colunas disponiveis: ", paste(names(metadados), collapse = ", "))
}

message("\nDistribuicao por AREA:")
metadados |> count(AREA) |> print()

# — Filtrar grupos —
dados_capital  <- metadados |>
  filter(AREA == "Capital",  !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))
dados_interior <- metadados |>
  filter(AREA == "Interior", !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))

message("\nEscolas validas  —  Capital: ", nrow(dados_capital),
        "  |  Interior: ", nrow(dados_interior))

# Selecao de representativas (se N_ESCOLAS_POR_GRUPO definido)
selecionar_extremas <- function(df, n) {
  if (is.null(n) || nrow(df) <= n) return(df)
  df |>
    mutate(SCORE = (scale(MEDIA_MT)[,1] + scale(MEDIA_LP)[,1]) / 2) |>
    arrange(SCORE) |>
    slice(c(1:ceiling(n/2), (n() - floor(n/2) + 1):n())) |>
    select(-SCORE)
}

dados_capital  <- selecionar_extremas(dados_capital,  N_ESCOLAS_POR_GRUPO)
dados_interior <- selecionar_extremas(dados_interior, N_ESCOLAS_POR_GRUPO)

dados_cluster <- bind_rows(dados_capital, dados_interior) |>
  mutate(cor_grupo = if_else(AREA == "Capital", COR_CAPITAL, COR_INTERIOR))

message("Escolas no dendrograma  —  Capital: ", sum(dados_cluster$AREA == "Capital"),
        "  |  Interior: ", sum(dados_cluster$AREA == "Interior"))

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
  cor    = c(COR_CAPITAL, COR_INTERIOR),
  rotulo = c("Capital", "Interior")
)

p_dend <- painel_dendrograma(
  hc,
  lab_cores    = lab_cores,
  y_expand     = 0.17,
  titulo       = paste0("Clustering: Capital vs Interior  (n = ", nrow(dados_cluster), ")"),
  subtitulo    = paste0("Variaveis: ", paste(VARS_CLUSTER, collapse = ", "),
                        "  |  Metodo: Ward.D2  |  Corte: ", N_CLUSTERS, " clusters"),
  altura_corte = altura_corte,
  annot_texto  = paste0("Corte: ", N_CLUSTERS, " clusters  |  altura = ",
                        round(altura_corte, 2)),
  legenda_df   = legenda_df
)

# — Painel 2: Estatisticas dos grupos —
resumo_grupos <- dados_cluster |>
  group_by(GRUPO = AREA) |>
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
  mutate(cor_grupo = if_else(GRUPO == "Capital", COR_CAPITAL, COR_INTERIOR))

p_stats <- painel_estatisticas(
  resumo_grupos,
  titulo = "Estatisticas por Area"
)

# — Painel 3: Scatter validador —
p_scatter <- painel_scatter(
  dados_cluster,
  var_forma  = "TIPO_ESCOLA",
  titulo     = "Validacao: MT x LP  (Capital vs Interior)",
  subtitulo  = "Cor = Area  |  Forma = Tipo de escola  |  Tamanho = INSE"
)

# — Composicao final —
caption <- paste0(
  "Area: Capital (n=", sum(dados_cluster$AREA == "Capital"),
  ")  vs  Interior (n=", sum(dados_cluster$AREA == "Interior"), ")",
  "\nClustering hierarquico — distancia euclidiana, metodo Ward.D2",
  "  |  Gerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M")
)

nome_fig <- paste0("dendrograma_capital_vs_interior_", ts, ".png")

salvar_figura_completa(
  p_dend     = p_dend,
  p_stats    = p_stats,
  p_scatter  = p_scatter,
  dir_saida  = DIR_SAIDA,
  nome_arquivo = nome_fig,
  caption_txt  = caption
)

# — Tabela —
tabela <- dados_cluster |>
  arrange(CLUSTER, AREA, desc(MEDIA_MT)) |>
  select(ID_ESCOLA, AREA, TIPO_ESCOLA, LOCALIZACAO, AREA_LOCAL, CLUSTER,
         MEDIA_MT, MEDIA_LP, INSE_MEDIO,
         FAIXA_MT, FAIXA_LP, GRUPO_INSE) |>
  mutate(across(c(MEDIA_MT, MEDIA_LP, INSE_MEDIO), ~ round(., 2)))

write_csv(tabela,
          file.path(DIR_SAIDA, paste0("tabela_capital_vs_interior_", ts, ".csv")))

message("\nResumo por cluster:")
tabela |>
  group_by(CLUSTER, AREA) |>
  summarise(N = n(), MT = round(mean(MEDIA_MT), 1),
            LP = round(mean(MEDIA_LP), 1),
            INSE = round(mean(INSE_MEDIO), 2), .groups = "drop") |>
  arrange(CLUSTER) |>
  print(width = Inf)

message("\n", strrep("=", 70))
message("CONCLUIDO. Saida: ", DIR_SAIDA)
message(strrep("=", 70))