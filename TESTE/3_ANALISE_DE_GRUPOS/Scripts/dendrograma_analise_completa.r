################################################################################
# SCRIPT: dendrograma_analise_completa.r
#
# FUNCIONALIDADE:
#   Dendrograma geral com TODAS as escolas ALTO + BAIXO desempenho
#
# ENTRADA:
#   - metadados_escolas_*.csv  (saida de classificar_escolas.r)
#
# SAIDA:
#   - dendrograma_geral_ALTO_BAIXO_<ts>.png
#   - tabela_escolas_ALTO_BAIXO_<ts>.csv
#
# VERSAO: 3.0 — Mai 2026 (Apenas MODO 1)
################################################################################

library(tidyverse)
library(ggdendro)
library(patchwork)

# =============================================================================
# DETECCAO AUTOMATICA DE CAMINHOS — Funciona em qualquer computador!
# =============================================================================

detectar_raiz <- function() {
  # 1. Começar do diretório de trabalho atual
  cwd <- getwd()
  
  # 2. Procurar pela pasta "TESTE" subindo a árvore de diretórios
  while (cwd != dirname(cwd)) {  # enquanto não chegar à raiz do sistema
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("✓ Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)  # sobe um nível
  }
  
  # 3. Se não encontrar, pedir ao usuário
  message("⚠️  Não consegui encontrar a pasta 'TESTE' automaticamente.")
  message("   Por favor, selecione manualmente a pasta raiz do projeto TCC")
  
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC (onde está a pasta TESTE)")
    if (is.na(raiz) || raiz == "") {
      stop("Caminho não selecionado. Encerrando.")
    }
    message("✓ Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Script não pode rodar em modo não-interativo sem encontrar o caminho.",
         "\nExecute no RStudio ou em um terminal interativo.")
  }
}

# Detectar e confirmar caminho
RAIZ            <- detectar_raiz()
DIR_PROCESSADOS <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs/metadados")
DIR_FIGURAS     <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs/figuras")

message("Caminhos configurados:")
message("  RAIZ:              ", RAIZ)
message("  Metadados:         ", DIR_PROCESSADOS)
message("  Figuras (saida):   ", DIR_FIGURAS, "\n")

# =============================================================================
# CONFIGURACAO — Ajuste conforme necessário
# =============================================================================

# Este script gera APENAS dendrogramas gerais (todas as escolas ALTO+BAIXO)
# Para comparar pares específicos, use o script comparar_duas_escolas.r

# Percentis para classificar desempenho (Modo 1)
PERCENTIL_ALTO  <- 0.75
PERCENTIL_BAIXO <- 0.25

# Numero de clusters no corte do dendrograma (Modo 1)
N_CLUSTERS <- 3

# Maximo de escolas por grupo no dendrograma geral (Modo 1)
# Com 1165 escolas o grafico fica ilegivel — recomendado: 20 a 40
# Seleciona automaticamente as mais representativas de cada extremo
N_MAX_POR_GRUPO <- 30

# Remover outliers de MEDIA_LP antes do clustering? (TRUE recomendado)
# Remove escolas com MEDIA_LP fora de [media - 3*dp, media + 3*dp]
REMOVER_OUTLIERS_LP <- TRUE

# Variaveis usadas no clustering (devem existir nos metadados)
VARS_CLUSTER <- c("MEDIA_MT_escala", "MEDIA_LP_escala", "INSE_escala")

# Cores fixas
COR_ALTO   <- "#2CA02C"
COR_BAIXO  <- "#D62728"
COR_FUNDO  <- "#F8F9FA"
COR_CORTE  <- "#7B2D8B"

# =============================================================================
# FUNCOES UTILITARIAS
# =============================================================================

# Retorna o arquivo mais recente que bate com o padrao
arquivo_mais_recente <- function(pasta, padrao) {
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE)
  if (length(arqs) == 0L) return(NULL)
  arqs[which.max(file.info(arqs)$mtime)]
}

