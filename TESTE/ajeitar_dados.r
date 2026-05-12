# =========================================================================
# PASSO 1: LIMPEZA E TRANSFORMAÇÃO DOS DADOS SAEB
# =========================================================================

# Resolve caminhos para garantir que a saida fique dentro de TESTE.
resolver_base_dir <- function(nome_script) {
  cwd <- getwd()
  if (file.exists(file.path(cwd, nome_script))) return(cwd)
  if (file.exists(file.path(cwd, "TESTE", nome_script))) return(file.path(cwd, "TESTE"))

  args <- commandArgs(trailingOnly = FALSE)
  arg_file <- grep("^--file=", args, value = TRUE)
  if (length(arg_file) > 0L) {
    script_path <- sub("^--file=", "", arg_file[1])
    return(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE)))
  }

  cwd
}

base_dir <- resolver_base_dir("ajeitar_dados.r")

source(file.path(base_dir, "utils_saeb.r"))   # gerar_caminho_sem_sobrescrever

# -------------------------------------------------------------------------
# Configuração — ajuste estes caminhos antes de executar
# -------------------------------------------------------------------------
arquivo_entrada        <- file.path(base_dir, "..", "MICRODADOS_SAEB_2023", "DADOS", "TS_ALUNO_34EM_escola_61425355.csv")
arquivo_saida_geral    <- file.path(base_dir, "dados_escola_limpos.csv")
dir_saida_por_escola   <- file.path(base_dir, "dados_por_escola")
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

limpar_respostas_q <- function(df) {
  colunas_q <- grep("^TX_RESP_Q", names(df), value = TRUE)
  for (coluna in colunas_q) {
    x <- df[[coluna]]
    for (valor_na in VALORES_NA) {
      x <- ifelse(x == valor_na, NA, x)
    }
    df[[coluna]] <- as.numeric(as.factor(x))
  }
  df
}

# -------------------------------------------------------------------------
# 2. Limpeza e transformação das respostas do questionário
# -------------------------------------------------------------------------
dados_escola_limpos <- limpar_respostas_q(dados_escola)

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
pasta_saida_por_escola <- file.path(base_dir, "dados_por_escola")
dir.create(pasta_saida_por_escola, showWarnings = FALSE, recursive = TRUE)
if (!dir.exists(pasta_saida_por_escola)) {
  stop("Nao foi possivel criar a pasta de saida: ", pasta_saida_por_escola)
}

if (!exists("dados_escola_limpos")) {
  message("dados_escola_limpos nao encontrado; recalculando a limpeza a partir da entrada.")
  dados_escola <- read.csv(arquivo_entrada, stringsAsFactors = FALSE)
  dados_escola_limpos <- limpar_respostas_q(dados_escola)
}

ids_escola <- sort(unique(dados_escola_limpos$ID_ESCOLA))
ids_escola <- ids_escola[!is.na(ids_escola)]

message("Escolas encontradas: ", length(ids_escola))

for (id_escola in ids_escola) {
  pasta_escola <- file.path(pasta_saida_por_escola, as.character(id_escola))
  dir.create(pasta_escola, showWarnings = FALSE, recursive = TRUE)

  dados_uma_escola <- dados_escola_limpos[dados_escola_limpos$ID_ESCOLA == id_escola, , drop = FALSE]

  arquivo_saida <- gerar_caminho_sem_sobrescrever(
    file.path(pasta_escola, "dados_escola_em_numeros.csv"),
    sobrescrever = sobrescrever_por_escola
  )

  write.csv(dados_uma_escola, arquivo_saida, row.names = FALSE)
}

message("Limpeza concluida. Arquivos por escola salvos em: ", pasta_saida_por_escola)
