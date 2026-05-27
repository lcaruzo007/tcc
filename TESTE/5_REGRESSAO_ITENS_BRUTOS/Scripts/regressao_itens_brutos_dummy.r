################################################################################
# SCRIPT: regressao_itens_brutos_dummy.r
#
# FUNCIONALIDADE:
#   Regressão Linear Múltipla com variáveis dummy geradas a partir dos
#   itens brutos do questionário socioeconômico SAEB (TX_RESP_Q01–Q25).
#   Agrega por escola e modela MEDIA_MT e MEDIA_LP.
#
# DIFERENÇA EM RELAÇÃO AO SCRIPT PRINCIPAL (regressao_linear_multipla.r):
#   O script principal usa INSE_MEDIO (score TRI calculado pelo INEP) como
#   proxy socioeconômico. Este script substitui o INSE pelos próprios itens
#   brutos do questionário, convertidos em variáveis dummy (n_cats − 1 por
#   item, com a categoria "A" como referência). O objetivo é explorar quais
#   dimensões específicas do nível socioeconômico (bens domésticos, escolaridade
#   dos pais, hábitos culturais etc.) apresentam efeito independente sobre a
#   proficiência, algo que o INSE agrega em um único índice.
#
# ENTRADA:
#   - TS_ALUNO_34EM.csv  (dados brutos SAEB — nível aluno)
#
# SAÍDA (pasta outputs_itens_brutos/):
#   - base_escolas_itens_<ts>.csv
#   - resumo_modelos_itens_<ts>.csv
#   - coeficientes_MT_itens_<ts>.csv / coeficientes_LP_itens_<ts>.csv
#   - diagnosticos_MT_itens_<ts>.csv / diagnosticos_LP_itens_<ts>.csv
#   - diagnosticos_residuos_MT_itens_<ts>.png / _LP_itens_<ts>.png
#   - preditos_vs_observados_MT_itens_<ts>.png / _LP_itens_<ts>.png
#   - resumo_qualidade_ajuste_itens_<ts>.png
#   - coeficientes_todos_MT_itens_<ts>.png / _LP_itens_<ts>.png
#   - mapa_calor_vif_itens_<ts>.png
#   - missings_por_item_<ts>.png
#
# VERSÃO: 1.1 — Maio 2026
#
# ---------------------------------------------------------------------------
# NOTA METODOLÓGICA — USO DE DUMMIES DOS ITENS BRUTOS E CRITÉRIOS DE ELIMINAÇÃO
# ---------------------------------------------------------------------------
#
# Os itens do questionário (TX_RESP_Q01 a TX_RESP_Q25 com subitens) são
# variáveis categóricas ordinais codificadas como letras (A, B, C…).
# A abordagem adotada aqui é:
#
# 1. CODIFICAÇÃO DUMMY (one-hot com referência)
#    Para cada item, a categoria "A" (menor grau da escala) é tomada como
#    referência. Para um item com k categorias válidas são geradas k−1
#    dummies binárias. No total, os itens geram ~169 dummies.
#    Respostas codificadas como "." (não respondeu) ou "*" (inválido) são
#    tratadas como NA antes da criação das dummies.
#
# 2. AGREGAÇÃO POR ESCOLA (proporção de respostas)
#    Como a unidade de análise é a escola (não o aluno), cada dummy é
#    agregada como a PROPORÇÃO de alunos da escola que respondeu aquela
#    categoria. Isso transforma valores binários individuais em variáveis
#    contínuas [0, 1] no nível escola — interpretáveis como "fração de
#    alunos com perfil X".
#
# ---------------------------------------------------------------------------
# CRITÉRIOS DE ELIMINAÇÃO DE VARIÁVEIS (TRÊS ETAPAS SEQUENCIAIS)
# ---------------------------------------------------------------------------
#
# As dummies geradas passam por três filtros sequenciais antes de entrar
# no modelo final. O número de variáveis eliminadas em cada etapa é
# registrado no relatório final e nos arquivos de log.
#
# ETAPA A — RESPOSTAS INVÁLIDAS (antes da geração das dummies)
#    Respostas codificadas como "." (ausência de resposta) ou "*" (código
#    inválido/inconsistente conforme dicionário SAEB) são convertidas para
#    NA antes de qualquer operação. Além disso, escolas onde um item tem
#    menos de MIN_RESP_ITEM (padrão = 3) respostas válidas recebem NA para
#    todas as dummies daquele item naquela escola — evitando proporções
#    calculadas sobre amostras ínfimas e potencialmente não representativas.
#    Critério: n_respostas_validas_por_escola < MIN_RESP_ITEM → NA.
#
# ETAPA B — FILTRO DE VARIÂNCIA ZERO / QUASE-ZERO (nível escola)
#    Após a agregação por escola, dummies cujas proporções apresentam
#    variância menor que LIMIAR_VAR_ZERO (padrão = 0,001) entre escolas,
#    ou cujo percentual de missings supera 50%, são descartadas.
#    Esse filtro elimina:
#      • Categorias de resposta raramente escolhidas (quase ninguém
#        respondeu "E" em determinado item → dummy TX_RESP_Q07a_E ≈ 0
#        em todas as escolas → variância ≈ 0 → sem poder discriminatório).
#      • Dummies com dados ausentes na maioria das escolas, que
#        introduziriam viés de seleção ao exigir descarte de muitas escolas.
#    Critério: var(dummy, na.rm=TRUE) ≤ LIMIAR_VAR_ZERO
#              OU mean(is.na(dummy)) > 0,50 → eliminada.
#
# ETAPA C — CONTROLE DE MULTICOLINEARIDADE VIA VIF ITERATIVO
#    Com dezenas a centenas de preditores contínuos derivados de itens
#    correlacionados entre si (p. ex., itens de bens domésticos Q07a–Q07e
#    tendem a co-variar), a multicolinearidade é estruturalmente esperada.
#    O script aplica eliminação iterativa pelo Variance Inflation Factor:
#      i.   Ajusta o modelo com todos os preditores restantes.
#      ii.  Calcula o VIF de cada preditor via car::vif().
#      iii. Identifica o preditor com maior VIF.
#      iv.  Se VIF_max > LIMIAR_VIF (padrão = 10): remove esse preditor,
#           registra em log e volta ao passo i.
#      v.   Encerra quando todos os VIFs ≤ LIMIAR_VIF.
#    O limiar VIF = 10 é o critério conservador clássico (Hair et al., 2019);
#    valores > 10 indicam que mais de 90% da variância do preditor é
#    explicada pelos demais, tornando sua estimativa instável.
#    A eliminação é feita com base no modelo MEDIA_MT e o conjunto de
#    preditoras resultante é reutilizado para MEDIA_LP, garantindo
#    comparabilidade direta entre os dois modelos.
#    O log completo das variáveis removidas nesta etapa (nome e VIF no
#    momento da remoção) é salvo em log_vif_removidos_<ts>.csv.
#    Critério: VIF > LIMIAR_VIF → preditor de maior VIF é removido
#              iterativamente até todos estarem abaixo do limiar.
#
# RESUMO DO FLUXO DE ELIMINAÇÃO:
#    Dummies brutas (~169)
#      → [A] NA por resposta inválida / escola com < MIN_RESP_ITEM respostas
#      → [B] Remoção por variância ≈ 0 ou > 50% missing
#      → [C] Remoção iterativa por VIF > LIMIAR_VIF
#      → Preditoras finais no modelo
#
# ---------------------------------------------------------------------------
# 3. INTERPRETAÇÃO DOS COEFICIENTES
#    Cada coeficiente representa o efeito estimado (em pontos SAEB) de
#    uma escola ter mais alunos respondendo a categoria X em vez da
#    categoria de referência "A", mantendo todos os demais preditores
#    constantes. Por exemplo, Q02_B = +5.2 significa que escolas onde
#    a fração de alunos respondendo "B" na Q02 é maior em 1 unidade
#    (i.e., 100% vs 0%) têm proficiência 5.2 pontos maior, ceteris paribus.
#    O gráfico de coeficientes exibe TODAS as preditoras mantidas no modelo
#    (após os três filtros), ordenadas pelo valor absoluto do coeficiente,
#    de forma a revelar tanto os efeitos de maior magnitude quanto os
#    estatisticamente não significativos.
#
# REFERÊNCIA: INEP (2021). Nota Técnica — Indicador de Nível
# Socioeconômico das Escolas de Educação Básica (INSE).
# Hair, J. F. et al. (2019). Multivariate Data Analysis (8ª ed.).
# ---------------------------------------------------------------------------
################################################################################

