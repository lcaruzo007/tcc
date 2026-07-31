################################################################################
# SCRIPT: regressao_itens_brutos_dummy.r
#
# FUNCIONALIDADE:
#   Regressao Linear Multipla com variaveis dummy geradas a partir dos
#   itens brutos do questionario socioeconomico SAEB (TX_RESP_Q01-Q25).
#   Agrega por escola e modela MEDIA_MT e MEDIA_LP.
#
# DIFERENCA EM RELACAO AO SCRIPT PRINCIPAL (regressao_linear_multipla.r):
#   O script principal usa INSE_MEDIO (score TRI calculado pelo INEP) como
#   proxy socioeconomico. Este script substitui o INSE pelos proprios itens
#   brutos do questionario, convertidos em variaveis dummy (n_cats - 1 por
#   item, com a categoria "A" como referencia). O objetivo e explorar quais
#   dimensoes especificas do nivel socioeconomico (bens domesticos, escolaridade
#   dos pais, habitos culturais etc.) apresentam efeito independente sobre a
#   proficiencia, algo que o INSE agrega em um unico indice.
#
# ENTRADA:
#   - TS_ALUNO_34EM.csv  (dados brutos SAEB - nivel aluno)
#
# SAIDA (outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>):
#   - tabelas/base_escolas_itens, resumo_modelos_itens,
#     coeficientes_MT_itens / coeficientes_LP_itens,
#     log_eliminadas_var0, log_vif_removidos, log_missings_itens
#   - diagnosticos/diagnosticos_MT_itens / diagnosticos_LP_itens
#   - figuras/diagnosticos_residuos/    -> residuos_MT_itens / _LP_itens
#   - figuras/preditos_vs_observados/   -> preditos_vs_observados_MT_itens / _LP_itens
#   - figuras/qualidade_ajuste/         -> resumo_qualidade_ajuste_itens
#   - figuras/mapas_calor_vif/          -> mapa_calor_vif_MT_itens / _LP_itens
#   - figuras/coeficientes_grupo/       -> coef_grupo_MT_IMAGEMNN / coef_grupo_LP_IMAGEMNN
#   - modelos/modelo_MT_itens.rds / modelo_LP_itens.rds
#
# VERSAO: 1.3 - Julho 2026 (refatoracao: p-valor F, IC via t, log VIF em
#   colunas, log_missings, pivot_wider, helpers de utils_saeb.r, ASCII)
#
# ---------------------------------------------------------------------------
# NOTA METODOLOGICA - USO DE DUMMIES DOS ITENS BRUTOS E CRITERIOS DE ELIMINACAO
# ---------------------------------------------------------------------------
#
# Os itens do questionario (TX_RESP_Q01 a TX_RESP_Q25 com subitens) sao
# variaveis categoricas ordinais codificadas como letras (A, B, C...).
# A abordagem adotada aqui e:
#
# 1. CODIFICACAO DUMMY (one-hot com referencia)
#    Para cada item, a categoria "A" (menor grau da escala) e tomada como
#    referencia. Para um item com k categorias validas sao geradas k-1
#    dummies binarias. No total, os itens geram ~169 dummies.
#    Respostas codificadas como "." (nao respondeu) ou "*" (invalido) sao
#    tratadas como NA antes da criacao das dummies.
#
# 2. AGREGACAO POR ESCOLA (proporcao de respostas)
#    Como a unidade de analise e a escola (nao o aluno), cada dummy e
#    agregada como a PROPORCAO de alunos da escola que respondeu aquela
#    categoria. Isso transforma valores binarios individuais em variaveis
#    continuas [0, 1] no nivel escola - interpretaveis como "fracao de
#    alunos com perfil X".
#
# ---------------------------------------------------------------------------
# CRITERIOS DE ELIMINACAO DE VARIAVEIS (TRES ETAPAS SEQUENCIAIS)
# ---------------------------------------------------------------------------
#
# As dummies geradas passam por tres filtros sequenciais antes de entrar
# no modelo final. O numero de variaveis eliminadas em cada etapa e
# registrado no relatorio final e nos arquivos de log.
#
# ETAPA A - RESPOSTAS INVALIDAS (antes da geracao das dummies)
#    Respostas codificadas como "." (ausencia de resposta) ou "*" (codigo
#    invalido/inconsistente conforme dicionario SAEB) sao convertidas para
#    NA antes de qualquer operacao. Alem disso, escolas onde um item tem
#    menos de MIN_RESP_ITEM (padrao = 3) respostas validas recebem NA para
#    todas as dummies daquele item naquela escola - evitando proporcoes
#    calculadas sobre amostras infimas e potencialmente nao representativas.
#    Criterio: n_respostas_validas_por_escola < MIN_RESP_ITEM -> NA.
#
# ETAPA B - FILTRO DE VARIANCIA ZERO / QUASE-ZERO (nivel escola)
#    Apos a agregacao por escola, dummies cujas proporcoes apresentam
#    variancia menor que LIMIAR_VAR_ZERO (padrao = 0,001) entre escolas,
#    ou cujo percentual de missings supera 50%, sao descartadas.
#    Esse filtro elimina:
#      * Categorias de resposta raramente escolhidas (quase ninguem
#        respondeu "E" em determinado item -> dummy TX_RESP_Q07a_E ~ 0
#        em todas as escolas -> variancia ~ 0 -> sem poder discriminatorio).
#      * Dummies com dados ausentes na maioria das escolas, que
#        introduziriam vies de selecao ao exigir descarte de muitas escolas.
#    Criterio: var(dummy, na.rm=TRUE) <= LIMIAR_VAR_ZERO
#              OU mean(is.na(dummy)) > 0,50 -> eliminada.
#
# ETAPA C - CONTROLE DE MULTICOLINEARIDADE VIA VIF ITERATIVO
#    Com dezenas a centenas de preditores continuos derivados de itens
#    correlacionados entre si (p. ex., itens de bens domesticos Q07a-Q07e
#    tendem a co-variar), a multicolinearidade e estruturalmente esperada.
#    O script aplica eliminacao iterativa pelo Variance Inflation Factor:
#      i.   Ajusta o modelo com todos os preditores restantes.
#      ii.  Calcula o VIF de cada preditor via car::vif().
#      iii. Identifica o preditor com maior VIF.
#      iv.  Se VIF_max > LIMIAR_VIF (padrao = 10): remove esse preditor,
#           registra em log e volta ao passo i.
#      v.   Encerra quando todos os VIFs <= LIMIAR_VIF.
#    O limiar VIF = 10 e o criterio conservador classico (Hair et al., 2019);
#    valores > 10 indicam que mais de 90% da variancia do preditor e
#    explicada pelos demais, tornando sua estimativa instavel.
#    A eliminacao e feita com base no modelo MEDIA_MT e o conjunto de
#    preditoras resultante e reutilizado para MEDIA_LP, garantindo
#    comparabilidade direta entre os dois modelos.
#    O log completo das variaveis removidas nesta etapa (nome e VIF no
#    momento da remocao) e salvo em log_vif_removidos_<ts>.csv.
#    Criterio: VIF > LIMIAR_VIF -> preditor de maior VIF e removido
#              iterativamente ate todos estarem abaixo do limiar.
#
# RESUMO DO FLUXO DE ELIMINACAO:
#    Dummies brutas (~169)
#      -> [A] NA por resposta invalida / escola com < MIN_RESP_ITEM respostas
#      -> [B] Remocao por variancia ~ 0 ou > 50% missing
#      -> [C] Remocao iterativa por VIF > LIMIAR_VIF
#      -> Preditoras finais no modelo
#
# ---------------------------------------------------------------------------
# 3. INTERPRETACAO DOS COEFICIENTES
#    Cada coeficiente representa o efeito estimado (em pontos SAEB) de
#    uma escola ter mais alunos respondendo a categoria X em vez da
#    categoria de referencia "A", mantendo todos os demais preditores
#    constantes. Por exemplo, Q02_B = +5.2 significa que escolas onde
#    a fracao de alunos respondendo "B" na Q02 e maior em 1 unidade
#    (i.e., 100% vs 0%) tem proficiencia 5.2 pontos maior, ceteris paribus.
#    O grafico de coeficientes exibe apenas as preditoras estatisticamente
#    significativas (p < 0,05) entre as mantidas no modelo apos os tres
#    filtros, ordenadas pelo valor absoluto do coeficiente, de forma a
#    revelar os efeitos de maior magnitude. Preditoras nao significativas
#    continuam no modelo (como controle) mas sao omitidas dos graficos por
#    grupo tematico por legibilidade. IC 95% via quantil t (qt(0.975, gl)).
#
# REFERENCIA: INEP (2021). Nota Tecnica - Indicador de Nivel
# Socioeconomico das Escolas de Educacao Basica (INSE).
# Hair, J. F. et al. (2019). Multivariate Data Analysis (8a ed.).
# ---------------------------------------------------------------------------
################################################################################
# ---------------------------------------------------------------------------
# ALGORITMOS E METODOS ESTATISTICOS UTILIZADOS
# ---------------------------------------------------------------------------
#
# 1. TRANSFORMACAO DE VARIAVEIS CATEGORICAS (ONE-HOT ENCODING)
#    Algoritmo: Para cada variavel categorica (item do questionario) com
#    k categorias validas, geram-se k-1 variaveis binarias dummy.
#    Implementacao: loops sobre itens, geracao de colunas logicas transformadas
#    em proporcoes por escola. Categoria "A" e tomada como referencia (omitida).
#
# 2. AGREGACAO HIERARQUICA (NIVEL: ALUNO -> ESCOLA)
#    Metodo: Calculo de proporcoes por escola (mean na dummy binaria do aluno).
#    Transformacao: valores binarios individuais {0,1} -> continuos [0,1] no
#    nivel escola. Filtragem: escolas com menos de MIN_RESP_ITEM (padrao=3)
#    respostas validas por item recebem NA, evitando estimativas instaveis.
#
# 3. FILTRAGEM DE VARIANCIA ZERO (LIMIAR ADAPTATIVO)
#    Metodo: Calculo de var(X) para cada variavel candidata no nivel escola.
#    Criterio: Removes sao variaveis com var < 0,001 ou >50% dados faltantes,
#    sem poder discriminatorio entre escolas.
#    Implementacao: sapply() com var() e mean(is.na()).
#
# 4. CONTROLE DE MULTICOLINEARIDADE - VIF ITERATIVO
#    Algoritmo: Procedimento iterativo de eliminacao progressiva:
#      a) Ajustar modelo completo via OLS (Ordinary Least Squares)
#      b) Calcular VIF usando car::vif() para cada preditora
#      c) Identificar preditora com VIF maximo
#      d) Se VIF_max > limiar: remover, registrar em log, retornar a (a)
#      e) Parar quando todos VIF <= limiar
#    VIF = 1 / (1 - R2_j), onde R2_j e o R2 da regressao da preditora j
#    contra todas as demais. VIF > 10 indica >90% variancia colinear.
#    Implementacao: repeat{ } loop com tryCatch para robustez.
#
# 5. REGRESSAO LINEAR MULTIPLA (MINIMOS QUADRADOS ORDINARIOS - OLS)
#    Modelo: Y = beta0 + beta1X1 + beta2X2 + ... + beta_pX_p + e
#    Estimacao: lm(formula, data) ajusta via decomposicao QR.
#    Pressupostos testados graficamente:
#      * Linearidade: grafico Residuos vs Ajustados
#      * Normalidade dos erros: Q-Q plot (qqplot)
#      * Homocedasticidade: Scale-Location plot
#      * Independencia: suposicao por design (escolas independentes)
#    Implementacao: stats::lm() funcao base R.
#
# 6. DIAGNOSTICO DE RESIDUOS (GRAFICOS EXPLORATORIOS)
#    Procedimentos graficos (ggplot2 + patchwork):
#      i.    Residuos vs Ajustados: detecta nao-linearidade e heteroced.
#      ii.   Q-Q plot: avalia normalidade dos erros via quantis teoricos
#      iii.  Scale-Location: sqrt(|residuos padronizados|) vs ajustados
#      iv.   Histograma de residuos: visualiza simetria e curtose
#    Implementacao: fitted(), residuals(), rstandard(), stat_qq().
#
# 7. INDICES DE AJUSTE E QUALIDADE DO MODELO
#    * R2 ajustado = 1 - [(n-1)/(n-p-1)] x (1 - R2)
#      Corrige vies de R2 crescente com numero de preditores; comparavel
#      entre modelos com diferentes numeros de variaveis.
#    * RMSE (Root Mean Square Error) = sqrt[sum(e_i^2) / n]
#      Erro medio de predicao nas mesmas unidades da resposta; penaliza
#      erros grandes exponencialmente.
#    * AIC (Akaike Information Criterion) = 2k - 2ln(L)
#      Balanceia ajuste vs complexidade; menor = melhor modelo relativo.
#    * BIC (Bayesian IC) = kxln(n) - 2ln(L)
#      Similar ao AIC com penalizacao maior por numero de parametros;
#      preferivel para grandes amostras.
#    Implementacao: summary(lm), AIC(), BIC() base R.
#
# 8. TESTES DE SIGNIFICANCIA DOS COEFICIENTES
#    Metodo: Teste t de Student para cada coeficiente.
#    Hipotese nula: H0: beta_j = 0 (sem efeito da preditora j).
#    Estatistica: t_j = beta_j / SE(beta_j) ~ t_{n-p-1} sob H0.
#    p-valor bilateral: P(|T| >= |t_j|).
#    Limiar alfa = 0,05 (padrao).
#    Implementacao: summary(lm)$coefficients + tidy(broom).
#
# 9. INTERVALO DE CONFIANCA (IC 95%)
#    Calculo: IC = beta_j +/- qt(0.975, gl) x SE(beta_j) [distribuicao t,
#    n grande aproxima-se da normal; gl = n - p - 1].
#    Interpretacao: Intervalo de 95% de confianca para o parametro populacional.
#    Visualizacao: barras de erro nos graficos de coeficientes.
#    Implementacao: estimate +/- qt(0.975, df.residual) * std.error.
#
# 10. VALIDACAO E ESTRATIFICACAO
#     Particao por escola: analise independente por grupo de contraste
#     (Publica vs Privada, Capital vs Interior, Urbana vs Rural).
#     Estratificacao tematica: agrupa itens por dimensao socioeconomica
#     (Q01-Q09, Q10-Q14, Q15-Q20, Q21-Q25) para facilitar interpretacao
#     e reduzir problema de multiplos testes.
#     Implementacao: filter(), group_by(), facet estratificacao em ggplot2.
#
# REFERENCIAS TEORICAS:
# * Hair, J. F. et al. (2019). Multivariate Data Analysis (8a ed.).
#   Pearson. - Caps. 4-5: regressao, multicolinearidade, diagnostico.
# * Wooldridge, J. M. (2020). Introductory Econometrics: A Modern Approach
#   (7a ed.). Cengage. - Cap. 3: estimacao OLS, pressupostos, testes.
# * James, G. et al. (2021). An Introduction to Statistical Learning
#   (2a ed.). Springer. - Cap. 3: regressao linear, interpretacao, validacao.
# * Fox, J. (2016). Applied Regression Analysis & Generalized Linear Models
#   (3a ed.). SAGE. - Cap. 6: diagnostico, multicolinearidade, VIF.
#
# --------------------------------------------------------------------------

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
# DIR_BASE e base para caminho_saida(); DIR_* legacy sao mantidos apenas
# para mensagens de log e fallback de leitura (compatibilidade com run
# antigas). As escritas usam caminho_saida() -> outputs/<YYYY-MM-DD>/<tipo>/
DIR_BASE <- file.path(RAIZ, "TESTE", "5_REGRESSAO_ITENS_BRUTOS")
DIR_MODELOS     <- file.path(DIR_BASE, "outputs/modelos")
DIR_DIAGNOSTICOS<- file.path(DIR_BASE, "outputs/diagnosticos")
DIR_FIGURAS     <- file.path(DIR_BASE, "outputs/figuras")
DIR_TABELAS     <- file.path(DIR_BASE, "outputs/tabelas")

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
message("  Saidas       : ", DIR_BASE, "/outputs/<YYYY-MM-DD>/<tipo>/")
message("  (legacy)     : ", DIR_TABELAS, " | ", DIR_FIGURAS, "\n")

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
  preds <- setdiff(names(df_modelo), resposta)
  log_removidos <- tibble(Iteracao = integer(0),
                          Preditor = character(0),
                          VIF      = numeric(0))
  iter <- 0L

  repeat {
    formula_atual <- as.formula(
      paste(resposta, "~", paste(preds, collapse = " + "))
    )
    modelo_tmp <- lm(formula_atual, data = df_modelo)
    vif_vals   <- tryCatch(car::vif(modelo_tmp), error = function(e) NULL)

    if (is.null(vif_vals)) {
      message("  [!] VIF nao pode ser calculado - encerrando eliminacao.")
      break
    }

    # vif() pode retornar matrix (quando ha fatores); pegar primeira coluna
    if (is.matrix(vif_vals)) vif_vals <- vif_vals[, 1]

    max_vif  <- max(vif_vals, na.rm = TRUE)
    max_pred <- names(which.max(vif_vals))

    if (max_vif <= limiar) break

    iter <- iter + 1L
    message(sprintf("  Removendo %-45s  VIF = %.1f", max_pred, max_vif))
    log_removidos <- log_removidos |>
      add_row(Iteracao = iter, Preditor = max_pred, VIF = max_vif)
    preds <- setdiff(preds, max_pred)
  }

  list(preditoras = preds, removidos = log_removidos)
}

