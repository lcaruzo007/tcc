################################################################################
# SCRIPT: dendrograma_duas_escolas.r
#
# OBJETIVO: Gerar dendrograma comparativo entre duas escolas com contexto
#           completo (tipo, area, localizacao, faixa de nota, INSE).
#
# ENTRADA:  metadados_escolas_*.csv (saida de classificar_escolas.r)
#           lista_comparacoes.csv   (opcional — colunas: ID_ESCOLA_A, ID_ESCOLA_B)
#
# SAIDA:
#   - dendrograma_<A>_vs_<B>_<timestamp>.png  (dendrograma + painel de contexto)
#
# VERSAO: 2.0 — Maio 2026
################################################################################

library(tidyverse)
library(ggdendro)    # install.packages("ggdendro")
library(patchwork)   # install.packages("patchwork")

# =============================================================================
# CONFIGURACAO
# =============================================================================

RAIZ            <- "C:/Users/13756596699/tcc"
DIR_PROCESSADOS <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs_escolas")
DIR_FIGURAS     <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/outputs_figuras")

# Arquivo Excel/CSV com os pares a comparar.
# Colunas obrigatorias: ID_ESCOLA_A, ID_ESCOLA_B
# Se NULL, usa os IDs fixos abaixo.
ARQUIVO_PARES <- file.path(RAIZ, "TESTE/3_ANALISE_DE_GRUPOS/lista_comparacoes.csv")

# IDs usados quando ARQUIVO_PARES = NULL ou nao for encontrado
ID_ESCOLA_A_FIXO <- 61432986
ID_ESCOLA_B_FIXO <- 61466120

# Variaveis usadas no clustering (devem existir em metadados_escolas)
VARS_CLUSTER <- c("MEDIA_MT", "MEDIA_LP", "INSE_MEDIO")

# =============================================================================
# FUNCOES AUXILIARES
# =============================================================================

# Retorna descricao textual do contexto de comparacao entre duas escolas
descrever_comparacao <- function(ea, eb) {
  linhas <- character(0)

  # Tipo
  if (!is.na(ea$TIPO_ESCOLA) && !is.na(eb$TIPO_ESCOLA)) {
    if (ea$TIPO_ESCOLA == eb$TIPO_ESCOLA) {
      linhas <- c(linhas, paste0("Tipo: ambas ", ea$TIPO_ESCOLA, "s"))
    } else {
      linhas <- c(linhas, paste0("Tipo: ", ea$TIPO_ESCOLA, " vs ", eb$TIPO_ESCOLA))
    }
  }

  # Area (Capital / Interior)
  if (!is.na(ea$AREA) && !is.na(eb$AREA)) {
    if (ea$AREA == eb$AREA) {
      linhas <- c(linhas, paste0("Area: ambas do ", ea$AREA))
    } else {
      linhas <- c(linhas, paste0("Area: ", ea$AREA, " vs ", eb$AREA))
    }
  }

  # Localizacao (Urbana / Rural)
  if (!is.na(ea$LOCALIZACAO) && !is.na(eb$LOCALIZACAO)) {
    if (ea$LOCALIZACAO == eb$LOCALIZACAO) {
      linhas <- c(linhas, paste0("Localizacao: ambas ", ea$LOCALIZACAO, "s"))
    } else {
      linhas <- c(linhas, paste0("Localizacao: ", ea$LOCALIZACAO, " vs ", eb$LOCALIZACAO))
    }
  }

  # Faixa de nota MT
  if (!is.na(ea$FAIXA_MT) && !is.na(eb$FAIXA_MT)) {
    if (ea$FAIXA_MT == eb$FAIXA_MT) {
      linhas <- c(linhas, paste0("Faixa MT: ambas na ", ea$FAIXA_MT))
    } else {
      linhas <- c(linhas, paste0("Faixa MT: ", ea$FAIXA_MT, " vs ", eb$FAIXA_MT))
    }
  }

  # INSE
  if (!is.na(ea$GRUPO_INSE) && !is.na(eb$GRUPO_INSE)) {
    if (ea$GRUPO_INSE == eb$GRUPO_INSE) {
      linhas <- c(linhas, paste0("INSE: ambas no grupo ", ea$GRUPO_INSE))
    } else {
      linhas <- c(linhas, paste0("INSE: ", ea$GRUPO_INSE, " vs ", eb$GRUPO_INSE))
    }
  }

  paste(linhas, collapse = "\n")
}