# Tema base compartilhado entre todos os paineis
tema_saeb <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title       = element_text(face = "bold", size = base_size + 2,
                                      colour = "#1A1A1A", margin = margin(b = 4)),
      plot.subtitle    = element_text(size = base_size - 1, colour = "#555555",
                                      margin = margin(b = 8)),
      plot.background  = element_rect(fill = COR_FUNDO,  colour = NA),
      panel.background = element_rect(fill = "#FFFFFF",  colour = NA),
      panel.grid.major = element_line(colour = "#E8E8E8", linewidth = 0.4),
      panel.grid.minor = element_blank(),
      plot.margin      = margin(16, 16, 8, 16)
    )
}

# Interpreta a distancia euclidiana entre dois pontos
interpretar_distancia <- function(d) {
  dplyr::case_when(
    d < 1 ~ "muito similares",
    d < 2 ~ "moderadamente similares",
    TRUE  ~ "bem diferentes"
  )
}

# Constroi o painel de dendrograma (ggplot) a partir de um objeto hclust
painel_dendrograma <- function(hc, lab_cores, y_expand = 0.28,
                               titulo = "", subtitulo = "",
                               annot_texto = NULL, annot_y_frac = 1.02,
                               prof_labels = NULL) {
  dend_data <- dendro_data(hc, type = "rectangle")
  seg       <- dend_data$segments
  lab       <- dend_data$labels |>
    left_join(lab_cores, by = "label")

  y_max   <- max(seg$y, na.rm = TRUE)
  y_label <- -0.22 * y_max
  y_prof  <- if (!is.null(prof_labels)) -0.20 * y_max else NULL

  p <- ggplot() +
    geom_segment(data = seg,
                 aes(x = x, y = y, xend = xend, yend = yend),
                 colour = "#555555", linewidth = 1.1, lineend = "round") +
    geom_point(data = lab,
               aes(x = x, y = 0, colour = cor),
               size = 6, shape = 19) +
    geom_text(data = lab,
              aes(x = x, y = y_label, label = label, colour = cor),
              size = 3.2, fontface = "bold", hjust = 0.5, lineheight = 0.9, angle = 90) +
    scale_colour_identity() +
    scale_y_continuous(
      expand = expansion(mult = c(0.45, 0.06)),
      name = "Distancia Euclidiana (Ward.D2)"
    ) +
    labs(title = titulo, subtitle = subtitulo) +
    tema_saeb() +
    theme(
      axis.title.x       = element_blank(),
      axis.text.x        = element_blank(),
      axis.ticks.x       = element_blank(),
      panel.grid.major.x = element_blank()
    )

  # Proficiencias abaixo dos labels (Modo 2)
  if (!is.null(prof_labels) && !is.null(y_prof)) {
    lab_prof <- lab |> left_join(prof_labels, by = "label")
    p <- p +
      geom_text(data = lab_prof,
                aes(x = x, y = y_prof, label = prof, colour = cor),
                size = 2.8, fontface = "italic", hjust = 0.5)
  }

  # Anotacao de distancia / corte
  if (!is.null(annot_texto)) {
    p <- p +
      annotate("text",
               x     = mean(range(lab$x)),
               y     = y_max * annot_y_frac,
               label = annot_texto,
               size  = 3.2, colour = COR_CORTE,
               fontface = "bold.italic", hjust = 0.5)
  }

  p
}

# =============================================================================
# INICIALIZACAO
# =============================================================================

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

message(strrep("=", 70))
message("ANALISE DE DENDROGRAMAS — SAEB MG  (Geral ALTO+BAIXO)")
message(strrep("=", 70))

# =============================================================================
# CARREGAR METADADOS
# =============================================================================

arq_meta <- arquivo_mais_recente(DIR_PROCESSADOS, "^metadados_escolas_.*\\.csv$")
if (is.null(arq_meta)) {
  stop("metadados_escolas_*.csv nao encontrado. Execute classificar_escolas.r primeiro.")
}
message("Metadados: ", basename(arq_meta))
metadados <- read_csv(arq_meta, show_col_types = FALSE)
message("Escolas carregadas: ", nrow(metadados))

# =============================================================================
# CATEGORIZAR POR DESEMPENHO (necessario nos dois modos)
# =============================================================================

