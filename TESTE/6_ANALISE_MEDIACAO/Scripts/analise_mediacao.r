################################################################################
# SCRIPT: analise_mediacao.r
# ENTRADA: Metadados escolares validos do passo 4.
# SAIDA: Mediacao exploratoria, tamanhos de grupos, fluxo de inclusao e figuras.
# VERSAO: 3.0 - Outubro 2026
# Bootstrap percentil: 1000 simulacoes, semente 2023. Sem covariaveis adicionais.
# AREA_LOCAL: cada categoria e comparada somente com Urbana_Capital.
# Diagramas reutilizam os modelos ajustados no respectivo contraste.
# A decomposicao observacional nao identifica efeitos causais por si so.
################################################################################

library(tidyverse)
library(data.table)

# =========================================================================
# CAMINHOS
# =========================================================================

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
  }
  stop("Nao foi possivel detectar o caminho automaticamente.")
}

RAIZ <- detectar_raiz()
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_OUTPUTS_ANALISE <- file.path(DIR_ANALISE, "outputs")

DIR_BASE <- file.path(DIR_TESTE, "6_ANALISE_MEDIACAO")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

ts_global <- format(Sys.time(), "%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSARIOS
# =========================================================================

pacotes_necessarios <- c("mediation", "boot")
pacotes_ausentes <- pacotes_necessarios[
  !vapply(pacotes_necessarios, requireNamespace, logical(1), quietly = TRUE)
]
if (length(pacotes_ausentes) > 0L) {
  stop(
    "Pacotes ausentes: ", paste(pacotes_ausentes, collapse = ", "),
    ". Consulte TESTE/DOCUMENTACAO/requisitos.md."
  )
}

library(mediation)

# =========================================================================
# PASSO 1: CARREGAR DADOS
# =========================================================================

message(strrep("=", 70))
message("ANALISE DE MEDIACAO - INSE como mediador")
message(strrep("=", 70))

arq_meta <- encontrar_arquivo_mais_recente(DIR_OUTPUTS_ANALISE, "metadados_escolas", tipo = "metadados")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv nao encontrado.")

base_mediacao <- read_csv(arq_meta, show_col_types = FALSE)
validar_metadados_saeb(base_mediacao)
fluxo_mediacao <- amostra_escolas_saeb(base_mediacao)
write_csv(fluxo_mediacao, caminho_saida(DIR_BASE, "diagnosticos", "fluxo_amostra_mediacao", "csv"))
metadados <- fluxo_mediacao |>
  filter(Incluida) |>
  filter(!is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO)) %>%
  filter(TIPO_ESCOLA %in% c("Publica", "Privada")) %>%
  filter(AREA_LOCAL %in% c("Urbana_Capital", "Urbana_Interior",
                           "Rural_Capital", "Rural_Interior")) %>%
  mutate(
    TIPO_PRIVADA = as.integer(TIPO_ESCOLA == "Privada"),
    # Dummies de AREA_LOCAL combinada (ref = Urbana_Capital), substituindo o
    # binario LOCAL_RURAL por 3 dummies, captando interacoes Urbano/Rural x
    # Capital/Interior (lacuna apontada na apresentacao do TCC)
    RURAL_INTERIOR  = as.integer(AREA_LOCAL == "Rural_Interior"),
    RURAL_CAPITAL   = as.integer(AREA_LOCAL == "Rural_Capital"),
    URBANA_INTERIOR = as.integer(AREA_LOCAL == "Urbana_Interior")
  )

message("Escolas validas: ", nrow(metadados))

tratamentos_area <- c(
  RURAL_INTERIOR = "Rural_Interior",
  RURAL_CAPITAL = "Rural_Capital",
  URBANA_INTERIOR = "Urbana_Interior"
)
tratamentos_disponiveis <- names(tratamentos_area)[
  vapply(
    names(tratamentos_area),
    function(x) dplyr::n_distinct(metadados[[x]]) == 2L,
    logical(1)
  )
]
tratamentos_ausentes <- setdiff(names(tratamentos_area), tratamentos_disponiveis)
if (length(tratamentos_ausentes) > 0L) {
  message(
    "Tratamentos AREA_LOCAL sem variacao e ignorados: ",
    paste(tratamentos_ausentes, collapse = ", ")
  )
}

