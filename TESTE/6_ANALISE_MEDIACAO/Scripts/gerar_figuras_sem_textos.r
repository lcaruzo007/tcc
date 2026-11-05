################################################################################
# SCRIPT: gerar_figuras_sem_textos.r
# ENTRADA: Objetos de mediacao salvos pelo passo 10.
# SAIDA: Diagramas somente com caixas, setas e coeficientes em figuras/sem_textos.
# VERSAO: 1.0 - Novembro 2026
################################################################################

library(tidyverse)

detectar_raiz <- function() {
  pasta <- normalizePath(getwd(), winslash = "/")
  while (pasta != dirname(pasta)) {
    if (dir.exists(file.path(pasta, "TESTE"))) return(pasta)
    pasta <- dirname(pasta)
  }
  stop("Nao foi possivel detectar a raiz do projeto.")
}

RAIZ <- detectar_raiz()
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))
DIR_BASE <- file.path(RAIZ, "TESTE", "6_ANALISE_MEDIACAO")
if (!exists("arquivo_modelos_mediacao", inherits = FALSE)) {
  arquivo_modelos_mediacao <- encontrar_arquivo_mais_recente(
    file.path(DIR_BASE, "outputs"), "objetos_mediacao", "modelos", ext = "rds"
  )
}
if (is.null(arquivo_modelos_mediacao)) stop("Execute analise_mediacao.r antes de gerar as figuras.")
objetos <- readRDS(arquivo_modelos_mediacao)
message("Modelos utilizados: ", arquivo_modelos_mediacao)

criar_diagrama_sem_textos <- function(estimativa, grupo, referencia, disciplina,
                                      tipo = NULL) {
  tratamento <- estimativa$treat
  rotulo <- paste0(grupo, " (1)\n", referencia, " (0)",
                   if (!is.null(tipo)) paste0("\n", tipo) else "")
  caixas <- tibble(
    x = c(0, 3, 6),
    label = c(rotulo, "INSE_MEDIO", paste0("Proficiencia\n", disciplina))
  )
  ggplot() +
    geom_rect(data = caixas,
              aes(xmin = x - 1.1, xmax = x + 1.1, ymin = 0.6, ymax = 1.6),
              fill = c("#3498DB", "#F39C12", "#27AE60"),
              alpha = 0.8, color = "#333333", linewidth = 0.8) +
    geom_text(data = caixas, aes(x = x, y = 1.1, label = label),
              size = 4.5, fontface = "bold", color = "white") +
    annotate("segment", x = c(1.1, 4.1), xend = c(1.9, 4.9),
             y = 1.2, yend = 1.2, color = "#E74C3C", linewidth = 1.2,
             arrow = grid::arrow(length = grid::unit(0.25, "cm"))) +
    annotate("text", x = c(1.5, 4.5), y = 1.75,
             label = c(paste0("a = ", round(coef(estimativa$model.m)[tratamento], 3)),
                       paste0("b = ", round(coef(estimativa$model.y)["INSE_MEDIO"], 3))),
             size = 4, fontface = "bold", color = "#E74C3C") +
    annotate("segment", x = 0, xend = 6, y = 0.3, yend = 0.3,
             color = "#3498DB", linewidth = 1, linetype = "dashed",
             arrow = grid::arrow(length = grid::unit(0.25, "cm"))) +
    annotate("text", x = 3, y = 0.05,
             label = paste0("c' = ", round(coef(estimativa$model.y)[tratamento], 3)),
             size = 4, fontface = "bold", color = "#3498DB") +
    theme_void() +
    theme(plot.margin = margin(8, 8, 8, 8)) +
    coord_cartesian(xlim = c(-1.3, 7.3), ylim = c(-0.1, 1.95), expand = FALSE)
}

ordem_area <- c("URBANA_INTERIOR_PUBLICA", "URBANA_INTERIOR_PRIVADA",
                 "RURAL_VS_URBANA_INTERIOR", "RURAL_INTERIOR",
                 "RURAL_CAPITAL", "URBANA_INTERIOR")
contrastes <- c("TIPO_PRIVADA", ordem_area[ordem_area %in% names(objetos$area_MT)])
numero <- 18L
for (contraste in contrastes) {
  grupo <- if (contraste == "TIPO_PRIVADA") "Privada" else if (
    startsWith(contraste, "RURAL")
  ) {
    if (contraste == "RURAL_CAPITAL") "Rural_Capital" else "Rural_Interior"
  } else "Urbana_Interior"
  referencia <- if (contraste == "TIPO_PRIVADA") "Publica" else if (
    contraste == "RURAL_VS_URBANA_INTERIOR"
  ) "Urbana_Interior" else "Urbana_Capital"
  tipo <- switch(contraste, URBANA_INTERIOR_PUBLICA = "Publica",
                  URBANA_INTERIOR_PRIVADA = "Privada", NULL)
  for (disciplina in c("MT", "LP")) {
    estimativa <- if (contraste == "TIPO_PRIVADA") {
      objetos[[paste0("tipo_", disciplina)]]
    } else {
      objetos[[paste0("area_", disciplina)]][[contraste]]
    }
    if (is.null(estimativa)) stop("Modelo ausente: ", contraste, " / ", disciplina)
    plot <- criar_diagrama_sem_textos(
      estimativa, grupo, referencia,
      if (disciplina == "MT") "Matematica" else "Lingua Portuguesa", tipo
    )
    caminho <- caminho_saida(
      DIR_BASE, file.path("figuras", "sem_textos"),
      paste0("figura_", numero, "_", contraste, "_", disciplina), "png"
    )
    ggsave(caminho, plot = plot, width = 12, height = 3.4,
           dpi = DPI_PADRAO, bg = "white")
    message("OK ", caminho)
    numero <- numero + 1L
  }
}
