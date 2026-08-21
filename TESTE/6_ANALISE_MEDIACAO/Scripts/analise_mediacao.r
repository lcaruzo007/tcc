################################################################################
# SCRIPT: analise_mediacao.r
#
# OBJETIVO: Testar se INSE media o efeito de variaveis de contexto
#           (tipo escola, localizacao) sobre a proficiencia
#
# ENTRADA:
#   - metadados_escolas_*.csv (PASSO 4)
#
# SAIDA:
#   - outputs/tabelas/mediacao_*.csv (efeitos direto, indireto, total)
#   - outputs/figuras/caminhos_mediacao_MT.png (Figura 21)
#   - outputs/figuras/caminhos_mediacao_LP.png (Figura 22)
#
# VERSAO: 1.0 - Julho 2026
#
# ---------------------------------------------------------------------------
# NOTA METODOLOGICA - MEDIACAO COM INSE
# ---------------------------------------------------------------------------
#
# A analise de mediacao testa se o INSE_ALUNO (nivel socioeconomico individual,
# agregado como INSE_MEDIO por escola) funciona como mecanismo intermediario
# entre variaveis estruturais (tipo da escola, localizacao) e a proficiencia.
# Ou seja: em que medida o "efeito" de ser escola privada se da por recrutar
# alunos de maior INSE (efeito indireto mediado) vs. por caracteristicas
# institucionais proprias (efeito direto).
#
# 1. Modelo de mediacao classico (Baron & Kenny, 1986)
#    Estima tres regressoes:
#      (a) Y ~ X               [efeito total c]
#      (b) M ~ X               [efeito X -> M, a]
#      (c) Y ~ X + M           [efeito direto c', efeito M -> Y b]
#    Efeito indireto (mediado) = a * b. Efeito total = c = c' + a*b.
#    Medicao parcial: c' significativo e nao-zero. Medicao completa: c' ~ 0.
#
# 2. Em vez de teste Sobel, usamos bootstrap
#    O teste de Sobel assume normalidade do produto a*b, que raramente e
#    satisfeita em amostras moderadas. Segundo Preacher & Hayes (2008),
#    intervalos de confianca via bootstrap (percentil ou BCa, 5.000 repeticoes)
#    sao mais robustos para testar o efeito indireto. Reportamos IC 95% BCa.
#
# 3. Direcao causal e pressuposto de nao confundimento
#    A mediacao pressupoe que nao exista confundidor nao medido do caminho
#    M -> Y. Para SAEB, essa hipotese e plausivel mas nao testavel com os
#    dados administrativos: caracteristicas familiares nao observadas podem
#    afetar simultaneamente INSE e proficiencia. A interpretação correta e
#    "associacao indireta condicional aos preditores do modelo", nao prova
#    causal.
#
# 4. INSE como mediador vs. moderador
#    Testamos INSE como mediador (linha de teste causal X -> M -> Y). Uma
#    alternativa conceitual seria INSE como moderador (interacao X*INSE).
#    Optamos pela medicao porque o referencial teorico do INEP (2021) trata
#    INSE como dimensao socioeconomica antecedente ao desempenho, nao como
#    fator que modifica como tipo de escola afeta desempenho.
#
# 5. Tamanho de efeito
#    Reportamos proporcao mediada (PM = ab/c), que varia de 0 (nenhuma
#    mediacao) a 1 (mediacao completa). Valores podem exceder 1 quando ha
#    supressao (c' e a*b de sinais opostos) - caso em que reportamos PM
#    mas advertimos contra interpretacao literal como "porcentagem".
#
# CONCLUSAO: A medicao com IC bootstrap BCa, baseada no modelo Baron & Kenny
# estendido por Preacher & Hayes, e o arcabouco metodologicamente defensavel
# para estimar em que proporcao o efeito institucional (tipo/area) sobre a
# proficiencia passa pelo nivel socioeconomico da escola.
# ---------------------------------------------------------------------------
################################################################################

library(tidyverse)
library(data.table)

# =========================================================================
# CAMINHOS
# =========================================================================

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
message("ANALISE DE MEDIACAO - INSE como mediador")
message(strrep("=", 70))

arq_meta <- encontrar_arquivo_mais_recente(DIR_OUTPUTS_ANALISE, "metadados_escolas", tipo = "metadados")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv nao encontrado.")

metadados <- read_csv(arq_meta, show_col_types = FALSE) %>%
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

# --- MATEMATICA: 3 mediacoes por dummy de AREA_LOCAL (ref: Urbana_Capital) ---
helper_mediar_area_local <- function(tratamento) {
  formula_a <- as.formula(paste("INSE_MEDIO ~", tratamento))
  formula_b <- as.formula(paste("MEDIA_MT ~ INSE_MEDIO +", tratamento))
  lm_a <- lm(formula_a, data = metadados)
  lm_b <- lm(formula_b, data = metadados)
  m <- mediate(lm_a, lm_b, treat = tratamento, mediator = "INSE_MEDIO",
               boot = TRUE, sims = 1000)
  message("\n>>> Matematica - Mediacao por INSE (",
          tratamento, " vs Urbana_Capital):")
  print(summary(m))
  m
}
med_loc_mt_ri <- helper_mediar_area_local("RURAL_INTERIOR")
med_loc_mt_rc <- helper_mediar_area_local("RURAL_CAPITAL")
med_loc_mt_ui <- helper_mediar_area_local("URBANA_INTERIOR")