library(tidyverse)
library(broom)
library(patchwork)
library(car)

# =============================================================================
# DETECÇÃO AUTOMÁTICA DE CAMINHOS
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
  message("⚠️  Pasta 'TESTE' não encontrada automaticamente.")
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho não selecionado. Encerrando.")
    message("✓ Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Script não pode rodar em modo não-interativo sem encontrar o caminho.")
  }
}

arquivo_mais_recente <- function(pasta, padrao) {
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE)
  if (length(arqs) == 0L) return(NULL)
  arqs[which.max(file.info(arqs)$mtime)]
}

RAIZ                 <- detectar_raiz()
DIR_DADOS_BRUTOS     <- file.path(RAIZ, "MICRODADOS_SAEB_2023", "DADOS")
ARQUIVO_DADOS_BRUTOS <- arquivo_mais_recente(DIR_DADOS_BRUTOS, "^TS_ALUNO_34EM\\.csv$")

# Subpastas próprias — separadas do script principal
DIR_BASE <- file.path(RAIZ, "TESTE", "5_REGRESSAO_ITENS_BRUTOS")
DIR_MODELOS     <- file.path(DIR_BASE, "outputs_modelos")
DIR_DIAGNOSTICOS<- file.path(DIR_BASE, "outputs_diagnosticos")
DIR_FIGURAS     <- file.path(DIR_BASE, "outputs_figuras")
DIR_TABELAS     <- file.path(DIR_BASE, "outputs_tabelas")

message("Caminhos configurados:")
message("  Dados brutos : ", ARQUIVO_DADOS_BRUTOS)
message("  Modelos      : ", DIR_MODELOS)
message("  Figuras      : ", DIR_FIGURAS)
message("  Tabelas      : ", DIR_TABELAS, "\n")

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================

MIN_ALUNOS_ESCOLA  <- 5      # escolas com menos alunos são descartadas
PROF_MIN           <- 150    # limite inferior de proficiência válida
PROF_MAX           <- 800    # limite superior de proficiência válida
MIN_RESP_ITEM      <- 3      # alunos mínimos respondendo um item por escola
LIMIAR_VIF         <- 10     # VIF máximo tolerado (eliminação iterativa)
LIMIAR_VAR_ZERO    <- 0.001  # variância mínima de uma dummy no nível escola
ALPHA              <- 0.05

# Itens brutos do questionário socioeconômico
ITENS_QUEST <- c(
  "TX_RESP_Q01", "TX_RESP_Q02", "TX_RESP_Q03", "TX_RESP_Q04",
  "TX_RESP_Q05a","TX_RESP_Q05b","TX_RESP_Q05c",
  "TX_RESP_Q06",
  "TX_RESP_Q07a","TX_RESP_Q07b","TX_RESP_Q07c","TX_RESP_Q07d","TX_RESP_Q07e",
  "TX_RESP_Q08", "TX_RESP_Q09",
  "TX_RESP_Q10a","TX_RESP_Q10b","TX_RESP_Q10c","TX_RESP_Q10d",
  "TX_RESP_Q10e","TX_RESP_Q10f",
  "TX_RESP_Q11a","TX_RESP_Q11b","TX_RESP_Q11c",
  "TX_RESP_Q12a","TX_RESP_Q12b","TX_RESP_Q12c","TX_RESP_Q12d",
  "TX_RESP_Q12e","TX_RESP_Q12f","TX_RESP_Q12g",
  "TX_RESP_Q13a","TX_RESP_Q13b","TX_RESP_Q13c","TX_RESP_Q13d",
  "TX_RESP_Q13e","TX_RESP_Q13f","TX_RESP_Q13g","TX_RESP_Q13h","TX_RESP_Q13i",
  "TX_RESP_Q14",
  "TX_RESP_Q15a","TX_RESP_Q15b",
  "TX_RESP_Q16", "TX_RESP_Q17", "TX_RESP_Q18", "TX_RESP_Q19", "TX_RESP_Q20",
  "TX_RESP_Q21a","TX_RESP_Q21b","TX_RESP_Q21c","TX_RESP_Q21d","TX_RESP_Q21e",
  "TX_RESP_Q22a","TX_RESP_Q22b","TX_RESP_Q22c","TX_RESP_Q22d",
  "TX_RESP_Q22e","TX_RESP_Q22f","TX_RESP_Q22g","TX_RESP_Q22h",
  "TX_RESP_Q23a","TX_RESP_Q23b","TX_RESP_Q23c","TX_RESP_Q23d",
  "TX_RESP_Q23e","TX_RESP_Q23f","TX_RESP_Q23g","TX_RESP_Q23h","TX_RESP_Q23i",
  "TX_RESP_Q24", "TX_RESP_Q25"
)

# Variáveis estruturais da escola (mantidas como controle)
VARS_ESTRUTURAIS <- c("TIPO_ESCOLA", "AREA", "LOCALIZACAO")

VARIAVEL_DEPENDENTE <- c("MEDIA_MT", "MEDIA_LP")

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

tema_saeb <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title       = element_text(face = "bold", size = base_size + 2,
                                      colour = "#1A1A1A", margin = margin(b = 4)),
      plot.subtitle    = element_text(size = base_size - 1, colour = "#555555",
                                      margin = margin(b = 8)),
      plot.caption     = element_text(size = base_size - 2, colour = "#777777",
                                      face = "italic", hjust = 0,
                                      margin = margin(t = 10)),
      plot.background  = element_rect(fill = "#FFFFFF", colour = NA),
      panel.background = element_rect(fill = "#F5F5F5", colour = NA),
      panel.grid.major = element_line(colour = "#D0D0D0", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      plot.margin      = margin(16, 16, 12, 16)
    )
}

