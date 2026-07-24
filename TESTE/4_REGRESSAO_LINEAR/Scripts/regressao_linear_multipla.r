################################################################################
# SCRIPT: regressao_linear_multipla.r
#
# FUNCIONALIDADE:
#   Regressao Linear Multipla com variaveis dummy
#   Parte dos dados brutos dos alunos (TS_ALUNO_34EM.csv),
#   agrega por escola e modela MEDIA_MT e MEDIA_LP
#
# ENTRADA:
#   - TS_ALUNO_34EM.csv  (dados brutos SAEB - nivel aluno)
#
# SAIDA:
#   - resumo_modelos_<ts>.csv
#   - coeficientes_MT_<ts>.csv / coeficientes_LP_<ts>.csv
#   - diagnosticos_MT_<ts>.csv / diagnosticos_LP_<ts>.csv
#   - diagnosticos_residuos_MT_<ts>.png / _LP_<ts>.png
#   - preditos_vs_observados_MT_<ts>.png / _LP_<ts>.png
#   - resumo_qualidade_ajuste_<ts>.png
#   - coeficientes_MT_<ts>.png / coeficientes_LP_<ts>.png
#
# VERSAO: 2.0 - Maio 2026
#
# ---------------------------------------------------------------------------
# NOTA METODOLOGICA - ESCOLHA DO INSE COMO VARIAVEL SOCIOECONOMICA
# ---------------------------------------------------------------------------
#
# O questionario contextual do SAEB contem 72 itens socioeconomicos
# (colunas TX_RESP_Q01 a TX_RESP_Q25, incluindo subitens como Q05a/b/c).
# Poder-se-ia questionar se essas perguntas brutas nao deveriam ser usadas
# diretamente como preditoras no modelo. A opcao pelo INSE_ALUNO (agregado
# como INSE_MEDIO por escola) e deliberada e sustentada pelos seguintes
# argumentos:
#
# 1. O INSE ja e a sintese psicometrica das perguntas brutas
#    O INEP constroi o INSE_ALUNO por meio de um modelo de Teoria de
#    Resposta ao Item (TRI), calibrado sobre exatamente esses itens
#    (Q01-Q25). Ele sintetiza em um unico score continuo a informacao
#    latente de todas as respostas, com pesos derivados de modelagem
#    psicometrica validada. Usar os itens brutos em lugar do INSE seria
#    equivalente a descartar o produto final em favor dos insumos,
#    perdendo precisao e coerencia metodologica.
#    Referencia: INEP (2021). Nota Tecnica - Indicador de Nivel
#    Socioeconomico das Escolas de Educacao Basica (INSE).
#
# 2. Risco de multicolinearidade severa
#    Os 72 itens medem facetas do mesmo constructo latente (nivel
#    socioeconomico) e sao, portanto, altamente correlacionados entre si.
#    Inclui-los simultaneamente como preditores independentes viola a
#    premissa de ausencia de multicolinearidade perfeita da regressao OLS,
#    tornando os estimadores instaveis (variancias infladas) e a
#    interpretacao dos coeficientes inviavel. O VIF (Variance Inflation
#    Factor) de varios preditores ultrapassaria o limiar critico de 10.
#
# 3. Explosao dimensional e custo de graus de liberdade
#    As respostas sao variaveis categoricas ordinais codificadas como
#    letras (A, B, C, D, ...). A codificacao dummy de todos os itens
#    geraria facilmente 150-200 variaveis adicionais, consumindo graus
#    de liberdade e comprometendo o ajuste em amostras de tamanho
#    moderado (nivel escola).
#
# 4. Validade e reprodutibilidade
#    O INSE possui metodologia publica, documentada e reproduzivel,
#    facilitando comparacoes com outros estudos que utilizem dados SAEB.
#    Uma construcao ad hoc de indice a partir dos itens brutos exigiria
#    validacao psicometrica propria (analise fatorial confirmatoria ou
#    TRI), o que extrapolaria o escopo deste trabalho.
#
# CONCLUSAO: O uso de INSE_MEDIO como proxy socioeconomico e a escolha
# metodologicamente mais rigorosa, parcimoniana e defensavel para os
# objetivos desta analise. Pesquisadores que desejarem decompor o efeito
# de dimensoes especificas do NSE (ex.: capital cultural vs. capital
# economico) deverao conduzir uma analise fatorial exploratoria previa
# sobre os itens brutos, construindo subescores interpretaveis antes de
# inclui-los em qualquer modelo preditivo.
# ---------------------------------------------------------------------------
################################################################################

library(tidyverse)
library(broom)
library(patchwork)
if (!requireNamespace("car", quietly = TRUE)) install.packages("car")
library(car)


# =============================================================================
# DETECCAO AUTOMATICA DE CAMINHOS
# =============================================================================

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

ARQUIVO_DADOS_BRUTOS <- file.path(RAIZ, "MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv")

DIR_BASE         <- file.path(RAIZ, "TESTE/4_REGRESSAO_LINEAR")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

message("Arquivo de dados: ", ARQUIVO_DADOS_BRUTOS)
message("Existe? ", file.exists(ARQUIVO_DADOS_BRUTOS))
# =========================================================
# CONFIGURACOES
# =============================================================================

# Filtro de qualidade: escolas com menos alunos que isso sao descartadas
MIN_ALUNOS_ESCOLA <- 5

# Filtro de outliers nas proficiencias individuais (escala SAEB: ~150-800)
PROF_MIN <- 150
PROF_MAX <- 800

# Numero minimo de alunos com INSE para calcular INSE medio da escola
MIN_ALUNOS_INSE <- 3

# Variaveis do modelo
# ---------------------------------------------------------------------------
# NOTA: AREA_LOCAL combina AREA (Capital/Interior) com LOCALIZACAO
# (Urbana/Rural) em uma unica variavel de 4 categorias:
#   Urbana_Capital, Urbana_Interior, Rural_Capital, Rural_Interior
# Isso substitui AREA e LOCALIZACAO como preditores separados nos modelos
# de regressao, permitindo capturar interacoes como "escolas rurais do
# interior" vs. "urbanas da capital" - lacuna identificada na apresentacao
# do TCC para futura investigacao.
# ---------------------------------------------------------------------------
VARIAVEL_DEPENDENTE <- c("MEDIA_MT", "MEDIA_LP")
VARS_CATEGORICAS    <- c("TIPO_ESCOLA", "AREA_LOCAL")
VARS_CONTINUAS      <- c("INSE_MEDIO")
ALPHA               <- 0.05

# =============================================================================
# FUNCAO: CRIAR DUMMIES COM REFERENCIAS EXPLICITAS
# =============================================================================

