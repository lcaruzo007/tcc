################################################################################
# SCRIPT AUXILIAR: grafico_coeficientes_referencia_oposta.r
#
# Gera o grafico de coeficientes TCC com a referencia OPOSTA do modelo principal.
#
# Referencias deste grafico (oposta ao modelo principal):
#   TIPO_ESCOLA = "Privada"
#   AREA_LOCAL  = "Rural_Interior"
#
# O modelo principal usa TIPO_ESCOLA = "Publica" e AREA_LOCAL = "Urbana_Capital".
# Este script auxiliar gera o mesmo grafico invertendo a referencia, para mostrar
# os coeficientes sob a perspectiva oposta.
#
# Entrada: base_escolas_agregada_<ts>.csv (gerada pelo script principal)
#          - procurada em subpastas datadas (outputs/<YYYY-MM-DD>/tabelas/)
#            com fallback para o padrao antigo (outputs/tabelas/)
# Saida:
#   outputs/<YYYY-MM-DD>/figuras/coeficientes_TCC_color_referencia_oposta_<HHMMSS>.png
#   outputs/<YYYY-MM-DD>/figuras/coeficientes_TCC_PB_referencia_oposta_<HHMMSS>.png
#   outputs/<YYYY-MM-DD>/tabelas/coeficientes_referencia_oposta_MT_<HHMMSS>.csv
#   outputs/<YYYY-MM-DD>/tabelas/coeficientes_referencia_oposta_LP_<HHMMSS>.csv
################################################################################

library(tidyverse)

# == Caminhos (deteccao automatica) ============================================
# Bootstrap local (utils_saeb.r tambem define detectar_raiz; sourced abaixo)
detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("OK Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho nao selecionado.")
    message("OK Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Nao foi possivel detectar o caminho automaticamente.")
  }
}

RAIZ <- detectar_raiz()
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))
DIR_BASE     <- file.path(RAIZ, "TESTE", "4_REGRESSAO_LINEAR")
DIR_OUTPUTS  <- file.path(DIR_BASE, "outputs")

# Localiza a base agregada mais recente (subpastas datadas ou padrao antigo)
arquivo_base <- encontrar_arquivo_mais_recente(DIR_OUTPUTS, "base_escolas_agregada", "tabelas")
if (is.null(arquivo_base)) {
  stop("Base agregada (base_escolas_agregada_*.csv) nao encontrada em ",
       DIR_OUTPUTS, ". Rode regressao_linear_multipla.r antes deste script.")
}
message("Usando base: ", arquivo_base)

dados_escola <- read_csv(arquivo_base, show_col_types = FALSE)
message("Escolas carregadas: ", nrow(dados_escola))

# Referencias opostas ao modelo principal
# Modelo principal: Publica + Urbana_Capital
# Este script:       Privada + Rural_Interior
refs_oposta <- list(
  TIPO_ESCOLA = "Privada",
  AREA_LOCAL  = "Rural_Interior"
)

# == Funcao: criar dummies com referencia especifica ==========================
criar_dummies_ref <- function(df, vars_cat, refs) {
  for (var in vars_cat) {
    valores <- sort(unique(na.omit(df[[var]])))
    ref <- refs[[var]]
    if (!(ref %in% valores)) stop("Referencia '", ref, "' nao encontrada em ", var)
    for (valor in valores[valores != ref]) {
      nome <- paste0(var, "_", valor)
      df[[nome]] <- as.integer(df[[var]] == valor)
    }
  }
  df
}

# Limpeza minima
vars_cat <- c("TIPO_ESCOLA", "AREA_LOCAL")
for (var in vars_cat) {
  dados_escola <- dados_escola[!is.na(dados_escola[[var]]), ]
}

# Normaliza INSE (z-score)
dados_escola$INSE_MEDIO_norm <- as.numeric(scale(dados_escola$INSE_MEDIO))

# Criar dummies
dados_modelo <- criar_dummies_ref(dados_escola, vars_cat, refs_oposta)

# Preditoras: dummies de AREA_LOCAL + TIPO_ESCOLA + INSE normalizado
preditoras <- names(dados_modelo)[
  grepl("^(TIPO_ESCOLA_|AREA_LOCAL_)", names(dados_modelo)) |
  names(dados_modelo) == "INSE_MEDIO_norm"
]
preditoras <- setdiff(preditoras, vars_cat)

message("Preditoras: ", paste(preditoras, collapse = ", "))

# == Ajustar modelos ==========================================================
formula_mt <- as.formula(paste("MEDIA_MT ~", paste(preditoras, collapse = " + ")))
formula_lp <- as.formula(paste("MEDIA_LP ~", paste(preditoras, collapse = " + ")))

modelo_mt <- lm(formula_mt, data = dados_modelo)
modelo_lp <- lm(formula_lp, data = dados_modelo)