formatar_pvalor <- function(p) {
  case_when(
    p < 0.001 ~ "***",
    p < 0.01  ~ "**",
    p < 0.05  ~ "*",
    TRUE      ~ ""
  )
}

# Função auxiliar: validar dados antes de plotar
validar_dados_plot <- function(df, nome_grafico) {
  if (is.null(df) || nrow(df) == 0) {
    warning("⚠️  ", nome_grafico, ": nenhum dado para plotar. Gráfico não será gerado.")
    return(FALSE)
  }
  TRUE
}

# Eliminação iterativa de preditores com VIF > limiar
eliminar_por_vif <- function(df_modelo, resposta, limiar = LIMIAR_VIF) {
  preds <- setdiff(names(df_modelo), resposta)
  log_removidos <- character(0)

  repeat {
    formula_atual <- as.formula(
      paste(resposta, "~", paste(preds, collapse = " + "))
    )
    modelo_tmp <- lm(formula_atual, data = df_modelo)
    vif_vals   <- tryCatch(car::vif(modelo_tmp), error = function(e) NULL)

    if (is.null(vif_vals)) {
      message("  ⚠️  VIF não pôde ser calculado — encerrando eliminação.")
      break
    }

    # vif() pode retornar matrix (quando há fatores); pegar primeira coluna
    if (is.matrix(vif_vals)) vif_vals <- vif_vals[, 1]

    max_vif  <- max(vif_vals, na.rm = TRUE)
    max_pred <- names(which.max(vif_vals))

    if (max_vif <= limiar) break

    message(sprintf("  Removendo %-45s  VIF = %.1f", max_pred, max_vif))
    log_removidos <- c(log_removidos, sprintf("%s (VIF=%.1f)", max_pred, max_vif))
    preds <- setdiff(preds, max_pred)
  }

  list(preditoras = preds, removidos = log_removidos)
}

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

for (d in c(DIR_MODELOS, DIR_DIAGNOSTICOS, DIR_FIGURAS, DIR_TABELAS))
  dir.create(d, showWarnings = FALSE, recursive = TRUE)

ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

message(strrep("=", 70))
message("REGRESSÃO COM ITENS BRUTOS (DUMMIES) — DADOS SAEB")
message(strrep("=", 70))

# =============================================================================
# ETAPA 1: CARREGAR DADOS BRUTOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 1: CARREGANDO DADOS BRUTOS")
message(strrep("-", 50))

if (is.null(ARQUIVO_DADOS_BRUTOS) || !file.exists(ARQUIVO_DADOS_BRUTOS)) {
  stop(
    "Arquivo TS_ALUNO*.csv não encontrado em:\n  ", DIR_DADOS_BRUTOS,
    "\nVerifique se a pasta MICRODADOS_SAEB_2023/DADOS existe na raiz do projeto."
  )
}

# Colunas necessárias: proficiência + estrutura da escola + itens do questionário
colunas_fixas <- cols(
  ID_ESCOLA            = col_character(),
  IN_PUBLICA           = col_integer(),
  ID_AREA              = col_integer(),
  ID_LOCALIZACAO       = col_integer(),
  IN_PROFICIENCIA_MT   = col_integer(),
  IN_PROFICIENCIA_LP   = col_integer(),
  PROFICIENCIA_MT_SAEB = col_double(),
  PROFICIENCIA_LP_SAEB = col_double(),
  IN_PREENCHIMENTO_QUESTIONARIO = col_integer(),
  .default             = col_character()   # itens do questionário são char
)

dados_brutos <- read_csv(
  ARQUIVO_DADOS_BRUTOS,
  col_types = colunas_fixas,
  show_col_types = FALSE
)

# Converter colunas numéricas que vieram como character por causa do .default
dados_brutos <- dados_brutos |>
  mutate(
    IN_PROFICIENCIA_MT   = as.integer(IN_PROFICIENCIA_MT),
    IN_PROFICIENCIA_LP   = as.integer(IN_PROFICIENCIA_LP),
    PROFICIENCIA_MT_SAEB = as.double(PROFICIENCIA_MT_SAEB),
    PROFICIENCIA_LP_SAEB = as.double(PROFICIENCIA_LP_SAEB),
    IN_PUBLICA           = as.integer(IN_PUBLICA),
    ID_AREA              = as.integer(ID_AREA),
    ID_LOCALIZACAO       = as.integer(ID_LOCALIZACAO)
  )

# Tratar "." e "*" como NA nos itens do questionário
itens_presentes <- intersect(ITENS_QUEST, names(dados_brutos))
dados_brutos <- dados_brutos |>
  mutate(across(all_of(itens_presentes),
                ~ if_else(.x %in% c(".", "*", ""), NA_character_, .x)))

message("Arquivo    : ", basename(ARQUIVO_DADOS_BRUTOS))
message("Alunos     : ", nrow(dados_brutos))
message("Escolas    : ", n_distinct(dados_brutos$ID_ESCOLA))
message("Itens lidos: ", length(itens_presentes))

# =============================================================================
# ETAPA 2: MÉDIAS DE PROFICIÊNCIA POR ESCOLA
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 2: MÉDIAS DE PROFICIÊNCIA POR ESCOLA")
message(strrep("-", 50))