criar_dummies_com_refs <- function(df, vars_cat, refs_explicitas = NULL) {
  # refs_explicitas: named list. Ex: list(TIPO_ESCOLA = "Publica", AREA = "Capital")
  # Se nao fornecido, usa o primeiro valor ordenado como referencia (aviso emitido)
  
  vars_ok      <- intersect(vars_cat, names(df))
  dummies_list <- list()
  refs_usadas  <- list()
  
  for (var in vars_ok) {
    valores <- sort(unique(na.omit(df[[var]])))
    
    # Determinar referencia
    if (!is.null(refs_explicitas) && var %in% names(refs_explicitas)) {
      ref <- refs_explicitas[[var]]
      if (!(ref %in% valores)) {
        warning("Referencia '", ref, "' nao encontrada em ", var, 
                ". Usando primeira ordenada: ", valores[1])
        ref <- valores[1]
      }
    } else {
      ref <- valores[1]  # Primeira em ordem alfabetica = referencia
      warning("Nenhuma referencia explicita para ", var, 
              ". Usando categoria de referencia: ", ref)
    }
    
    refs_usadas[[var]] <- ref
    
    # Criar dummies para todas EXCETO a referencia
    for (valor in valores[valores != ref]) {
      nome          <- paste0(var, "_", valor)
      df[[nome]]    <- as.integer(df[[var]] == valor)
      dummies_list[[nome]] <- c(var, valor, "vs", ref)
    }
  }
  
  attr(df, "dummies_criadas") <- dummies_list
  attr(df, "refs_dummies")    <- refs_usadas
  df
}

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

# =============================================================================
# INICIALIZACAO
# =============================================================================

for (d in c(DIR_MODELOS, DIR_DIAGNOSTICOS, DIR_FIGURAS, DIR_TABELAS))
  dir.create(d, showWarnings = FALSE, recursive = TRUE)

ts_global <- format(Sys.time(), "%H%M%S")

message(strrep("=", 70))
message("REGRESSAO LINEAR MULTIPLA - DADOS BRUTOS SAEB")
message(strrep("=", 70))

# =============================================================================
# ETAPA 1: CARREGAR DADOS BRUTOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 1: CARREGANDO DADOS BRUTOS")
message(strrep("-", 50))

if (is.null(ARQUIVO_DADOS_BRUTOS) || !file.exists(ARQUIVO_DADOS_BRUTOS)) {
  stop(
    "Arquivo TS_ALUNO*.csv nao encontrado em:\n  ", DIR_DADOS_BRUTOS,
    "\nVerifique se a pasta MICRODADOS_SAEB_2023/DADOS existe na raiz do projeto."
  )
}

message("Arquivo: ", basename(ARQUIVO_DADOS_BRUTOS))

dados_brutos <- read_csv(
  ARQUIVO_DADOS_BRUTOS,
  col_types = cols(
    ID_ESCOLA          = col_character(),
    IN_PUBLICA         = col_integer(),
    ID_AREA            = col_integer(),
    ID_LOCALIZACAO     = col_integer(),
    IN_PROFICIENCIA_MT = col_integer(),
    IN_PROFICIENCIA_LP = col_integer(),
    PROFICIENCIA_MT_SAEB = col_double(),
    PROFICIENCIA_LP_SAEB = col_double(),
    IN_INSE            = col_integer(),
    INSE_ALUNO         = col_double(),
    .default           = col_skip()     # ignora todas as outras colunas
  ),
  show_col_types = FALSE
)

message("Alunos carregados: ", nrow(dados_brutos))
message("Escolas distintas: ", n_distinct(dados_brutos$ID_ESCOLA))

# =============================================================================
# ETAPA 2: AGREGAR POR ESCOLA
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 2: AGREGANDO POR ESCOLA")
message(strrep("-", 50))

message("Filtros aplicados:")
message("  Proficiencia valida:  IN_PROFICIENCIA_MT/LP = 1")
message("  Faixa de valores:     PROFICIENCIA_SAEB entre ", PROF_MIN, " e ", PROF_MAX)
message("  Minimo alunos/escola: ", MIN_ALUNOS_ESCOLA)

# Criar dummies com referencias EXPLICITAS
refs_modelo <- list(
  TIPO_ESCOLA = "Publica",
  AREA_LOCAL  = "Urbana_Capital"
)

# ?? Medias de proficiencia ????????????????????????????????????????????????????
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

message("\nEscolas apos filtro de proficiencia: ", nrow(media_prof))

# ?? INSE medio por escola ?????????????????????????????????????????????????????
# NOTA: utilizamos INSE_ALUNO (score TRI calculado pelo INEP) como proxy
# socioeconomico, e nao os itens brutos do questionario (TX_RESP_Q01-Q25).
# Justificativa detalhada no cabecalho deste script (secao NOTA METODOLOGICA).
# Em sintese: o INSE ja sintetiza os 72 itens via TRI com validacao psicometrica
# publicada; usar os itens brutos introduziria multicolinearidade severa e
# explosao dimensional inviavel para regressao OLS no nivel escola.
inse_escola <- dados_brutos |>
  filter(IN_INSE == 1, !is.na(INSE_ALUNO)) |>
  group_by(ID_ESCOLA) |>
  summarise(
    INSE_MEDIO   = mean(INSE_ALUNO, na.rm = TRUE),
    N_ALUNOS_INSE = n(),
    .groups      = "drop"
  ) |>
  filter(N_ALUNOS_INSE >= MIN_ALUNOS_INSE)

# ?? Variaveis categoricas (1 linha por escola) ????????????????????????????????
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
      AREA        = if_else(ID_AREA == 1, "Capital", "Interior"),
      LOCALIZACAO = if_else(ID_LOCALIZACAO == 1, "Urbana", "Rural"),
      AREA_LOCAL  = paste0(LOCALIZACAO, "_", AREA)
    ) |>
  select(ID_ESCOLA, TIPO_ESCOLA, AREA, LOCALIZACAO, AREA_LOCAL)

# ?? Juntar tudo ???????????????????????????????????????????????????????????????
dados_escola <- media_prof |>
  inner_join(inse_escola,  by = "ID_ESCOLA") |>
  inner_join(categ_escola, by = "ID_ESCOLA") |>
  select(ID_ESCOLA, TIPO_ESCOLA, AREA, LOCALIZACAO, AREA_LOCAL,
         MEDIA_MT, MEDIA_LP, INSE_MEDIO, N_ALUNOS_MT, N_ALUNOS_INSE)

