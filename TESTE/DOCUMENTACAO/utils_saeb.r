# =========================================================================
# utils_saeb.r — Funções utilitárias compartilhadas entre os scripts SAEB
# =========================================================================
# Fonte: source("utils_saeb.r")  (use caminho absoluto se necessário)

# -------------------------------------------------------------------------
# Retorna o arquivo mais recente que corresponde a nome_base (com ou sem
# sufixo de timestamp) dentro de `pasta`.
# -------------------------------------------------------------------------
encontrar_arquivo_mais_recente <- function(pasta, nome_base) {
  padrao <- paste0("^", nome_base, "(_[0-9]{8}_[0-9]{6}(_[0-9]+)?)?\\.csv$")
  arquivos <- list.files(pasta, pattern = padrao, full.names = TRUE)

  if (length(arquivos) == 0L) return(NULL)

  arquivos[which.max(file.info(arquivos)$mtime)]
}

# -------------------------------------------------------------------------
# Verifica se já existe ao menos um arquivo com o padrão de nome_base.
# -------------------------------------------------------------------------
arquivo_com_versao_existe <- function(pasta, nome_base) {
  padrao <- paste0("^", nome_base, "(_[0-9]{8}_[0-9]{6}(_[0-9]+)?)?\\.csv$")
  length(list.files(pasta, pattern = padrao)) > 0L
}

# -------------------------------------------------------------------------
# Gera caminho de saída sem sobrescrever arquivos já existentes.
# Quando sobrescrever = FALSE, acrescenta timestamp (e contador se necessário).
# -------------------------------------------------------------------------
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

# =========================================================================
# DICIONÁRIOS CENTRALIZADOS DE VARIÁVEIS
# Usados em ajeitar_dados.r e correlacao.r para evitar duplicação
# =========================================================================

# -------------------------------------------------------------------------
# ORDINAIS_SAEB: Variáveis com ordem explícita
# Mapeia cada variável para seu vetor de níveis ordenados
# -------------------------------------------------------------------------
ORDINAIS_SAEB <- list(
  # Q10 — frequência pais: Nunca(A) < De vez em quando(B) < Sempre(C)
  TX_RESP_Q10a = c("A","B","C"), TX_RESP_Q10b = c("A","B","C"),
  TX_RESP_Q10c = c("A","B","C"), TX_RESP_Q10d = c("A","B","C"),
  TX_RESP_Q10e = c("A","B","C"), TX_RESP_Q10f = c("A","B","C"),

  # Q21 — tempo fora da escola: Não uso(A) < <1h(B) < 1-2h(C) < >2h(D)
  TX_RESP_Q21a = c("A","B","C","D"), TX_RESP_Q21b = c("A","B","C","D"),
  TX_RESP_Q21c = c("A","B","C","D"), TX_RESP_Q21d = c("A","B","C","D"),
  TX_RESP_Q21e = c("A","B","C","D"),

  # Q22 — proporção professores: Todos(A) > Maioria(B) > Poucos(C) > Nenhum(D)
  # invertido: Nenhum=1, Poucos=2, Maioria=3, Todos=4
  TX_RESP_Q22a = c("D","C","B","A"), TX_RESP_Q22b = c("D","C","B","A"),
  TX_RESP_Q22c = c("D","C","B","A"), TX_RESP_Q22d = c("D","C","B","A"),
  TX_RESP_Q22e = c("D","C","B","A"), TX_RESP_Q22f = c("D","C","B","A"),
  TX_RESP_Q22g = c("D","C","B","A"), TX_RESP_Q22h = c("D","C","B","A"),

  # Q23 — concordância: Discordo totalmente(D)=1 ... Concordo totalmente(A)=4
  TX_RESP_Q23a = c("D","C","B","A"), TX_RESP_Q23b = c("D","C","B","A"),
  TX_RESP_Q23c = c("D","C","B","A"), TX_RESP_Q23d = c("D","C","B","A"),
  TX_RESP_Q23e = c("D","C","B","A"), TX_RESP_Q23f = c("D","C","B","A"),
  TX_RESP_Q23g = c("D","C","B","A"), TX_RESP_Q23h = c("D","C","B","A"),
  TX_RESP_Q23i = c("D","C","B","A"),

  # Q19 — reprovação: Não(A)=1, 1x(B)=2, 2x+(C)=3
  TX_RESP_Q19 = c("A","B","C"),

  # Q20 — abandono: Nunca(A)=1, 1x(B)=2, 2x+(C)=3
  TX_RESP_Q20 = c("A","B","C")
)

# -------------------------------------------------------------------------
# NOMINAIS_SAEB: Variáveis categóricas sem ordem (convertem para dummies)
# Estrutura: list(nome_col = list(prefix = "Qnn", mapping = c(cod = label)))
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# CONTINUAS_SAEB: Variáveis numéricas contínuas (sem transformação)
# -------------------------------------------------------------------------
CONTINUAS_SAEB <- c("INSE_ALUNO", "NU_TIPO_NIVEL_INSE")

# -------------------------------------------------------------------------
# CONFIGURAÇÃO COMPARTILHADA: Parâmetros globais dos filtros
# -------------------------------------------------------------------------
# Limiar de correlação mínima (Cohen 1988: 0.30 = efeito pequeno a moderado)
LIMIAR_COR_PADRAO <- 0.30

# Método de detecção de degeneração:
#   "zero_variancia" - remove apenas colunas sem variação (var = 0)
#   "near_zero"      - aplica somente nearZeroVar
#   "hibrido"        - zero_variancia + nearZeroVar (quando n >= min_linhas)
METODO_DEGENERACAO_PADRAO <- "zero_variancia"

# Mínimo de linhas para aplicar nearZeroVar (evita falsos positivos com n pequeno)
MIN_LINHAS_NEAR_ZERO <- 30L

# Parâmetros do caret::nearZeroVar (se aplicável)
FREQ_CUT_NZV <- 19      # razão freq(1a)/freq(2a); 19 ≈ padrão 95/5
UNIQUE_CUT_NZV <- 10    # % mínima de valores únicos