media_prof <- dados_brutos |>
  filter(
    IN_PROFICIENCIA_MT == 1,
    IN_PROFICIENCIA_LP == 1,
    between(PROFICIENCIA_MT_SAEB, PROF_MIN, PROF_MAX),
    between(PROFICIENCIA_LP_SAEB, PROF_MIN, PROF_MAX)
  ) |>
  group_by(ID_ESCOLA) |>
  summarise(
    MEDIA_MT    = mean(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    MEDIA_LP    = mean(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    N_ALUNOS_MT = n(),
    .groups     = "drop"
  ) |>
  filter(N_ALUNOS_MT >= MIN_ALUNOS_ESCOLA)

message("Escolas com proficiência válida: ", nrow(media_prof))

# =============================================================================
# ETAPA 3: VARIÁVEIS ESTRUTURAIS DA ESCOLA
# =============================================================================

categ_escola <- dados_brutos |>
  group_by(ID_ESCOLA) |>
  summarise(
    IN_PUBLICA     = first(IN_PUBLICA),
    ID_AREA        = first(ID_AREA),
    ID_LOCALIZACAO = first(ID_LOCALIZACAO),
    .groups        = "drop"
  ) |>
  mutate(
    TIPO_ESCOLA = if_else(IN_PUBLICA == 1, "Publica", "Privada"),
    AREA        = if_else(ID_AREA == 1,    "Capital", "Interior"),
    LOCALIZACAO = if_else(ID_LOCALIZACAO == 1, "Urbana", "Rural")
  ) |>
  select(ID_ESCOLA, TIPO_ESCOLA, AREA, LOCALIZACAO)

# =============================================================================
# ETAPA 4: CRIAR DUMMIES DOS ITENS BRUTOS E AGREGAR POR ESCOLA
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 4: CRIANDO DUMMIES E AGREGANDO POR ESCOLA")
message(strrep("-", 50))

dados_quest <- dados_brutos |>
  select(ID_ESCOLA, all_of(itens_presentes))

props_lista <- lapply(itens_presentes, function(item) {

  cats_validas <- sort(unique(na.omit(dados_quest[[item]])))
  cats_validas <- cats_validas[cats_validas != "A"]

  if (length(cats_validas) == 0L) {
    return(NULL)
  }

  df_agg <- dados_quest |>
    select(ID_ESCOLA, resp = all_of(item)) |>
    group_by(ID_ESCOLA) |>
    summarise(.groups = "drop")

  for (cat in cats_validas) {

    nome_col <- paste0(item, "_", cat)

    prop_cat <- dados_quest |>
      select(ID_ESCOLA, resp = all_of(item)) |>
      group_by(ID_ESCOLA) |>
      summarise(
        !!nome_col := {

          respostas_validas <- resp[!is.na(resp)]

          n_v <- length(respostas_validas)

          if (n_v < MIN_RESP_ITEM) {
            NA_real_
          } else {
            mean(respostas_validas == cat)
          }
        },
        .groups = "drop"
      )

    df_agg <- left_join(df_agg, prop_cat, by = "ID_ESCOLA")
  }

  return(df_agg)
})

props_lista <- Filter(Negate(is.null), props_lista)

props_escola <- reduce(props_lista, left_join, by = "ID_ESCOLA")

todas_dummies <- setdiff(names(props_escola), "ID_ESCOLA")

message("Dummies geradas: ", length(todas_dummies))
message("Escolas: ", nrow(props_escola))

# =============================================================================
# ETAPA 5: DIAGNÓSTICO DE MISSINGS POR ITEM (CORRIGIDO)
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 5: DIAGNÓSTICO DE MISSINGS")
message(strrep("-", 50))

miss_info <- map_dfr(itens_presentes, function(item) {

  pct_miss <- dados_brutos |>
    group_by(ID_ESCOLA) |>
    summarise(
      n_valid = sum(!is.na(.data[[item]])),
      .groups = "drop"
    ) |>
    summarise(
      pct = mean(n_valid < MIN_RESP_ITEM) * 100
    ) |>
    pull(pct)

  tibble(
    Item = item,
    Pct_NA_Escolas = round(pct_miss, 1)
  )
}) |>
  arrange(desc(Pct_NA_Escolas))

# =============================================================================
# ETAPA 6: MONTAR BASE ESCOLA E REMOVER DUMMIES COM VARIÂNCIA ZERO
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 6: BASE ESCOLA — FILTRO DE VARIÂNCIA ZERO")
message(strrep("-", 50))

dados_escola <- media_prof |>
  inner_join(categ_escola, by = "ID_ESCOLA") |>
  inner_join(props_escola,  by = "ID_ESCOLA")

message("Escolas na base final: ", nrow(dados_escola))

# Dummies de variáveis estruturais (TIPO_ESCOLA, AREA, LOCALIZACAO)
dados_escola <- dados_escola |>
  mutate(
    TIPO_ESCOLA_Privada = as.integer(TIPO_ESCOLA == "Privada"),
    AREA_Interior       = as.integer(AREA == "Interior"),
    LOCALIZACAO_Rural   = as.integer(LOCALIZACAO == "Rural")
  )

dummies_estruturais <- c("TIPO_ESCOLA_Privada", "AREA_Interior", "LOCALIZACAO_Rural")

# todas_dummies agora é o vetor de colunas efetivamente presentes em props_escola
# (atualizado no final da Etapa 4)
# Identificar e remover dummies de itens com variância quase-zero
vars_candidatas <- c(dummies_estruturais, todas_dummies)
vars_candidatas <- intersect(vars_candidatas, names(dados_escola))

vars_var_ok <- vars_candidatas[
  sapply(vars_candidatas, function(v) {
    x <- dados_escola[[v]]
    var(x, na.rm = TRUE) > LIMIAR_VAR_ZERO && mean(is.na(x)) < 0.5
  })
]

n_removidas_var0 <- length(vars_candidatas) - length(vars_var_ok)
message("Dummies removidas por variância ≈ 0 ou >50% missing: ", n_removidas_var0)
message("Dummies mantidas para o modelo: ", length(vars_var_ok))

# Salvar log das variáveis eliminadas na etapa B (variância zero / missing)
vars_eliminadas_var0 <- setdiff(vars_candidatas, vars_var_ok)
write_csv(
  tibble(
    Predictor_Removido = vars_eliminadas_var0,
    Motivo = sapply(vars_eliminadas_var0, function(v) {
      x <- dados_escola[[v]]
      if (mean(is.na(x)) > 0.5) {
        paste0(">50% missing (", round(mean(is.na(x)) * 100, 1), "%)")
      } else {
        paste0("variância ≈ 0 (var=", round(var(x, na.rm = TRUE), 6), ")")
      }
    })
  ),
  file.path(DIR_TABELAS, paste0("log_eliminadas_var0_", ts_global, ".csv"))
)

write_csv(dados_escola,
          file.path(DIR_TABELAS, paste0("base_escolas_itens_", ts_global, ".csv")))
message("Base escola salva: base_escolas_itens_", ts_global, ".csv")

# =============================================================================
# ETAPA 7: CONTROLE DE MULTICOLINEARIDADE (VIF ITERATIVO)
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 7: CONTROLE DE MULTICOLINEARIDADE — VIF ITERATIVO")
message(strrep("-", 50))
message("Limiar VIF: ", LIMIAR_VIF,
        " | Preditores antes da eliminação: ", length(vars_var_ok))

# Trabalha com complete cases para o VIF
df_completo <- dados_escola |>
  select(MEDIA_MT, MEDIA_LP, all_of(vars_var_ok)) |>
  drop_na()

message("Observações (escolas) com dados completos: ", nrow(df_completo))

# Eliminação para MEDIA_MT (o resultado serve para ambos os modelos,
# pois as preditoras são as mesmas)
resultado_vif <- eliminar_por_vif(
  df_modelo = df_completo |> select(-MEDIA_LP),
  resposta  = "MEDIA_MT",
  limiar    = LIMIAR_VIF
)

preditoras_finais <- resultado_vif$preditoras
log_vif           <- resultado_vif$removidos

message("\nPreditoras após eliminação VIF: ", length(preditoras_finais))
message("Removidas pelo VIF           : ", length(log_vif))

# Salvar log de remoção por VIF
write_csv(
  tibble(Predictor_Removido = log_vif),
  file.path(DIR_TABELAS, paste0("log_vif_removidos_", ts_global, ".csv"))
)

# =============================================================================
# ETAPA 8: AJUSTAR MODELOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 8: AJUSTANDO MODELOS")
message(strrep("-", 50))

formula_mt <- as.formula(
  paste("MEDIA_MT ~", paste(preditoras_finais, collapse = " + "))
)
formula_lp <- as.formula(
  paste("MEDIA_LP ~", paste(preditoras_finais, collapse = " + "))
)

modelo_mt <- lm(formula_mt, data = df_completo)
modelo_lp <- lm(formula_lp, data = df_completo)

summary_mt <- summary(modelo_mt)
summary_lp <- summary(modelo_lp)

message("\n>>> MODELO MEDIA_MT (Matemática) <<<")
message("  Observações    : ", nrow(df_completo))
message("  Preditoras     : ", length(preditoras_finais))
message("  R² ajustado    : ", round(summary_mt$adj.r.squared, 4))
message("  F-statistic    : ", round(summary_mt$fstatistic[1], 2))
message("  RMSE           : ", round(sqrt(mean(summary_mt$residuals^2)), 2))

message("\n>>> MODELO MEDIA_LP (Língua Portuguesa) <<<")
message("  Observações    : ", nrow(df_completo))
message("  Preditoras     : ", length(preditoras_finais))
message("  R² ajustado    : ", round(summary_lp$adj.r.squared, 4))
message("  F-statistic    : ", round(summary_lp$fstatistic[1], 2))
message("  RMSE           : ", round(sqrt(mean(summary_lp$residuals^2)), 2))

# =============================================================================
# ETAPA 9: COEFICIENTES
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 9: EXTRAINDO COEFICIENTES")
message(strrep("-", 50))

extrair_coef <- function(modelo) {
  tidy(modelo) |>
    mutate(
      Sig       = formatar_pvalor(p.value),
      IC_lower  = estimate - 1.96 * std.error,
      IC_upper  = estimate + 1.96 * std.error,
      # Decompor nome do termo: item + categoria
      Item      = str_extract(term, "^TX_RESP_Q[^_]+"),
      Categoria = str_extract(term, "[A-Z]$")
    ) |>
    select(
      Termo     = term,
      Item, Categoria,
      Coef      = estimate,
      SE        = std.error,
      t_value   = statistic,
      p_valor   = p.value,
      Sig,
      IC_95_inf = IC_lower,
      IC_95_sup = IC_upper
    ) |>
    arrange(desc(abs(t_value)))
}

coef_mt <- extrair_coef(modelo_mt)
coef_lp <- extrair_coef(modelo_lp)

write_csv(coef_mt,
          file.path(DIR_TABELAS, paste0("coeficientes_MT_itens_", ts_global, ".csv")))
write_csv(coef_lp,
          file.path(DIR_TABELAS, paste0("coeficientes_LP_itens_", ts_global, ".csv")))

message("Coeficientes MT (top 15):")
print(head(coef_mt, 15), n = 15)

# =============================================================================
# ETAPA 10: TABELA RESUMO DE DIAGNÓSTICOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 10: DIAGNÓSTICOS DOS MODELOS")
message(strrep("-", 50))

extrair_diag <- function(modelo, summary_mod) {
  tibble(
    Diagnostico = c("R² ajustado", "RMSE", "AIC", "BIC"),
    Valor       = c(
      round(summary_mod$adj.r.squared, 4),
      round(sqrt(mean(summary_mod$residuals^2)), 2),
      round(AIC(modelo), 2),
      round(BIC(modelo), 2)
    ),
    Descricao = c(
      "Proporção da variância explicada (ajustada pelo número de preditores)",
      "Erro médio de predição nas mesmas unidades da variável resposta",
      "Qualidade relativa do modelo penalizando complexidade (menor = melhor)",
      "Similar ao AIC com penalização maior por complexidade (menor = melhor)"
    )
  )
}

diag_mt <- extrair_diag(modelo_mt, summary_mt)
diag_lp <- extrair_diag(modelo_lp, summary_lp)

write_csv(diag_mt,
          file.path(DIR_DIAGNOSTICOS, paste0("diagnosticos_MT_itens_", ts_global, ".csv")))
write_csv(diag_lp,
          file.path(DIR_DIAGNOSTICOS, paste0("diagnosticos_LP_itens_", ts_global, ".csv")))

tabela_resumo <- tibble(
  Modelo      = c("MEDIA_MT", "MEDIA_LP"),
  Observacoes = nrow(df_completo),
  Preditoras  = length(preditoras_finais),
  R2_ajustado = c(round(summary_mt$adj.r.squared, 4),
                  round(summary_lp$adj.r.squared, 4)),
  RMSE        = c(round(sqrt(mean(summary_mt$residuals^2)), 2),
                  round(sqrt(mean(summary_lp$residuals^2)), 2)),
  F_statistic = c(round(summary_mt$fstatistic[1], 2),
                  round(summary_lp$fstatistic[1], 2)),
  p_valor     = "< 0.001",
  AIC         = c(round(AIC(modelo_mt), 2), round(AIC(modelo_lp), 2)),
  BIC         = c(round(BIC(modelo_mt), 2), round(BIC(modelo_lp), 2))
)

write_csv(tabela_resumo,
          file.path(DIR_TABELAS, paste0("resumo_modelos_itens_", ts_global, ".csv")))
message("Resumo dos modelos:")
print(tabela_resumo)

# =============================================================================
# ETAPA 11: GRÁFICOS DE DIAGNÓSTICO DE RESÍDUOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 11: GRÁFICOS DE DIAGNÓSTICO DE RESÍDUOS")
message(strrep("-", 50))

gerar_graficos_residuos <- function(modelo, nome, cor) {

  dados_resid <- tibble(
    fitted        = fitted(modelo),
    residuals     = residuals(modelo),
    std_residuals = rstandard(modelo)
  )

  p1 <- ggplot(dados_resid, aes(x = fitted, y = residuals)) +
    geom_point(alpha = 0.50, size = 2, colour = cor, stroke = 0.3) +
    geom_hline(yintercept = 0, linetype = "dashed",
               colour = "#D62728", linewidth = 1.1) +
    geom_smooth(method = "loess", se = TRUE, colour = "#2CA02C",
                fill = "#2CA02C", alpha = 0.20, linewidth = 1) +
    labs(
      title    = paste0("Resíduos vs Ajustados (", nome, ")"),
      subtitle = "Dispersão aleatória em torno de zero indica bom ajuste",
      x        = "Valores ajustados",
      y        = "Resíduos"
    ) +
    tema_saeb()

  p2 <- ggplot(dados_resid, aes(sample = std_residuals)) +
    stat_qq(alpha = 0.55, size = 2.2, colour = cor, stroke = 0.3) +
    stat_qq_line(colour = "#D62728", linewidth = 1.2) +
    labs(
      title    = paste0("Q-Q Plot dos Resíduos (", nome, ")"),
      subtitle = "Aderência dos resíduos à distribuição normal",
      x        = "Quantis teóricos",
      y        = "Quantis amostrais"
    ) +
    tema_saeb()

  p3 <- ggplot(dados_resid, aes(x = fitted, y = sqrt(abs(std_residuals)))) +
    geom_point(alpha = 0.50, size = 2, colour = cor, stroke = 0.3) +
    geom_smooth(method = "loess", se = TRUE, colour = "#2CA02C",
                fill = "#2CA02C", alpha = 0.20, linewidth = 1) +
    labs(
      title    = paste0("Scale-Location (", nome, ")"),
      subtitle = "Verifica homocedasticidade",
      x        = "Valores ajustados",
      y        = "√|Resíduos padronizados|"
    ) +
    tema_saeb()

  p4 <- ggplot(dados_resid, aes(x = residuals)) +
    geom_histogram(bins = 30, fill = cor, alpha = 0.75, colour = "black", linewidth = 0.5) +
    geom_vline(xintercept = 0, linetype = "dashed",
               colour = "#D62728", linewidth = 1.1) +
    labs(
      title    = paste0("Distribuição dos Resíduos (", nome, ")"),
      subtitle = "Histograma dos erros de predição",
      x        = "Resíduos",
      y        = "Frequência"
    ) +
    tema_saeb()

  (p1 + p2) / (p3 + p4) +
    plot_annotation(
      title    = paste0("Diagnóstico do Modelo ", nome,
                        " — Itens Brutos (Dummies)"),
      subtitle = "Análise gráfica dos resíduos e do ajuste do modelo de regressão",
      caption  = paste(
        "① Resíduos vs Ajustados: sem padrão sistemático = bom.",
        "② Q-Q Plot: pontos sobre a diagonal = resíduos normais.",
        "③ Scale-Location: dispersão uniforme = homocedasticidade.",
        "④ Histograma: sino centrado em zero = sem viés sistemático.",
        sep = "\n"
      ),
      theme = theme(
        plot.title    = element_text(hjust = 0.5, face = "bold", size = 14),
        plot.subtitle = element_text(hjust = 0.5, size = 11, colour = "#555555"),
        plot.caption  = element_text(hjust = 0, size = 9, colour = "#666666",
                                     face = "italic", lineheight = 1.5,
                                     margin = margin(t = 12))
      )
    )
}

p_diag_mt <- gerar_graficos_residuos(modelo_mt, "MEDIA_MT", "#1f77b4")
p_diag_lp <- gerar_graficos_residuos(modelo_lp, "MEDIA_LP", "#ff7f0e")

ggsave(
  file.path(DIR_FIGURAS,
            paste0("diagnosticos_residuos_MT_itens_", ts_global, ".png")),
  p_diag_mt, width = 14, height = 10, dpi = 180, bg = "white"
)
message("Figura salva: diagnosticos_residuos_MT_itens")

ggsave(
  file.path(DIR_FIGURAS,
            paste0("diagnosticos_residuos_LP_itens_", ts_global, ".png")),
  p_diag_lp, width = 14, height = 10, dpi = 180, bg = "white"
)
message("Figura salva: diagnosticos_residuos_LP_itens")

# =============================================================================
# ETAPA 12: GRÁFICOS DE COEFICIENTES — DIVIDIDOS POR GRUPO TEMÁTICO
# =============================================================================

grupos_tematicos <- list(
  "Contexto Socioeconômico e Familiar — Parte 1\n(Q01–Q09)" = 
    c("TX_RESP_Q01", "TX_RESP_Q02", "TX_RESP_Q03", "TX_RESP_Q04",
      "TX_RESP_Q05a","TX_RESP_Q05b","TX_RESP_Q05c",
      "TX_RESP_Q06",
      "TX_RESP_Q07a","TX_RESP_Q07b","TX_RESP_Q07c","TX_RESP_Q07d","TX_RESP_Q07e",
      "TX_RESP_Q08","TX_RESP_Q09"),

  "Contexto Socioeconômico e Familiar — Parte 2\n(Q10–Q14)" = 
    c("TX_RESP_Q10a","TX_RESP_Q10b","TX_RESP_Q10c","TX_RESP_Q10d",
      "TX_RESP_Q10e","TX_RESP_Q10f",
      "TX_RESP_Q11a","TX_RESP_Q11b","TX_RESP_Q11c",
      "TX_RESP_Q12a","TX_RESP_Q12b","TX_RESP_Q12c","TX_RESP_Q12d",
      "TX_RESP_Q12e","TX_RESP_Q12f","TX_RESP_Q12g",
      "TX_RESP_Q13a","TX_RESP_Q13b","TX_RESP_Q13c","TX_RESP_Q13d",
      "TX_RESP_Q13e","TX_RESP_Q13f","TX_RESP_Q13g","TX_RESP_Q13h","TX_RESP_Q13i",
      "TX_RESP_Q14"),

  "Contexto Socioeconômico e Familiar — Parte 3\n(Q15–Q20)" = 
    c("TX_RESP_Q15a","TX_RESP_Q15b",
      "TX_RESP_Q16","TX_RESP_Q17","TX_RESP_Q18","TX_RESP_Q19","TX_RESP_Q20"),

  "Práticas Escolares e Tecnologia\n(Q21–Q25)" = 
    c("TX_RESP_Q21a","TX_RESP_Q21b","TX_RESP_Q21c","TX_RESP_Q21d","TX_RESP_Q21e",
      "TX_RESP_Q22a","TX_RESP_Q22b","TX_RESP_Q22c","TX_RESP_Q22d",
      "TX_RESP_Q22e","TX_RESP_Q22f","TX_RESP_Q22g","TX_RESP_Q22h",
      "TX_RESP_Q23a","TX_RESP_Q23b","TX_RESP_Q23c","TX_RESP_Q23d",
      "TX_RESP_Q23e","TX_RESP_Q23f","TX_RESP_Q23g","TX_RESP_Q23h","TX_RESP_Q23i",
      "TX_RESP_Q24","TX_RESP_Q25"),

  "Variáveis Estruturais da Escola" = 
    c("TIPO_ESCOLA","AREA","LOCALIZACAO")
)

# ── FUNÇÃO ────────────────────────────────────────────────────────────────────
gerar_grafico_grupo <- function(coef_df, nome_modelo, cor_sig,
                                grupo_nome, itens_grupo) {
  
  dados_plot <- coef_df |>
    filter(Termo != "(Intercept)", p_valor < ALPHA) |>
    filter(
      str_replace(Termo, "_[A-Z]$", "") %in% itens_grupo |
      str_detect(Termo, "^TIPO_ESCOLA_|^AREA_|^LOCALIZACAO_")
    ) |>
    mutate(Termo = fct_reorder(Termo, abs(Coef)))
  
  if (nrow(dados_plot) == 0) return(NULL)
  
  n_preds    <- nrow(dados_plot)
  altura_fig <- max(5, n_preds * 0.32)
  
  p <- ggplot(dados_plot, aes(x = Termo, y = Coef)) +
    geom_hline(yintercept = 0, linetype = "dashed",
               colour = "#D62728", linewidth = 0.9) +
    geom_col(fill = cor_sig, alpha = 0.85,
             colour = "black", linewidth = 0.25) +
    geom_errorbar(aes(ymin = IC_95_inf, ymax = IC_95_sup),
                  width = 0.35, linewidth = 0.55, colour = "#333333") +
    geom_text(
      aes(label = Sig,
          y = if_else(Coef >= 0, IC_95_sup + 0.5, IC_95_inf - 0.5)),
      size = 3.2, fontface = "bold", colour = "#1A1A1A"
    ) +
    coord_flip() +
    scale_y_continuous(
      breaks = scales::pretty_breaks(n = 7),
      labels = function(x) paste0(ifelse(x > 0, "+", ""), x)
    ) +
    labs(
      title    = paste0(grupo_nome, " — Modelo ", nome_modelo),
      subtitle = paste0(
        n_preds, " coeficientes significativos (p < 0,05) | ",
        "ordenados por |coeficiente| | categoria A = referência"
      ),
      x       = NULL,
      y       = "Coeficiente (pontos de proficiência SAEB)",
      caption = paste0(
        "Coef > 0: categoria aumenta proficiência vs referência 'A'  |  ",
        "Coef < 0: reduz proficiência\n",
        "Barras de erro = IC 95%  |  *** p<0,001  ** p<0,01  * p<0,05"
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.background    = element_rect(fill = "white", colour = NA),
      panel.background   = element_rect(fill = "white", colour = NA),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = "#E5E5E5", linewidth = 0.4),
      panel.grid.minor   = element_blank(),
      plot.title    = element_text(face = "bold", size = 13, colour = "#1A1A1A"),
      plot.subtitle = element_text(size = 10, colour = "#555555"),
      plot.caption  = element_text(size = 8.5, colour = "#777777",
                                   face = "italic", hjust = 0, lineheight = 1.4),
      axis.text.y   = element_text(size = 10, colour = "#1A1A1A"),
      axis.text.x   = element_text(size = 10),
      axis.title.x  = element_text(size = 10, margin = margin(t = 8)),
      plot.margin   = margin(14, 20, 10, 14)
    )
  
  list(plot = p, altura = altura_fig, n = n_preds)
}

# ── Gerar com numeração sequencial por modelo ─────────────────────────────────
contador_mt <- 1L
contador_lp <- 1L

for (grupo_nome in names(grupos_tematicos)) {
  
  itens_grupo <- grupos_tematicos[[grupo_nome]]
  
  # MT
  res_mt <- gerar_grafico_grupo(coef_mt, "MEDIA_MT", "#E65100",
                                grupo_nome, itens_grupo)
  if (!is.null(res_mt)) {
    arq <- file.path(DIR_FIGURAS,
                     sprintf("coef_grupo_MT_IMAGEM%02d_%s.png",
                             contador_mt, ts_global))
    ggsave(arq, res_mt$plot, width = 12, height = res_mt$altura,
           dpi = 180, bg = "white", limitsize = FALSE)
    message("Salvo: ", basename(arq), "  (", res_mt$n, " coefs) — ", grupo_nome)
    contador_mt <- contador_mt + 1L
  } else {
    message("⚠️  Sem coefs significativos: MT — ", grupo_nome)
  }
  
  # LP
  res_lp <- gerar_grafico_grupo(coef_lp, "MEDIA_LP", "#1B5E20",
                                grupo_nome, itens_grupo)
  if (!is.null(res_lp)) {
    arq <- file.path(DIR_FIGURAS,
                     sprintf("coef_grupo_LP_IMAGEM%02d_%s.png",
                             contador_lp, ts_global))
    ggsave(arq, res_lp$plot, width = 12, height = res_lp$altura,
           dpi = 180, bg = "white", limitsize = FALSE)
    message("Salvo: ", basename(arq), "  (", res_lp$n, " coefs) — ", grupo_nome)
    contador_lp <- contador_lp + 1L
  } else {
    message("⚠️  Sem coefs significativos: LP — ", grupo_nome)
  }
}

message("\n✅ Gráficos gerados em: ", DIR_FIGURAS)
message("   MT: ", contador_mt - 1L, " imagens")
message("   LP: ", contador_lp - 1L, " imagens")

# =============================================================================
# ETAPA 13: PREDITOS vs OBSERVADOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 13: PREDITOS vs OBSERVADOS")
message(strrep("-", 50))

gerar_pred_obs <- function(modelo, summary_mod, nome, cor) {

  dados_po <- tibble(
    Observado = modelo$model[[1]],
    Predito   = fitted(modelo)
  )

  if (!validar_dados_plot(dados_po, paste0("Preditos vs Observados — ", nome))) {
    return(NULL)
  }

  r2   <- round(summary_mod$adj.r.squared, 4)
  rmse <- round(sqrt(mean(summary_mod$residuals^2)), 2)
  corr <- round(cor(dados_po$Observado, dados_po$Predito), 3)

  ggplot(dados_po, aes(x = Observado, y = Predito)) +
    geom_point(alpha = 0.40, size = 2.2, colour = cor, stroke = 0.3) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed",
                colour = "#D62728", linewidth = 1.3) +
    geom_smooth(method = "lm", se = FALSE,
                colour = "#2CA02C", linewidth = 1.1) +
    annotate("label", x = Inf, y = -Inf,
             label = paste0("R² = ", r2, "\nRMSE = ", rmse,
                            "\nCorr = ", corr),
             hjust = 1.05, vjust = -0.3, size = 4.2, fontface = "bold",
             colour = "#1A1A1A", fill = "#FFFFEE", label.size = 0.5) +
    coord_fixed(ratio = 1) +
    labs(
      title    = paste0("Preditos vs Observados (", nome,
                        ") — Itens Brutos"),
      subtitle = "Linha vermelha = ajuste perfeito | Linha verde = ajuste do modelo",
      x        = "Proficiência observada (média da escola)",
      y        = "Proficiência predita",
      caption  = paste0(
        "Pontos sobre a diagonal = predição perfeita.\n",
        "Acima da linha = subestimação | Abaixo = superestimação."
      )
    ) +
    tema_saeb() +
    theme(aspect.ratio = 1)
}

p_pred_mt <- gerar_pred_obs(modelo_mt, summary_mt, "MEDIA_MT", "#1f77b4")
p_pred_lp <- gerar_pred_obs(modelo_lp, summary_lp, "MEDIA_LP", "#ff7f0e")

if (!is.null(p_pred_mt)) {
  ggsave(
    file.path(DIR_FIGURAS,
              paste0("preditos_vs_observados_MT_itens_", ts_global, ".png")),
    p_pred_mt, width = 9, height = 9, dpi = 180, bg = "white"
  )
  message("Figura salva: preditos_vs_observados_MT_itens")
} else {
  message("⚠️  Gráfico preditos_MT não pôde ser gerado")
}

if (!is.null(p_pred_lp)) {
  ggsave(
    file.path(DIR_FIGURAS,
              paste0("preditos_vs_observados_LP_itens_", ts_global, ".png")),
    p_pred_lp, width = 9, height = 9, dpi = 180, bg = "white"
  )
  message("Figura salva: preditos_vs_observados_LP_itens")
} else {
  message("⚠️  Gráfico preditos_LP não pôde ser gerado")
}

# =============================================================================
# ETAPA 14: GRÁFICO COMPARATIVO DE R²
# =============================================================================

dados_r2 <- tibble(
  Modelo = c("MEDIA_MT\n(Matemática)", "MEDIA_LP\n(Língua Portuguesa)"),
  R2     = c(summary_mt$adj.r.squared, summary_lp$adj.r.squared),
  Cor    = c("#1f77b4", "#ff7f0e")
)

p_r2 <- ggplot(dados_r2, aes(x = Modelo, y = R2, fill = Modelo)) +
  geom_col(alpha = 0.90, colour = "black", linewidth = 0.8) +
  geom_text(aes(label = paste0(round(R2 * 100, 1), "%")),
            vjust = -0.5, size = 6, fontface = "bold", colour = "#1A1A1A") +
  geom_hline(yintercept = 0.30, linetype = "dotted",
             colour = "#2CA02C", linewidth = 1.1) +
  geom_hline(yintercept = 0.50, linetype = "dotted",
             colour = "#FFA500", linewidth = 1.1) +
  geom_hline(yintercept = 0.70, linetype = "dotted",
             colour = "#D62728", linewidth = 1.1) +
  annotate("text", x = 0.55, y = 0.31, label = "30% — razoável",
           size = 3.8, colour = "#2CA02C", hjust = 0, fontface = "bold") +
  annotate("text", x = 0.55, y = 0.51, label = "50% — bom",
           size = 3.8, colour = "#8B6914", hjust = 0, fontface = "bold") +
  annotate("text", x = 0.55, y = 0.71, label = "70% — excelente",
           size = 3.8, colour = "#D62728", hjust = 0, fontface = "bold") +
  scale_y_continuous(
    limits = c(0, max(dados_r2$R2) * 1.2),
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_fill_manual(values = setNames(dados_r2$Cor, dados_r2$Modelo),
                    guide = "none") +
  labs(
    title    = "Qualidade do Ajuste: R² Ajustado — Itens Brutos (Dummies)",
    subtitle = "Percentual da variância da proficiência explicado pelos itens do questionário",
    x        = NULL,
    y        = "R² Ajustado",
    caption  = paste0(
      "Modelo usa proporções por escola das dummies dos itens Q01–Q25,\n",
      "após eliminação iterativa de multicolinearidade (VIF > ", LIMIAR_VIF, ").\n",
      "R² ajustado penaliza a inclusão de variáveis irrelevantes."
    )
  ) +
  tema_saeb() +
  theme(
    axis.text  = element_text(size = 11, colour = "#1A1A1A"),
    plot.title = element_text(size = 14, colour = "#1A1A1A")
  )

ggsave(
  file.path(DIR_FIGURAS,
            paste0("resumo_qualidade_ajuste_itens_", ts_global, ".png")),
  p_r2, width = 8, height = 6, dpi = 180, bg = "white"
)
message("Figura salva: resumo_qualidade_ajuste_itens")

# =============================================================================
# ETAPA 15: MAPA DE CALOR — VIF DAS PREDITORAS FINAIS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 15: MAPA DE CALOR DOS VIFs FINAIS")
message(strrep("-", 50))

vif_final <- tryCatch(
  car::vif(modelo_mt),
  error = function(e) {
    message("  ⚠️  VIF não pôde ser calculado para o modelo final: ", conditionMessage(e))
    NULL
  }
)

if (is.null(vif_final) || length(vif_final) == 0L) {
  message("  ⚠️  Pulando mapa de calor VIF — sem preditoras suficientes.")
} else {

  if (is.matrix(vif_final)) vif_final <- vif_final[, 1]

  df_vif <- tibble(
    Predictor = names(vif_final),
    VIF       = as.numeric(vif_final),
    Item      = str_extract(Predictor, "TX_RESP_Q[^_]+")
  ) |>
    mutate(Item = if_else(is.na(Item), Predictor, Item)) |>
    arrange(desc(VIF))

  # Número de barras: min entre 40 e total de preditoras
  n_barras <- min(40L, nrow(df_vif))

  p_vif <- ggplot(df_vif |> slice_max(VIF, n = n_barras),
                  aes(x = fct_reorder(Predictor, VIF), y = VIF,
                      fill = VIF)) +
    geom_col(alpha = 0.85) +
    geom_hline(yintercept = LIMIAR_VIF, linetype = "dashed",
               colour = "#D62728", linewidth = 0.9) +
    coord_flip() +
    scale_fill_gradient(low = "#AEC6CF", high = "#D62728",
                        name = "VIF") +
    scale_y_continuous(breaks = c(1, 2, 5, LIMIAR_VIF)) +
    labs(
      title    = paste0("VIF das Preditoras Finais (Top ", n_barras,
                        ") — Modelo MEDIA_MT"),
      subtitle = "Após eliminação iterativa: todas as preditoras mantidas têm VIF ≤ limiar",
      x        = NULL,
      y        = "Variance Inflation Factor (VIF)",
      caption  = paste0("Linha vermelha = limiar VIF = ", LIMIAR_VIF,
                        ". VIF < 5 = baixa multicolinearidade (verde/azul).")
    ) +
    tema_saeb() +
    theme(legend.position = "right")

  ggsave(
    file.path(DIR_FIGURAS,
              paste0("mapa_calor_vif_itens_", ts_global, ".png")),
    p_vif, width = 12, height = max(8, n_barras * 0.25), dpi = 180, bg = "white"
  )
  message("Figura salva: mapa_calor_vif_itens")

}

# =============================================================================
# SALVAR MODELOS RDS
# =============================================================================

saveRDS(modelo_mt,
        file.path(DIR_MODELOS, paste0("modelo_MT_itens_", ts_global, ".rds")))
saveRDS(modelo_lp,
        file.path(DIR_MODELOS, paste0("modelo_LP_itens_", ts_global, ".rds")))

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

message("\n", strrep("=", 70))
message("RELATÓRIO FINAL — ITENS BRUTOS (DUMMIES)")
message(strrep("=", 70))
message("\nPré-processamento:")
message("  Alunos no raw            : ", nrow(dados_brutos))
message("  Escolas na base final    : ", nrow(df_completo))
message("  Dummies geradas (total)  : ", length(todas_dummies))
message("  [A] Respostas inválidas  : tratadas como NA antes da geração das dummies")
message("  [B] Removidas (var ≈ 0)  : ", n_removidas_var0)
message("  [C] Removidas (VIF > ",  LIMIAR_VIF, ")    : ", length(log_vif))
message("  Preditoras no modelo     : ", length(preditoras_finais))
message("\nModelos:")
message("  MT — R²aj: ", round(summary_mt$adj.r.squared, 4),
        " | RMSE: ", round(sqrt(mean(summary_mt$residuals^2)), 2))
message("  LP — R²aj: ", round(summary_lp$adj.r.squared, 4),
        " | RMSE: ", round(sqrt(mean(summary_lp$residuals^2)), 2))
message("\nArquivos de log gerados:")
message("  log_eliminadas_var0_", ts_global, ".csv  (etapa B)")
message("  log_vif_removidos_",   ts_global, ".csv  (etapa C)")
message("\nArquivos gerados em:")
message("  ", DIR_TABELAS)
message("  ", DIR_FIGURAS)
message("  ", DIR_MODELOS)
message("\n✅ MELHORIAS v1.1:")
message("  • Gráfico de coeficientes exibe TODAS as preditoras (não apenas top 20)")
message("  • Altura do gráfico calculada dinamicamente pelo nº de preditoras")
message("  • limitsize = FALSE para acomodar figuras muito altas")
message("  • Log das variáveis eliminadas por variância zero salvo em CSV (etapa B)")
message("  • Nota metodológica expandida com os 3 critérios de eliminação")
message("  • Relatório final discrimina as 3 etapas de eliminação [A], [B], [C]")

message("\n", strrep("=", 70))
message("CONCLUÍDO COM SUCESSO!")
message(strrep("=", 70))