message("Escolas na base final (com INSE): ", nrow(dados_escola))
message("\nDistribuicao por variavel categorica:")
message("  TIPO_ESCOLA:\n", paste(capture.output(print(table(dados_escola$TIPO_ESCOLA))), collapse = "\n"))
message("  AREA_LOCAL (variavel combinada usada nos modelos):\n",
        paste(capture.output(print(table(dados_escola$AREA_LOCAL))), collapse = "\n"))
message("  (AREA e LOCALIZACAO mantidas separadas apenas para referencia descritiva)")
message("\nEstatisticas das proficiencias:")
message("  MEDIA_MT - media: ", round(mean(dados_escola$MEDIA_MT), 2),
        " | dp: ", round(sd(dados_escola$MEDIA_MT), 2),
        " | min: ", round(min(dados_escola$MEDIA_MT), 2),
        " | max: ", round(max(dados_escola$MEDIA_MT), 2))
message("  MEDIA_LP - media: ", round(mean(dados_escola$MEDIA_LP), 2),
        " | dp: ", round(sd(dados_escola$MEDIA_LP), 2),
        " | min: ", round(min(dados_escola$MEDIA_LP), 2),
        " | max: ", round(max(dados_escola$MEDIA_LP), 2))

# Salvar base agregada para rastreabilidade
write_csv(dados_escola,
          caminho_saida(DIR_BASE, "tabelas", "base_escolas_agregada", "csv"))
message("\nBase agregada salva: base_escolas_agregada_", ts_global, ".csv")

# Documentar referencias utilizadas
refs_doc <- tibble(
  Variavel  = c("TIPO_ESCOLA", "AREA_LOCAL"),
  Referencia = c(refs_modelo$TIPO_ESCOLA, refs_modelo$AREA_LOCAL),
  Descricao = c(
    "Categoria base para comparacao de tipo de escola",
    "Categoria base para comparacao da localizacao combinada (urbana/rural ? capital/interior)"
  )
)
write_csv(refs_doc, caminho_saida(DIR_BASE, "tabelas", "REFERENCIAS_MODELOS", "csv"))
message("Referencias documentadas: REFERENCIAS_MODELOS_", ts_global, ".csv")

# =============================================================================
# ETAPA 3: PREPARAR DADOS DO MODELO
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 3: PREPARANDO DADOS DO MODELO")
message(strrep("-", 50))

# Validar categoricas antes de criar dummies
message("\nValidacao de valores faltantes nas categoricas:")
for (var in VARS_CATEGORICAS) {
  n_na <- sum(is.na(dados_escola[[var]]))
  if (n_na > 0) {
    warning("!?  ", var, " tem ", n_na, " valores faltantes. Serao excluidos.")
    dados_escola <- dados_escola |> filter(!is.na(!!sym(var)))
  } else {
    message("  OK ", var, ": sem faltantes")
  }
}

message("\nEscolas apos remocao de NAs nas categoricas: ", nrow(dados_escola))



dados_modelo <- criar_dummies_com_refs(dados_escola, VARS_CATEGORICAS, refs_explicitas = refs_modelo)
dummies_info <- attr(dados_modelo, "dummies_criadas")
refs_usadas  <- attr(dados_modelo, "refs_dummies")

message("\nReferencias utilizadas no modelo:")
for (var in names(refs_usadas)) {
  message("  OK ", var, " = ", refs_usadas[[var]])
}

message("\nVariaveis dummy criadas: ", length(dummies_info))
for (dummy_name in names(dummies_info)) {
  info <- dummies_info[[dummy_name]]
  message("  + ", dummy_name, "  (", info[3], " ", info[4], ")")
}

# Normalizar INSE (z-score)
dados_modelo <- dados_modelo |>
  mutate(INSE_MEDIO_norm = as.numeric(scale(INSE_MEDIO)))

message("INSE_MEDIO normalizado (z-score) -> INSE_MEDIO_norm")

# Preditoras: dummies + INSE_MEDIO_norm
# (exclui as colunas categoricas originais + AREA e LOCALIZACAO separadas,
#  que e redundant com AREA_LOCAL nos modelos; e INSE_MEDIO bruto)
preditoras <- setdiff(
  names(dados_modelo),
  c(VARIAVEL_DEPENDENTE, VARS_CATEGORICAS, VARS_CONTINUAS,
    "AREA", "LOCALIZACAO",
    "ID_ESCOLA", "N_ALUNOS_MT", "N_ALUNOS_INSE")
)

message("Preditoras no modelo: ", paste(preditoras, collapse = ", "))

# =============================================================================
# ETAPA 4: AJUSTAR MODELOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 4: AJUSTANDO MODELOS")
message(strrep("-", 50))

formula_mt <- as.formula(paste("MEDIA_MT ~", paste(preditoras, collapse = " + ")))
formula_lp <- as.formula(paste("MEDIA_LP ~", paste(preditoras, collapse = " + ")))

modelo_mt <- lm(formula_mt, data = dados_modelo)
modelo_lp <- lm(formula_lp, data = dados_modelo)

summary_mt <- summary(modelo_mt)
summary_lp <- summary(modelo_lp)

message("\n>>> MODELO MEDIA_MT <<<")
message("  Observacoes: ", nrow(dados_modelo))
message("  R2 ajustado: ", round(summary_mt$adj.r.squared, 4))
message("  F-statistic: ", round(summary_mt$fstatistic[1], 2))
message("  RMSE:        ", round(sqrt(mean(summary_mt$residuals^2)), 2))

message("\n>>> MODELO MEDIA_LP <<<")
message("  Observacoes: ", nrow(dados_modelo))
message("  R2 ajustado: ", round(summary_lp$adj.r.squared, 4))
message("  F-statistic: ", round(summary_lp$fstatistic[1], 2))
message("  RMSE:        ", round(sqrt(mean(summary_lp$residuals^2)), 2))

# =============================================================================
# ETAPA 4b: VERIFICAR MULTICOLINEARIDADE (VIF)
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 4b: MULTICOLINEARIDADE (VIF)")
message(strrep("-", 50))

vif_mt <- car::vif(modelo_mt)
vif_lp <- car::vif(modelo_lp)

message("\nFatores de Inflacao de Variancia (VIF):")
message("  MT - Minimo: ", round(min(vif_mt), 2), " | Maximo: ", round(max(vif_mt), 2))
message("  LP - Minimo: ", round(min(vif_lp), 2), " | Maximo: ", round(max(vif_lp), 2))
message("\n  (Interpretacao: VIF > 10 = multicolinearidade severa | VIF > 5 = problematico)")