# --- LINGUA PORTUGUESA: 3 mediacoes por dummy de AREA_LOCAL ---
helper_mediar_area_local_lp <- function(tratamento) {
  formula_a <- as.formula(paste("INSE_MEDIO ~", tratamento))
  formula_b <- as.formula(paste("MEDIA_LP ~ INSE_MEDIO +", tratamento))
  lm_a <- lm(formula_a, data = metadados)
  lm_b <- lm(formula_b, data = metadados)
  m <- mediate(lm_a, lm_b, treat = tratamento, mediator = "INSE_MEDIO",
               boot = TRUE, sims = 1000)
  message("\n>>> Lingua Portuguesa - Mediacao por INSE (",
          tratamento, " vs Urbana_Capital):")
  print(summary(m))
  m
}
med_loc_lp_ri <- helper_mediar_area_local_lp("RURAL_INTERIOR")
med_loc_lp_rc <- helper_mediar_area_local_lp("RURAL_CAPITAL")
med_loc_lp_ui <- helper_mediar_area_local_lp("URBANA_INTERIOR")

# =========================================================================
# PASSO 4: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

# Tabela consolidada de mediacao - 8 linhas:
#   2 (TIPO_ESCOLA: MT e LP) + 6 (3 dummies de AREA_LOCAL x 2 disciplinas)
resultados_mediacao <- tibble(
  Variavel_Independente = c(
    "Tipo Escola (Privada)", "Tipo Escola (Privada)",
    "AREA_LOCAL: Rural_Interior", "AREA_LOCAL: Rural_Interior",
    "AREA_LOCAL: Rural_Capital",  "AREA_LOCAL: Rural_Capital",
    "AREA_LOCAL: Urbana_Interior","AREA_LOCAL: Urbana_Interior"
  ),
  Mediador = rep("INSE_MEDIO", 8),
  Disciplina = c("MT", "LP", "MT", "LP", "MT", "LP", "MT", "LP"),
  Efeito_Direto = c(
    med_tipo_mt$d0,  med_tipo_lp$d0,
    med_loc_mt_ri$d0, med_loc_lp_ri$d0,
    med_loc_mt_rc$d0, med_loc_lp_rc$d0,
    med_loc_mt_ui$d0, med_loc_lp_ui$d0
  ),
  Efeito_Indireto = c(
    med_tipo_mt$d1,  med_tipo_lp$d1,
    med_loc_mt_ri$d1, med_loc_lp_ri$d1,
    med_loc_mt_rc$d1, med_loc_lp_rc$d1,
    med_loc_mt_ui$d1, med_loc_lp_ui$d1
  ),
  Efeito_Total = c(
    med_tipo_mt$d0 + med_tipo_mt$d1,  med_tipo_lp$d0 + med_tipo_lp$d1,
    med_loc_mt_ri$d0 + med_loc_mt_ri$d1, med_loc_lp_ri$d0 + med_loc_lp_ri$d1,
    med_loc_mt_rc$d0 + med_loc_mt_rc$d1, med_loc_lp_rc$d0 + med_loc_lp_rc$d1,
    med_loc_mt_ui$d0 + med_loc_mt_ui$d1, med_loc_lp_ui$d0 + med_loc_lp_ui$d1
  ),
  Proporcao_Mediada = c(
    abs(med_tipo_mt$d1) / abs(med_tipo_mt$d0 + med_tipo_mt$d1),
    abs(med_tipo_lp$d1) / abs(med_tipo_lp$d0 + med_tipo_lp$d1),
    abs(med_loc_mt_ri$d1) / abs(med_loc_mt_ri$d0 + med_loc_mt_ri$d1),
    abs(med_loc_lp_ri$d1) / abs(med_loc_lp_ri$d0 + med_loc_lp_ri$d1),
    abs(med_loc_mt_rc$d1) / abs(med_loc_mt_rc$d0 + med_loc_mt_rc$d1),
    abs(med_loc_lp_rc$d1) / abs(med_loc_lp_rc$d0 + med_loc_lp_rc$d1),
    abs(med_loc_mt_ui$d1) / abs(med_loc_mt_ui$d0 + med_loc_mt_ui$d1),
    abs(med_loc_lp_ui$d1) / abs(med_loc_lp_ui$d0 + med_loc_lp_ui$d1)
  ),
  p_Direto = c(
    med_tipo_mt$d0.ci[1], med_tipo_lp$d0.ci[1],
    med_loc_mt_ri$d0.ci[1], med_loc_lp_ri$d0.ci[1],
    med_loc_mt_rc$d0.ci[1], med_loc_lp_rc$d0.ci[1],
    med_loc_mt_ui$d0.ci[1], med_loc_lp_ui$d0.ci[1]
  ),
  p_Indireto = c(
    med_tipo_mt$d1.ci[1], med_tipo_lp$d1.ci[1],
    med_loc_mt_ri$d1.ci[1], med_loc_lp_ri$d1.ci[1],
    med_loc_mt_rc$d1.ci[1], med_loc_lp_rc$d1.ci[1],
    med_loc_mt_ui$d1.ci[1], med_loc_lp_ui$d1.ci[1]
  )
) %>%
  mutate(
    Efeito_Direto = round(Efeito_Direto, 3),
    Efeito_Indireto = round(Efeito_Indireto, 3),
    Efeito_Total = round(Efeito_Total, 3),
    Proporcao_Mediada = round(Proporcao_Mediada * 100, 1)
  )

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
  prop_med <- abs(efeito_indireto) / abs(efeito_total) * 100
  
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
           " | Mediacao = ", round(prop_med, 1), "%")
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
  fig_num = 21,
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
  fig_num = 22,
  categoria_referencia = "Publica",
  nome_grupo = "Privada"
)

ggsave(caminho_saida(DIR_BASE, "figuras", "caminhos_mediacao_LP", "png"),
       plot = p22, width = 14, height = 8.2, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 22: caminhos_mediacao_LP_", ts_global, ".png")

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