metadados <- metadados |>
  mutate(MEDIA_PROFICIENCIA = (MEDIA_MT + MEDIA_LP) / 2)

q_alto  <- quantile(metadados$MEDIA_PROFICIENCIA, PERCENTIL_ALTO,  na.rm = TRUE)
q_baixo <- quantile(metadados$MEDIA_PROFICIENCIA, PERCENTIL_BAIXO, na.rm = TRUE)

metadados <- metadados |>
  mutate(CATEGORIA_DESEMPENHO = case_when(
    MEDIA_PROFICIENCIA >= q_alto  ~ "ALTO",
    MEDIA_PROFICIENCIA <= q_baixo ~ "BAIXO",
    TRUE                          ~ "INTERMEDIARIO"
  ))

message("\nDistribuicao de desempenho:")
metadados |>
  count(CATEGORIA_DESEMPENHO) |>
  arrange(CATEGORIA_DESEMPENHO) |>
  { \(d) message(paste0("  ", d$CATEGORIA_DESEMPENHO, ": ", d$n, collapse = "\n")) }()

# =============================================================================
# MODO 1 — DENDROGRAMA GERAL (ALTO + BAIXO)
# =============================================================================

if (MODO == 1) {

  message("\n", strrep("-", 50))
  message("MODO 1: Dendrograma geral ALTO + BAIXO")
  message(strrep("-", 50))

  # ---- PASSO 1: Filtrar e limpar outliers ----
  dados_modo1 <- metadados |>
    filter(CATEGORIA_DESEMPENHO %in% c("ALTO", "BAIXO"),
           !is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))

  # Remover outliers de MEDIA_LP (valores > media +/- 3 dp sao dados corrompidos)
  if (REMOVER_OUTLIERS_LP) {
    mu_lp  <- mean(dados_modo1$MEDIA_LP, na.rm = TRUE)
    dp_lp  <- sd(dados_modo1$MEDIA_LP,   na.rm = TRUE)
    lim_inf <- mu_lp - 3 * dp_lp
    lim_sup <- mu_lp + 3 * dp_lp
    n_antes <- nrow(dados_modo1)
    dados_modo1 <- dados_modo1 |>
  filter(
    MEDIA_MT >= 150, MEDIA_MT <= 500,
    MEDIA_LP >= 150, MEDIA_LP <= 500
  )
    n_depois <- nrow(dados_modo1)
    message("\nRemocao de outliers de MEDIA_LP: ", n_antes - n_depois,
            " escolas removidas (fora de ", round(lim_inf, 1), " a ", round(lim_sup, 1), ")")
  }
  

  message("Escolas apos limpeza: ", nrow(dados_modo1),
          "  (ALTO: ", sum(dados_modo1$CATEGORIA_DESEMPENHO == "ALTO"),
          ", BAIXO: ", sum(dados_modo1$CATEGORIA_DESEMPENHO == "BAIXO"), ")")

  # ---- PASSO 2: Amostragem inteligente para o DENDROGRAMA ----
  # Pega as N_MAX_POR_GRUPO mais extremas de cada grupo
  # (as que melhor representam alto vs baixo desempenho)
  amostrar_extremas <- function(df, n) {
    if (nrow(df) <= n) return(df)
    df |>
      mutate(.score = (scale(MEDIA_MT)[,1] + scale(MEDIA_LP)[,1]) / 2) |>
      arrange(.score) |>
      slice(c(1:ceiling(n / 2),                   # piores
              (n() - floor(n / 2) + 1):n())) |>   # melhores
      select(-.score)
  }

  dados_cluster <- bind_rows(
    dados_modo1 |> filter(CATEGORIA_DESEMPENHO == "ALTO")  |> amostrar_extremas(N_MAX_POR_GRUPO),
    dados_modo1 |> filter(CATEGORIA_DESEMPENHO == "BAIXO") |> amostrar_extremas(N_MAX_POR_GRUPO)
  ) |>
    mutate(
      MEDIA_MT_escala = as.numeric(scale(MEDIA_MT)),
      MEDIA_LP_escala = as.numeric(scale(MEDIA_LP)),
      INSE_escala     = as.numeric(scale(INSE_MEDIO))
    )

  message("Escolas no dendrograma (amostra): ", nrow(dados_cluster),
          "  (ALTO: ", sum(dados_cluster$CATEGORIA_DESEMPENHO == "ALTO"),
          ", BAIXO: ", sum(dados_cluster$CATEGORIA_DESEMPENHO == "BAIXO"), ")")

  # ---- PASSO 3: Clustering ----
  vars_ok <- intersect(VARS_CLUSTER, names(dados_cluster))
  mat     <- as.matrix(dados_cluster[, vars_ok])
  rownames(mat) <- sprintf("Esc.%d", dados_cluster$ID_ESCOLA)

  dist_mat <- dist(mat, method = "euclidean")
  hc       <- hclust(dist_mat, method = "ward.D2")

  dados_cluster <- dados_cluster |>
    mutate(CLUSTER = as.character(cutree(hc, k = N_CLUSTERS)))

  # Avaliar pureza: % de ALTO/BAIXO em cada cluster
  message("\nPureza dos clusters:")
  dados_cluster |>
    count(CLUSTER, CATEGORIA_DESEMPENHO) |>
    group_by(CLUSTER) |>
    mutate(PCT = round(100 * n / sum(n), 1)) |>
    ungroup() |>
    arrange(CLUSTER) |>
    print(n = Inf, width = Inf)

  # ---- PASSO 4: Painel — Dendrograma ----
  lab_cores <- dados_cluster |>
    transmute(
      label = sprintf("Esc.%d", ID_ESCOLA),
      cor   = if_else(CATEGORIA_DESEMPENHO == "ALTO", COR_ALTO, COR_BAIXO)
    )

  altura_corte <- sort(hc$height, decreasing = TRUE)[N_CLUSTERS]
  y_max_g      <- max(hc$height)

  # Legenda posicionada no canto DIREITO (longe das folhas que ficam na esquerda)
  x_leg <- nrow(dados_cluster) - 1.5

  p_dend_g <- painel_dendrograma(
    hc,
    lab_cores = lab_cores,
    y_expand  = 0.18,
    titulo    = paste0(
      "Dendrograma Geral — Escolas ALTO e BAIXO Desempenho",
      "  (amostra: ", nrow(dados_cluster), " de ", nrow(dados_modo1), ")"
    ),
    subtitulo = paste0(
      "Variaveis: ", paste(vars_ok, collapse = ", "),
      "  |  Metodo: Ward.D2  |  Corte: ", N_CLUSTERS, " clusters",
      "  |  N_MAX por grupo: ", N_MAX_POR_GRUPO
    )
  ) +
    geom_hline(yintercept = altura_corte,
               linetype = "dashed", colour = COR_CORTE, linewidth = 0.8) +
    annotate("text", x = x_leg, y = altura_corte * 1.04,
             label = paste0("Corte: ", N_CLUSTERS, " clusters"),
             hjust = 1, size = 2.8, colour = COR_CORTE, fontface = "italic") +
    # Legenda — canto superior direito
    annotate("point", x = x_leg, y = y_max_g * 0.97,
             colour = COR_ALTO, size = 3.5) +
    annotate("text",  x = x_leg - 0.3, y = y_max_g * 0.97,
             label = paste0("ALTO (n=", sum(dados_cluster$CATEGORIA_DESEMPENHO == "ALTO"), ")"),
             hjust = 1, size = 3, colour = COR_ALTO, fontface = "bold") +
    annotate("point", x = x_leg, y = y_max_g * 0.90,
             colour = COR_BAIXO, size = 3.5) +
    annotate("text",  x = x_leg - 0.3, y = y_max_g * 0.90,
             label = paste0("BAIXO (n=", sum(dados_cluster$CATEGORIA_DESEMPENHO == "BAIXO"), ")"),
             hjust = 1, size = 3, colour = COR_BAIXO, fontface = "bold")

  # ---- PASSO 5: Painel — Scatter MT x LP (usa TODA a amostra limpa) ----
  # Limites de eixo excluindo outliers residuais (99.5 percentil)
  lp_max <- quantile(dados_modo1$MEDIA_LP, 0.995, na.rm = TRUE)
  mt_max <- quantile(dados_modo1$MEDIA_MT, 0.995, na.rm = TRUE)

  p_scatter_g <- ggplot(dados_modo1,
                        aes(x = MEDIA_MT, y = MEDIA_LP,
                            colour = CATEGORIA_DESEMPENHO,
                            shape  = TIPO_ESCOLA)) +
    geom_point(aes(size = INSE_MEDIO), alpha = 0.72) +
    coord_cartesian(xlim = c(0, mt_max * 1.05),
                    ylim = c(0, lp_max * 1.05)) +
    scale_colour_manual(values = c("ALTO" = COR_ALTO, "BAIXO" = COR_BAIXO),
                        name = "Desempenho") +
    scale_shape_manual(values = c("Publica" = 16, "Privada" = 17, "Pública" = 16),
                       name = "Tipo") +
    scale_size_continuous(range = c(1.5, 6), name = "INSE") +
    labs(
      title    = paste0("Validacao: MT x LP  (todas as escolas limpas, n = ",
                        nrow(dados_modo1), ")"),
      subtitle = "Cor = Desempenho  |  Forma = Tipo de escola  |  Tamanho = INSE",
      x = "Proficiencia MT", y = "Proficiencia LP"
    ) +
    tema_saeb(base_size = 10) +
    theme(legend.position = "right")

  # ---- PASSO 6: Composicao e salvamento ----
  final_g <- p_dend_g / p_scatter_g +
    plot_layout(heights = c(2.5, 1)) +
    plot_annotation(
      caption = paste0(
        "Percentil ALTO >= ", PERCENTIL_ALTO * 100, "%  (>= ", round(q_alto, 1), ")",
        "  |  Percentil BAIXO <= ", PERCENTIL_BAIXO * 100, "%  (<= ", round(q_baixo, 1), ")",
        if (REMOVER_OUTLIERS_LP) paste0("  |  Outliers LP removidos (fora de ±3dp: ",
                                        round(lim_inf, 1), " a ", round(lim_sup, 1), ")") else "",
        "\nGerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M")
      ),
      theme = theme(
        plot.caption    = element_text(size = 7.5, colour = "#888888", hjust = 0),
        plot.background = element_rect(fill = COR_FUNDO, colour = NA)
      )
    )

  nome_fig <- paste0("dendrograma_geral_ALTO_BAIXO_", ts_global, ".png")
  ggsave(file.path(DIR_FIGURAS, nome_fig), final_g,
         width = 16, height = 11, dpi = 180, bg = COR_FUNDO)
  message("Figura salva: ", nome_fig)

  # ---- PASSO 7: Tabela resumo ----
  tabela_resumo <- dados_cluster |>
    arrange(CLUSTER, desc(MEDIA_MT)) |>
    select(ID_ESCOLA, TIPO_ESCOLA, AREA, LOCALIZACAO,
           CATEGORIA_DESEMPENHO, CLUSTER,
           MEDIA_MT, MEDIA_LP, INSE_MEDIO) |>
    mutate(across(c(MEDIA_MT, MEDIA_LP, INSE_MEDIO), ~ round(., 2)))

  write_csv(tabela_resumo,
            file.path(DIR_FIGURAS,
                      paste0("tabela_escolas_ALTO_BAIXO_", ts_global, ".csv")))

  message("\nResumo por cluster:")
  tabela_resumo |>
    group_by(CLUSTER, CATEGORIA_DESEMPENHO) |>
    summarise(N = n(), MT = round(mean(MEDIA_MT), 1),
              LP = round(mean(MEDIA_LP), 1),
              INSE = round(mean(INSE_MEDIO), 2), .groups = "drop") |>
    arrange(CLUSTER) |>
    print(width = Inf)
}

# =============================================================================
# FIM
# =============================================================================

message("\n", strrep("=", 70))
message("CONCLUIDO. Saida: ", DIR_FIGURAS)
message(strrep("=", 70))