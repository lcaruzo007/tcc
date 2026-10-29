################################################################################
# SCRIPT: regressao_itens_brutos_dummy.r
# ENTRADA: Microdados MG/2023; dominios e validade compartilhados.
# SAIDA: Modelos exploratorios, tabelas completas, figuras e logs de selecao.
# VERSAO: 3.0 - Outubro 2026
# Preditores: proporcoes por escola (A omitida inicialmente), tipo e AREA_LOCAL.
# Filtros: minimo 3 respostas/item, variancia, ausencias, casos completos e VIF.
# O conjunto selecionado para MT e reutilizado em LP; escolha exploratoria.
# Graficos tematicos exibem p < 0.05; tabelas preservam todos os coeficientes.
# Incremento 0.10 em proporcao = dez pontos percentuais. IC via quantil t.
# O questionario completo nao equivale ao conjunto de itens do INSE.
################################################################################

library(tidyverse)
library(broom)
library(patchwork)
library(car)

# =============================================================================
# DETECCAO AUTOMATICA DE CAMINHOS
# =============================================================================

# Helper local simples: lista arquivos por padrao e pega o de mtime maximo.
# (Diferente de encontrar_arquivo_mais_recente, que procura em subpastas
# datadas. Aqui queremos o arquivo bruto mais recente direto na pasta.)
arquivo_mais_recente <- function(pasta, padrao) {
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE)
  if (length(arqs) == 0L) return(NULL)
  arqs[which.max(file.info(arqs)$mtime)]
}

# detectar_raiz e definida localmente por necessidade: ela e pre-condicao
# do source() de utils_saeb.r (que por sua vez redefine detectar_raiz,
# caminho_saida, tema_saeb, etc., sobrescrevendo esta versao local).
# arquivo_mais_recente tambem e local (semantica distinta da
# encontrar_arquivo_mais_recente, que procura em subpastas datadas).
detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("OK Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  message("[!] Pasta 'TESTE' nao encontrada automaticamente.")
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho nao selecionado. Encerrando.")
    message("OK Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Script nao pode rodar em modo nao-interativo sem encontrar o caminho.")
  }
}

RAIZ <- detectar_raiz()
source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

DIR_DADOS_BRUTOS     <- file.path(RAIZ, "MICRODADOS_SAEB_2023", "DADOS")
ARQUIVO_DADOS_BRUTOS <- arquivo_mais_recente(DIR_DADOS_BRUTOS, "^TS_ALUNO_34EM\\.csv$")

# Subpastas proprias - separadas do script principal.
# DIR_BASE e base para caminho_saida().
DIR_BASE <- file.path(RAIZ, "TESTE", "5_REGRESSAO_ITENS_BRUTOS")

# Subpastas de figuras (organizacao por tipo, dentro de outputs/<data>/figuras/).
# Usadas como argumento `subpasta` de caminho_saida() -> cria figuras/<tipo>/.
FIG_DIAG_RESS  <- file.path("figuras", "diagnosticos_residuos")
FIG_PRED_OBS   <- file.path("figuras", "preditos_vs_observados")
FIG_VIF        <- file.path("figuras", "mapas_calor_vif")
FIG_QUALIDADE  <- file.path("figuras", "qualidade_ajuste")
FIG_COEF_GRUPO <- file.path("figuras", "coeficientes_grupo")

message("Caminhos configurados:")
message("  Dados brutos : ", ARQUIVO_DADOS_BRUTOS)
message("  Modulo (base): ", DIR_BASE)
message("  Saidas       : ", DIR_BASE, "/outputs/<YYYY-MM-DD>/<tipo>/\n")

# =============================================================================
# CONFIGURACOES
# =============================================================================

MIN_ALUNOS_ESCOLA  <- 5      # escolas com menos alunos sao descartadas
PROF_MIN           <- 150    # limite inferior de proficiencia valida
PROF_MAX           <- 800    # limite superior de proficiencia valida
MIN_RESP_ITEM      <- 3      # alunos minimos respondendo um item por escola
LIMIAR_VIF         <- 10     # VIF maximo tolerado (eliminacao iterativa)
LIMIAR_VAR_ZERO    <- 0.001  # variancia minima de uma dummy no nivel escola
ALPHA              <- 0.05

# Itens brutos do questionario socioeconomico
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

# =============================================================================
# FUNCOES UTILITARIAS
# =============================================================================
# Nota: tema_saeb, detectar_raiz, caminho_saida e demais helpers vem de
# utils_saeb.r (sourceado acima). Apenas funcoes especificas deste modulo
# sao definidas aqui.

formatar_pvalor <- function(p) {
  case_when(
    p < 0.001 ~ "***",
    p < 0.01  ~ "**",
    p < 0.05  ~ "*",
    TRUE      ~ ""
  )
}

# Funcao auxiliar: validar dados antes de plotar
validar_dados_plot <- function(df, nome_grafico) {
  if (is.null(df) || nrow(df) == 0) {
    warning("[!] ", nome_grafico, ": nenhum dado para plotar. Grafico nao sera gerado.")
    return(FALSE)
  }
  TRUE
}