set.seed(2023)

# =========================================================================
# PASSO 2: MEDIACAO - TIPO_ESCOLA -> INSE -> PROFICIENCIA
# =========================================================================

message("\n", strrep("-", 50))
message("MEDIACAO 1: TIPO_ESCOLA -> INSE -> PROFICIENCIA")
message(strrep("-", 50))

# --- MATEMATICA ---
# Caminho A: TIPO_ESCOLA -> INSE (mediador)
modelo_a_mt <- lm(INSE_MEDIO ~ TIPO_PRIVADA, data = metadados)

# Caminho B + C': INSE + TIPO_ESCOLA -> PROFICIENCIA
modelo_b_mt <- lm(MEDIA_MT ~ INSE_MEDIO + TIPO_PRIVADA, data = metadados)

# Mediacao com bootstrap
med_tipo_mt <- mediate(modelo_a_mt, modelo_b_mt,
                        treat = "TIPO_PRIVADA", mediator = "INSE_MEDIO",
                        boot = TRUE, sims = 1000)

message("\n>>> Matematica - Mediacao por INSE:")
summary(med_tipo_mt)

# --- LINGUA PORTUGUESA ---
modelo_a_lp <- lm(INSE_MEDIO ~ TIPO_PRIVADA, data = metadados)
modelo_b_lp <- lm(MEDIA_LP ~ INSE_MEDIO + TIPO_PRIVADA, data = metadados)

med_tipo_lp <- mediate(modelo_a_lp, modelo_b_lp,
                        treat = "TIPO_PRIVADA", mediator = "INSE_MEDIO",
                        boot = TRUE, sims = 1000)

message("\n>>> Lingua Portuguesa - Mediacao por INSE:")
summary(med_tipo_lp)

# =========================================================================
# PASSO 3: MEDIACAO - LOCALIZACAO -> INSE -> PROFICIENCIA
# =========================================================================

message("\n", strrep("-", 50))
message("MEDIACAO 2: LOCALIZACAO -> INSE -> PROFICIENCIA")
message(strrep("-", 50))

# Mediacao por dummy observada de AREA_LOCAL (ref: Urbana_Capital)
mediar_area_local <- function(tratamento, resposta, disciplina) {
  dados_contraste <- preparar_contraste_area_saeb(metadados, tratamentos_area[[tratamento]])
  formula_a <- reformulate(tratamento, response = "INSE_MEDIO")
  formula_b <- reformulate(c("INSE_MEDIO", tratamento), response = resposta)
  lm_a <- lm(formula_a, data = dados_contraste)
  lm_b <- lm(formula_b, data = dados_contraste)
  lm_a$call$formula <- formula_a
  lm_b$call$formula <- formula_b
  m <- mediate(lm_a, lm_b, treat = tratamento, mediator = "INSE_MEDIO",
               boot = TRUE, sims = 1000)
  message("\n>>> ", disciplina, " - Mediacao por INSE (",
          tratamento, " vs Urbana_Capital):")
  print(summary(m))
  m
}

med_loc_mt <- setNames(
  lapply(
    tratamentos_disponiveis,
    mediar_area_local,
    resposta = "MEDIA_MT",
    disciplina = "Matematica"
  ),
  tratamentos_disponiveis
)
med_loc_lp <- setNames(
  lapply(
    tratamentos_disponiveis,
    mediar_area_local,
    resposta = "MEDIA_LP",
    disciplina = "Lingua Portuguesa"
  ),
  tratamentos_disponiveis
)

# =========================================================================
# PASSO 4: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