# =============================================================================
# INICIALIZACAO
# =============================================================================

# Pastas datadas sao criadas automaticamente por caminho_saida().
# Os DIR_* legacy seguintes so existem para mensagens de log/fallback.
for (d in c(DIR_MODELOS, DIR_DIAGNOSTICOS, DIR_FIGURAS, DIR_TABELAS))
  dir.create(d, showWarnings = FALSE, recursive = TRUE)

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

dados_brutos <- read_csv(
  ARQUIVO_DADOS_BRUTOS,
  col_types = colunas_fixas,
  show_col_types = FALSE
)

# Converter colunas numericas que vieram como character por causa do .default
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

# Tratar "." e "*" como NA nos itens do questionario
itens_presentes <- intersect(ITENS_QUEST, names(dados_brutos))
dados_brutos <- dados_brutos |>
  mutate(across(all_of(itens_presentes),
                ~ if_else(.x %in% c(".", "*", ""), NA_character_, .x)))

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

message("Escolas com proficiencia valida: ", nrow(media_prof))

# =============================================================================
# ETAPA 3: VARIAVEIS ESTRUTURAIS DA ESCOLA
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
    LOCALIZACAO = if_else(ID_LOCALIZACAO == 1, "Urbana", "Rural"),
    AREA_LOCAL  = paste0(LOCALIZACAO, "_", AREA)
  ) |>
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
props_lista <- lapply(itens_presentes, function(item) {

  cats_validas <- sort(unique(na.omit(dados_quest[[item]])))
  cats_validas <- cats_validas[cats_validas != "A"]
  if (length(cats_validas) == 0L) return(NULL)

  # Conta respostas validas por escola e por categoria (uma varredura).
  contagem <- dados_quest |>
    filter(!is.na(.data[[item]])) |>
    count(ID_ESCOLA, resp = .data[[item]])

  # Total de respostas validas por escola (denominador da proporcao).
  n_valid_escola <- contagem |>
    group_by(ID_ESCOLA) |>
    summarise(n_valid = sum(n), .groups = "drop")

  # Pivot de TODAS as categorias (incl. "A") usando values_fill = 0, de
  # modo que escolas que responderam apenas "A" aparecam com prop 0 nas
  # demais categorias (mesma semantica do codigo original: mean(valid==cat)).
  # Apos o pivot descarta-se a coluna da referencia "A".
  col_a <- paste0(item, "_A")
  df_agg <- contagem |>
    left_join(n_valid_escola, by = "ID_ESCOLA") |>
    mutate(prop = n / n_valid) |>
    select(ID_ESCOLA, resp, prop) |>
    pivot_wider(
      id_cols      = ID_ESCOLA,
      names_from   = resp,
      values_from  = prop,
      names_prefix = paste0(item, "_"),
      values_fill  = 0
    ) |>
    select(-any_of(col_a)) |>
    left_join(n_valid_escola, by = "ID_ESCOLA") |>
    mutate(across(starts_with(paste0(item, "_")),
                  ~ if_else(n_valid < MIN_RESP_ITEM, NA_real_, .x))) |>
    select(-n_valid)

  df_agg
})

