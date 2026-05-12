################################################################################
# SCRIPT: dendrograma_geral.r
#
# OBJETIVO: Gerar dendrograma com N escolas de perfis variados (boas e ruins)
#           para validar se o clustering agrupa escolas similares entre si.
#           Ideal para apresentar ao orientador.
#
# LÓGICA:
#   - Você informa os IDs das escolas (de diferentes perfis)
#   - O script faz o clustering hierárquico (Ward.D2) com MEDIA_MT, MEDIA_LP e INSE
#   - O dendrograma mostra: nome da escola, MT, LP e INSE em cada folha
#   - Cada folha é colorida pelo grupo de desempenho (Alto / Médio / Baixo)
#   - Um scatter validador mostra os clusters sobrepostos
#
# ENTRADA:  metadados_escolas_*.csv (saida de classificar_escolas.r)
#
# SAÍDA:
#   - dendrograma_geral_<timestamp>.png   (dendrograma completo com labels)
#   - scatter_validacao_<timestamp>.png   (scatter MT x LP colorido por cluster)
#   - tabela_escolas_<timestamp>.csv      (resumo com cluster atribuído)
#
# VERSAO: 3.0 — Maio 2026
################################################################################

library(tidyverse)
library(ggdendro)   # install.packages("ggdendro")
library(patchwork)  # install.packages("patchwork")

# =============================================================================
# CONFIGURACAO
# =============================================================================

RAIZ            <- "C:/Users/13756596699/tcc"
DIR_PROCESSADOS <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs_escolas")
DIR_FIGURAS     <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs_figuras")

# -----------------------------------------------------------------------------
# ESCOLAS A COMPARAR
# Coloque aqui IDs de escolas com perfis variados:
#   - algumas com notas altas (boas)
#   - algumas com notas médias
#   - algumas com notas baixas (ruins)
#   - misture públicas e privadas se quiser
# O clustering vai mostrar se o algoritmo agrupa as similares juntas.
# -----------------------------------------------------------------------------
IDS_ESCOLAS <- c(
  61432986,   # Escola 1 — adicione quantas quiser
  61466120,   # Escola 2
  61425355,   # Escola 3
  61458788,   # Escola 4
  # 61XXXXXX, # Escola 5 — descomente e ajuste
  # 61XXXXXX, # Escola 6
  # 61XXXXXX, # Escola 7
  # 61XXXXXX, # Escola 8
  NULL        # deixe NULL aqui para fechar o vetor
)
IDS_ESCOLAS <- IDS_ESCOLAS[!is.null(IDS_ESCOLAS)]

# Variaveis usadas no clustering
VARS_CLUSTER <- c("MEDIA_MT", "MEDIA_LP", "INSE_MEDIO")

# Numero de clusters para corte visual (linhas tracejadas no dendrograma)
# Use 2 para mostrar "boas vs ruins", 3 para Alto/Medio/Baixo
N_CLUSTERS <- 3

# =============================================================================
# FUNCOES AUXILIARES
# =============================================================================

# Paleta de clusters (ate 5 grupos)
paleta_clusters <- c(
  "1" = "#2CA02C",   # verde  — melhor grupo
  "2" = "#1B4F9A",   # azul
  "3" = "#FF7F0E",   # laranja
  "4" = "#D62728",   # vermelho — pior grupo
  "5" = "#9467BD"    # roxo
  "6" = "#8C564B",   # marrom
  "7" = "#E377C2",   # rosa
  "8" = "#7F7F7F",   # cinza
  "9" = "#BCBD22",   # amarelo-oliva
  "10"= "#17BECF"    # ciano
)

# Cor por tipo de escola
cor_tipo <- function(tipo) {
  ifelse(tipo == "Privada", "#A23B72", "#2E86AB")
}

# =============================================================================
# EXECUCAO
# =============================================================================

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
ts <- format(Sys.time(), "%Y%m%d_%H%M%S")

