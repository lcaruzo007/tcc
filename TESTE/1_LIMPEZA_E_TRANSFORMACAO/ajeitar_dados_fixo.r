# =========================================================================
# PASSO 1: LIMPEZA E TRANSFORMAÇÃO DOS DADOS SAEB (VERSÃO CORRIGIDA)
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

# Carrega função auxiliar
gerar_caminho_sem_sobrescrever <- function(caminho_base, sobrescrever = FALSE) {
  if (sobrescrever || !file.exists(caminho_base)) return(caminho_base)
  
  pasta    <- dirname(caminho_base)
  nome     <- tools::file_path_sans_ext(basename(caminho_base))
  extensao <- tools::file_ext(caminho_base)
  sufixo   <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  montar <- function(contador = NULL) {
    parte_cnt <- if (!is.null(contador)) paste0("_", contador) else ""
    arquivo   <- paste0(nome, "_", sufixo, parte_cnt)
    if (nzchar(extensao)) arquivo <- paste0(arquivo, ".", extensao)
    file.path(pasta, arquivo)
  }
  
  candidato <- montar()
  contador  <- 1L
  while (file.exists(candidato)) {
    candidato <- montar(contador)
    contador  <- contador + 1L
  }
  candidato
}

# Dicionários centralizados
ORDINAIS_SAEB <- list(
  TX_RESP_Q10a = c("A","B","C"), TX_RESP_Q10b = c("A","B","C"),
  TX_RESP_Q10c = c("A","B","C"), TX_RESP_Q10d = c("A","B","C"),
  TX_RESP_Q10e = c("A","B","C"), TX_RESP_Q10f = c("A","B","C"),
  
  TX_RESP_Q21a = c("A","B","C","D"), TX_RESP_Q21b = c("A","B","C","D"),
  TX_RESP_Q21c = c("A","B","C","D"), TX_RESP_Q21d = c("A","B","C","D"),
  TX_RESP_Q21e = c("A","B","C","D"),
  
  TX_RESP_Q22a = c("D","C","B","A"), TX_RESP_Q22b = c("D","C","B","A"),
  TX_RESP_Q22c = c("D","C","B","A"), TX_RESP_Q22d = c("D","C","B","A"),
  TX_RESP_Q22e = c("D","C","B","A"), TX_RESP_Q22f = c("D","C","B","A"),
  TX_RESP_Q22g = c("D","C","B","A"), TX_RESP_Q22h = c("D","C","B","A"),
  
  TX_RESP_Q23a = c("D","C","B","A"), TX_RESP_Q23b = c("D","C","B","A"),
  TX_RESP_Q23c = c("D","C","B","A"), TX_RESP_Q23d = c("D","C","B","A"),
  TX_RESP_Q23e = c("D","C","B","A"), TX_RESP_Q23f = c("D","C","B","A"),
  TX_RESP_Q23g = c("D","C","B","A"), TX_RESP_Q23h = c("D","C","B","A"),
  TX_RESP_Q23i = c("D","C","B","A"),
  
  TX_RESP_Q19 = c("A","B","C"),
  TX_RESP_Q20 = c("A","B","C")
)

NOMINAIS_SAEB <- list(
  TX_RESP_Q01 = list(
    prefix = "Q01",
    mapping = c("A" = "masculino", "B" = "feminino")
  ),
  TX_RESP_Q04 = list(
    prefix = "Q04",
    mapping = c("A" = "Branca", "B" = "Preta", "C" = "Parda", 
                "D" = "Amarela", "E" = "Indigena")
  )
)

CONTINUAS_SAEB <- c("INSE_ALUNO", "NU_TIPO_NIVEL_INSE")

# ========== ATALHOS
ordinais      <- ORDINAIS_SAEB
nominais_info <- NOMINAIS_SAEB
continuas     <- CONTINUAS_SAEB

# =========================================================================
# CONFIGURAÇÃO — ajuste estes caminhos antes de executar
# =========================================================================
arquivo_entrada        <- file.path(DIR_MICRODADOS, "TS_ALUNO_34EM_escola_61466120.csv")
arquivo_saida_geral    <- file.path(DIR_SAIDA_RAIZ, "dados_escola_limpos.csv")
dir_saida_por_escola   <- DIR_SAIDA_POR_ESCOLA
sobrescrever_por_escola <- FALSE

# Valores tratados como NA nas colunas TX_RESP_Q*
VALORES_NA <- c("*", ".", " ", "F")

# Colunas de proficiência
nota_MT <- "PROFICIENCIA_MT_SAEB"
nota_LP <- "PROFICIENCIA_LP_SAEB"

# =========================================================================
# Validações iniciais
# =========================================================================
if (!file.exists(arquivo_entrada)) {
  stop("Arquivo de entrada nao encontrado: ", arquivo_entrada)
}