# Salvar VIF para referencia
vif_df <- tibble(
  Variavel = names(vif_mt),
  VIF_MT   = as.numeric(vif_mt),
  VIF_LP   = as.numeric(vif_lp),
  Status_MT = case_when(
    as.numeric(vif_mt) > 10 ~ "CRITICO (>10)",
    as.numeric(vif_mt) > 5  ~ "Problematico (5-10)",
    TRUE ~ "OK (<5)"
  ),
  Status_LP = case_when(
    as.numeric(vif_lp) > 10 ~ "CRITICO (>10)",
    as.numeric(vif_lp) > 5  ~ "Problematico (5-10)",
    TRUE ~ "OK (<5)"
  )
)
write_csv(vif_df, caminho_saida(DIR_BASE, "tabelas", "VIF_multicolinearidade", "csv"))
message("\nVIF salvo em: VIF_multicolinearidade_", ts_global, ".csv")

# =============================================================================
# ETAPA 5: COEFICIENTES
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 5: EXTRAINDO COEFICIENTES")
message(strrep("-", 50))

extrair_coef <- function(modelo) {
  tidy(modelo) |>
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
    ) |>
    arrange(desc(abs(t_value)))
}

coef_mt <- extrair_coef(modelo_mt)
coef_lp <- extrair_coef(modelo_lp)

write_csv(coef_mt, caminho_saida(DIR_BASE, "tabelas", "coeficientes_MT", "csv"))
write_csv(coef_lp, caminho_saida(DIR_BASE, "tabelas", "coeficientes_LP", "csv"))

message("Coeficientes MT:")
print(coef_mt, n = Inf)
message("\nCoeficientes LP:")
print(coef_lp, n = Inf)

# =============================================================================
# ETAPA 5b: MODELOS COM TODAS AS REFERENCIAS (COMPARACOES SIMETRICAS)
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 5b: GERANDO COMPARACOES COM TODAS AS REFERENCIAS")
message(strrep("-", 50))

# Funcao auxiliar: criar dummies com referencia especifica
criar_dummies_ref_especifica <- function(df, vars_cat, ref_especifica) {
  # ref_especifica: named list. Ex: list(TIPO_ESCOLA = "Privada", ...)
  
  vars_ok      <- intersect(vars_cat, names(df))
  dummies_list <- list()
  
  for (var in vars_ok) {
    valores <- sort(unique(na.omit(df[[var]])))
    ref <- ref_especifica[[var]]
    
    # Criar dummies para todas EXCETO a referencia
    for (valor in valores[valores != ref]) {
      nome          <- paste0(var, "_", valor)
      df[[nome]]    <- as.integer(df[[var]] == valor)
      dummies_list[[nome]] <- c(var, valor, "vs", ref)
    }
  }
  
  attr(df, "dummies_criadas") <- dummies_list
  df
}

# Obter todas as categorias de cada variavel categorica
categorias_unicas <- list()
for (var in VARS_CATEGORICAS) {
  categorias_unicas[[var]] <- sort(unique(na.omit(dados_escola[[var]])))
}

message("\nCategorias encontradas:")
for (var in names(categorias_unicas)) {
  message("  ", var, ": ", paste(categorias_unicas[[var]], collapse = ", "))
}

# Gerar todos os modelos possiveis com diferentes referencias
modelos_comparacao <- list()
coef_comparacao_mt <- list()
coef_comparacao_lp <- list()

# Iterar sobre todas as combinacoes de referencias (TIPO_ESCOLA ? AREA_LOCAL)
for (ref_tipo in categorias_unicas$TIPO_ESCOLA) {
  for (ref_area_local in categorias_unicas$AREA_LOCAL) {

      ref_combo <- list(
        TIPO_ESCOLA = ref_tipo,
        AREA_LOCAL  = ref_area_local
      )

      # Criar chave para identificar esta combinacao
      chave <- paste(ref_tipo, ref_area_local, sep = "_")

      # Preparar dados com as novas dummies
      dados_temp <- dados_modelo |>
        select(ID_ESCOLA, MEDIA_MT, MEDIA_LP, INSE_MEDIO_norm,
               TIPO_ESCOLA, AREA_LOCAL)

      dados_temp <- criar_dummies_ref_especifica(dados_temp, VARS_CATEGORICAS, ref_combo)

      # Definir preditoras
      preditoras_temp <- setdiff(
        names(dados_temp),
        c("ID_ESCOLA", "MEDIA_MT", "MEDIA_LP", VARS_CATEGORICAS, "INSE_MEDIO")
      )

      # Ajustar modelos
      formula_mt_temp <- as.formula(paste("MEDIA_MT ~", paste(preditoras_temp, collapse = " + ")))
      formula_lp_temp <- as.formula(paste("MEDIA_LP ~", paste(preditoras_temp, collapse = " + ")))

      mod_mt <- lm(formula_mt_temp, data = dados_temp)
      mod_lp <- lm(formula_lp_temp, data = dados_temp)

      modelos_comparacao[[chave]] <- list(mt = mod_mt, lp = mod_lp)
      coef_comparacao_mt[[chave]] <- extrair_coef(mod_mt) |>
        mutate(Referencia = chave)
      coef_comparacao_lp[[chave]] <- extrair_coef(mod_lp) |>
        mutate(Referencia = chave)
    }
  }

message("OK ", length(modelos_comparacao), " modelos gerados com referencias diferentes")

# Consolidar coeficientes em uma tabela unica
tabela_comparacao_mt <- bind_rows(coef_comparacao_mt) |>
  filter(Termo != "(Intercept)") |>
  arrange(Termo, Referencia)

tabela_comparacao_lp <- bind_rows(coef_comparacao_lp) |>
  filter(Termo != "(Intercept)") |>
  arrange(Termo, Referencia)

write_csv(tabela_comparacao_mt,
          caminho_saida(DIR_BASE, "tabelas", "comparacao_todas_referencias_MT", "csv"))
write_csv(tabela_comparacao_lp,
          caminho_saida(DIR_BASE, "tabelas", "comparacao_todas_referencias_LP", "csv"))

message("\nOK Tabelas de comparacao salvas:")
message("  comparacao_todas_referencias_MT_", ts_global, ".csv")
message("  comparacao_todas_referencias_LP_", ts_global, ".csv")

# =============================================================================
# ETAPA 5c: GRAFICO DE COEFICIENTES - VERSAO TCC
# =============================================================================

n_escolas   <- nrow(dados_modelo)
r2_mt       <- round(summary_mt$adj.r.squared * 100, 1)
r2_lp       <- round(summary_lp$adj.r.squared * 100, 1)