# Eliminacao iterativa de preditores com VIF > limiar.
# Retorna lista com:
#   preditoras - vetor de nomes mantidas
#   removidos  - tibble(Iteracao, Preditor, VIF) com o log detalhado
eliminar_por_vif <- function(df_modelo, resposta, limiar = LIMIAR_VIF) {
  preds <- sort(setdiff(names(df_modelo), resposta))
  if (!is.finite(limiar) || limiar < 1) stop("Limiar VIF invalido.")
  if (!all(vapply(df_modelo, is.numeric, logical(1))) ||
      any(!is.finite(as.matrix(df_modelo)))) stop("VIF exige dados numericos completos e finitos.")
  if (nrow(df_modelo) <= length(preds) + 1L) stop("Amostra insuficiente para VIF.")
  log_removidos <- tibble(Iteracao = integer(0),
                          Preditor = character(0),
                          VIF      = numeric(0))
  iter <- 0L

  repeat {
    formula_atual <- reformulate(if (length(preds)) preds else "1", response = resposta)
    modelo_tmp <- lm(formula_atual, data = df_modelo)
    if (anyNA(coef(modelo_tmp))) stop("Dependencia linear exata no VIF; revise a especificacao.")
    vif_vals <- if (length(preds) <= 1L) setNames(rep(1, length(preds)), preds) else car::vif(modelo_tmp)
    if (is.matrix(vif_vals) || any(!is.finite(vif_vals))) stop("VIF invalido; selecao interrompida.")
    if (!length(vif_vals)) break

    max_vif  <- max(vif_vals, na.rm = TRUE)
    max_pred <- sort(names(vif_vals)[vif_vals >= max_vif - 1e-10])[1]

    if (max_vif <= limiar) break

    iter <- iter + 1L
    message(sprintf("  Removendo %-45s  VIF = %.1f", max_pred, max_vif))
    log_removidos <- log_removidos |>
      add_row(Iteracao = iter, Preditor = max_pred, VIF = max_vif)
    preds <- setdiff(preds, max_pred)
  }

  list(preditoras = preds, removidos = log_removidos, vif_final = vif_vals)
}

# =============================================================================
# INICIALIZACAO
# =============================================================================

message(strrep("=", 70))
message("REGRESSAO COM ITENS BRUTOS (DUMMIES) - DADOS SAEB")
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

# Colunas necessarias: proficiencia + estrutura da escola + itens do questionario
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
  .default             = col_character()   # itens do questionario sao char
)

dados_brutos <- ler_microdados_saeb(ARQUIVO_DADOS_BRUTOS) |>
  transformar_respostas_saeb()
itens_presentes <- intersect(ITENS_QUEST, names(dados_brutos))

message("Arquivo    : ", basename(ARQUIVO_DADOS_BRUTOS))
message("Alunos     : ", nrow(dados_brutos))
message("Escolas    : ", n_distinct(dados_brutos$ID_ESCOLA))
message("Itens lidos: ", length(itens_presentes))

# =============================================================================
# ETAPA 2: MEDIAS DE PROFICIENCIA POR ESCOLA
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 2: MEDIAS DE PROFICIENCIA POR ESCOLA")
message(strrep("-", 50))

base_escolas <- agregar_escolas_saeb(dados_brutos, pareadas = TRUE)
fluxo_amostra <- amostra_escolas_saeb(base_escolas, MIN_ALUNOS_ESCOLA, exigir_inse = FALSE)
write_csv(fluxo_amostra, caminho_saida(DIR_BASE, "diagnosticos", "fluxo_amostra_itens", "csv"))
media_prof <- fluxo_amostra |> filter(Incluida) |>
  select(ID_ESCOLA, MEDIA_MT, MEDIA_LP, N_ALUNOS_MT)

message("Escolas com proficiencia valida: ", nrow(media_prof))

# =============================================================================
# ETAPA 3: VARIAVEIS ESTRUTURAIS DA ESCOLA
# =============================================================================

categ_escola <- base_escolas |>
  select(ID_ESCOLA, TIPO_ESCOLA, AREA, LOCALIZACAO, AREA_LOCAL)

# =============================================================================
# ETAPA 4: CRIAR DUMMIES DOS ITENS BRUTOS E AGREGAR POR ESCOLA
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 4: CRIANDO DUMMIES E AGREGANDO POR ESCOLA")
message(strrep("-", 50))

dados_quest <- dados_brutos |>
  select(ID_ESCOLA, all_of(itens_presentes))

# Agregacao por escola via count + pivot_wider (uma passagem por item, em
# vez de um summarise+left_join por categoria). Para cada item:
#   1. descarta NAs (respostas invalidas "."/"*" ja tratadas antes);
#   2. conta respostas validas por escola e por categoria;
#   3. n_valid por escola = total de respostas validas daquele item;
#   4. prop = n / n_valid (proporcao que respondeu a categoria);
#   5. escolas com n_valid < MIN_RESP_ITEM recebem NA em todas as dummies
#      do item (evita estimativas instaveis);
#   6. categoria "A" (referencia) e descartada.
props_escola <- agregar_proporcoes_saeb(dados_quest, itens_presentes, MIN_RESP_ITEM)


todas_dummies <- setdiff(names(props_escola), "ID_ESCOLA")

message("Dummies geradas: ", length(todas_dummies))
message("Escolas: ", nrow(props_escola))

# =============================================================================
# ETAPA 5: DIAGNOSTICO DE MISSINGS POR ITEM (CORRIGIDO)
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 5: DIAGNOSTICO DE MISSINGS")
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

arq_miss <- caminho_saida(DIR_BASE, "tabelas", "log_missings_itens", "csv")
write_csv(miss_info, arq_miss)
message("Log de missings por item salvo (", nrow(miss_info), " itens): ",
        basename(arq_miss))

# =============================================================================
# ETAPA 6: MONTAR BASE ESCOLA E REMOVER DUMMIES COM VARIANCIA ZERO
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 6: BASE ESCOLA - FILTRO DE VARIANCIA ZERO")
message(strrep("-", 50))

dados_escola <- media_prof |>
  inner_join(categ_escola, by = "ID_ESCOLA", relationship = "one-to-one") |>
  left_join(props_escola, by = "ID_ESCOLA", relationship = "one-to-one")

message("Escolas na base final: ", nrow(dados_escola))