# =========================================================================
# HELPER: extracao segura dos resultados de mediate()
# =========================================================================

extrair_seguro <- function(med_obj, campo) {
  if (is.null(med_obj)) return(NA_real_)
  valor <- med_obj[[campo]]
  if (is.null(valor) || length(valor) == 0 || anyNA(valor)) {
    return(NA_real_)
  }
  as.numeric(valor[1])
}

extrair_ci_seguro <- function(med_obj, campo_ci, posicao) {
  if (is.null(med_obj)) return(NA_real_)
  valor <- med_obj[[campo_ci]]
  if (is.null(valor) || length(valor) == 0 || anyNA(valor)) {
    return(NA_real_)
  }
  as.numeric(valor[posicao])
}

montar_resultado <- function(nome, disciplina, med_obj) {
  tibble(
    Variavel_Independente = nome,
    Mediador = "INSE_MEDIO",
    Disciplina = disciplina,
    N_Escolas = nobs(med_obj$model.y),
    N_Referencia = sum(med_obj$model.y$model[[med_obj$treat]] == 0),
    N_Tratamento = sum(med_obj$model.y$model[[med_obj$treat]] == 1),
    Referencia = if_else(grepl("^AREA_LOCAL", nome), "Urbana_Capital", "Publica"),
    Ajuste = "Sem covariaveis adicionais; exploratorio",
    Efeito_Direto = extrair_seguro(med_obj, "z.avg"),
    IC95_Direto_Inferior = extrair_ci_seguro(med_obj, "z.avg.ci", 1),
    IC95_Direto_Superior = extrair_ci_seguro(med_obj, "z.avg.ci", 2),
    p_Direto = extrair_seguro(med_obj, "z.avg.p"),
    Efeito_Indireto = extrair_seguro(med_obj, "d.avg"),
    IC95_Indireto_Inferior = extrair_ci_seguro(med_obj, "d.avg.ci", 1),
    IC95_Indireto_Superior = extrair_ci_seguro(med_obj, "d.avg.ci", 2),
    p_Indireto = extrair_seguro(med_obj, "d.avg.p"),
    Efeito_Total = extrair_seguro(med_obj, "tau.coef"),
    IC95_Total_Inferior = extrair_ci_seguro(med_obj, "tau.ci", 1),
    IC95_Total_Superior = extrair_ci_seguro(med_obj, "tau.ci", 2),
    IC95_Proporcao_Inferior = 100 * extrair_ci_seguro(med_obj, "n.avg.ci", 1),
    IC95_Proporcao_Superior = 100 * extrair_ci_seguro(med_obj, "n.avg.ci", 2),
    p_Total = extrair_seguro(med_obj, "tau.p"),
    Proporcao_Mediada = 100 * extrair_seguro(med_obj, "n.avg")
  )
}

resultados_mediacao <- bind_rows(
  montar_resultado("Tipo Escola (Privada)", "MT", med_tipo_mt),
  montar_resultado("Tipo Escola (Privada)", "LP", med_tipo_lp),
  map_dfr(tratamentos_disponiveis, function(tratamento) {
    nome <- paste0("AREA_LOCAL: ", tratamentos_area[[tratamento]])
    bind_rows(
      montar_resultado(nome, "MT", med_loc_mt[[tratamento]]),
      montar_resultado(nome, "LP", med_loc_lp[[tratamento]])
    )
  })
) %>%
  mutate(
    across(starts_with("Efeito_"), ~ round(., 3)),
    across(starts_with("IC95_"), ~ round(., 3)),
    Proporcao_Mediada = round(Proporcao_Mediada, 1)
  )

saveRDS(list(tipo_MT = med_tipo_mt, tipo_LP = med_tipo_lp, area_MT = med_loc_mt, area_LP = med_loc_lp),
        caminho_saida(DIR_BASE, "modelos", "objetos_mediacao", "rds"))

