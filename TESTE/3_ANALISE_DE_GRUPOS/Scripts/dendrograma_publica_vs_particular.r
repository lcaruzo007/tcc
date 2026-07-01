################################################################################
# SCRIPT: dendrograma_publica_vs_particular.r
#
# OBJETIVO: Clustering hierarquico comparando escolas PUBLICAS vs PRIVADAS
#           Responde: o algoritmo separa naturalmente publicas de privadas?
#           Qual a diferenca real de desempenho e INSE entre os dois grupos?
#
# VARIAVEL: TIPO_ESCOLA (valores esperados: "Publica" e "Privada")
#           ou IN_PUBLICA (1 = publica, 0 = privada) — detectado automaticamente
#
# SAIDA:
#   outputs_figuras/publica_vs_particular/
#     dendrograma_publica_vs_particular_<ts>.png
#     tabela_publica_vs_particular_<ts>.csv
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
DIR_PROCESSADOS <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs_escolas")
DIR_SAIDA       <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs_figuras/publica_vs_particular")

VARS_CLUSTER <- c("MEDIA_MT", "MEDIA_LP", "INSE_MEDIO")
N_CLUSTERS   <- 2

# NULL = usa todas; numero = seleciona as mais extremas de cada grupo
# Recomendado: como ha muito mais publicas que privadas,
# definir um numero igual dos dois lados torna o dendrograma mais legivel
N_ESCOLAS_POR_GRUPO <- 20


COR_PUBLICA  <- "#1B4F9A"   # azul
COR_PRIVADA  <- "#A23B72"   # roxo-rosa

# =============================================================================
# EXECUCAO
# =============================================================================

ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
message(strrep("=", 70))
message("DENDROGRAMA: Publica vs Privada")
message(strrep("=", 70))

metadados <- carregar_metadados(DIR_PROCESSADOS)

# Detectar coluna de tipo (aceita TIPO_ESCOLA ou IN_PUBLICA)
if ("TIPO_ESCOLA" %in% names(metadados)) {
  metadados <- metadados |>
    mutate(TIPO_NORM = case_when(
      str_detect(TIPO_ESCOLA, regex("priv", ignore_case = TRUE)) ~ "Privada",
      TRUE                                                         ~ "Publica"
    ))
  message("Usando coluna: TIPO_ESCOLA")

} else if ("IN_PUBLICA" %in% names(metadados)) {
  metadados <- metadados |>
    mutate(TIPO_NORM = if_else(IN_PUBLICA == 1L, "Publica", "Privada"))
  message("Usando coluna: IN_PUBLICA")

} else {
  stop("Nenhuma coluna de tipo encontrada (TIPO_ESCOLA ou IN_PUBLICA).\n",
       "Colunas disponiveis: ", paste(names(metadados), collapse = ", "))
}

message("\nDistribuicao por tipo:")
metadados |> count(TIPO_NORM) |> print()

dados_pub  <- metadados |>
  filter(TIPO_NORM == "Publica",  !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))
dados_priv <- metadados |>
  filter(TIPO_NORM == "Privada", !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))

message("\nEscolas validas  —  Publica: ", nrow(dados_pub),
        "  |  Privada: ", nrow(dados_priv))

selecionar_extremas <- function(df, n) {
  if (is.null(n) || nrow(df) <= n) return(df)
  df |>
    mutate(SCORE = (scale(MEDIA_MT)[,1] + scale(MEDIA_LP)[,1]) / 2) |>
    arrange(SCORE) |>
    slice(c(1:ceiling(n/2), (n() - floor(n/2) + 1):n())) |>
    select(-SCORE)
}

dados_pub  <- selecionar_extremas(dados_pub,  N_ESCOLAS_POR_GRUPO)
dados_priv <- selecionar_extremas(dados_priv, N_ESCOLAS_POR_GRUPO)

dados_cluster <- bind_rows(dados_pub, dados_priv) |>
  mutate(cor_grupo = if_else(TIPO_NORM == "Publica", COR_PUBLICA, COR_PRIVADA))

message("Escolas no dendrograma  —  Publica: ", sum(dados_cluster$TIPO_NORM == "Publica"),
        "  |  Privada: ", sum(dados_cluster$TIPO_NORM == "Privada"))

# — Clustering —
mat <- dados_cluster |>
  select(all_of(VARS_CLUSTER)) |>
  mutate(across(everything(), ~ as.numeric(scale(.)))) |>
  as.matrix()