# ?? Preparar dados ????????????????????????????????????????????????????????????
comparacao_simetrica <- bind_rows(
  coef_mt |> mutate(Modelo = "Matematica (MT)"),
  coef_lp |> mutate(Modelo = "Lingua Portuguesa (LP)")
) |>
  filter(Termo != "(Intercept)") |>
  mutate(
    Variavel = case_when(
      Termo == "TIPO_ESCOLA_Privada"           ~ "Tipo de escola\nPrivada",
      Termo == "AREA_LOCAL_Rural_Interior"    ~ "Localizacao combinada\nRural do Interior",
      Termo == "AREA_LOCAL_Rural_Capital"     ~ "Localizacao combinada\nRural da Capital",
      Termo == "AREA_LOCAL_Urbana_Interior"    ~ "Localizacao combinada\nUrbana do Interior",
      Termo == "INSE_MEDIO_norm"               ~ "Nivel socioeconomico\n(INSE +1 desvio-padrao)",
      TRUE ~ Termo
    ),
    Grupo = case_when(
      Termo == "INSE_MEDIO_norm"                                              ~ "1. Nivel Socioeconomico",
      Termo == "TIPO_ESCOLA_Privada"                                          ~ "2. Tipo de Escola",
      Termo %in% c("AREA_LOCAL_Rural_Interior",
                   "AREA_LOCAL_Rural_Capital",
                   "AREA_LOCAL_Urbana_Interior")                               ~ "3. Localizacao Combinada (Urbana/Rural ? Capital/Interior)",
      TRUE ~ "Outro"
    ),
    Variavel = factor(Variavel, levels = c(
      "Localizacao combinada\nRural do Interior",
      "Localizacao combinada\nRural da Capital",
      "Localizacao combinada\nUrbana do Interior",
      "Tipo de escola\nPrivada",
      "Nivel socioeconomico\n(INSE +1 desvio-padrao)"
    )),
    Magnitude = case_when(
      abs(Coef) >= 20 ~ "Alto",
      abs(Coef) >= 10 ~ "Medio",
      TRUE            ~ "Baixo"
    )
  )

# ?? Separadores de grupo (linhas horizontais entre categorias) ????????????????
# Eixo y?(levels factor de 1 a 5): 1=Rural_Interior, 2=Rural_Capital, 3=Urbana_Interior,
# 4=Tipo Privada, 5=INSE. Separadores em 3.5 (entre Localizacao e Tipo) e 4.5 (entre Tipo e INSE).
separadores_y <- c(3.5, 4.5)

# ?? Paleta: versao colorida E P&B geradas juntas ?????????????????????????????
gerar_grafico_coef_tcc <- function(colorido = TRUE) {

  if (colorido) {
    cores   <- c("Matematica (MT)" = "#1B6CA8", "Lingua Portuguesa (LP)" = "#C75B2A")
    formas  <- c("Matematica (MT)" = 21,        "Lingua Portuguesa (LP)" = 24)
    fill_ic <- c("Matematica (MT)" = "#1B6CA8", "Lingua Portuguesa (LP)" = "#C75B2A")
    cor_mag <- c("Alto" = "#8B0000", "Medio" = "#555555", "Baixo" = "#555555")
  } else {
    cores   <- c("Matematica (MT)" = "#111111", "Lingua Portuguesa (LP)" = "#666666")
    formas  <- c("Matematica (MT)" = 21,        "Lingua Portuguesa (LP)" = 24)
    fill_ic <- c("Matematica (MT)" = "#111111", "Lingua Portuguesa (LP)" = "#666666")
    cor_mag <- c("Alto" = "#000000", "Medio" = "#333333", "Baixo" = "#333333")
  }

  ggplot(comparacao_simetrica,
         aes(y = Variavel, x = Coef, colour = Modelo,
             shape = Modelo, fill = Modelo)) +

    # Faixa de destaque para INSE removida (conflito com eixo discreto no ggplot 3.4.2)

    # Separadores de grupo - removidos: conflitam com eixo discreto no ggplot 3.4.2

    # Linha zero no eixo x (Coef = 0)
    geom_vline(xintercept = 0,
               linetype = "dashed", colour = "#999999", linewidth = 0.8) +

    # ?? IC 95% ???????????????????????????????????????????????????????????????
    geom_errorbarh(aes(xmin = IC_95_inf, xmax = IC_95_sup),
                   position = position_dodge(width = 0.55),
                   height = 0.25, linewidth = 1.3, alpha = 0.45) +

    # ?? Pontos ???????????????????????????????????????????????????????????????
    geom_point(position = position_dodge(width = 0.55),
               size = 5, stroke = 1.4,
               colour = "white") +          # borda branca para destacar
    geom_point(position = position_dodge(width = 0.55),
               size = 3.8, stroke = 1.4) +

    # ?? Rotulos dos coeficientes ?????????????????????????????????????????????
    geom_text(
      aes(label = paste0(ifelse(Coef > 0, "+", ""), round(Coef, 1), Sig),
          x     = ifelse(Coef >= 0, IC_95_sup + 1.2, IC_95_inf - 1.2),
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
      breaks = seq(-10, 40, by = 10),
      labels = function(x) paste0(ifelse(x > 0, "+", ""), x),
      expand = expansion(mult = c(0.12, 0.15))
    ) +

    labs(
      title    = "Determinantes da proficiencia escolar - SAEB 2023 (3º serie EM)",
      subtitle = paste0(
        "Coeficientes da regressao linear multipla com intervalos de confianca 95%\n",
        "Comparado as escolas publicas e urbanas da Capital (referencia: Urbana_Capital)"
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
        "IC 95% calculado como Coef ? 1,96 ? EP\n",
        "INSE normalizado (z-score): coeficiente representa o efeito de +1 desvio-padrao ",
        "no nivel socioeconomico medio da escola"
      )
    ) +

    theme_minimal(base_size = 13) +
    theme(
      # Fundo totalmente branco
      plot.background   = element_rect(fill = "white", colour = NA),
      panel.background  = element_rect(fill = "white", colour = NA),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = "#E5E5E5", linewidth = 0.4),
      panel.grid.minor   = element_blank(),

      # Titulos
      plot.title    = element_text(face = "bold", size = 15, colour = "#1A1A1A",
                                   margin = margin(b = 4)),
      plot.subtitle = element_text(size = 11, colour = "#555555",
                                   lineheight = 1.3, margin = margin(b = 12)),
      plot.caption  = element_text(size = 9, colour = "#777777", face = "italic",
                                   hjust = 0, lineheight = 1.4,
                                   margin = margin(t = 14)),

      # Eixos
      axis.text.y  = element_text(size = 11, colour = "#1A1A1A",
                                  lineheight = 1.35, face = "plain"),
      axis.text.x  = element_text(size = 11, colour = "#555555"),
      axis.title.x = element_text(size = 11, colour = "#333333",
                                  margin = margin(t = 8)),

      # Legenda
      legend.position  = "top",
      legend.direction = "horizontal",
      legend.text      = element_text(size = 12),
      legend.title     = element_text(size = 12, face = "bold"),
      legend.key.size  = unit(1.1, "lines"),

      plot.margin = margin(16, 24, 12, 16)
    )
}