write_csv(resultados_mediacao, caminho_saida(DIR_BASE, "tabelas", "mediacao", "csv"))
message("   OK mediacao_", ts_global, ".csv")

# =========================================================================
# PASSO 5: VISUALIZACOES - DIAGRAMA DE CAMINHOS
# =========================================================================

message("\n>>> Gerando figuras...")

# -------------------------------------------------------------------------
# Funcao auxiliar: criar diagrama de caminhos
# -------------------------------------------------------------------------
criar_diagrama_mediacao <- function(var_indep, mediador, disciplina,
                                     efeito_a, efeito_b, efeito_cp,
                                     r2_med, r2_dep, fig_num,
                                     categoria_referencia = NULL,
                                     nome_grupo = NULL) {
  
  # Dados para o diagrama
  dados_diag <- tibble(
    x = c(0, 2, 4),
    y = c(2, 2, 2),
    label = c(var_indep, mediador, paste0("Proficiencia\n", disciplina)),
    tipo = c("independente", "mediador", "dependente")
  )
  
  # Calcular proporcao mediada
  efeito_indireto <- efeito_a * efeito_b
  efeito_total <- efeito_indireto + efeito_cp
  prop_med <- if (abs(efeito_total) > 1e-10) efeito_indireto / efeito_total * 100 else NA_real_
  
  # Deteccao automatica de supressao: c' e a*b com sinais opostos.
  # Nesse caso a "proporcao mediada" pode exceder 100% ou nao ter leitura
  # direta como porcentagem (ver NOTA METODOLOGICA, ponto 5, no cabecalho
  # deste script) - substituimos o rotulo por um aviso em vez do numero.
  houve_supressao <- sign(efeito_cp) != sign(efeito_indireto) &&
    efeito_cp != 0 && efeito_indireto != 0
  
  rotulo_efeito <- if (houve_supressao) {
    paste0("Efeito indireto (axb) = ", round(efeito_indireto, 3),
           " | \u26A0 Supressao: c' e axb tem sinais opostos - ",
           "'Mediacao' nao e interpretavel como % (ver nota metodologica)")
  } else {
    paste0("Efeito indireto (axb) = ", round(efeito_indireto, 3),
           " | Fracao indireta associativa = ", round(prop_med, 1), "%")
  }
  cor_rotulo <- if (houve_supressao) "#C0392B" else "#555555"
  
  # -----------------------------------------------------------------------
  # Traducao automatica de a, b e c' para linguagem simples (rodape/caption)
  # -----------------------------------------------------------------------
  # nome_grupo = rotulo curto do grupo-tratamento (ex: "Privada"). Se nao
  # informado, usa a primeira linha de var_indep (antes da quebra "\n").
  grupo <- if (!is.null(nome_grupo)) nome_grupo else strsplit(var_indep, "\n")[[1]][1]
  ref   <- if (!is.null(categoria_referencia)) categoria_referencia else "grupo de referencia"
  
  dir_a  <- if (efeito_a  >= 0) "maior"   else "menor"
  dir_b  <- if (efeito_b  >= 0) "a mais"  else "a menos"
  dir_cp <- if (efeito_cp >= 0) "a mais"  else "a menos"
  
  texto_interpretacao <- paste0(
    "a = ", round(efeito_a, 3), " -> escolas '", grupo, "' tem, em media, ",
    mediador, " ", abs(round(efeito_a, 3)), " pontos ", dir_a, " que '", ref, "'.\n",
    "b = ", round(efeito_b, 3), " -> mantendo o grupo fixo, cada ponto de ",
    mediador, " esta associado a ", abs(round(efeito_b, 3)), " pontos ", dir_b,
    " em ", disciplina, " (vale para os dois grupos).\n",
    "c' = ", round(efeito_cp, 3), " -> comparando uma escola '", grupo,
    "' com uma '", ref, "' de mesmo ", mediador, ", a '", grupo,
    "' tem em media ", abs(round(efeito_cp, 3)), " pontos ", dir_cp, " em ",
    disciplina, " (efeito direto, controlando o mediador)."
  )
  
  p <- ggplot() +
    # Caixas
    geom_rect(data = dados_diag,
              aes(xmin = x - 0.7, xmax = x + 0.7, ymin = y - 0.5, ymax = y + 0.5),
              fill = c("#3498DB", "#F39C12", "#27AE60"), alpha = 0.8, color = "#333333", linewidth = 0.8) +
    geom_text(data = dados_diag, aes(x = x, y = y, label = label),
              size = 4.5, fontface = "bold", color = "white") +
    # Seta A (independente -> mediador)
    annotate("segment", x = 0.7, xend = 1.3, y = 2.15, yend = 2.15,
             arrow = arrow(length = unit(0.3, "cm")), linewidth = 1.2, color = "#E74C3C") +
    annotate("text", x = 1, y = 2.5, 
             label = paste0("a = ", round(efeito_a, 3)),
             size = 4, fontface = "bold", color = "#E74C3C") +
    # Seta B (mediador -> dependente)
    annotate("segment", x = 2.7, xend = 3.3, y = 2.15, yend = 2.15,
             arrow = arrow(length = unit(0.3, "cm")), linewidth = 1.2, color = "#E74C3C") +
    annotate("text", x = 3, y = 2.5,
             label = paste0("b = ", round(efeito_b, 3)),
             size = 4, fontface = "bold", color = "#E74C3C") +
    # Seta C' (efeito direto)
    annotate("segment", x = 0.7, xend = 3.3, y = 1.7, yend = 1.7,
             arrow = arrow(length = unit(0.3, "cm")), linewidth = 1, color = "#3498DB",
             linetype = "dashed") +
    annotate("text", x = 2, y = 1.4,
             label = paste0("c' = ", round(efeito_cp, 3), " (direto)"),
             size = 3.8, fontface = "bold", color = "#3498DB") +
    # Informacoes (rotulo muda para aviso quando ha supressao)
    annotate("text", x = 2, y = 0.5,
             label = rotulo_efeito,
             size = 3.5, color = cor_rotulo,
             fontface = if (houve_supressao) "bold" else "plain") +
    labs(
      title = paste0("Figura ", fig_num, " - Diagrama de Mediacao (", disciplina, ")"),
      subtitle = paste0(
        var_indep, " -> ", mediador, " -> Proficiencia ",
        " | R2(mediador) = ", round(r2_med, 3),
        " | R2(proficiencia) = ", round(r2_dep, 3),
        if (!is.null(categoria_referencia)) {
          paste0(" | Referencia (0): ", categoria_referencia)
        } else {
          ""
        }
      ),
      caption = texto_interpretacao
    ) +
    tema_saeb() +
    theme(
      axis.title = element_blank(),
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      plot.caption = element_text(hjust = 0, size = 8.5, lineheight = 1.4,
                                   color = "#333333", margin = margin(t = 12)),
      plot.margin = margin(t = 5.5, r = 5.5, b = 10, l = 5.5)
    ) +
    coord_cartesian(xlim = c(-1.5, 5.5), ylim = c(0, 3))
  
  return(p)
}