props_lista <- Filter(Negate(is.null), props_lista)

props_escola <- reduce(props_lista, left_join, by = "ID_ESCOLA")

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
  inner_join(categ_escola, by = "ID_ESCOLA") |>
  inner_join(props_escola,  by = "ID_ESCOLA")

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
    var(x, na.rm = TRUE) > LIMIAR_VAR_ZERO && mean(is.na(x)) < 0.5
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

message("Observacoes (escolas) com dados completos: ", nrow(df_completo))

# Eliminacao para MEDIA_MT (o resultado serve para ambos os modelos,
# pois as preditoras sao as mesmas)
resultado_vif <- eliminar_por_vif(
  df_modelo = df_completo |> select(-MEDIA_LP),
  resposta  = "MEDIA_MT",
  limiar    = LIMIAR_VIF
)

preditoras_finais <- resultado_vif$preditoras
log_vif           <- resultado_vif$removidos   # tibble(Iteracao, Preditor, VIF)

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
      str_detect(Termo, "^TIPO_ESCOLA_|^AREA_LOCAL_")
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
      title    = paste0(grupo_nome, " - Modelo ", nome_modelo),
      subtitle = paste0(
        n_preds, " coeficientes significativos (p < 0,05) | ",
        "ordenados por |coeficiente| | categoria A = referencia"
      ),
      x       = NULL,
      y       = "Coeficiente (pontos de proficiencia SAEB)",
      caption = paste0(
        "Coef > 0: categoria aumenta proficiencia vs referencia 'A'  |  ",
        "Coef < 0: reduz proficiencia\n",
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
             label = paste0("R2 = ", r2, "\nRMSE = ", rmse,
                            "\nCorr = ", corr),
             hjust = 1.05, vjust = -0.3, size = 4.2, fontface = "bold",
             colour = "#1A1A1A", fill = "#FFFFEE", label.size = 0.5) +
    coord_fixed(ratio = 1) +
    labs(
      title    = paste0("Preditos vs Observados (", nome,
                        ") - Itens Brutos"),
      subtitle = "Linha vermelha = ajuste perfeito | Linha verde = ajuste do modelo",
      x        = "Proficiencia observada (media da escola)",
      y        = "Proficiencia predita",
      caption  = paste0(
        "Pontos sobre a diagonal = predicao perfeita.\n",
        "Acima da linha = subestimacao | Abaixo = superestimacao."
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
  geom_hline(yintercept = 0.30, linetype = "dotted",
             colour = "#2CA02C", linewidth = 1.1) +
  geom_hline(yintercept = 0.50, linetype = "dotted",
             colour = "#FFA500", linewidth = 1.1) +
  geom_hline(yintercept = 0.70, linetype = "dotted",
             colour = "#D62728", linewidth = 1.1) +
  annotate("text", x = 0.55, y = 0.31, label = "30% - razoavel",
           size = 3.8, colour = "#2CA02C", hjust = 0, fontface = "bold") +
  annotate("text", x = 0.55, y = 0.51, label = "50% - bom",
           size = 3.8, colour = "#8B6914", hjust = 0, fontface = "bold") +
  annotate("text", x = 0.55, y = 0.71, label = "70% - excelente",
           size = 3.8, colour = "#D62728", hjust = 0, fontface = "bold") +
  scale_y_continuous(
    limits = c(0, max(dados_r2$R2) * 1.2),
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