# ?? Salvar versao colorida ????????????????????????????????????????????????????
p_tcc_color <- gerar_grafico_coef_tcc(colorido = TRUE)
ggsave(
  caminho_saida(DIR_BASE, "figuras", "coeficientes_TCC_color", "png"),
  p_tcc_color, width = 12, height = 7, dpi = 200, bg = "white"
)
message("Figura salva: coeficientes_TCC_color")

# ?? Salvar versao P&B para impressao ?????????????????????????????????????????
p_tcc_pb <- gerar_grafico_coef_tcc(colorido = FALSE)
ggsave(
  caminho_saida(DIR_BASE, "figuras", "coeficientes_TCC_PB", "png"),
  p_tcc_pb, width = 12, height = 7, dpi = 200, bg = "white"
)
message("Figura salva: coeficientes_TCC_PB")

# =============================================================================
# ETAPA 6: DIAGNOSTICOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 6: DIAGNOSTICOS")
message(strrep("-", 50))

extrair_diag <- function(modelo, summary_mod) {
  tibble(
    Diagnostico = c("R2 ajustado", "RMSE", "AIC", "BIC"),
    Valor       = c(
      round(summary_mod$adj.r.squared, 4),
      round(sqrt(mean(summary_mod$residuals^2)), 2),
      round(AIC(modelo), 2),
      round(BIC(modelo), 2)
    ),
    Descricao = c(
      "Proporcao da variancia explicada (ajustada pelo numero de preditores)",
      "Erro medio de predicao nas mesmas unidades da variavel resposta",
      "Qualidade relativa do modelo penalizando complexidade (menor = melhor)",
      "Similar ao AIC com penalizacao maior por complexidade (menor = melhor)"
    )
  )
}

diag_mt <- extrair_diag(modelo_mt, summary_mt)
diag_lp <- extrair_diag(modelo_lp, summary_lp)

write_csv(diag_mt, caminho_saida(DIR_BASE, "diagnosticos", "diagnosticos_MT", "csv"))
write_csv(diag_lp, caminho_saida(DIR_BASE, "diagnosticos", "diagnosticos_LP", "csv"))

tabela_resumo <- tibble(
  Modelo       = c("MEDIA_MT", "MEDIA_LP"),
  Observacoes  = nrow(dados_modelo),
  Parametros   = c(length(coef(modelo_mt)), length(coef(modelo_lp))),
  R2_ajustado  = c(round(summary_mt$adj.r.squared, 4), round(summary_lp$adj.r.squared, 4)),
  RMSE         = c(round(sqrt(mean(summary_mt$residuals^2)), 2),
                   round(sqrt(mean(summary_lp$residuals^2)), 2)),
  F_statistic  = c(round(summary_mt$fstatistic[1], 2), round(summary_lp$fstatistic[1], 2)),
  p_valor      = "< 0.001",
  AIC          = c(round(AIC(modelo_mt), 2), round(AIC(modelo_lp), 2)),
  BIC          = c(round(BIC(modelo_mt), 2), round(BIC(modelo_lp), 2))
)

write_csv(tabela_resumo, caminho_saida(DIR_BASE, "tabelas", "resumo_modelos", "csv"))
message("\nResumo dos modelos:")
print(tabela_resumo)

# =============================================================================
# ETAPA 7: GRAFICOS DE DIAGNOSTICO DE RESIDUOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 7: GERANDO GRAFICOS")
message(strrep("-", 50))

