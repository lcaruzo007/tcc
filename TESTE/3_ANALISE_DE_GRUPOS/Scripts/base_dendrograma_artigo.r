################################################################################
# BASE: base_dendrograma.r
#
# FUNCOES COMPARTILHADAS entre os scripts de dendrograma comparativo:
#   - dendrograma_capital_vs_interior.r
#   - dendrograma_urbana_vs_rural.r
#   - dendrograma_publica_vs_particular.r
#
# NAO execute diretamente. Use source("base_dendrograma.r") nos scripts acima.
#
# VERSAO: 1.0 — Mai 2026
################################################################################

library(tidyverse)
library(ggdendro)
library(patchwork)

# =============================================================================
# DETECCAO AUTOMATICA DE CAMINHOS
# =============================================================================

detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("✓ Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  message("⚠️  Pasta 'TESTE' nao encontrada automaticamente.")
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho nao selecionado.")
    message("✓ Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Execute no RStudio ou terminal interativo.")
  }
}

# Retorna o arquivo mais recente que bate com o padrao
arquivo_mais_recente <- function(pasta, padrao) {
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE)
  if (length(arqs) == 0L) return(NULL)
  arqs[which.max(file.info(arqs)$mtime)]
}

# =============================================================================
# CORES GLOBAIS
# =============================================================================

COR_FUNDO  <- "#F8F9FA"
COR_CORTE  <- "#7B2D8B"
COR_GRUPO1 <- "#1B4F9A"   # primeiro grupo (Capital / Urbana / Publica)
COR_GRUPO2 <- "#D62728"   # segundo grupo  (Interior / Rural / Privada)

# =============================================================================
# TEMA BASE
# =============================================================================

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

# =============================================================================
# PAINEL: DENDROGRAMA
# =============================================================================
#
# hc           — objeto hclust
# lab_cores    — tibble com colunas (label, cor)  — uma linha por folha
# y_expand     — espaco inferior para labels (default 0.30)
# titulo       — string para plot title
# subtitulo    — string para plot subtitle
# annot_texto  — texto da anotacao no topo (distancia, corte, etc.)
# altura_corte — valor numerico para linha tracejada horizontal (opcional)
# legenda_df   — tibble (cor, label) para legenda manual no canto (opcional)
# prof_labels  — tibble (label, prof) para linha de proficiencia abaixo do nome
# =============================================================================

painel_dendrograma <- function(hc,
                                lab_cores,
                                y_expand     = 0.42,
                                titulo       = "",
                                subtitulo    = "",
                                annot_texto  = NULL,
                                altura_corte = NULL,
                                legenda_df   = NULL,
                                prof_labels  = NULL) {

  dend_data <- dendro_data(hc, type = "rectangle")
  seg       <- dend_data$segments
  lab       <- dend_data$labels |> left_join(lab_cores, by = "label")

  y_max   <- max(seg$y, na.rm = TRUE)
  y_label <- -0.03 * y_max
  y_prof  <- if (!is.null(prof_labels)) -0.30 * y_max else NULL

  p <- ggplot() +
    geom_segment(data = seg,
                 aes(x = x, y = y, xend = xend, yend = yend),
                 colour = "#4A4A4A", linewidth = 1.3, lineend = "round") +
    geom_point(data = lab,
               aes(x = x, y = 0, colour = cor),
               size = 4.6, shape = 19) +
    geom_text(data = lab,
              aes(x = x, y = y_label, label = label, colour = cor),
              size = 4.0, fontface = "bold", angle = 90, hjust = 1, vjust = 0.5, lineheight = 0.9) +
    scale_colour_identity() +
    scale_y_continuous(
      expand = expansion(mult = c(y_expand, 0.07)),
      name   = "Distancia Euclidiana (Ward.D2)"
    ) +
    scale_x_continuous(expand = expansion(mult = c(0.02, 0.18))) +
    labs(title = titulo, subtitle = subtitulo) +
    tema_saeb(base_size = 15) +
    theme(
      axis.title.x       = element_blank(),
      axis.text.x        = element_blank(),
      axis.ticks.x       = element_blank(),
      axis.text.y        = element_text(size = 13),
      axis.title.y       = element_text(size = 14, margin = margin(r = 8)),
      panel.grid.major.x = element_blank()
    )

  # Linha de proficiencia abaixo do nome (Modo par)
  if (!is.null(prof_labels) && !is.null(y_prof)) {
    lab_prof <- lab |> left_join(prof_labels, by = "label")
    p <- p +
      geom_text(data = lab_prof,
                aes(x = x, y = y_prof, label = prof, colour = cor),
                size = 2.9, fontface = "italic", hjust = 0.5)
  }

  # Linha de corte horizontal
  if (!is.null(altura_corte)) {
    p <- p +
      geom_hline(yintercept = altura_corte,
                 linetype = "dashed", colour = COR_CORTE, linewidth = 1.3)
  }

  # Anotacao no topo (distancia / corte)
  if (!is.null(annot_texto)) {
    p <- p +
      annotate("text",
               x = mean(range(lab$x)), y = y_max * 1.03,
               label    = annot_texto,
               size     = 4.2, colour = COR_CORTE,
               fontface = "bold.italic", hjust = 0.5)
  }

  # Legenda manual (tibble com colunas cor e rotulo)
  if (!is.null(legenda_df)) {
    n_leg    <- nrow(legenda_df)
    largura_rotulo <- max(nchar(legenda_df$rotulo)) * 0.22
    x_leg <- max(lab$x) + 1.5
    y_start  <- y_max * 0.97
    y_step   <- y_max * 0.09

    p <- p +
      annotate("rect",
               xmin = x_leg - 0.5,
               xmax = x_leg + 0.8 + largura_rotulo,
               ymin = y_start - (n_leg - 1) * y_step - y_step * 0.65,
               ymax = y_start + y_step * 0.65,
               fill = "#FFFFFF", colour = "#AAAAAA", linewidth = 0.6, alpha = 0.97)

    for (i in seq_len(n_leg)) {
      p <- p +
        annotate("point", x = x_leg, y = y_start - (i - 1) * y_step,
                 colour = legenda_df$cor[i], size = 4.6) +
        annotate("text",  x = x_leg + 0.45, y = y_start - (i - 1) * y_step,
                 label    = legenda_df$rotulo[i],
                 hjust    = 0, size = 4.2,
                 colour   = legenda_df$cor[i], fontface = "bold")
    }
  }

  p
}