summary_mt <- summary(modelo_mt)
summary_lp <- summary(modelo_lp)

# == Extrair coeficientes ====================================================
formatar_pvalor <- function(p) {
  ifelse(p < 0.001, "***", ifelse(p < 0.01, "**", ifelse(p < 0.05, "*", "")))
}
extrair_coef <- function(modelo) {
  broom::tidy(modelo) |>
    mutate(
      Sig      = formatar_pvalor(p.value),
      IC_lower = estimate - 1.96 * std.error,
      IC_upper = estimate + 1.96 * std.error
    ) |>
    select(
      Termo    = term,
      Coef     = estimate,
      SE       = std.error,
      t_value  = statistic,
      p_valor  = p.value,
      Sig,
      IC_95_inf = IC_lower,
      IC_95_sup = IC_upper
    )
}
coef_mt <- extrair_coef(modelo_mt)
coef_lp <- extrair_coef(modelo_lp)

write_csv(coef_mt, caminho_saida(DIR_BASE, "tabelas",
                                 "coeficientes_referencia_oposta_MT", "csv"))
write_csv(coef_lp, caminho_saida(DIR_BASE, "tabelas",
                                 "coeficientes_referencia_oposta_LP", "csv"))

# == Preparar dados do grafico ================================================
n_escolas <- nrow(dados_modelo)
r2_mt <- round(summary_mt$adj.r.squared * 100, 1)
r2_lp <- round(summary_lp$adj.r.squared * 100, 1)

comparacao_simetrica <- bind_rows(
  coef_mt |> mutate(Modelo = "Matematica (MT)"),
  coef_lp |> mutate(Modelo = "Lingua Portuguesa (LP)")
) |>
  filter(Termo != "(Intercept)") |>
  mutate(
    Variavel = case_when(
      grepl("^TIPO_ESCOLA_",     Termo) ~ paste0("Tipo de escola\n",
                                                 sub("^TIPO_ESCOLA_", "", Termo)),
      grepl("^AREA_LOCAL_",       Termo) ~ paste0("Localizacao combinada\n",
                                                 sub("^AREA_LOCAL_", "", Termo)),
      Termo == "INSE_MEDIO_norm"        ~ "Nivel socioeconomico\n(INSE +1 desvio-padrao)",
      TRUE ~ Termo
    ),
    Variavel = factor(Variavel, levels = c(
      "Localizacao combinada\nRural_Capital",
      "Localizacao combinada\nUrbana_Capital",
      "Localizacao combinada\nUrbana_Interior",
      "Tipo de escola\nPublica",
      "Nivel socioeconomico\n(INSE +1 desvio-padrao)"
    ))
  )

message("Termos unicos: ", paste(unique(comparacao_simetrica$Termo), collapse = "; "))
message("Variaveis unicas: ", paste(unique(as.character(comparacao_simetrica$Variavel)), collapse = "; "))
message("Variaveis NA: ", sum(is.na(comparacao_simetrica$Variavel)))

# == Ponto de quebra dinamico do eixo X =======================================
# Calcula intervalo dos dados (coef + IC) e arredonda para o proximo multiplo de 10,
# evitando cortes visuais quando os coeficientes extrapolam o intervalo fixo antigo.
limite_inf <- min(comparacao_simetrica$IC_95_inf, na.rm = TRUE)
limite_sup <- max(comparacao_simetrica$IC_95_sup, na.rm = TRUE)
passo      <- 10
brk_inf    <- floor(limite_inf / passo) * passo
brk_sup    <- ceiling(limite_sup / passo) * passo
breaks_x   <- seq(brk_inf, brk_sup, by = passo)
# Garante inclusao do zero
if (min(breaks_x) > 0)  breaks_x <- c(0, breaks_x)
if (max(breaks_x) < 0)  breaks_x <- c(breaks_x, 0)
message("Faixa do eixo X: [", brk_inf, ", ", brk_sup,
        "]  |  breaks: ", paste(breaks_x, collapse = ", "))

