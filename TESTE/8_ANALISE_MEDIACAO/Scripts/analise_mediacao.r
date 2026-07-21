################################################################################
# SCRIPT: analise_mediacao.r
#
# OBJETIVO: Testar se INSE media o efeito de variáveis de contexto
#           (tipo escola, localização) sobre a proficiência
#
# ENTRADA:
#   - metadados_escolas_*.csv (PASSO 4)
#
# SAÍDA:
#   - outputs/tabelas/mediacao_*.csv (efeitos direto, indireto, total)
#   - outputs/figuras/caminhos_mediacao_MT.png (Figura 21)
#   - outputs/figuras/caminhos_mediacao_LP.png (Figura 22)
#
# VERSÃO: 1.0 — Julho 2026
################################################################################

library(tidyverse)
library(data.table)

# =========================================================================
# CAMINHOS
# =========================================================================

RAIZ <- detectar_raiz()
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_METADADOS <- file.path(DIR_ANALISE, "outputs/metadados")

DIR_BASE <- file.path(DIR_TESTE, "8_ANALISE_MEDIACAO")
DIR_FIGURAS <- file.path(DIR_BASE, "outputs/figuras")
DIR_TABELAS <- file.path(DIR_BASE, "outputs/tabelas")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_TABELAS, showWarnings = FALSE, recursive = TRUE)

ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSÁRIOS
# =========================================================================

pacotes_necessarios <- c("mediation", "boot")
for (pkg in pacotes_necessarios) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Instalando pacote: ", pkg)
    install.packages(pkg, dependencies = TRUE)
  }
}

library(mediation)

# =========================================================================
# PASSO 1: CARREGAR DADOS
# =========================================================================

message(strrep("=", 70))
message("ANÁLISE DE MEDIAÇÃO — INSE como mediador")
message(strrep("=", 70))

arq_meta <- encontrar_arquivo_mais_recente(DIR_METADADOS, "metadados_escolas")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv não encontrado.")

metadados <- read_csv(arq_meta, show_col_types = FALSE) %>%
  filter(!is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO)) %>%
  filter(TIPO_ESCOLA %in% c("Pública", "Privada")) %>%
  filter(LOCALIZACAO %in% c("Urbana", "Rural")) %>%
  mutate(
    TIPO_PRIVADA = as.integer(TIPO_ESCOLA == "Privada"),
    LOCAL_RURAL = as.integer(LOCALIZACAO == "Rural")
  )

message("Escolas válidas: ", nrow(metadados))

# =========================================================================
# PASSO 2: MEDIAÇÃO — TIPO_ESCOLA → INSE → PROFICIÊNCIA
# =========================================================================

message("\n", strrep("-", 50))
message("MEDIAÇÃO 1: TIPO_ESCOLA → INSE → PROFICIÊNCIA")
message(strrep("-", 50))

# --- MATEMÁTICA ---
# Caminho A: TIPO_ESCOLA → INSE (mediador)
modelo_a_mt <- lm(INSE_MEDIO ~ TIPO_PRIVADA, data = metadados)

# Caminho B + C': INSE + TIPO_ESCOLA → PROFICIÊNCIA
modelo_b_mt <- lm(MEDIA_MT ~ INSE_MEDIO + TIPO_PRIVADA, data = metadados)

# Mediação com bootstrap
med_tipo_mt <- mediate(modelo_a_mt, modelo_b_mt,
                        treat = "TIPO_PRIVADA", mediator = "INSE_MEDIO",
                        boot = TRUE, sims = 1000)

message("\n>>> Matemática — Mediação por INSE:")
summary(med_tipo_mt)

# --- LÍNGUA PORTUGUESA ---
modelo_a_lp <- lm(INSE_MEDIO ~ TIPO_PRIVADA, data = metadados)
modelo_b_lp <- lm(MEDIA_LP ~ INSE_MEDIO + TIPO_PRIVADA, data = metadados)

med_tipo_lp <- mediate(modelo_a_lp, modelo_b_lp,
                        treat = "TIPO_PRIVADA", mediator = "INSE_MEDIO",
                        boot = TRUE, sims = 1000)

message("\n>>> Língua Portuguesa — Mediação por INSE:")
summary(med_tipo_lp)

# =========================================================================
# PASSO 3: MEDIAÇÃO — LOCALIZACAO → INSE → PROFICIÊNCIA
# =========================================================================