# =============================================================================
# PAINEL: ESTATISTICAS DO GRUPO (lateral direita)
# =============================================================================
#
# resumo_grupos — tibble com colunas:
#   GRUPO, N, MT_medio, MT_dp, LP_medio, LP_dp, INSE_medio, INSE_dp
#   cor_grupo
# titulo        — string
# =============================================================================

painel_estatisticas <- function(resumo_grupos, titulo = "Estatisticas por Grupo") {

  n_grupos <- nrow(resumo_grupos)

  # Montar linhas de texto para cada grupo
  linhas <- purrr::map(seq_len(n_grupos), function(i) {
    g <- resumo_grupos[i, ]
    list(
      grupo = g$GRUPO,
      cor   = g$cor_grupo,
      linhas_txt = c(
        sprintf("n = %d escolas", g$N),
        sprintf("MT: %.1f  (dp ±%.1f)", g$MT_medio,   g$MT_dp),
        sprintf("LP: %.1f  (dp ±%.1f)", g$LP_medio,   g$LP_dp),
        sprintf("INSE: %.2f  (dp ±%.2f)", g$INSE_medio, g$INSE_dp)
      )
    )
  })

  # Calcular posicoes y
  linhas_por_grupo <- 5L   # titulo do grupo + 4 linhas de stats + espaco
  total_linhas     <- n_grupos * linhas_por_grupo + 2L

  df_plot <- purrr::imap_dfr(linhas, function(grp, i_grp) {
    y_base <- total_linhas - (i_grp - 1L) * linhas_por_grupo
    # titulo do grupo
    r_titulo <- tibble(x = 0.5, y = y_base,
                       txt = grp$grupo, cor = grp$cor,
                       bold = TRUE, size = 4.0)
    # linhas de stats
    r_stats <- tibble(
      x    = 0.7,
      y    = y_base - seq_along(grp$linhas_txt),
      txt  = grp$linhas_txt,
      cor  = "#333333",
      bold = FALSE,
      size = 3.1
    )
    bind_rows(r_titulo, r_stats)
  })

  # Linha de separador entre grupos
  y_seps <- total_linhas - seq_len(n_grupos - 1L) * linhas_por_grupo - 0.4

  p <- ggplot(df_plot) +
    # Cabecalho
    annotate("rect", xmin = 0, xmax = 10,
             ymin = total_linhas + 0.4, ymax = total_linhas + 1.5,
             fill = "#1F3864", colour = NA) +
    annotate("text", x = 5, y = total_linhas + 0.95,
             label = titulo, hjust = 0.5, size = 3.5,
             fontface = "bold", colour = "white") +
    # Fundo zebrado por grupo
    {
      purrr::imap(linhas, function(grp, i_grp) {
        y_base <- total_linhas - (i_grp - 1L) * linhas_por_grupo
        list(
          annotate("rect", xmin = 0, xmax = 10,
                   ymin  = y_base - linhas_por_grupo + 0.6,
                   ymax  = y_base + 0.5,
                   fill  = if (i_grp %% 2 == 0) "#EEF2F7" else "#FFFFFF",
                   colour = NA),
          annotate("segment", x = 0.2, xend = 0.2,
                   y = y_base - linhas_por_grupo + 0.8,
                   yend = y_base + 0.4,
                   colour = grp$cor, linewidth = 3)
        )
      })
    } +
    # Linhas de separacao
    {
      if (length(y_seps) > 0)
        geom_hline(yintercept = y_seps,
                   colour = "#CCCCCC", linewidth = 0.5, linetype = "dashed")
    } +
    # Texto
    geom_text(aes(x = x, y = y, label = txt, colour = cor,
                  fontface = if_else(bold, "bold", "plain"),
                  size = size),
              hjust = 0, show.legend = FALSE) +
    scale_colour_identity() +
    scale_size_identity() +
    scale_x_continuous(limits = c(0, 10), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, total_linhas + 2), expand = c(0, 0)) +
    theme_void() +
    theme(
      plot.title      = element_text(face = "bold", size = 12,
                                     colour = "#1A1A1A", margin = margin(b = 6)),
      plot.background = element_rect(fill = COR_FUNDO, colour = NA),
      plot.margin     = margin(16, 8, 8, 4)
    )

  p
}