# -------------------------------------------------------------------------
# Figura 21: Mediacao Tipo Escola -> INSE -> MT
# -------------------------------------------------------------------------
p21 <- criar_diagrama_mediacao(
  "Tipo Escola\n(Privada=1)", "INSE_MEDIO", "Matematica",
  efeito_a = coef(modelo_a_mt)["TIPO_PRIVADA"],
  efeito_b = coef(modelo_b_mt)["INSE_MEDIO"],
  efeito_cp = coef(modelo_b_mt)["TIPO_PRIVADA"],
  r2_med = summary(modelo_a_mt)$r.squared,
  r2_dep = summary(modelo_b_mt)$r.squared,
  fig_num = 18,
  categoria_referencia = "Publica",
  nome_grupo = "Privada"
)

ggsave(caminho_saida(DIR_BASE, "figuras", "caminhos_mediacao_MT", "png"),
       plot = p21, width = 14, height = 8.2, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 21: caminhos_mediacao_MT_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 22: Mediacao Tipo Escola -> INSE -> LP
# -------------------------------------------------------------------------
p22 <- criar_diagrama_mediacao(
  "Tipo Escola\n(Privada=1)", "INSE_MEDIO", "Lingua Portuguesa",
  efeito_a = coef(modelo_a_lp)["TIPO_PRIVADA"],
  efeito_b = coef(modelo_b_lp)["INSE_MEDIO"],
  efeito_cp = coef(modelo_b_lp)["TIPO_PRIVADA"],
  r2_med = summary(modelo_a_lp)$r.squared,
  r2_dep = summary(modelo_b_lp)$r.squared,
  fig_num = 19,
  categoria_referencia = "Publica",
  nome_grupo = "Privada"
)

ggsave(caminho_saida(DIR_BASE, "figuras", "caminhos_mediacao_LP", "png"),
       plot = p22, width = 14, height = 8.2, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 22: caminhos_mediacao_LP_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figuras a partir de 23: AREA_LOCAL observado -> INSE -> proficiencia
# -------------------------------------------------------------------------
salvar_diagrama_area_local <- function(tratamento, nome_grupo, disciplina,
                                       fig_num) {
  resposta <- if (disciplina == "Matematica") "MEDIA_MT" else "MEDIA_LP"
  estimativa <- if (disciplina == "Matematica") med_loc_mt[[tratamento]] else med_loc_lp[[tratamento]]
  modelo_a <- estimativa$model.m
  modelo_b <- estimativa$model.y
  nome_arquivo <- paste0("caminhos_mediacao_AREA_LOCAL_", nome_grupo,
                         "_", if (disciplina == "Matematica") "MT" else "LP")
  plot <- criar_diagrama_mediacao(
    paste0("AREA_LOCAL\n(", nome_grupo, "=1)"), "INSE_MEDIO", disciplina,
    efeito_a = coef(modelo_a)[tratamento],
    efeito_b = coef(modelo_b)["INSE_MEDIO"],
    efeito_cp = coef(modelo_b)[tratamento],
    r2_med = summary(modelo_a)$r.squared,
    r2_dep = summary(modelo_b)$r.squared,
    fig_num = fig_num,
    categoria_referencia = "Urbana_Capital",
    nome_grupo = nome_grupo
  )
  ggsave(caminho_saida(DIR_BASE, "figuras", nome_arquivo, "png"),
         plot = plot, width = 14, height = 8.2,
         dpi = DPI_PADRAO, bg = "white")
  message("   OK Figura ", fig_num, ": ", nome_arquivo, "_", ts_global, ".png")
}

for (i in seq_along(tratamentos_disponiveis)) {
  tratamento <- tratamentos_disponiveis[i]
  nome_grupo <- tratamentos_area[[tratamento]]
  salvar_diagrama_area_local(
    tratamento, nome_grupo, "Matematica", 18 + 2 * i
  )
  salvar_diagrama_area_local(
    tratamento, nome_grupo, "Lingua Portuguesa", 19 + 2 * i
  )
}

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("ANALISE DE MEDIACAO CONCLUIDA")
message(strrep("=", 70))
message("Escolas analisadas: ", nrow(metadados))
message("\nResultados:")
print(resultados_mediacao)
message("\nFiguras geradas:")
message("  ? Figura 21: caminhos_mediacao_MT_", ts_global, ".png")
message("  ? Figura 22: caminhos_mediacao_LP_", ts_global, ".png")
message(
  "  ? Figuras AREA_LOCAL: ", 2 * length(tratamentos_disponiveis),
  " arquivo(s) caminhos_mediacao_AREA_LOCAL_*_", ts_global, ".png"
)