# — Carregar metadados —
arquivos_meta <- list.files(DIR_PROCESSADOS,
                             pattern    = "^metadados_escolas_.*\\.csv$",
                             full.names = TRUE)
if (length(arquivos_meta) == 0) {
  stop("Nenhum metadados_escolas encontrado. Execute classificar_escolas.r primeiro.")
}
metadados <- read_csv(sort(arquivos_meta, decreasing = TRUE)[1],
                      show_col_types = FALSE)
message("Metadados carregados: ", nrow(metadados), " escolas")

# — Filtrar apenas as escolas solicitadas —
dados <- metadados |>
  filter(ID_ESCOLA %in% IDS_ESCOLAS)

nao_encontradas <- setdiff(IDS_ESCOLAS, dados$ID_ESCOLA)
if (length(nao_encontradas) > 0) {
  warning("Escolas nao encontradas nos metadados: ",
          paste(nao_encontradas, collapse = ", "))
}

if (nrow(dados) < 3) {
  stop("Minimo de 3 escolas encontradas necessario para o dendrograma geral.")
}

message("Escolas para o dendrograma: ", nrow(dados))

# — Verificar variaveis disponíveis —
vars_ok <- intersect(VARS_CLUSTER, names(dados))
vars_ok <- vars_ok[sapply(vars_ok, function(v) all(!is.na(dados[[v]])))]
message("Variaveis usadas: ", paste(vars_ok, collapse = ", "))

# — Classificar grupo de desempenho (para cor das folhas) —
# Baseado na media de MT+LP de cada escola vs o grupo todo
dados <- dados |>
  mutate(
    SCORE_GERAL = (scale(MEDIA_MT)[, 1] + scale(MEDIA_LP)[, 1]) / 2,
    GRUPO_DESEMPENHO = case_when(
      SCORE_GERAL >= quantile(SCORE_GERAL, 0.67, na.rm = TRUE) ~ "Alto",
      SCORE_GERAL >= quantile(SCORE_GERAL, 0.33, na.rm = TRUE) ~ "Medio",
      TRUE                                                       ~ "Baixo"
    ),
    GRUPO_DESEMPENHO = factor(GRUPO_DESEMPENHO, levels = c("Alto", "Medio", "Baixo"))
  )

cores_desempenho <- c("Alto" = "#2CA02C", "Medio" = "#FF7F0E", "Baixo" = "#D62728")

# =============================================================================
# CLUSTERING
# =============================================================================

mat <- dados |>
  select(all_of(vars_ok)) |>
  mutate(across(everything(), ~ scale(.)[, 1])) |>
  as.matrix()

# Label de cada escola: ID + MT + LP
rownames(mat) <- sprintf("Escola %d\nMT:%.0f | LP:%.0f\nINSE:%.2f",
                          dados$ID_ESCOLA,
                          dados$MEDIA_MT,
                          dados$MEDIA_LP,
                          dados$INSE_MEDIO)

dist_mat <- dist(mat, method = "euclidean")
hc       <- hclust(dist_mat, method = "ward.D2")

# Cortar em N_CLUSTERS e guardar atribuicao
clusters_atrib <- cutree(hc, k = N_CLUSTERS)
dados <- dados |>
  mutate(
    LABEL_DEND = sprintf("Escola %d\nMT:%.0f | LP:%.0f\nINSE:%.2f",
                          ID_ESCOLA, MEDIA_MT, MEDIA_LP, INSE_MEDIO),
    CLUSTER = as.character(clusters_atrib)   # índice posicional, sem depender do nome
  )
message("vars_ok encontradas: ", paste(vars_ok, collapse = ", "))
message("Linhas na matriz: ", nrow(mat), " | Colunas: ", ncol(mat))
# =============================================================================
# PAINEL 1 — DENDROGRAMA
# =============================================================================

dend_data <- dendro_data(hc, type = "rectangle")
seg       <- dend_data$segments
lab       <- dend_data$labels