gerar_graficos_residuos <- function(modelo, nome, cor) {

  dados_resid <- tibble(
    fitted        = fitted(modelo),
    residuals     = residuals(modelo),
    std_residuals = rstandard(modelo)
  )

  p1 <- ggplot(dados_resid, aes(x = fitted, y = residuals)) +
    geom_point(alpha = 0.5, size = 2, colour = cor) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "#D62728", linewidth = 1) +
    geom_smooth(method = "loess", se = TRUE, colour = "#2CA02C",
                fill = "#2CA02C", alpha = 0.15) +
    labs(
      title    = paste0("Residuos vs Ajustados (", nome, ")"),
      subtitle = "Diferenca entre valor observado e previsto por escola",
      x        = "Valores ajustados (proficiencia prevista)",
      y        = "Residuos (observado ? previsto)"
    ) +
    tema_saeb()

  p2 <- ggplot(dados_resid, aes(sample = std_residuals)) +
    stat_qq(alpha = 0.5, size = 2, colour = cor) +
    stat_qq_line(colour = "#D62728", linewidth = 1) +
    labs(
      title    = paste0("Q-Q Plot dos Residuos (", nome, ")"),
      subtitle = "Aderencia dos residuos a distribuicao normal",
      x        = "Quantis teoricos (normal padrao)",
      y        = "Quantis amostrais (residuos padronizados)"
    ) +
    tema_saeb()

  p3 <- ggplot(dados_resid, aes(x = fitted, y = sqrt(abs(std_residuals)))) +
    geom_point(alpha = 0.5, size = 2, colour = cor) +
    geom_smooth(method = "loess", se = TRUE, colour = "#2CA02C",
                fill = "#2CA02C", alpha = 0.15) +
    labs(
      title    = paste0("Scale-Location (", nome, ")"),
      subtitle = "Verifica homocedasticidade: variancia dos erros e constante?",
      x        = "Valores ajustados",
      y        = "?|Residuos padronizados|"
    ) +
    tema_saeb()

  p4 <- ggplot(dados_resid, aes(x = residuals)) +
    geom_histogram(bins = 30, fill = cor, alpha = 0.7, colour = "black") +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "#D62728", linewidth = 1) +
    labs(
      title    = paste0("Distribuicao dos Residuos (", nome, ")"),
      subtitle = "Histograma dos erros de predicao",
      x        = "Residuos",
      y        = "Frequencia"
    ) +
    tema_saeb()

  (p1 + p2) / (p3 + p4) +
    plot_annotation(
      title    = paste0("Diagnostico do Modelo ", nome),
      subtitle = "Analise grafica dos residuos e do ajuste do modelo de regressao",
      caption  = paste(
        "? Residuos vs Ajustados: dispersao aleatoria em torno de zero e linha verde horizontal = sem padrao sistematico (bom).",
        "? Q-Q Plot: pontos sobre a diagonal vermelha = residuos normais; desvios nas extremidades = caudas pesadas.",
        "? Scale-Location: dispersao uniforme e linha horizontal = variancia constante (homocedasticidade).",
        "? Histograma: sino centrado em zero = modelo erra aleatoriamente, sem vies sistematico.",
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

ggsave(caminho_saida(DIR_BASE, "figuras", "diagnosticos_residuos_MT", "png"),
       p_diag_mt, width = 14, height = 10, dpi = 180, bg = "white", device = "png")
message("Figura salva: diagnosticos_residuos_MT")

ggsave(caminho_saida(DIR_BASE, "figuras", "diagnosticos_residuos_LP", "png"),
       p_diag_lp, width = 14, height = 10, dpi = 180, bg = "white", device = "png")
message("Figura salva: diagnosticos_residuos_LP")

# =============================================================================
# ETAPA 8: GRAFICOS DE COEFICIENTES
# =============================================================================

gerar_grafico_coef <- function(coef_df, nome, cor_sig, refs_usadas) {
  # refs_usadas: named list com as referencias de cada variavel dummy

  refs_texto <- paste(
    "Referencias: Escola", refs_usadas$TIPO_ESCOLA, "| Localizacao combinada:",
    refs_usadas$AREA_LOCAL
  )

  dados_plot <- coef_df |>
    filter(Termo != "(Intercept)") |>
    mutate(Significancia = p_valor < ALPHA,
           Termo = fct_reorder(Termo, Coef))

  ggplot(dados_plot, aes(y = Termo, x = Coef, fill = Significancia)) +
    geom_col(alpha = 0.85) +
    geom_errorbar(aes(xmin = IC_95_inf, xmax = IC_95_sup),
                  height = 0.25, linewidth = 0.6) +
    geom_text(aes(label = Sig,
                  x = if_else(Coef >= 0, IC_95_sup + 0.5, IC_95_inf - 0.5)),
              size = 4.5, fontface = "bold", colour = "#333333") +
    geom_vline(xintercept = 0, linetype = "dashed",
               colour = "#666666", linewidth = 0.6) +
    scale_fill_manual(
      values = c("FALSE" = "#CCCCCC", "TRUE" = cor_sig),
      labels = c("FALSE" = "Nao significativo (p >= 0,05)",
                 "TRUE"  = "Significativo (p < 0,05)")
    ) +
    labs(
      title    = paste0("Coeficientes estimados (", nome, ")"),
      subtitle = "Efeito parcial de cada variavel sobre a proficiencia, mantendo as demais constantes",
      y        = NULL,
      x        = "Coeficiente (pontos de proficiencia SAEB)",
      fill     = "Significancia estatistica",
      caption  = paste0(
        refs_texto, "\n",
        "Coef > 0: variavel aumenta a proficiencia em relacao a referencia\n",
        "Coef < 0: variavel reduz a proficiencia em relacao a referencia\n",
        "Barras de erro = intervalo de confianca 95% (se cruzar o zero, efeito pode ser nulo)\n",
        "*** p<0,001 | ** p<0,01 | * p<0,05"
      )
    ) +
    tema_saeb() +
    theme(
      legend.position = "bottom",
      plot.caption    = element_text(size = 9, lineheight = 1.4)
    )
}

p_coef_mt <- gerar_grafico_coef(coef_mt, "MEDIA_MT", "#1f77b4", refs_usadas)
p_coef_lp <- gerar_grafico_coef(coef_lp, "MEDIA_LP", "#ff7f0e", refs_usadas)

ggsave(caminho_saida(DIR_BASE, "figuras", "coeficientes_MT", "png"),
       p_coef_mt, width = 10, height = 8, dpi = 180, bg = "white", device = "png")
message("Figura salva: coeficientes_MT")

ggsave(caminho_saida(DIR_BASE, "figuras", "coeficientes_LP", "png"),
       p_coef_lp, width = 10, height = 8, dpi = 180, bg = "white", device = "png")
message("Figura salva: coeficientes_LP")

# =============================================================================
# ETAPA 9: PREDITOS vs OBSERVADOS
# =============================================================================

gerar_pred_obs <- function(modelo, summary_mod, nome, cor) {

  dados_po <- tibble(
    Observado = modelo$model[[1]],
    Predito   = fitted(modelo)
  )

  r2   <- round(summary_mod$adj.r.squared, 4)
  rmse <- round(sqrt(mean(summary_mod$residuals^2)), 2)
  corr <- round(cor(dados_po$Observado, dados_po$Predito), 3)

  ggplot(dados_po, aes(x = Observado, y = Predito)) +
    geom_point(alpha = 0.4, size = 2, colour = cor) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed",
                colour = "#D62728", linewidth = 1.2) +
    geom_smooth(method = "lm", se = FALSE, colour = "#2CA02C",
                linewidth = 1) +
    annotate("label", x = Inf, y = -Inf,
             label = paste0("R2 = ", r2, "\nRMSE = ", rmse, "\nCorr = ", corr),
             hjust = 1.05, vjust = -0.3, size = 4, fontface = "bold",
             colour = "#333333", fill = "#FFFFEE", label.size = 0.3) +
    coord_fixed(ratio = 1) +
    labs(
      title    = paste0("Preditos vs Observados (", nome, ")"),
      subtitle = "Linha vermelha tracejada = ajuste perfeito | Linha verde = ajuste do modelo",
      x        = "Proficiencia observada (media da escola)",
      y        = "Proficiencia predita pelo modelo",
      caption  = "Quanto mais proximos os pontos da linha diagonal, mais preciso o modelo.\nPontos acima da linha = modelo subestimou | Pontos abaixo = modelo superestimou."
    ) +
    tema_saeb() +
    theme(aspect.ratio = 1)
}

p_pred_mt <- gerar_pred_obs(modelo_mt, summary_mt, "MEDIA_MT", "#1f77b4")
p_pred_lp <- gerar_pred_obs(modelo_lp, summary_lp, "MEDIA_LP", "#ff7f0e")

ggsave(caminho_saida(DIR_BASE, "figuras", "preditos_vs_observados_MT", "png"),
       p_pred_mt, width = 9, height = 9, dpi = 180, bg = "white", device = "png")
message("Figura salva: preditos_vs_observados_MT")

ggsave(file.path(DIR_FIGURAS, paste0("preditos_vs_observados_LP_", ts_global, ".png")),
       p_pred_lp, width = 9, height = 9, dpi = 180, bg = "white", device = "png")
message("Figura salva: preditos_vs_observados_LP")

# =============================================================================
# ETAPA 10: GRAFICO COMPARATIVO DE R2
# =============================================================================

dados_r2 <- tibble(
  Modelo      = c("MEDIA_MT\n(Matematica)", "MEDIA_LP\n(Lingua Portuguesa)"),
  R2          = c(summary_mt$adj.r.squared, summary_lp$adj.r.squared),
  Cor         = c("#1f77b4", "#ff7f0e")
)

p_r2 <- ggplot(dados_r2, aes(x = Modelo, y = R2, fill = Modelo)) +
  geom_col(alpha = 0.85, colour = "black", linewidth = 0.8) +
  geom_text(aes(label = paste0(round(R2 * 100, 1), "%")),
            vjust = -0.5, size = 5.5, fontface = "bold") +
  geom_hline(yintercept = 0.30, linetype = "dotted", colour = "#2CA02C",  linewidth = 1) +
  geom_hline(yintercept = 0.50, linetype = "dotted", colour = "#FFA500",  linewidth = 1) +
  geom_hline(yintercept = 0.70, linetype = "dotted", colour = "#D62728",  linewidth = 1) +
  annotate("text", x = 0.55, y = 0.31, label = "30% - razoavel",  size = 3.5, colour = "#2CA02C",  hjust = 0) +
  annotate("text", x = 0.55, y = 0.51, label = "50% - bom",       size = 3.5, colour = "#FFA500",  hjust = 0) +
  annotate("text", x = 0.55, y = 0.71, label = "70% - excelente", size = 3.5, colour = "#D62728",  hjust = 0) +
  scale_y_continuous(
    limits = c(0, max(dados_r2$R2) * 1.2),
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_fill_manual(values = setNames(dados_r2$Cor, dados_r2$Modelo), guide = "none") +
  labs(
    title    = "Qualidade do Ajuste: R2 Ajustado por Modelo",
    subtitle = "Percentual da variancia da proficiencia explicado pelos preditores",
    x        = NULL,
    y        = "R2 Ajustado",
    caption  = "R2 ajustado penaliza a inclusao de variaveis irrelevantes (diferente do R2 simples).\nLinhas de referencia indicam patamares convencionais de qualidade de ajuste."
  ) +
  tema_saeb()

ggsave(file.path(DIR_FIGURAS, paste0("resumo_qualidade_ajuste_", ts_global, ".png")),
       p_r2, width = 8, height = 6, dpi = 180, bg = "white", device = "png")
message("Figura salva: resumo_qualidade_ajuste")

# =============================================================================
# SALVAR MODELOS RDS
# =============================================================================

saveRDS(modelo_mt, file.path(DIR_MODELOS, paste0("modelo_MT_", ts_global, ".rds")))
saveRDS(modelo_lp, file.path(DIR_MODELOS, paste0("modelo_LP_", ts_global, ".rds")))

# =============================================================================
# RELATORIO FINAL
# =============================================================================

message("\n", strrep("=", 70))
message("RELATORIO FINAL")
message(strrep("=", 70))
message("\nBase:")
message("  Alunos no raw:             ", nrow(dados_brutos))
message("  Escolas na base final:     ", nrow(dados_escola))
message("  Outliers de profic. removidos: ",
        sum(dados_brutos$IN_PROFICIENCIA_MT == 1, na.rm = TRUE) -
        sum(between(
          dados_brutos$PROFICIENCIA_MT_SAEB[dados_brutos$IN_PROFICIENCIA_MT == 1],
          PROF_MIN, PROF_MAX), na.rm = TRUE))
message("\nModelos:")
message("  MT - R2aj: ", round(summary_mt$adj.r.squared, 4),
        " | RMSE: ", round(sqrt(mean(summary_mt$residuals^2)), 2))
message("  LP - R2aj: ", round(summary_lp$adj.r.squared, 4),
        " | RMSE: ", round(sqrt(mean(summary_lp$residuals^2)), 2))

message("\n!?  IMPORTANTE - INTERPRETACAO DOS COEFICIENTES:")
message("\nAs referencias utilizadas no modelo sao:")
for (var in names(refs_usadas)) {
  message("  ? ", var, " = ", refs_usadas[[var]])
}
message("\nSignificado dos coeficientes:")
message("  ? Coef > 0: a categoria do dummy tem proficiencia MAIOR que a referencia")
message("  ? Coef < 0: a categoria do dummy tem proficiencia MENOR que a referencia")
message("\nExemplo:")
message("  Se TIPO_ESCOLA_Privada = -7, significa:")
message("    -> Escolas PRIVADAS tem ~7 pontos MENOS de proficiencia")
message("    -> comparadas as escolas PUBLICAS (referencia)")
message("  Se AREA_LOCAL_Rural_Interior = -8.5, significa:")
message("    -> Escolas RURAIS DO INTERIOR tem ~8,5 pontos MENOS de proficiencia")
message("    -> comparadas as escolas URBANAS DA CAPITAL (referencia Urbana_Capital)")

message("\nArquivos gerados em:")
message("  ", DIR_TABELAS)
message("  ", DIR_FIGURAS)
message("  ", DIR_MODELOS)

message("\nArquivos de referencia:")
message("  ? REFERENCIAS_MODELOS_", ts_global, ".csv (categorias de referencia de cada dummy)")
message("  ? VIF_multicolinearidade_", ts_global, ".csv (verificacao de multicolinearidade)")
message("  ? base_escolas_agregada_", ts_global, ".csv (dados utilizados no modelo)")
message("\nArquivos de comparacoes simetricas:")
message("  ? comparacao_todas_referencias_MT_", ts_global, ".csv (todos os modelos - MT)")
message("  ? comparacao_todas_referencias_LP_", ts_global, ".csv (todos os modelos - LP)")
message("  ? resumo_pares_MT_", ts_global, ".csv (tabela pivotada de comparacoes rapidas)")
message("  ? comparacao_tipo_escola_MT_", ts_global, ".png (visualizacao das diferencas)")
message("\n?? DICA: Use os arquivos 'comparacao_todas_referencias_*.csv' para ver")
message("   TODAS as comparacoes possiveis entre categorias (A vs B, B vs C, etc)")
message("   e entender quais diferencas sao estatisticamente significativas.")

message("\n", strrep("=", 70))
message("CONCLUIDO COM SUCESSO!")
message(strrep("=", 70))