# Dummies estruturais (TIPO_ESCOLA + AREA_LOCAL combinada, ref = Urbana_Capital)
# Substitui AREA_Interior e LOCALIZACAO_Rural por 3 dummies de AREA_LOCAL,
# capturando interacoes Urbana/Rural x Capital/Interior (lacuna apontada na
# apresentacao do TCC para investigacao futura)
dados_escola <- dados_escola |>
  mutate(
    TIPO_ESCOLA_Privada        = as.integer(TIPO_ESCOLA == "Privada"),
    AREA_LOCAL_Rural_Interior  = as.integer(AREA_LOCAL == "Rural_Interior"),
    AREA_LOCAL_Rural_Capital   = as.integer(AREA_LOCAL == "Rural_Capital"),
    AREA_LOCAL_Urbana_Interior = as.integer(AREA_LOCAL == "Urbana_Interior")
  )

dummies_estruturais <- c("TIPO_ESCOLA_Privada",
                         "AREA_LOCAL_Rural_Interior",
                         "AREA_LOCAL_Rural_Capital",
                         "AREA_LOCAL_Urbana_Interior")

# todas_dummies agora e o vetor de colunas efetivamente presentes em props_escola
# (atualizado no final da Etapa 4)
# Identificar e remover dummies de itens com variancia quase-zero
vars_candidatas <- c(dummies_estruturais, todas_dummies)
vars_candidatas <- intersect(vars_candidatas, names(dados_escola))

vars_var_ok <- vars_candidatas[
  sapply(vars_candidatas, function(v) {
    x <- dados_escola[[v]]
    is.finite(var(x, na.rm = TRUE)) && var(x, na.rm = TRUE) > LIMIAR_VAR_ZERO && mean(is.na(x)) < 0.5
  })
]

n_removidas_var0 <- length(vars_candidatas) - length(vars_var_ok)
message("Dummies removidas por variancia ~ 0 ou >50% missing: ", n_removidas_var0)
message("Dummies mantidas para o modelo: ", length(vars_var_ok))

# Salvar log das variaveis eliminadas na etapa B (variancia zero / missing)
vars_eliminadas_var0 <- setdiff(vars_candidatas, vars_var_ok)
arq_log_var0 <- caminho_saida(DIR_BASE, "tabelas", "log_eliminadas_var0", "csv")
write_csv(
  tibble(
    Predictor_Removido = vars_eliminadas_var0,
    Motivo = sapply(vars_eliminadas_var0, function(v) {
      x <- dados_escola[[v]]
      if (mean(is.na(x)) > 0.5) {
        paste0(">50% missing (", round(mean(is.na(x)) * 100, 1), "%)")
      } else {
        paste0("variancia ~ 0 (var=", round(var(x, na.rm = TRUE), 6), ")")
      }
    })
  ),
  arq_log_var0
)

arq_base_escolas <- caminho_saida(DIR_BASE, "tabelas", "base_escolas_itens", "csv")
write_csv(dados_escola, arq_base_escolas)
message("Base escola salva: ", basename(arq_base_escolas))

# =============================================================================
# ETAPA 7: CONTROLE DE MULTICOLINEARIDADE (VIF ITERATIVO)
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 7: CONTROLE DE MULTICOLINEARIDADE - VIF ITERATIVO")
message(strrep("-", 50))
message("Limiar VIF: ", LIMIAR_VIF,
        " | Preditores antes da eliminacao: ", length(vars_var_ok))

# Trabalha com complete cases para o VIF
df_completo <- dados_escola |>
  select(MEDIA_MT, MEDIA_LP, all_of(vars_var_ok)) |>
  drop_na()
ids_completos <- dados_escola$ID_ESCOLA[complete.cases(dados_escola[c("MEDIA_MT", "MEDIA_LP", vars_var_ok)])]
write_csv(tibble(ID_ESCOLA = dados_escola$ID_ESCOLA,
  Incluida = dados_escola$ID_ESCOLA %in% ids_completos,
  Motivo = if_else(Incluida, "INCLUIDA", "PREDITORES_AUSENTES")),
  caminho_saida(DIR_BASE, "diagnosticos", "fluxo_casos_completos_itens", "csv"))

message("Observacoes (escolas) com dados completos: ", nrow(df_completo))

# Eliminacao para MEDIA_MT (o resultado serve para ambos os modelos,
# pois as preditoras sao as mesmas)
resultado_vif <- eliminar_por_vif(
  df_modelo = df_completo |> select(-MEDIA_LP),
  resposta  = "MEDIA_MT",
  limiar    = LIMIAR_VIF
)

preditoras_finais <- resultado_vif$preditoras
referencias_efetivas <- map_dfr(itens_presentes, function(item) {
  categorias <- sort(unique(na.omit(dados_quest[[item]])))
  mantidas <- sub(paste0("^", item, "_"), "",
                  grep(paste0("^", item, "_"), preditoras_finais, value = TRUE))
  omitidas <- setdiff(categorias, mantidas)
  tibble(Item = item, Categorias_mantidas = paste(mantidas, collapse = " + "),
         Categorias_omitidas = paste(omitidas, collapse = " + "),
         Somente_A_omitida = identical(omitidas, "A"))
})
write_csv(referencias_efetivas,
          caminho_saida(DIR_BASE, "tabelas", "referencias_efetivas_itens", "csv"))
log_vif           <- resultado_vif$removidos   # tibble(Iteracao, Preditor, VIF)
write_csv(tibble(Preditor = names(resultado_vif$vif_final),
                 VIF = as.numeric(resultado_vif$vif_final)),
          caminho_saida(DIR_BASE, "tabelas", "vif_final_completo", "csv"))
write_csv(tibble(ID_ESCOLA = ids_completos),
          caminho_saida(DIR_BASE, "metadados", "escolas_modelo_itens", "csv"))

message("\nPreditoras apos eliminacao VIF: ", length(preditoras_finais))
message("Removidas pelo VIF           : ", nrow(log_vif))