# Juntar cor de desempenho e cluster nas labels
lab <- lab |>
  left_join(
    dados |> select(LABEL_DEND, GRUPO_DESEMPENHO, CLUSTER, TIPO_ESCOLA),
    by = c("label" = "LABEL_DEND")
  ) |>
  mutate(
    cor_folha = cores_desempenho[as.character(GRUPO_DESEMPENHO)]
  )

y_max   <- max(seg$y)
y_label <- -0.10 * y_max   # posicao do label multilinhas abaixo do ponto

# Altura de corte para N_CLUSTERS (linha tracejada)
alturas <- sort(hc$height, decreasing = TRUE)
altura_corte <- alturas[min(N_CLUSTERS, length(alturas))]

p_dend <- ggplot() +
  # Retangulo de fundo por cluster (faixas verticais suaves)
  # Segmentos do dendrograma
  geom_segment(data = seg,
               aes(x = x, y = y, xend = xend, yend = yend),
               colour = "#555555", linewidth = 1.1, lineend = "round") +
  # Linha de corte
  geom_hline(yintercept = altura_corte,
             linetype = "dashed", colour = "#7B2D8B", linewidth = 0.8) +
  annotate("text",
           x     = max(lab$x) + 0.3,
           y     = altura_corte,
           label = sprintf("Corte: %d clusters", N_CLUSTERS),
           hjust = 0, vjust = -0.4,
           size = 3, colour = "#7B2D8B", fontface = "italic") +
  # Pontos nas folhas
  geom_point(data = lab,
             aes(x = x, y = 0, colour = cor_folha),
             size = 6, shape = 19) +
  # Labels multilinhas (ID + MT + LP + INSE)
  geom_text(data = lab,
            aes(x = x, y = y_label, label = label, colour = cor_folha),
            size = 2.9, fontface = "bold", hjust = 0.5,
            lineheight = 0.85, vjust = 1) +
  scale_colour_identity() +
  scale_y_continuous(
    expand = expansion(mult = c(0.38, 0.08)),
    name   = "Distancia Euclidiana (Ward.D2)"
  ) +
  labs(
    title    = "Dendrograma Geral — Agrupamento Hierarquico de Escolas",
    subtitle = paste0("Variaveis: ", paste(vars_ok, collapse = ", "),
                      "   |   Metodo: Ward.D2   |   n = ", nrow(dados), " escolas")
  ) +
  # Legenda manual de desempenho
  annotate("point", x = 0.55, y = y_max * 0.97,
           colour = "#2CA02C", size = 3.5) +
  annotate("text",  x = 0.65, y = y_max * 0.97,
           label = "Alto desempenho",  hjust = 0, size = 3, colour = "#2CA02C") +
  annotate("point", x = 0.55, y = y_max * 0.90,
           colour = "#FF7F0E", size = 3.5) +
  annotate("text",  x = 0.65, y = y_max * 0.90,
           label = "Medio desempenho", hjust = 0, size = 3, colour = "#FF7F0E") +
  annotate("point", x = 0.55, y = y_max * 0.83,
           colour = "#D62728", size = 3.5) +
  annotate("text",  x = 0.65, y = y_max * 0.83,
           label = "Baixo desempenho", hjust = 0, size = 3, colour = "#D62728") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title         = element_text(face = "bold", size = 14, colour = "#1A1A1A"),
    plot.subtitle      = element_text(size = 10, colour = "#555555"),
    axis.title.x       = element_blank(),
    axis.text.x        = element_blank(),
    axis.ticks.x       = element_blank(),
    axis.title.y       = element_text(size = 10),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.background    = element_rect(fill = "#F8F9FA", colour = NA),
    panel.background   = element_rect(fill = "#FFFFFF", colour = NA),
    plot.margin        = margin(16, 20, 8, 16)
  )

