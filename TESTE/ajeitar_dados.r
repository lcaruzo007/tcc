# =========================================================================
# PASSO 1: LIMPEZA E TRANSFORMAÇÃO DOS DADOS SAEB
# =========================================================================

library(tidyverse)
source("utils_saeb.r")   # gerar_caminho_sem_sobrescrever

# -------------------------------------------------------------------------
# Configuração — ajuste estes caminhos antes de executar
# -------------------------------------------------------------------------
arquivo_entrada        <- "C:/Users/Usuario/Desktop/tcc/MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM_escola_61432986.csv"
arquivo_saida_geral    <- "C:/Users/Usuario/Desktop/tcc/TESTE/dados_escola_limpos.csv"
dir_saida_por_escola   <- "C:/Users/Usuario/Desktop/tcc/TESTE/dados_por_escola"
sobrescrever_por_escola <- FALSE

# Valores tratados como NA nas colunas TX_RESP_Q*
VALORES_NA <- c(".", "*", " ", "F")

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
dados_escola <- read.csv(arquivo_entrada, stringsAsFactors = FALSE)

if (!"ID_ESCOLA" %in% names(dados_escola)) {
  stop("A coluna ID_ESCOLA nao foi encontrada na base de entrada.")
}

message("Registros lidos: ", nrow(dados_escola))

# -------------------------------------------------------------------------
# 2. Limpeza e transformação das respostas do questionário
# -------------------------------------------------------------------------
dados_escola_limpos <- dados_escola |>
  mutate(across(
    starts_with("TX_RESP_Q"),
    ~ as.numeric(as.factor(na_if(na_if(na_if(na_if(., VALORES_NA[1]),
                                              VALORES_NA[2]),
                                        VALORES_NA[3]),
                                  VALORES_NA[4])))
  ))

# Alternativa mais legível para o passo acima (usa reduce para encadear na_if):
# dados_escola_limpos <- dados_escola |>
#   mutate(across(
#     starts_with("TX_RESP_Q"),
#     ~ {
#       x <- .x
#       for (v in VALORES_NA) x <- na_if(x, v)
#       as.numeric(as.factor(x))
#     }
#   ))

# -------------------------------------------------------------------------
# 3. Salvar arquivo geral (usado pelo script de correlação)
# -------------------------------------------------------------------------
dir.create(dirname(arquivo_saida_geral), showWarnings = FALSE, recursive = TRUE)
write.csv(dados_escola_limpos, arquivo_saida_geral, row.names = FALSE)
message("Arquivo geral salvo em: ", arquivo_saida_geral)

# -------------------------------------------------------------------------
# 4. Salvar uma cópia filtrada por escola
# -------------------------------------------------------------------------
dir.create(dir_saida_por_escola, showWarnings = FALSE, recursive = TRUE)

ids_escola <- sort(unique(dados_escola_limpos$ID_ESCOLA))
ids_escola <- ids_escola[!is.na(ids_escola)]

message("Escolas encontradas: ", length(ids_escola))

for (id_escola in ids_escola) {
  pasta_escola <- file.path(dir_saida_por_escola, as.character(id_escola))
  dir.create(pasta_escola, showWarnings = FALSE, recursive = TRUE)

  dados_uma_escola <- filter(dados_escola_limpos, ID_ESCOLA == id_escola)

  arquivo_saida <- gerar_caminho_sem_sobrescrever(
    file.path(pasta_escola, "dados_escola_em_numeros.csv"),
    sobrescrever = sobrescrever_por_escola
  )

  write.csv(dados_uma_escola, arquivo_saida, row.names = FALSE)
}

message("Limpeza concluida. Arquivos por escola salvos em: ", dir_saida_por_escola)
