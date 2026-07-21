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

# =========================================================================
# TEMA VISUAL CENTRALIZADO — Para todos os gráficos do projeto
# =========================================================================
# Uso: tema_saeb() + labs(title = "Figura X — ...")
# Requisitos: library(ggplot2) antes de source()

tema_saeb <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold", size = base_size + 3,
                                                colour = "#1A1A1A", margin = ggplot2::margin(b = 4)),
      plot.subtitle    = ggplot2::element_text(size = base_size, colour = "#555555",
                                                margin = ggplot2::margin(b = 10)),
      plot.caption     = ggplot2::element_text(size = base_size - 2, colour = "#777777",
                                                face = "italic", hjust = 0,
                                                margin = ggplot2::margin(t = 10)),
      plot.background  = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.grid.major = ggplot2::element_line(colour = "#E8E8E8", linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      plot.margin      = ggplot2::margin(16, 20, 12, 16),
      axis.title       = ggplot2::element_text(size = base_size, face = "bold", colour = "#333333"),
      axis.text        = ggplot2::element_text(size = base_size - 1, colour = "#444444"),
      strip.text       = ggplot2::element_text(size = base_size, face = "bold", colour = "#1A1A1A"),
      legend.title     = ggplot2::element_text(size = base_size - 1, face = "bold"),
      legend.text      = ggplot2::element_text(size = base_size - 1)
    )
}

# -------------------------------------------------------------------------
# Paletas de cores padronizadas
# -------------------------------------------------------------------------
PALETA_PUBLICA_PRIVADA <- c("Pública" = "#2E86AB", "Privada" = "#A23B72")
PALETA_URBANA_RURAL    <- c("Urbana" = "#06A77D", "Rural" = "#D5622B")
PALETA_CAPITAL_INTERIOR <- c("Capital" = "#4A90E2", "Interior" = "#F5A623")
PALETA_INSE            <- c("Baixo_INSE" = "#E74C3C", "Medio_INSE" = "#F39C12", "Alto_INSE" = "#27AE60")
PALETA_DISCIPLINA      <- c("Matemática" = "#1B4F9A", "Língua Portuguesa" = "#1A6B3A")

# -------------------------------------------------------------------------
# Constantes de saída
# -------------------------------------------------------------------------
DPI_PADRAO <- 600
LARGURA_PADRAO <- 12
ALTURA_PADRAO <- 7

# -------------------------------------------------------------------------
# Função auxiliar: formatar p-valor para anotação em gráficos
# -------------------------------------------------------------------------
formatar_p_annot <- function(p) {
  if (p < 0.001) return("p < 0,001")
  if (p < 0.01)  return("p < 0,01")
  if (p < 0.05)  return("p < 0,05")
  return(paste0("p = ", format(round(p, 3), nsmall = 3)))
}

# -------------------------------------------------------------------------
# Função auxiliar: interpretar tamanho de efeito (Cohen)
# -------------------------------------------------------------------------
interpretar_efeito <- function(r) {
  abs_r <- abs(r)
  if (abs_r < 0.1) return("desprezível")
  if (abs_r < 0.3) return("pequeno")
  if (abs_r < 0.5) return("moderado")
  return("grande")
}

# -------------------------------------------------------------------------
# Função auxiliar: detectar raiz do projeto automaticamente
# -------------------------------------------------------------------------
detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("✓ Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho não selecionado.")
    message("✓ Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Não foi possível detectar o caminho automaticamente.")
  }
}