# =============================================================================
# PAINEL 2 — SCATTER VALIDADOR (MT x LP colorido por cluster)
# =============================================================================

p_scatter <- ggplot(dados,
                    aes(x = MEDIA_MT, y = MEDIA_LP,
                        colour = GRUPO_DESEMPENHO,
                        shape  = TIPO_ESCOLA)) +
  geom_point(aes(size = INSE_MEDIO), alpha = 0.85) +
  geom_text(aes(label = as.character(ID_ESCOLA)),
            vjust = -1.1, size = 2.8, fontface = "bold",
            colour = cores_desempenho[as.character(dados$GRUPO_DESEMPENHO)]) +
  scale_colour_manual(values = cores_desempenho, name = "Desempenho") +
  scale_shape_manual(values  = c("Publica" = 16, "Privada" = 17),
                     name = "Tipo") +
  scale_size_continuous(range = c(4, 10), name = "INSE medio") +
  labs(
    title    = "Validacao: Proficiencia MT x LP",
    subtitle = "Cor = grupo de desempenho  |  Forma = tipo de escola  |  Tamanho = INSE",
    x = "Proficiencia MT",
    y = "Proficiencia LP"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title      = element_text(face = "bold", size = 12, colour = "#1A1A1A"),
    plot.subtitle   = element_text(size = 9,  colour = "#555555"),
    legend.position = "right",
    plot.background = element_rect(fill = "#F8F9FA", colour = NA),
    panel.background= element_rect(fill = "#FFFFFF", colour = NA),
    plot.margin     = margin(16, 16, 8, 16)
  )

# =============================================================================
# COMPOSICAO E SALVAMENTO
# =============================================================================

final <- p_dend / p_scatter +
  plot_layout(heights = c(2, 1)) +
  plot_annotation(
    caption = paste0(
      "Clustering hierarquico — distancia euclidiana, metodo Ward.D2   |   ",
      "Gerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M")
    ),
    theme = theme(
      plot.caption    = element_text(size = 8, colour = "#888888", hjust = 0),
      plot.background = element_rect(fill = "#F8F9FA", colour = NA)
    )
  )

nome_fig <- paste0("dendrograma_geral_", ts, ".png")
ggsave(file.path(DIR_FIGURAS, nome_fig),
       final, width = 14, height = 14, dpi = 180, bg = "#F8F9FA")

message("Figura salva: ", nome_fig)

# — Tabela resumo —
tabela_saida <- dados |>
  arrange(CLUSTER, desc(MEDIA_MT)) |>
  select(ID_ESCOLA, TIPO_ESCOLA, GRUPO_DESEMPENHO, CLUSTER,
         MEDIA_MT, MEDIA_LP, INSE_MEDIO, FAIXA_MT, FAIXA_LP) |>
  mutate(across(c(MEDIA_MT, MEDIA_LP, INSE_MEDIO), ~ round(., 2)))

write_csv(tabela_saida,
          file.path(DIR_FIGURAS, paste0("tabela_escolas_", ts, ".csv")))

# — Imprimir resumo no console —
cat("\n", strrep("=", 70), "\n", sep = "")
cat("RESUMO POR CLUSTER\n")
cat(strrep("=", 70), "\n\n", sep = "")

tabela_saida |>
  group_by(CLUSTER, GRUPO_DESEMPENHO) |>
  summarise(
    N          = n(),
    MT_medio   = round(mean(MEDIA_MT), 1),
    LP_medio   = round(mean(MEDIA_LP), 1),
    INSE_medio = round(mean(INSE_MEDIO), 2),
    Escolas    = paste(ID_ESCOLA, collapse = ", "),
    .groups    = "drop"
  ) |>
  arrange(CLUSTER) |>
  print(width = Inf)

cat("\nFigura:  ", nome_fig, "\n")
cat("Tabela:  tabela_escolas_", ts, ".csv\n", sep = "")
cat("Salvo em:", DIR_FIGURAS, "\n")