rownames(mat) <- sprintf("Esc.%d", dados_cluster$ID_ESCOLA)

dist_mat <- dist(mat, method = "euclidean")
hc       <- hclust(dist_mat, method = "ward.D2")

dados_cluster <- dados_cluster |>
  mutate(CLUSTER = as.character(cutree(hc, k = N_CLUSTERS)))

# Avaliar pureza dos clusters (quanto % de cada tipo caiu em cada cluster)
pureza <- dados_cluster |>
  count(CLUSTER, TIPO_NORM) |>
  group_by(CLUSTER) |>
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  ungroup()

message("\nPureza dos clusters (quanto o algoritmo separou os dois tipos):")
print(pureza, n = Inf, width = Inf)

altura_corte <- sort(hc$height, decreasing = TRUE)[N_CLUSTERS]

# — Painel 1: Dendrograma —
lab_cores <- dados_cluster |>
  transmute(label = sprintf("Esc.%d", ID_ESCOLA), cor = cor_grupo)

legenda_df <- tibble(
  cor    = c(COR_PUBLICA, COR_PRIVADA),
  rotulo = c("Publica", "Privada")
)

p_dend <- painel_dendrograma(
  hc,
  lab_cores    = lab_cores,
  y_expand     = 0.25,
  titulo       = paste0("Clustering: Publica vs Privada  (n = ", nrow(dados_cluster), ")"),
  subtitulo    = paste0("Variaveis: ", paste(VARS_CLUSTER, collapse = ", "),
                        "  |  Metodo: Ward.D2  |  Corte: ", N_CLUSTERS, " clusters"),
  altura_corte = altura_corte,
  annot_texto  = paste0("Corte: ", N_CLUSTERS, " clusters  |  altura = ",
                        round(altura_corte, 2)),
  legenda_df   = legenda_df
)

# — Painel 2: Estatisticas —
resumo_grupos <- dados_cluster |>
  group_by(GRUPO = TIPO_NORM) |>
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
  mutate(cor_grupo = if_else(GRUPO == "Publica", COR_PUBLICA, COR_PRIVADA))

p_stats <- painel_estatisticas(
  resumo_grupos,
  titulo = "Estatisticas por Tipo de Escola"
)

# — Painel 3: Scatter —
p_scatter <- painel_scatter(
  dados_cluster |> rename(cor_grupo = cor_grupo),
  var_forma  = "AREA",
  titulo     = "Validacao: MT x LP  (Publica vs Privada)",
  subtitulo  = "Cor = Tipo  |  Forma = Area (Capital/Interior)  |  Tamanho = INSE"
)

# — Composicao —
caption <- paste0(
  "Tipo: Publica (n=", sum(dados_cluster$TIPO_NORM == "Publica"),
  ")  vs  Privada (n=", sum(dados_cluster$TIPO_NORM == "Privada"), ")",
  "\nClustering hierarquico — distancia euclidiana, metodo Ward.D2",
  "  |  Gerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M")
)

nome_fig <- paste0("dendrograma_publica_vs_particular_", ts, ".png")

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
  arrange(CLUSTER, TIPO_NORM, desc(MEDIA_MT)) |>
  select(ID_ESCOLA, TIPO_NORM, AREA, LOCALIZACAO, CLUSTER,
         MEDIA_MT, MEDIA_LP, INSE_MEDIO,
         FAIXA_MT, FAIXA_LP, GRUPO_INSE) |>
  rename(TIPO_ESCOLA = TIPO_NORM) |>
  mutate(across(c(MEDIA_MT, MEDIA_LP, INSE_MEDIO), ~ round(., 2)))

write_csv(tabela,
          file.path(DIR_SAIDA, paste0("tabela_publica_vs_particular_", ts, ".csv")))

message("\nResumo por cluster:")
tabela |>
  group_by(CLUSTER, TIPO_ESCOLA) |>
  summarise(N = n(), MT = round(mean(MEDIA_MT), 1),
            LP = round(mean(MEDIA_LP), 1),
            INSE = round(mean(INSE_MEDIO), 2), .groups = "drop") |>
  arrange(CLUSTER) |>
  print(width = Inf)

message("\n", strrep("=", 70))
message("CONCLUIDO. Saida: ", DIR_SAIDA)
message(strrep("=", 70))