# Salvar log de remocao por VIF (uma linha por preditor removido, com o
# VIF no momento da remocao e a iteracao em que ocorreu)
write_csv(
  log_vif,
  caminho_saida(DIR_BASE, "tabelas", "log_vif_removidos", "csv")
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

message("\n>>> MODELO MEDIA_MT (Matematica) <<<")
message("  Observacoes    : ", nrow(df_completo))
message("  Preditoras     : ", length(preditoras_finais))
message("  R2 ajustado    : ", round(summary_mt$adj.r.squared, 4))
message("  F-statistic    : ", round(summary_mt$fstatistic[1], 2))
message("  RMSE           : ", round(sqrt(mean(summary_mt$residuals^2)), 2))

message("\n>>> MODELO MEDIA_LP (Lingua Portuguesa) <<<")
message("  Observacoes    : ", nrow(df_completo))
message("  Preditoras     : ", length(preditoras_finais))
message("  R2 ajustado    : ", round(summary_lp$adj.r.squared, 4))
message("  F-statistic    : ", round(summary_lp$fstatistic[1], 2))
message("  RMSE           : ", round(sqrt(mean(summary_lp$residuals^2)), 2))

# =============================================================================
# ETAPA 9: COEFICIENTES
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 9: EXTRAINDO COEFICIENTES")
message(strrep("-", 50))

extrair_coef <- function(modelo) {
  crit <- qt(0.975, df = df.residual(modelo))
  tidy(modelo) |>
    mutate(
      Sig       = formatar_pvalor(p.value),
      IC_lower  = estimate - crit * std.error,
      IC_upper  = estimate + crit * std.error,
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
          caminho_saida(DIR_BASE, "tabelas", "coeficientes_MT_itens", "csv"))
write_csv(coef_lp,
          caminho_saida(DIR_BASE, "tabelas", "coeficientes_LP_itens", "csv"))

message("Coeficientes MT (top 15):")
print(head(coef_mt, 15), n = 15)

# =============================================================================
# ETAPA 10: TABELA RESUMO DE DIAGNOSTICOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 10: DIAGNOSTICOS DOS MODELOS")
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

write_csv(diag_mt,
          caminho_saida(DIR_BASE, "diagnosticos", "diagnosticos_MT_itens", "csv"))
write_csv(diag_lp,
          caminho_saida(DIR_BASE, "diagnosticos", "diagnosticos_LP_itens", "csv"))

# p-valor do teste F global: pf(F, df1, df2, lower.tail=FALSE).
# summary()$fstatistic = c(F, numdf, dendf Retorna numeric; formatamos
# como "< 0.001" quando abaixo desse limiar para legibilidade, e
# arredondamos com 4 casas caso contrario.
calc_p_F <- function(fstat) {
  p <- pf(fstat[1], fstat[2], fstat[3], lower.tail = FALSE)
  if (is.na(p)) return(NA_character_)
  if (p < 0.001) return("< 0.001")
  format(round(p, 4), nsmall = 4)
}

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
  p_valor     = c(calc_p_F(summary_mt$fstatistic),
                   calc_p_F(summary_lp$fstatistic)),
  AIC         = c(round(AIC(modelo_mt), 2), round(AIC(modelo_lp), 2)),
  BIC         = c(round(BIC(modelo_mt), 2), round(BIC(modelo_lp), 2))
)

write_csv(tabela_resumo,
          caminho_saida(DIR_BASE, "tabelas", "resumo_modelos_itens", "csv"))
message("Resumo dos modelos:")
print(tabela_resumo)

# =============================================================================
# ETAPA 11: GRAFICOS DE DIAGNOSTICO DE RESIDUOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 11: GRAFICOS DE DIAGNOSTICO DE RESIDUOS")
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
      title    = paste0("Residuos vs Ajustados (", nome, ")"),
      subtitle = "Dispersao aleatoria em torno de zero indica bom ajuste",
      x        = "Valores ajustados",
      y        = "Residuos"
    ) +
    tema_saeb()

  p2 <- ggplot(dados_resid, aes(sample = std_residuals)) +
    stat_qq(alpha = 0.55, size = 2.2, colour = cor, stroke = 0.3) +
    stat_qq_line(colour = "#D62728", linewidth = 1.2) +
    labs(
      title    = paste0("Q-Q Plot dos Residuos (", nome, ")"),
      subtitle = "Aderencia dos residuos a distribuicao normal",
      x        = "Quantis teoricos",
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
      y        = "sqrt(|Residuos padronizados|)"
    ) +
    tema_saeb()

  p4 <- ggplot(dados_resid, aes(x = residuals)) +
    geom_histogram(bins = 30, fill = cor, alpha = 0.75, colour = "black", linewidth = 0.5) +
    geom_vline(xintercept = 0, linetype = "dashed",
               colour = "#D62728", linewidth = 1.1) +
    labs(
      title    = paste0("Distribuicao dos Residuos (", nome, ")"),
      subtitle = "Histograma dos erros de predicao",
      x        = "Residuos",
      y        = "Frequencia"
    ) +
    tema_saeb()

  (p1 + p2) / (p3 + p4) +
    plot_annotation(
      title    = paste0("Diagnostico do Modelo ", nome,
                        " - Itens Brutos (Dummies)"),
      subtitle = "Analise grafica dos residuos e do ajuste do modelo de regressao",
      caption  = paste(
        "* Residuos vs Ajustados: sem padrao sistematico = bom.",
        "* Q-Q Plot: pontos sobre a diagonal = residuos normais.",
        "* Scale-Location: dispersao uniforme = homocedasticidade.",
        "* Histograma: sino centrado em zero = sem vies sistematico.",
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
  caminho_saida(DIR_BASE, FIG_DIAG_RESS, "diagnosticos_residuos_MT_itens", "png"),
  p_diag_mt, width = 14, height = 10, dpi = 180, bg = "white"
)
message("Figura salva: diagnosticos_residuos_MT_itens")

ggsave(
  caminho_saida(DIR_BASE, FIG_DIAG_RESS, "diagnosticos_residuos_LP_itens", "png"),
  p_diag_lp, width = 14, height = 10, dpi = 180, bg = "white"
)
message("Figura salva: diagnosticos_residuos_LP_itens")

# =============================================================================
# ETAPA 12: GRAFICOS DE COEFICIENTES - DIVIDIDOS POR GRUPO TEMATICO
# =============================================================================

grupos_tematicos <- list(
  "Contexto Socioeconomico e Familiar - Parte 1\n(Q01-Q09)" = 
    c("TX_RESP_Q01", "TX_RESP_Q02", "TX_RESP_Q03", "TX_RESP_Q04",
      "TX_RESP_Q05a","TX_RESP_Q05b","TX_RESP_Q05c",
      "TX_RESP_Q06",
      "TX_RESP_Q07a","TX_RESP_Q07b","TX_RESP_Q07c","TX_RESP_Q07d","TX_RESP_Q07e",
      "TX_RESP_Q08","TX_RESP_Q09"),

  "Contexto Socioeconomico e Familiar - Parte 2\n(Q10-Q14)" = 
    c("TX_RESP_Q10a","TX_RESP_Q10b","TX_RESP_Q10c","TX_RESP_Q10d",
      "TX_RESP_Q10e","TX_RESP_Q10f",
      "TX_RESP_Q11a","TX_RESP_Q11b","TX_RESP_Q11c",
      "TX_RESP_Q12a","TX_RESP_Q12b","TX_RESP_Q12c","TX_RESP_Q12d",
      "TX_RESP_Q12e","TX_RESP_Q12f","TX_RESP_Q12g",
      "TX_RESP_Q13a","TX_RESP_Q13b","TX_RESP_Q13c","TX_RESP_Q13d",
      "TX_RESP_Q13e","TX_RESP_Q13f","TX_RESP_Q13g","TX_RESP_Q13h","TX_RESP_Q13i",
      "TX_RESP_Q14"),

  "Contexto Socioeconomico e Familiar - Parte 3\n(Q15-Q20)" = 
    c("TX_RESP_Q15a","TX_RESP_Q15b",
      "TX_RESP_Q16","TX_RESP_Q17","TX_RESP_Q18","TX_RESP_Q19","TX_RESP_Q20"),

  "Praticas Escolares e Tecnologia - Parte 1\n(Q21-Q22)" = 
    c("TX_RESP_Q21a","TX_RESP_Q21b","TX_RESP_Q21c","TX_RESP_Q21d","TX_RESP_Q21e",
      "TX_RESP_Q22a","TX_RESP_Q22b","TX_RESP_Q22c","TX_RESP_Q22d",
      "TX_RESP_Q22e","TX_RESP_Q22f","TX_RESP_Q22g","TX_RESP_Q22h"),

  "Praticas Escolares e Tecnologia - Parte 2\n(Q23-Q25)" = 
    c("TX_RESP_Q23a","TX_RESP_Q23b","TX_RESP_Q23c","TX_RESP_Q23d",
      "TX_RESP_Q23e","TX_RESP_Q23f","TX_RESP_Q23g","TX_RESP_Q23h","TX_RESP_Q23i",
      "TX_RESP_Q24","TX_RESP_Q25"),

  "Variaveis Estruturais da Escola\n(TIPO_ESCOLA + AREA_LOCAL)" =
    c("TIPO_ESCOLA_Privada",
      "AREA_LOCAL_Rural_Interior", "AREA_LOCAL_Rural_Capital",
      "AREA_LOCAL_Urbana_Interior")
)

# -- FUNCAO ---------------------------------------------------------------------
gerar_grafico_grupo <- function(coef_df, nome_modelo, cor_sig,
                                grupo_nome, itens_grupo) {

  dados_plot <- coef_df |>
    filter(Termo != "(Intercept)", p_valor < ALPHA) |>
    filter(
      str_replace(Termo, "_[A-Z]$", "") %in% itens_grupo |
      Termo %in% itens_grupo
    ) |>
    # Reordenar PRIMEIRO por Item (agrupa barras do mesmo item adjacentes)
    # e DEPOIS por |Coef| dentro de cada item. Isso mitiga o problema de
    # rotulos quase identigos (ex.: TX_RESP_Q23d_C/D/B) ficarem espalhados
    # e dificil de distinguir; agora ficam visualmente agrupados.
    arrange(Item, desc(abs(Coef))) |>
    mutate(Termo = factor(Termo, levels = Termo))

  if (nrow(dados_plot) == 0) return(NULL)

  n_preds    <- nrow(dados_plot)
  # Altura por barra ampliada de 0.32 para 0.40 para reduzir impressao de
  # "grudado" entre rotulos do eixo Y em figuras com 15+ preditoras.
  altura_fig <- max(5, n_preds * 0.40)

  # Offset dos asteriscos de Sig proporcional aa escala do eixo X (nao mais
  # fixo +0.5/-0.5). Com coeficientes de magnitude ate ~50 pontos SAEB, o
  # offset 0.5 ficava insignificante e os asteriscos sobrepostos aa barra
  # de erro. 4% do alcance dos ICs da um afastamento visivel.
  alcance <- diff(range(c(dados_plot$IC_95_inf, dados_plot$IC_95_sup),
                        na.rm = TRUE))
  if (!is.finite(alcance) || alcance == 0) alcance <- 10
  offset_sig <- alcance * 0.04

  p <- ggplot(dados_plot, aes(x = Termo, y = Coef)) +
    geom_hline(yintercept = 0, linetype = "dashed",
               colour = "#D62728", linewidth = 0.9) +
    geom_col(fill = cor_sig, alpha = 0.85,
             colour = "black", linewidth = 0.25) +
    geom_errorbar(aes(ymin = IC_95_inf, ymax = IC_95_sup),
                  width = 0.35, linewidth = 0.55, colour = "#333333") +
    geom_text(
      aes(label = Sig,
          y = if_else(Coef >= 0,
                      IC_95_sup + offset_sig,
                      IC_95_inf - offset_sig)),
      size = 3.2, fontface = "bold", colour = "#1A1A1A"
    ) +
    coord_flip() +
    scale_y_continuous(
      breaks = scales::pretty_breaks(n = 7),
      labels = function(x) paste0(ifelse(x > 0, "+", ""), x)
    ) +
    labs(
      title    = paste0(grupo_nome, " - Modelo ", nome_modelo),
      subtitle = paste0(
        n_preds, " coeficientes significativos (p < 0,05) | ",
        "agrupados por item e |coeficiente|; categorias omitidas no CSV de referencias"
      ),
      x       = NULL,
      y       = "Coeficiente (pontos de proficiencia SAEB)",
      caption = paste0(
        "Associacoes escolares: 0.10 x coeficiente = pontos por +10 pp na proporcao.\n",
        "Categorias omitidas apos selecao podem incluir outras alem de A. Consulte referencias_efetivas_itens.\n",
        "Estruturais: Publica e Urbana_Capital. Inferencia exploratoria apos selecao.\n",
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
      # Aumentar um pouco o espacamento vertical dos rotulos do eixo Y
      axis.text.y   = element_text(size = 10, colour = "#1A1A1A",
                                   margin = margin(r = 4)),
      axis.text.x   = element_text(size = 10),
      axis.title.x  = element_text(size = 10, margin = margin(t = 8)),
      plot.margin   = margin(14, 20, 10, 14)
    )

  list(plot = p, altura = altura_fig, n = n_preds)
}

# -- Gerar com numeracao sequencial por modelo --------------------------------
contador_mt <- 1L
contador_lp <- 1L

for (grupo_nome in names(grupos_tematicos)) {
  
  itens_grupo <- grupos_tematicos[[grupo_nome]]
  
  # MT
  res_mt <- gerar_grafico_grupo(coef_mt, "MEDIA_MT", "#E65100",
                                grupo_nome, itens_grupo)
  if (!is.null(res_mt)) {
    arq <- caminho_saida(DIR_BASE, FIG_COEF_GRUPO,
                         sprintf("coef_grupo_MT_IMAGEM%02d", contador_mt), "png")
    ggsave(arq, res_mt$plot, width = 12, height = res_mt$altura,
           dpi = 180, bg = "white", limitsize = FALSE)
    message("Salvo: ", basename(arq), "  (", res_mt$n, " coefs) - ", grupo_nome)
    contador_mt <- contador_mt + 1L
  } else {
    message("[!] Sem coefs significativos: MT - ", grupo_nome)
  }

  # LP
  res_lp <- gerar_grafico_grupo(coef_lp, "MEDIA_LP", "#1B5E20",
                                grupo_nome, itens_grupo)
  if (!is.null(res_lp)) {
    arq <- caminho_saida(DIR_BASE, FIG_COEF_GRUPO,
                         sprintf("coef_grupo_LP_IMAGEM%02d", contador_lp), "png")
    ggsave(arq, res_lp$plot, width = 12, height = res_lp$altura,
           dpi = 180, bg = "white", limitsize = FALSE)
    message("Salvo: ", basename(arq), "  (", res_lp$n, " coefs) - ", grupo_nome)
    contador_lp <- contador_lp + 1L
  } else {
    message("[!] Sem coefs significativos: LP - ", grupo_nome)
  }
}

message("\n* Graficos gerados em: ",
        file.path(DIR_BASE, "outputs", format(Sys.Date(), FORMATO_DATA_PASTA), "figuras"),
        " (subpastas por tipo)")
message("   MT: ", contador_mt - 1L, " imagens")
message("   LP: ", contador_lp - 1L, " imagens")

# =============================================================================
# ETAPA 13: PREDITOS vs OBSERVADOS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 13: PREDITOS vs OBSERVADOS")
message(strrep("-", 50))

gerar_pred_obs <- function(modelo, summary_mod, nome, cor) {

  # Acesso nomeado a variavel-resposta (evita depender da ordem das colunas
  # do model frame, que e a primeira coluna por convencao, mas fragil).
  resp_nome <- all.vars(formula(modelo))[1]
  dados_po <- tibble(
    Observado = modelo$model[[resp_nome]],
    Predito   = fitted(modelo)
  )

  if (!validar_dados_plot(dados_po, paste0("Preditos vs Observados - ", nome))) {
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
             label = paste0("R2 ajustado = ", r2, "\nRMSE = ", rmse,
                            "\nCorr = ", corr),
             hjust = 1.05, vjust = -0.3, size = 4.2, fontface = "bold",
             colour = "#1A1A1A", fill = "#FFFFEE", linewidth = 0.5) +
    coord_fixed(ratio = 1) +
    labs(
      title    = paste0("Preditos vs Observados (", nome,
                        ") - Itens Brutos"),
      subtitle = "Linha vermelha = ajuste perfeito | Linha verde = ajuste do modelo",
      x        = "Proficiencia observada (media da escola)",
      y        = "Proficiencia predita",
      caption  = paste0(
        "Pontos sobre a diagonal = predicao perfeita.\n",
        "Acima da linha = superestimacao | Abaixo = subestimacao."
      )
    ) +
    tema_saeb() +
    theme(aspect.ratio = 1)
}

p_pred_mt <- gerar_pred_obs(modelo_mt, summary_mt, "MEDIA_MT", "#1f77b4")
p_pred_lp <- gerar_pred_obs(modelo_lp, summary_lp, "MEDIA_LP", "#ff7f0e")

if (!is.null(p_pred_mt)) {
  ggsave(
    caminho_saida(DIR_BASE, FIG_PRED_OBS, "preditos_vs_observados_MT_itens", "png"),
    p_pred_mt, width = 9, height = 9, dpi = 180, bg = "white"
  )
  message("Figura salva: preditos_vs_observados_MT_itens")
} else {
  message("[!] Grafico preditos_MT nao pode ser gerado")
}

if (!is.null(p_pred_lp)) {
  ggsave(
    caminho_saida(DIR_BASE, FIG_PRED_OBS, "preditos_vs_observados_LP_itens", "png"),
    p_pred_lp, width = 9, height = 9, dpi = 180, bg = "white"
  )
  message("Figura salva: preditos_vs_observados_LP_itens")
} else {
  message("[!] Grafico preditos_LP nao pode ser gerado")
}

# =============================================================================
# ETAPA 14: GRAFICO COMPARATIVO DE R2
# =============================================================================

dados_r2 <- tibble(
  Modelo = c("MEDIA_MT\n(Matematica)", "MEDIA_LP\n(Lingua Portuguesa)"),
  R2     = c(summary_mt$adj.r.squared, summary_lp$adj.r.squared),
  Cor    = c("#1f77b4", "#ff7f0e")
)

p_r2 <- ggplot(dados_r2, aes(x = Modelo, y = R2, fill = Modelo)) +
  geom_col(alpha = 0.90, colour = "black", linewidth = 0.8) +
  geom_text(aes(label = paste0(round(R2 * 100, 1), "%")),
            vjust = -0.5, size = 6, fontface = "bold", colour = "#1A1A1A") +
  scale_y_continuous(
    limits = c(0, max(0.75, max(dados_r2$R2) * 1.2)),
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_fill_manual(values = setNames(dados_r2$Cor, dados_r2$Modelo),
                    guide = "none") +
  labs(
    title    = "Qualidade do Ajuste: R2 Ajustado - Itens Brutos (Dummies)",
    subtitle = "Percentual da variancia da proficiencia explicado pelos itens do questionario",
    x        = NULL,
    y        = "R2 Ajustado",
    caption  = paste0(
      "Modelo usa proporcoes por escola das dummies dos itens Q01-Q25,\n",
      "apos eliminacao iterativa de multicolinearidade (VIF > ", LIMIAR_VIF, ").\n",
      "R2 ajustado penaliza a inclusao de variaveis irrelevantes."
    )
  ) +
  tema_saeb() +
  theme(
    axis.text  = element_text(size = 11, colour = "#1A1A1A"),
    plot.title = element_text(size = 14, colour = "#1A1A1A")
  )

ggsave(
  caminho_saida(DIR_BASE, FIG_QUALIDADE, "resumo_qualidade_ajuste_itens", "png"),
  p_r2, width = 8, height = 6, dpi = 180, bg = "white"
)
message("Figura salva: resumo_qualidade_ajuste_itens")

# =============================================================================
# ETAPA 15: MAPA DE CALOR - VIF DAS PREDITORAS FINAIS
# =============================================================================

message("\n", strrep("-", 50))
message("ETAPA 15: MAPA DE CALOR DOS VIFs FINAIS")
message(strrep("-", 50))

# Funcao reutilizavel: gera o mapa de calor do VIF para um modelo.
# Os conjuntos de preditoras finais sao identicos entre MT e LP (ambos
# usam preditoras_finais), mas exibimos os dois mapas para documentar
# que o VIF final respeita o limiar em cada modelo.
gerar_mapa_vif <- function(modelo, nome_modelo, nome_arq) {

  vif_final <- tryCatch(
    car::vif(modelo),
    error = function(e) {
      message("  [!] VIF nao pode ser calculado para ", nome_modelo,
              ": ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(vif_final) || length(vif_final) == 0L) {
    message("  [!] Pulando mapa de calor VIF - ", nome_modelo,
            " sem preditoras suficientes.")
    return(invisible(NULL))
  }

  if (is.matrix(vif_final)) vif_final <- vif_final[, 1]

  df_vif <- tibble(
    Predictor = names(vif_final),
    VIF       = as.numeric(vif_final),
    Item      = str_extract(Predictor, "TX_RESP_Q[^_]+")
  ) |>
    mutate(Item = if_else(is.na(Item), Predictor, Item)) |>
    arrange(desc(VIF))

  # Numero de barras: min entre 40 e total de preditoras
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
                        ") - Modelo ", nome_modelo),
      subtitle = "Apos eliminacao iterativa: todas as preditoras mantidas tem VIF <= limiar",
      x        = NULL,
      y        = "Variance Inflation Factor (VIF)",
      caption  = paste0("Linha vermelha = limiar VIF = ", LIMIAR_VIF,
                        ". VIF < 5 = baixa multicolinearidade (verde/azul).")
    ) +
    tema_saeb() +
    theme(legend.position = "right")

  ggsave(
    caminho_saida(DIR_BASE, FIG_VIF, nome_arq, "png"),
    p_vif, width = 12, height = max(8, n_barras * 0.25), dpi = 180, bg = "white"
  )
  message("Figura salva: ", nome_arq)
}

gerar_mapa_vif(modelo_mt, "MEDIA_MT", "mapa_calor_vif_MT_itens")
gerar_mapa_vif(modelo_lp, "MEDIA_LP", "mapa_calor_vif_LP_itens")

# =============================================================================
# SALVAR MODELOS RDS
# =============================================================================

saveRDS(modelo_mt,
        caminho_saida(DIR_BASE, "modelos", "modelo_MT_itens", "rds"))
saveRDS(modelo_lp,
        caminho_saida(DIR_BASE, "modelos", "modelo_LP_itens", "rds"))

# =============================================================================
# GERAR TXT DE PERGUNTAS E RESPOSTAS (dicionario legivel)
# =============================================================================
# Para nao poluir os graficos de coeficientes com texto, as perguntas
# completas e os rotulos das categorias sao exportadas para um TXT de
# referencia, em pastas datadas. Os dicionarios DICT_PERGUNTAS_SAEB e
# DICT_ROTULOS_SAEB vem de utils_saeb.r (extracao do INPUT_R do INEP).

if (exists("DICT_PERGUNTAS_SAEB") && exists("DICT_ROTULOS_SAEB")) {

  arq_txt <- caminho_saida(DIR_BASE, "tabelas", "dicionario_perguntas_respostas", "txt")

  # Itens que de fato entraram no modelo (preditoras_finais)
  itens_no_modelo <- unique(str_extract(preditoras_finais, "^TX_RESP_Q[^_]+"))
  itens_no_modelo <- itens_no_modelo[!is.na(itens_no_modelo)]

  # Acumular todo o conteudo num vetor de linhas e escrever de uma vez
  # (writeLines com path string abre/escreve/fecha automaticamente).
  linhas <- c(
    "================================================================================",
    "DICIONARIO DE PERGUNTAS E RESPOSTAS - QUESTIONARIO SOCIOECONOMICO SAEB 2023",
    "================================================================================",
    "Fonte: MICRODADOS_SAEB_2023/INPUTS/INPUT_R_TS_ALUNO_34EM.R (INEP)",
    "Normalizado para ASCII puro. A e omitida inicialmente; outras categorias podem sair na selecao.",
    "Consulte referencias_efetivas_itens para as categorias omitidas no modelo final.",
    "Itens presentes no modelo final aparecem marcados com [*].",
    "",
    paste0("Total de itens: ", length(DICT_PERGUNTAS_SAEB)),
    ""
  )

  for (it in names(DICT_PERGUNTAS_SAEB)) {
    marca <- if (it %in% itens_no_modelo) " [*]" else ""
    linhas <- c(linhas, paste0("---- ", it, marca, " ----"),
                paste0("Pergunta: ", DICT_PERGUNTAS_SAEB[[it]]),
                "Categorias:")
    rot <- DICT_ROTULOS_SAEB[[it]]
    if (!is.null(rot) && length(rot) > 0) {
      for (cat in names(rot)) {
        linhas <- c(linhas, paste0("  ", cat, " = ", rot[[cat]]))
      }
    } else {
      linhas <- c(linhas, "  (sem rotulos registrados)")
    }
    linhas <- c(linhas, "")
  }
  linhas <- c(linhas, "================================================================================")

  writeLines(linhas, arq_txt, useBytes = TRUE)
  message("TXT de perguntas/respostas salvo: ", basename(arq_txt),
          " (", length(DICT_PERGUNTAS_SAEB), " itens, ",
          length(linhas), " linhas)")
} else {
  message("[!] Dicionarios DICT_PERGUNTAS_SAEB/DICT_ROTULOS_SAEB indisponiveis - TXT nao gerado.")
}

# =============================================================================
# RELATORIO FINAL
# =============================================================================

message("\n", strrep("=", 70))
message("RELATORIO FINAL - ITENS BRUTOS (DUMMIES)")
message(strrep("=", 70))
message("\nPre-processamento:")
message("  Alunos no raw            : ", nrow(dados_brutos))
message("  Escolas na base final    : ", nrow(df_completo))
message("  Dummies geradas (total)  : ", length(todas_dummies))
message("  [A] Respostas invalidas  : tratadas como NA antes da geracao das dummies")
message("  [B] Removidas (var ~ 0)  : ", n_removidas_var0)
message("  [C] Removidas (VIF > ",  LIMIAR_VIF, ")    : ", nrow(log_vif))
message("  Preditoras no modelo     : ", length(preditoras_finais))
message("\nModelos:")
message("  MT - R2aj: ", round(summary_mt$adj.r.squared, 4),
        " | RMSE: ", round(sqrt(mean(summary_mt$residuals^2)), 2))
message("  LP - R2aj: ", round(summary_lp$adj.r.squared, 4),
        " | RMSE: ", round(sqrt(mean(summary_lp$residuals^2)), 2))
message("\nArquivos de log gerados:")
message("  log_eliminadas_var0  (etapa B)")
message("  log_vif_removidos    (etapa C)")
message("\nArquivos gerados em (pastas datadas):")
message("  ", file.path(DIR_BASE, "outputs", format(Sys.Date(), FORMATO_DATA_PASTA)))
message("\n* MELHORIAS v1.2:")
message("  * Grafico de coeficientes: apenas preditoras significativas (p < 0,05)")
message("  * Altura do grafico calculada dinamicamente pelo n de preditoras")
message("  * limitsize = FALSE para acomodar figuras muito altas")
message("  * Log das variaveis eliminadas por variancia zero salvo em CSV (etapa B)")
message("  * Log de missings por item salvo em CSV (log_missings_itens)")
message("  * Log VIF em 3 colunas (Iteracao, Preditor, VIF) - etapa C")
message("  * p-valor do teste F global calculado via pf() (nao mais hardcoded)")
message("  * IC 95% via quantil t (qt(0.975, gl)) em vez de aproximacao 1,96")
message("  * Agregacao por escola via count + pivot_wider (1 passagem por item)")
message("  * tema_saeb/detectar_raiz reutilizados de utils_saeb.r (sem duplicacao)")
message("  * Nota metodologica expandida com os 3 criterios de eliminacao")
message("  * Relatorio final discrimina as 3 etapas de eliminacao [A], [B], [C]")

message("\n", strrep("=", 70))
message("CONCLUIDO COM SUCESSO!")
message(strrep("=", 70))