message("\n", strrep("-", 50))
message("MEDIAÇÃO 2: LOCALIZACAO → INSE → PROFICIÊNCIA")
message(strrep("-", 50))

# --- MATEMÁTICA ---
modelo_a2_mt <- lm(INSE_MEDIO ~ LOCAL_RURAL, data = metadados)
modelo_b2_mt <- lm(MEDIA_MT ~ INSE_MEDIO + LOCAL_RURAL, data = metadados)

med_loc_mt <- mediate(modelo_a2_mt, modelo_b2_mt,
                       treat = "LOCAL_RURAL", mediator = "INSE_MEDIO",
                       boot = TRUE, sims = 1000)

message("\n>>> Matemática — Mediação por INSE (Localização):")
summary(med_loc_mt)

# --- LÍNGUA PORTUGUESA ---
modelo_a2_lp <- lm(INSE_MEDIO ~ LOCAL_RURAL, data = metadados)
modelo_b2_lp <- lm(MEDIA_LP ~ INSE_MEDIO + LOCAL_RURAL, data = metadados)

med_loc_lp <- mediate(modelo_a2_lp, modelo_b2_lp,
                       treat = "LOCAL_RURAL", mediator = "INSE_MEDIO",
                       boot = TRUE, sims = 1000)

message("\n>>> Língua Portuguesa — Mediação por INSE (Localização):")
summary(med_loc_lp)

# =========================================================================
# PASSO 4: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

# Tabela consolidada de mediação
resultados_mediacao <- tibble(
  Variavel_Independente = c("Tipo Escola (Privada)", "Tipo Escola (Privada)",
                            "Localização (Rural)", "Localização (Rural)"),
  Mediador = rep("INSE_MEDIO", 4),
  Disciplina = c("MT", "LP", "MT", "LP"),
  Efeito_Direto = c(
    med_tipo_mt$d0, med_tipo_lp$d0,
    med_loc_mt$d0, med_loc_lp$d0
  ),
  Efeito_Indireto = c(
    med_tipo_mt$d1, med_tipo_lp$d1,
    med_loc_mt$d1, med_loc_lp$d1
  ),
  Efeito_Total = c(
    med_tipo_mt$d0 + med_tipo_mt$d1,
    med_tipo_lp$d0 + med_tipo_lp$d1,
    med_loc_mt$d0 + med_loc_mt$d1,
    med_loc_lp$d0 + med_loc_lp$d1
  ),
  Proporcao_Mediada = c(
    abs(med_tipo_mt$d1) / abs(med_tipo_mt$d0 + med_tipo_mt$d1),
    abs(med_tipo_lp$d1) / abs(med_tipo_lp$d0 + med_tipo_lp$d1),
    abs(med_loc_mt$d1) / abs(med_loc_mt$d0 + med_loc_mt$d1),
    abs(med_loc_lp$d1) / abs(med_loc_lp$d0 + med_loc_lp$d1)
  ),
  p_Direto = c(
    med_tipo_mt$d0.ci[1], med_tipo_lp$d0.ci[1],
    med_loc_mt$d0.ci[1], med_loc_lp$d0.ci[1]
  ),
  p_Indireto = c(
    med_tipo_mt$d1.ci[1], med_tipo_lp$d1.ci[1],
    med_loc_mt$d1.ci[1], med_loc_lp$d1.ci[1]
  )
) %>%
  mutate(
    Efeito_Direto = round(Efeito_Direto, 3),
    Efeito_Indireto = round(Efeito_Indireto, 3),
    Efeito_Total = round(Efeito_Total, 3),
    Proporcao_Mediada = round(Proporcao_Mediada * 100, 1)
  )

write_csv(resultados_mediacao, file.path(DIR_TABELAS, paste0("mediacao_", ts_global, ".csv")))
message("   ✓ mediacao_", ts_global, ".csv")

# =========================================================================
# PASSO 5: VISUALIZAÇÕES — DIAGRAMA DE CAMINHOS
# =========================================================================

message("\n>>> Gerando figuras...")