message("================================")
message("Iniciando limpeza de dados...")
message("================================")

# =========================================================================
# 1. Leitura
# =========================================================================
message("\n[1/6] Lendo arquivo de entrada...")
df <- data.table::fread(
  arquivo_entrada,
  integer64 = 'character',
  stringsAsFactors = FALSE
)

if (!"ID_ESCOLA" %in% names(df)) {
  stop("A coluna ID_ESCOLA nao foi encontrada na base de entrada.")
}

message("  ✓ Registros lidos: ", nrow(df))
message("  ✓ Colunas: ", ncol(df))

# =========================================================================
# 2. Garante que notas são numéricas
# =========================================================================
message("\n[2/6] Convertendo notas para numéricas...")
if (nota_MT %in% names(df)) {
  df[[nota_MT]] <- as.numeric(df[[nota_MT]])
  message("  ✓ ", nota_MT)
}
if (nota_LP %in% names(df)) {
  df[[nota_LP]] <- as.numeric(df[[nota_LP]])
  message("  ✓ ", nota_LP)
}

# =========================================================================
# 3. Helper: substitui nulos/brancos por NA
# =========================================================================
limpa <- function(x) { 
  x[x %in% VALORES_NA] <- NA
  x 
}

# =========================================================================
# 4. Processa ORDINAIS — respeita ordem + Spearman
# =========================================================================
message("\n[3/6] Processando variáveis ordinais...")
ordinais_processadas <- 0
for (col in names(ordinais)) {
  if (col %in% names(df)) {
    v <- limpa(df[[col]])
    df[[paste0(col, "_num")]] <- as.integer(
      factor(v, levels = ordinais[[col]], ordered = TRUE)
    )
    ordinais_processadas <- ordinais_processadas + 1
  }
}
message("  ✓ ", ordinais_processadas, " variáveis ordinais processadas")

# =========================================================================
# 5. Processa NOMINAIS — cria dummies
# =========================================================================
message("\n[4/6] Processando variáveis nominais...")
nominais_processadas <- 0
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
    nominais_processadas <- nominais_processadas + 1
  }
}
message("  ✓ ", nominais_processadas, " variáveis nominais processadas")

# =========================================================================
# 6. Garante que contínuas são numéricas
# =========================================================================
message("\n[5/6] Processando variáveis contínuas...")
continuas_processadas <- 0
for (col in continuas) {
  if (col %in% names(df)) {
    df[[col]] <- as.numeric(df[[col]])
    continuas_processadas <- continuas_processadas + 1
  }
}
message("  ✓ ", continuas_processadas, " variáveis contínuas processadas")

# =========================================================================
# RELATÓRIO DE MISSINGS (Dados Ausentes)
# =========================================================================
message("\n[6/6] Gerando relatório de dados ausentes...")

cols_questoes <- names(df)[grep("^TX_RESP_Q", names(df))]

na_stats <- data.frame(
  Variavel = cols_questoes,
  N_Total = nrow(df),
  N_NA = sapply(cols_questoes, function(x) sum(is.na(df[[x]]))),
  Pct_NA = round(100 * sapply(cols_questoes, function(x) sum(is.na(df[[x]]))) / nrow(df), 2),
  stringsAsFactors = FALSE
)

na_stats <- na_stats[order(na_stats$Pct_NA, decreasing = TRUE), ]
rownames(na_stats) <- NULL

message("\n=== RESUMO DE DADOS AUSENTES ===")
message("Variáveis com > 5% de missings:")
print(na_stats[na_stats$Pct_NA > 5, ])

# =========================================================================
# 7. Salvar arquivo geral
# =========================================================================
dir.create(dirname(arquivo_saida_geral), showWarnings = FALSE, recursive = TRUE)
write.csv(as.data.frame(df), arquivo_saida_geral, row.names = FALSE)
message("\n✓ Arquivo geral salvo em: ", arquivo_saida_geral)

# =========================================================================
# 8. Salvar relatório de missings
# =========================================================================
dir.create(dir_saida_por_escola, showWarnings = FALSE, recursive = TRUE)
caminho_missings_geral <- file.path(dir_saida_por_escola, "resumo_missings.csv")
write.csv(na_stats, caminho_missings_geral, row.names = FALSE)
message("✓ Relatório de missings salvo em: ", caminho_missings_geral)

# =========================================================================
# 9. Salvar uma cópia filtrada por escola
# =========================================================================
message("\nSalvando dados por escola...")
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
  message("  ✓ Escola ", id_escola, ": ", nrow(dados_uma_escola), " registros salvos")
}

message("\n================================")
message("✓ LIMPEZA CONCLUÍDA COM SUCESSO!")
message("================================")
message("Arquivos por escola salvos em: ", dir_saida_por_escola)