# == Funcao geradora do grafico (colorido ou P&B) =============================
gerar_grafico <- function(colorido = TRUE) {

  if (colorido) {
    cores   <- c("Matematica (MT)" = "#1B6CA8", "Lingua Portuguesa (LP)" = "#C75B2A")
    formas  <- c("Matematica (MT)" = 21,         "Lingua Portuguesa (LP)" = 24)
    fill_ic <- c("Matematica (MT)" = "#1B6CA8", "Lingua Portuguesa (LP)" = "#C75B2A")
  } else {
    cores   <- c("Matematica (MT)" = "#111111", "Lingua Portuguesa (LP)" = "#666666")
    formas  <- c("Matematica (MT)" = 21,         "Lingua Portuguesa (LP)" = 24)
    fill_ic <- c("Matematica (MT)" = "#111111", "Lingua Portuguesa (LP)" = "#666666")
  }

  # Deslocamento dos rotulos: proporcional a faixa (evita sobrepor IC em faixas largas)
  desloc <- round((brk_sup - brk_inf) * 0.02, 1)

  ggplot(comparacao_simetrica,
         aes(y = Variavel, x = Coef, colour = Modelo, shape = Modelo, fill = Modelo)) +

    geom_vline(xintercept = 0, linetype = "dashed", colour = "#999999", linewidth = 0.8) +

    geom_linerange(aes(xmin = IC_95_inf, xmax = IC_95_sup),
                   position = position_dodge(width = 0.55),
                   linewidth = 1.3, alpha = 0.45) +

    geom_point(position = position_dodge(width = 0.55),
               size = 5, stroke = 1.4, colour = "white") +
    geom_point(position = position_dodge(width = 0.55),
               size = 3.8, stroke = 1.4) +

    geom_text(
      aes(label = paste0(ifelse(Coef > 0, "+", ""), round(Coef, 1), Sig),
          x    = ifelse(Coef >= 0, IC_95_sup + desloc, IC_95_inf - desloc),
          colour = Modelo),
      position    = position_dodge(width = 0.55),
      size        = 3.8,
      fontface    = "bold",
      show.legend = FALSE
    ) +

    scale_colour_manual(values = cores) +
    scale_fill_manual(values   = fill_ic) +
    scale_shape_manual(values  = formas) +
    scale_x_continuous(
      breaks = breaks_x,
      labels = function(x) paste0(ifelse(x > 0, "+", ""), x),
      expand = ggplot2::expansion(mult = c(0.12, 0.15))
    ) +

    labs(
      title    = "Determinantes da proficiencia escolar - SAEB 2023 (3º serie EM)",
      subtitle = paste0(
        "Coeficientes da regressao linear multipla com intervalos de confianca 95%\n",
        "Comparado as escolas privadas e rurais do Interior (referencia: Privada_Rural_Interior)"
      ),
      y       = NULL,
      x       = "Coeficiente (pontos de proficiencia SAEB)",
      colour  = "Disciplina:",
      shape   = "Disciplina:",
      fill    = "Disciplina:",
      caption = paste0(
        "N = ", n_escolas, " escolas  |  ",
        "R2 ajustado: Matematica = ", r2_mt, "%  .  Lingua Portuguesa = ", r2_lp, "%\n",
        "*** p<0,001  ** p<0,01  * p<0,05  |  ",
        "IC 95% calculado como Coef +/- 1,96 x EP\n",
        "INSE normalizado (z-score): coeficiente representa o efeito de +1 desvio-padrao ",
        "no nivel socioeconomico medio da escola"
      )
    ) +

    theme_minimal(base_size = 13) +
    theme(
      plot.background   = element_rect(fill = "white", colour = NA),
      panel.background  = element_rect(fill = "white", colour = NA),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = "#E5E5E5", linewidth = 0.4),
      panel.grid.minor   = element_blank(),
      plot.title    = element_text(face = "bold", size = 15, colour = "#1A1A1A",
                                   margin = margin(b = 4)),
      plot.subtitle = element_text(size = 11, colour = "#555555",
                                   lineheight = 1.3, margin = margin(b = 12)),
      plot.caption  = element_text(size = 9, colour = "#777777", face = "italic",
                                   hjust = 0, lineheight = 1.4,
                                   margin = margin(t = 14)),
      axis.text.y  = element_text(size = 11, colour = "#1A1A1A", lineheight = 1.35),
      axis.text.x  = element_text(size = 11, colour = "#555555"),
      axis.title.x = element_text(size = 11, colour = "#333333",
                                  margin = margin(t = 8)),
      legend.position  = "top",
      legend.direction = "horizontal",
      legend.text      = element_text(size = 12),
      legend.title     = element_text(size = 12, face = "bold"),
      legend.key.size  = unit(1.1, "lines"),
      plot.margin = margin(16, 24, 12, 16)
    )
}

# == Salvar versao colorida ==================================================
p_color <- gerar_grafico(colorido = TRUE)
out_color <- caminho_saida(DIR_BASE, "figuras",
                           "coeficientes_TCC_color_referencia_oposta", "png")
ggsave(out_color, p_color, width = 12, height = 7, dpi = 200, bg = "white")
message("Figura salva: ", basename(out_color))

# == Salvar versao P&B =======================================================
p_pb <- gerar_grafico(colorido = FALSE)
out_pb <- caminho_saida(DIR_BASE, "figuras",
                        "coeficientes_TCC_PB_referencia_oposta", "png")
ggsave(out_pb, p_pb, width = 12, height = 7, dpi = 200, bg = "white")
message("Figura salva: ", basename(out_pb))

message("\nConcluido.")