# -------------------------------------------------------------------------
# Função auxiliar: criar diagrama de caminhos
# -------------------------------------------------------------------------
criar_diagrama_mediacao <- function(var_indep, mediador, disciplina,
                                     efeito_a, efeito_b, efeito_cp,
                                     r2_med, r2_dep, fig_num) {
  
  # Dados para o diagrama
  dados_diag <- tibble(
    x = c(0, 2, 4),
    y = c(2, 2, 2),
    label = c(var_indep, mediador, paste0("Proficiência\n", disciplina)),
    tipo = c("independente", "mediador", "dependente")
  )
  
  # Calcular proporção mediada
  efeito_total <- efeito_a * efeito_b + efeito_cp
  prop_med <- abs(efeito_a * efeito_b) / abs(efeito_total) * 100
  
  p <- ggplot() +
    # Caixas
    geom_rect(data = dados_diag,
              aes(xmin = x - 0.7, xmax = x + 0.7, ymin = y - 0.5, ymax = y + 0.5),
              fill = c("#3498DB", "#F39C12", "#27AE60"), alpha = 0.8, color = "#333333", linewidth = 0.8) +
    geom_text(data = dados_diag, aes(x = x, y = y, label = label),
              size = 4.5, fontface = "bold", color = "white") +
    # Seta A (independente → mediador)
    annotate("segment", x = 0.7, xend = 1.3, y = 2.15, yend = 2.15,
             arrow = arrow(length = unit(0.3, "cm")), linewidth = 1.2, color = "#E74C3C") +
    annotate("text", x = 1, y = 2.5, 
             label = paste0("a = ", round(efeito_a, 3)),
             size = 4, fontface = "bold", color = "#E74C3C") +
    # Seta B (mediador → dependente)
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
    # Informações
    annotate("text", x = 2, y = 0.5,
             label = paste0("Efeito indireto (a×b) = ", round(efeito_a * efeito_b, 3),
                            " | Mediação = ", round(prop_med, 1), "%"),
             size = 3.5, color = "#555555") +
    labs(
      title = paste0("Figura ", fig_num, " — Diagrama de Mediação (", disciplina, ")"),
      subtitle = paste0(var_indep, " → ", mediador, " → Proficiência ",
                        " | R²(mediador) = ", round(r2_med, 3),
                        " | R²(proficiência) = ", round(r2_dep, 3))
    ) +
    tema_saeb() +
    theme(
      axis.title = element_blank(),
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank()
    ) +
    coord_cartesian(xlim = c(-1.5, 5.5), ylim = c(0, 3))
  
  return(p)
}

# -------------------------------------------------------------------------
# Figura 21: Mediação Tipo Escola → INSE → MT
# -------------------------------------------------------------------------
p21 <- criar_diagrama_mediacao(
  "Tipo Escola\n(Privada=1)", "INSE_MEDIO", "Matemática",
  efeito_a = coef(modelo_a_mt)["TIPO_PRIVADA"],
  efeito_b = coef(modelo_b_mt)["INSE_MEDIO"],
  efeito_cp = coef(modelo_b_mt)["TIPO_PRIVADA"],
  r2_med = summary(modelo_a_mt)$r.squared,
  r2_dep = summary(modelo_b_mt)$r.squared,
  fig_num = 21
)

ggsave(file.path(DIR_FIGURAS, paste0("caminhos_mediacao_MT_", ts_global, ".png")),
       plot = p21, width = 14, height = 7, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 21: caminhos_mediacao_MT_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 22: Mediação Tipo Escola → INSE → LP
# -------------------------------------------------------------------------
p22 <- criar_diagrama_mediacao(
  "Tipo Escola\n(Privada=1)", "INSE_MEDIO", "Língua Portuguesa",
  efeito_a = coef(modelo_a_lp)["TIPO_PRIVADA"],
  efeito_b = coef(modelo_b_lp)["INSE_MEDIO"],
  efeito_cp = coef(modelo_b_lp)["TIPO_PRIVADA"],
  r2_med = summary(modelo_a_lp)$r.squared,
  r2_dep = summary(modelo_b_lp)$r.squared,
  fig_num = 22
)

ggsave(file.path(DIR_FIGURAS, paste0("caminhos_mediacao_LP_", ts_global, ".png")),
       plot = p22, width = 14, height = 7, dpi = DPI_PADRAO, bg = "white")

message("   ✓ Figura 22: caminhos_mediacao_LP_", ts_global, ".png")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("ANÁLISE DE MEDIAÇÃO CONCLUÍDA")
message(strrep("=", 70))
message("Escolas analisadas: ", nrow(metadados))
message("\nResultados:")
print(resultados_mediacao)
message("\nFiguras geradas:")
message("  • Figura 21: caminhos_mediacao_MT_", ts_global, ".png")
message("  • Figura 22: caminhos_mediacao_LP_", ts_global, ".png")
