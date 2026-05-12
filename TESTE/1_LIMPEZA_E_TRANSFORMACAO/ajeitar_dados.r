# =========================================================================
# PASSO 1: LIMPEZA E TRANSFORMAÇÃO DOS DADOS SAEB
# Com tratamento diferenciado por TIPO DE VARIÁVEL
# =========================================================================

library(data.table)
library(tidyverse)

# =========================================================================
# Configuração de Caminhos
# =========================================================================
RAIZ <- "C:/Users/Usuario/Desktop/tcc"
DIR_MICRODADOS <- file.path(RAIZ, "MICRODADOS_SAEB_2023/DADOS")
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_SAIDA_POR_ESCOLA <- file.path(DIR_TESTE, "dados_por_escola")
DIR_SAIDA_RAIZ <- DIR_TESTE

source(file.path(RAIZ, "DOCUMENTACAO", "utils_saeb.r"))

# Atalhos para os dicionários centralizados (compatibilidade com código existente)
ordinais      <- ORDINAIS_SAEB
nominais_info <- NOMINAIS_SAEB
continuas     <- CONTINUAS_SAEB

# -------------------------------------------------------------------------
# Configuração — ajuste estes caminhos antes de executar
# -------------------------------------------------------------------------
arquivo_entrada        <- file.path(DIR_MICRODADOS, "TS_ALUNO_34EM_escola_61432986.csv")
arquivo_saida_geral    <- file.path(DIR_SAIDA_RAIZ, "dados_escola_limpos.csv")
dir_saida_por_escola   <- DIR_SAIDA_POR_ESCOLA
sobrescrever_por_escola <- FALSE

# Valores tratados como NA nas colunas TX_RESP_Q*
VALORES_NA <- c("*", ".", " ", "F")

# Colunas de proficiência (usadas para correlação)
nota_MT <- "PROFICIENCIA_MT_SAEB"
nota_LP <- "PROFICIENCIA_LP_SAEB"

# -------------------------------------------------------------------------
# Validações iniciais
# -------------------------------------------------------------------------
if (!file.exists(arquivo_entrada)) {
  stop("Arquivo de entrada nao encontrado: ", arquivo_entrada)
}

# -------------------------------------------------------------------------
# 1. Leitura
# -------------------------------------------------------------------------
message("Lendo arquivo de entrada...")
df <- data.table::fread(
  arquivo_entrada,
  integer64 = 'character',
  stringsAsFactors = FALSE
)

if (!"ID_ESCOLA" %in% names(df)) {
  stop("A coluna ID_ESCOLA nao foi encontrada na base de entrada.")
}

message("Registros lidos: ", nrow(df))

# -------------------------------------------------------------------------
# 2. Garante que notas são numéricas
# -------------------------------------------------------------------------
if (nota_MT %in% names(df)) df[[nota_MT]] <- as.numeric(df[[nota_MT]])
if (nota_LP %in% names(df)) df[[nota_LP]] <- as.numeric(df[[nota_LP]])

# -------------------------------------------------------------------------
# 3. Helper: substitui nulos/brancos por NA
# -------------------------------------------------------------------------
limpa <- function(x) { 
  x[x %in% VALORES_NA] <- NA
  x 
}

# -------------------------------------------------------------------------
# 4. Processa ORDINAIS — respeita ordem + Spearman
# -------------------------------------------------------------------------
message("Processando variáveis ordinais...")
for (col in names(ordinais)) {
  if (col %in% names(df)) {
    v <- limpa(df[[col]])
    df[[paste0(col, "_num")]] <- as.integer(
      factor(v, levels = ordinais[[col]], ordered = TRUE)
    )
  }
}

# -------------------------------------------------------------------------
# 5. Processa NOMINAIS — cria dummies
# -------------------------------------------------------------------------
message("Processando variáveis nominais...")
for (col in names(nominais_info)) {
  if (col %in% names(df)) {
    v <- limpa(df[[col]])
    mapping <- nominais_info[[col]]$mapping
    prefix <- nominais_info[[col]]$prefix
    
    for (cod in names(mapping)) {
      nome_dummy <- paste0(prefix, "_", mapping[[cod]])
      df[[nome_dummy]] <- ifelse(v == cod, 1,
                          ifelse(!is.na(v), 0, NA))
    }
  }
}

# -------------------------------------------------------------------------
# 6. Garante que contínuas são numéricas
# -------------------------------------------------------------------------
message("Processando variáveis contínuas...")
for (col in continuas) {
  if (col %in% names(df)) {
    df[[col]] <- as.numeric(df[[col]])
  }
}

# =========================================================================
# RELATÓRIO DE MISSINGS (Dados Ausentes) — NOVO!
# =========================================================================
# Importante para documentar na metodologia do TCC:
# "X% dos alunos não responderam à pergunta Y"
# =========================================================================

message("Gerando relatório de dados ausentes...")

# Selecionar apenas colunas TX_RESP_Q* (perguntas do socioeconômico)
cols_questoes <- names(df)[grep("^TX_RESP_Q", names(df))]

# Calcular missings por coluna (ANTES das transformações)
na_stats <- data.frame(
  Variavel = cols_questoes,
  N_Total = nrow(df),
  N_NA = sapply(cols_questoes, function(x) sum(is.na(df[[x]]))),
  Pct_NA = round(100 * sapply(cols_questoes, function(x) sum(is.na(df[[x]]))) / nrow(df), 2),
  stringsAsFactors = FALSE
)

# Ordenar por % de missing (maior para menor)
na_stats <- na_stats[order(na_stats$Pct_NA, decreasing = TRUE), ]
rownames(na_stats) <- NULL

# Exibir resumo
message("\n=== RESUMO DE DADOS AUSENTES (Missing Data) ===")
message("Variáveis com > 5% de missings:")
print(na_stats[na_stats$Pct_NA > 5, ])

message("\nArquivo completo de missings salvo em: dados_por_escola/resumo_missings.csv")

# Salvar relatório de missings (geral)
caminho_missings_geral <- file.path(dir_saida_por_escola, "resumo_missings.csv")
write.csv(na_stats, caminho_missings_geral, row.names = FALSE)

# -------------------------------------------------------------------------
# 8. Salvar arquivo geral (usado pelo script de correlação)
# -------------------------------------------------------------------------
dir.create(dirname(arquivo_saida_geral), showWarnings = FALSE, recursive = TRUE)
write.csv(as.data.frame(df), arquivo_saida_geral, row.names = FALSE)
message("Arquivo geral salvo em: ", arquivo_saida_geral)

# -------------------------------------------------------------------------
# 9. Salvar uma cópia filtrada por escola
# -------------------------------------------------------------------------
dir.create(dir_saida_por_escola, showWarnings = FALSE, recursive = TRUE)

ids_escola <- sort(unique(df$ID_ESCOLA))
ids_escola <- ids_escola[!is.na(ids_escola)]

message("Escolas encontradas: ", length(ids_escola))

for (id_escola in ids_escola) {
  pasta_escola <- file.path(dir_saida_por_escola, as.character(id_escola))
  dir.create(pasta_escola, showWarnings = FALSE, recursive = TRUE)

  dados_uma_escola <- df[ID_ESCOLA == id_escola]

  arquivo_saida <- gerar_caminho_sem_sobrescrever(
    file.path(pasta_escola, "dados_escola_em_numeros.csv"),
    sobrescrever = sobrescrever_por_escola
  )

  write.csv(as.data.frame(dados_uma_escola), arquivo_saida, row.names = FALSE)
}

message("Limpeza concluida. Arquivos por escola salvos em: ", dir_saida_por_escola)