# Gera e salva o dendrograma completo para um par de escolas
gerar_dendrograma_par <- function(ea, eb, metadados, dir_saida) {

  id_a  <- ea$ID_ESCOLA
  id_b  <- eb$ID_ESCOLA
  ts    <- format(Sys.time(), "%Y%m%d_%H%M%S")
  label_a <- paste0("Escola A\n(", id_a, ")")
  label_b <- paste0("Escola B\n(", id_b, ")")

  # ------------------------------------------------------------------
  # 1. Clustering (apenas as 2 escolas, todas as vars disponiveis)
  # ------------------------------------------------------------------
  vars_ok <- intersect(VARS_CLUSTER, names(metadados))
  vars_ok <- vars_ok[vars_ok %in% names(ea) & vars_ok %in% names(eb)]
  vars_ok <- vars_ok[!is.na(ea[vars_ok]) & !is.na(eb[vars_ok])]

  if (length(vars_ok) < 2) {
    message("  ! Variaveis insuficientes para o par ", id_a, " vs ", id_b, ". Pulando.")
    return(invisible(NULL))
  }

  mat <- rbind(as.numeric(ea[vars_ok]), as.numeric(eb[vars_ok]))
  mat <- scale(mat)
  rownames(mat) <- c(label_a, label_b)

  dist_mat  <- dist(mat, method = "euclidean")
  hc        <- hclust(dist_mat, method = "ward.D2")
  distancia <- round(as.matrix(dist_mat)[1, 2], 2)

  # ------------------------------------------------------------------
  # 2. Dados do dendrograma para ggplot (via ggdendro)
  # ------------------------------------------------------------------
  dend_data  <- dendro_data(hc, type = "rectangle")
  seg        <- dend_data$segments
  lab        <- dend_data$labels

  # Cor por escola
  cor_a <- "#1B4F9A"
  cor_b <- "#D62728"
  lab <- lab |>
    mutate(cor = if_else(label == label_a, cor_a, cor_b))

  # Proficiencias para exibir no grafico
  prof_a <- paste0(
    "MT: ", round(ea$MEDIA_MT, 1),
    "  |  LP: ", round(ea$MEDIA_LP, 1)
  )
  prof_b <- paste0(
    "MT: ", round(eb$MEDIA_MT, 1),
    "  |  LP: ", round(eb$MEDIA_LP, 1)
  )
  lab <- lab |>
    mutate(prof = if_else(label == label_a, prof_a, prof_b))

  # ------------------------------------------------------------------
  # 3. Painel A — Dendrograma
  # ------------------------------------------------------------------
  contexto <- descrever_comparacao(ea, eb)

  y_max     <- max(seg$y)
  y_label   <- -0.08 * y_max   # posicao do nome da escola
  y_prof    <- -0.22 * y_max   # posicao dos valores de proficiencia (abaixo do nome)

  p_dend <- ggplot() +
    geom_segment(data = seg,
                 aes(x = x, y = y, xend = xend, yend = yend),
                 colour = "#555555", linewidth = 1.2, lineend = "round") +
    geom_point(data = lab,
               aes(x = x, y = 0, colour = cor),
               size = 7, shape = 19) +
    # Nome da escola
    geom_text(data = lab,
              aes(x = x, y = y_label, label = label, colour = cor),
              size = 3.8, fontface = "bold", hjust = 0.5, lineheight = 0.9) +
    # Valores de proficiencia MT e LP
    geom_text(data = lab,
              aes(x = x, y = y_prof, label = prof, colour = cor),
              size = 3.2, fontface = "italic", hjust = 0.5) +
    scale_colour_identity() +
    scale_y_continuous(
      expand = expansion(mult = c(0.32, 0.07)),
      name   = "Distancia Euclidiana (Ward.D2)"
    ) +
    annotate("text",
             x     = mean(range(lab$x)),
             y     = max(seg$y) * 1.02,
             label = paste0("Distancia: ", distancia,
                            if (distancia < 1)   "  |  muito similares"
                            else if (distancia < 2) "  |  moderadamente similares"
                            else                    "  |  bem diferentes"),
             size = 3.5, colour = "#7B2D8B", fontface = "bold.italic", hjust = 0.5) +
    labs(
      title    = paste0("Escola ", id_a, "  vs  Escola ", id_b),
      subtitle = paste0("Variaveis: ", paste(vars_ok, collapse = ", "),
                        "   |   Metodo: Ward.D2")
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title       = element_text(face = "bold", size = 14, colour = "#1A1A1A"),
      plot.subtitle    = element_text(size = 10, colour = "#555555"),
      axis.title.x     = element_blank(),
      axis.text.x      = element_blank(),
      axis.ticks.x     = element_blank(),
      axis.title.y     = element_text(size = 10),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.background  = element_rect(fill = "#F8F9FA", colour = NA),
      panel.background = element_rect(fill = "#FFFFFF", colour = NA),
      plot.margin      = margin(16, 16, 8, 16)
    )

  # ------------------------------------------------------------------
  # 4. Painel B — Ficha comparativa
  # ------------------------------------------------------------------
  campo <- function(label, val_a, val_b, igual = (val_a == val_b)) {
    cor_val <- if (isTRUE(igual)) "#2CA02C" else "#D62728"
    list(label = label, val_a = as.character(val_a),
         val_b = as.character(val_b), cor = cor_val)
  }

  campos <- list(
    campo("Tipo",        ea$TIPO_ESCOLA,  eb$TIPO_ESCOLA),
    campo("Area",        ea$AREA,         eb$AREA),
    campo("Localizacao", ea$LOCALIZACAO,  eb$LOCALIZACAO),
    campo("Faixa MT",    ea$FAIXA_MT,     eb$FAIXA_MT),
    campo("Faixa LP",    ea$FAIXA_LP,     eb$FAIXA_LP),
    campo("INSE grupo",  ea$GRUPO_INSE,   eb$GRUPO_INSE),
    campo("Media MT",
          round(ea$MEDIA_MT, 1), round(eb$MEDIA_MT, 1),
          igual = abs(ea$MEDIA_MT - eb$MEDIA_MT) < 5),
    campo("Media LP",
          round(ea$MEDIA_LP, 1), round(eb$MEDIA_LP, 1),
          igual = abs(ea$MEDIA_LP - eb$MEDIA_LP) < 5),
    campo("INSE medio",
          round(ea$INSE_MEDIO, 2), round(eb$INSE_MEDIO, 2),
          igual = abs(ea$INSE_MEDIO - eb$INSE_MEDIO) < 0.3)
  )

  n    <- length(campos)
  ypos <- seq(n, 1)

  df_ficha <- tibble(
    y       = ypos,
    label   = map_chr(campos, "label"),
    val_a   = map_chr(campos, "val_a"),
    val_b   = map_chr(campos, "val_b"),
    cor_val = map_chr(campos, "cor")
  )

  p_ficha <- ggplot(df_ficha) +
    # fundo zebrado
    geom_rect(aes(xmin = 0, xmax = 10, ymin = y - 0.45, ymax = y + 0.45,
                  fill = y %% 2 == 0),
              show.legend = FALSE) +
    scale_fill_manual(values = c("TRUE" = "#EEF2F7", "FALSE" = "#FFFFFF")) +
    # coluna de label
    geom_text(aes(x = 0.3, y = y, label = label),
              hjust = 0, size = 3.4, fontface = "bold", colour = "#333333") +
    # coluna Escola A
    geom_text(aes(x = 5, y = y, label = val_a),
              hjust = 0.5, size = 3.4, colour = cor_a, fontface = "bold") +
    # coluna Escola B
    geom_text(aes(x = 8.5, y = y, label = val_b),
              hjust = 0.5, size = 3.4, colour = cor_b, fontface = "bold") +
    # indicador de igualdade
    geom_point(aes(x = 9.7, y = y, colour = cor_val), size = 2.5) +
    scale_colour_identity() +
    # cabecalho
    annotate("rect", xmin = 0, xmax = 10, ymin = n + 0.5, ymax = n + 1.3,
             fill = "#1F3864", colour = NA) +
    annotate("text", x = 0.3,  y = n + 0.9, label = "Atributo",
             hjust = 0,   size = 3.5, fontface = "bold", colour = "white") +
    annotate("text", x = 5,    y = n + 0.9, label = paste0("Escola A\n(", id_a, ")"),
             hjust = 0.5, size = 3.2, fontface = "bold", colour = "#AED6F1",
             lineheight = 0.85) +
    annotate("text", x = 8.5,  y = n + 0.9, label = paste0("Escola B\n(", id_b, ")"),
             hjust = 0.5, size = 3.2, fontface = "bold", colour = "#F1948A",
             lineheight = 0.85) +
    # rodape com contexto da comparacao
    annotate("rect", xmin = 0, xmax = 10, ymin = -0.6, ymax = 0.4,
             fill = "#EAF2FF", colour = "#AED6F1", linewidth = 0.5) +
    annotate("text", x = 0.3, y = -0.1,
             label = paste0("Contexto: ", gsub("\n", "  |  ", contexto)),
             hjust = 0, size = 2.9, colour = "#1F3864", fontface = "italic") +
    # legenda de cores
    annotate("point", x = 9.3, y = 0.8, colour = "#2CA02C", size = 2.5) +
    annotate("text",  x = 9.6, y = 0.8, label = "igual", hjust = 1,
             size = 2.6, colour = "#555555") +
    annotate("point", x = 9.3, y = 0.1, colour = "#D62728", size = 2.5) +
    annotate("text",  x = 9.6, y = 0.1, label = "diferente", hjust = 1,
             size = 2.6, colour = "#555555") +
    scale_x_continuous(limits = c(0, 10), expand = c(0, 0)) +
    scale_y_continuous(limits = c(-0.7, n + 1.4), expand = c(0, 0)) +
    labs(title = "Ficha Comparativa") +
    theme_void(base_size = 12) +
    theme(
      plot.title      = element_text(face = "bold", size = 12, colour = "#1A1A1A",
                                     margin = margin(b = 6)),
      plot.background = element_rect(fill = "#F8F9FA", colour = NA),
      plot.margin     = margin(16, 8, 8, 4)
    )

  # ------------------------------------------------------------------
  # 5. Composicao final com patchwork
  # ------------------------------------------------------------------
  final <- p_dend + p_ficha +
    plot_layout(widths = c(1.6, 1)) +
    plot_annotation(
      caption = paste0(
        "Comparacao: ", descrever_comparacao(ea, eb) |> gsub(pattern = "\n", replacement = "  |  "),
        "\nClustering hierarquico — distancia euclidiana, metodo Ward.D2",
        "   |   Gerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M")
      ),
      theme = theme(
        plot.caption    = element_text(size = 8, colour = "#888888", hjust = 0),
        plot.background = element_rect(fill = "#F8F9FA", colour = NA)
      )
    )

  # ------------------------------------------------------------------
  # 6. Salvar
  # ------------------------------------------------------------------
  nome_arquivo <- paste0("dendrograma_", id_a, "_vs_", id_b, "_", ts, ".png")
  caminho      <- file.path(dir_saida, nome_arquivo)

  ggsave(caminho, final, width = 16, height = 8.5, dpi = 180, bg = "#F8F9FA")
  message("  Salvo: ", nome_arquivo)
  invisible(caminho)
}