# =============================================================================
# PAINEL: SCATTER VALIDADOR
# =============================================================================
#
# dados       — tibble com ID_ESCOLA, MEDIA_MT, MEDIA_LP, INSE_MEDIO, GRUPO, cor_grupo
# var_forma   — string: coluna para shape (ex. "TIPO_ESCOLA")
# =============================================================================

painel_scatter <- function(dados,
                            var_forma  = NULL,
                            titulo     = "Validacao: Proficiencia MT x LP",
                            subtitulo  = "Cor = grupo comparado  |  Tamanho = INSE") {

  p <- ggplot(dados, aes(x = MEDIA_MT, y = MEDIA_LP, colour = cor_grupo)) +
    geom_point(aes(size = INSE_MEDIO), alpha = 0.82, shape = 19) +
    scale_colour_identity() +
    scale_size_continuous(range = c(2, 8), name = "INSE") +
    labs(title = titulo, subtitle = subtitulo,
         x = "Proficiencia MT", y = "Proficiencia LP") +
    tema_saeb(base_size = 10) +
    theme(
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.box = "vertical",
      legend.key.size = grid::unit(0.4, "cm"),
      legend.margin = margin(t = 4, b = 0, unit = "pt")
    )

  # Forma diferente por tipo de escola (se informado)
  if (!is.null(var_forma) && var_forma %in% names(dados)) {
    formas <- c(16, 17, 15, 18, 8)
    niveis <- unique(dados[[var_forma]])
    mapa   <- setNames(formas[seq_along(niveis)], niveis)
    p <- p +
      aes(shape = .data[[var_forma]]) +
      scale_shape_manual(values = mapa, name = var_forma)
  }

  p
}

# =============================================================================
# FUNCAO PRINCIPAL: GERAR E SALVAR FIGURA COMPLETA
# =============================================================================
#
# Recebe os dois paineis ja construidos (dend + stats) + scatter
# e compoe o layout final:
#
#   [ dendrograma  |  estatisticas ]
#   [     scatter (largura total)  ]
#
# =============================================================================

salvar_figura_completa <- function(p_dend,
                                    p_stats,
                                    p_scatter,
                                    dir_saida,
                                    nome_arquivo,
                                    caption_txt = "") {

  dir.create(dir_saida, showWarnings = FALSE, recursive = TRUE)

  topo   <- p_dend + p_stats + plot_layout(widths = c(2, 1))
  final  <- topo / p_scatter +
    plot_layout(heights = c(2.2, 1)) +
    plot_annotation(
      caption = caption_txt,
      theme   = theme(
        plot.caption    = element_text(size = 7.5, colour = "#888888", hjust = 0),
        plot.background = element_rect(fill = COR_FUNDO, colour = NA)
      )
    )

  n_folhas <- nrow(p_dend$layers[[2]]$data)
  largura  <- max(16, n_folhas * 0.6)

  caminho <- file.path(dir_saida, nome_arquivo)
  ggsave(caminho, final, width = largura, height = 11, dpi = 180, bg = COR_FUNDO)
  message("✓ Figura salva: ", nome_arquivo)
  invisible(caminho)
}

# =============================================================================
# CARREGAR METADADOS (funcao auxiliar para os 3 scripts)
# =============================================================================

carregar_metadados <- function(dir_processados) {
  arq <- arquivo_mais_recente(dir_processados, "^metadados_escolas_.*\\.csv$")
  if (is.null(arq)) {
    stop("metadados_escolas_*.csv nao encontrado em: ", dir_processados,
         "\nExecute classificar_escolas.r primeiro.")
  }
  message("Metadados: ", basename(arq))
  df <- read_csv(arq, show_col_types = FALSE)
  message("Escolas carregadas: ", nrow(df))
  df
}

message("✓ base_dendrograma.r carregado.")