# =============================================================================
# EXECUCAO PRINCIPAL
# =============================================================================

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)

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

# — Carregar pares —
if (!is.null(ARQUIVO_PARES) && file.exists(ARQUIVO_PARES)) {
  pares <- read_csv(ARQUIVO_PARES, show_col_types = FALSE) |>
    filter(!is.na(ID_ESCOLA_A), !is.na(ID_ESCOLA_B)) |>
    mutate(across(c(ID_ESCOLA_A, ID_ESCOLA_B), as.numeric))
  message("Pares carregados do CSV: ", nrow(pares))
} else {
  pares <- tibble(ID_ESCOLA_A = ID_ESCOLA_A_FIXO,
                  ID_ESCOLA_B = ID_ESCOLA_B_FIXO)
  message("Usando IDs fixos: ", ID_ESCOLA_A_FIXO, " vs ", ID_ESCOLA_B_FIXO)
}

# — Processar cada par —
for (i in seq_len(nrow(pares))) {
  id_a <- pares$ID_ESCOLA_A[i]
  id_b <- pares$ID_ESCOLA_B[i]
  message("\nPar ", i, "/", nrow(pares), ": ", id_a, " vs ", id_b)

  ea <- filter(metadados, ID_ESCOLA == id_a)
  eb <- filter(metadados, ID_ESCOLA == id_b)

  if (nrow(ea) == 0) { message("  ! Escola A (", id_a, ") nao encontrada."); next }
  if (nrow(eb) == 0) { message("  ! Escola B (", id_b, ") nao encontrada."); next }

  gerar_dendrograma_par(ea[1, ], eb[1, ], metadados, DIR_FIGURAS)
}

message("\nConcluido. Figuras salvas em: ", DIR_FIGURAS)