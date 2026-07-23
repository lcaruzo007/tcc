# =========================================================================
# utils_saeb.r ? Funcoes utilitarias compartilhadas entre os scripts SAEB
# =========================================================================
# Fonte: source("utils_saeb.r")  (use caminho absoluto se necessario)

# =========================================================================
# STRUCTURE DE PASTAS DATADAS
# =========================================================================
# Convencao (Refatoracao #2 - Julho 2026):
#   <modulo>/outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>
#
# Exemplo:
#   TESTE/4_REGRESSAO_LINEAR/outputs/2026-07-22/tabelas/coeficientes_MT_100906.csv
#
# As funcoes abaixo percorrem subpastas datadas quando necessario e mantem
# compatibilidade reversa com o padrao antigo de timestamp sufixo no nome.
# -------------------------------------------------------------------------

# Constante de formato de data para a subpasta
FORMATO_DATA_PASTA <- "%Y-%m-%d"

# -------------------------------------------------------------------------
# Helper: caminho de saida sob pasta datada. Constroi automaticamente
#   <DIR_BASE>/outputs/<YYYY-MM-DD>/<subpasta>/<nome>_<HHMMSS>.<ext>
# (Subpasta tipicamente: "tabelas", "figuras", "modelos", "diagnosticos")
# Cria a pasta automaticamente.
# -------------------------------------------------------------------------
caminho_saida <- function(DIR_BASE_MODULO, subpasta, nome, ext = "csv") {
  data_run <- format(Sys.Date(), FORMATO_DATA_PASTA)
  hhmmss   <- format(Sys.time(), "%H%M%S")
  pasta_out <- file.path(DIR_BASE_MODULO, "outputs", data_run, subpasta)
  dir.create(pasta_out, showWarnings = FALSE, recursive = TRUE)
  if (nzchar(ext)) {
    arquivo <- paste0(nome, "_", hhmmss, ".", ext)
  } else {
    arquivo <- paste0(nome, "_", hhmmss)
  }
  file.path(pasta_out, arquivo)
}

# -------------------------------------------------------------------------
# Encontra o arquivo mais recente correspondente a nome_base dentro de
# `pasta`. Procura primeiro em subpastas datadas (mais recente primeiro),
# depois na propria pasta (compatibilidade com o padrao antigo).
#
# Aceita arquivos com:
#   <nome_base>_<YYYYMMDD>_<HHMMSS>.<ext>      (padrao antigo)
#   <nome_base>_<HHMMSS>.<ext>                   (padrao novo, pasta datada)
#   <nome_base>.<ext>                            (sem timestamp)
# -------------------------------------------------------------------------
encontrar_arquivo_mais_recente <- function(pasta, nome_base, tipo = NULL) {
  candidatos <- c()

  # 1) Procurar em subpastas datadas (YYYY-MM-DD)
  if (dir.exists(pasta)) {
    subpastas <- list.dirs(pasta, full.names = TRUE, recursive = TRUE)
    # Filtra apenas subpastas que terminam em YYYY-MM-DD (eventualmente aninhadas)
    datas <- grep("[0-9]{4}-[0-9]{2}-[0-9]{2}$", basename(subpastas), value = TRUE)
    pasta_datas <- subpastas[basename(subpastas) %in% datas]
    if (length(pasta_datas) > 0L) {
      # Se tipo especificado, concatena com subpasta do tipo
      if (!is.null(tipo)) {
        pasta_datas <- file.path(pasta_datas, tipo)
        pasta_datas <- pasta_datas[dir.exists(pasta_datas)]
      }
      padrao <- paste0("^", nome_base, "(_[0-9]{6}(_[0-9]+)?)?\\.[Cc][Ss][Vv]$")
      arqs <- unlist(lapply(pasta_datas, function(p) {
        list.files(p, pattern = padrao, full.names = TRUE)
      }))
      candidatos <- c(candidatos, arqs)
    }
  }

  # 2) Compatibilidade: pasta direta (padrao antigo de sufixo)
  padrao_antigo <- paste0("^", nome_base, "(_[0-9]{8}_[0-9]{6}(_[0-9]+)?)?\\.[Cc][Ss][Vv]$")
  arqs_antigos <- list.files(pasta, pattern = padrao_antigo, full.names = TRUE)
  candidatos <- c(candidatos, arqs_antigos)

  if (length(candidatos) == 0L) return(NULL)

  # Critério de "mais recente": mtime do arquivo OU, se empate, lexico do path
  info <- file.info(candidatos)
  candidatos[which.max(info$mtime)]
}

# -------------------------------------------------------------------------
# Verifica se existe ao menos um arquivo com o padrao de nome_base
# (mantém compatibilidade com sufixo timestamp antigo).
# -------------------------------------------------------------------------
arquivo_com_versao_existe <- function(pasta, nome_base, tipo = NULL) {
  !is.null(encontrar_arquivo_mais_recente(pasta, nome_base, tipo))
}

# -------------------------------------------------------------------------
# Mantido por compatibilidade: gera caminho sem sobrescrever.
# Em geral, scripts novos devem usar caminho_saida() (com pasta datada).
# Esta funcao antiga continua disponivel para scripts que ainda nao foram
# migrados ou para casos excepcionais onde a pasta datada nao se aplica.
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
# DICIONARIOS CENTRALIZADOS DE VARIAVEIS
# Usados em ajeitar_dados.r e correlacao.r para evitar duplicacao
# =========================================================================

# -------------------------------------------------------------------------
# ORDINAIS_SAEB: Variaveis com ordem explicita
# Mapeia cada variavel para seu vetor de niveis ordenados
# -------------------------------------------------------------------------
ORDINAIS_SAEB <- list(
  # Q10 ? frequencia pais: Nunca(A) < De vez em quando(B) < Sempre(C)
  TX_RESP_Q10a = c("A","B","C"), TX_RESP_Q10b = c("A","B","C"),
  TX_RESP_Q10c = c("A","B","C"), TX_RESP_Q10d = c("A","B","C"),
  TX_RESP_Q10e = c("A","B","C"), TX_RESP_Q10f = c("A","B","C"),

  # Q21 ? tempo fora da escola: Nao uso(A) < <1h(B) < 1-2h(C) < >2h(D)
  TX_RESP_Q21a = c("A","B","C","D"), TX_RESP_Q21b = c("A","B","C","D"),
  TX_RESP_Q21c = c("A","B","C","D"), TX_RESP_Q21d = c("A","B","C","D"),
  TX_RESP_Q21e = c("A","B","C","D"),

  # Q22 ? proporcao professores: Todos(A) > Maioria(B) > Poucos(C) > Nenhum(D)
  # invertido: Nenhum=1, Poucos=2, Maioria=3, Todos=4
  TX_RESP_Q22a = c("D","C","B","A"), TX_RESP_Q22b = c("D","C","B","A"),
  TX_RESP_Q22c = c("D","C","B","A"), TX_RESP_Q22d = c("D","C","B","A"),
  TX_RESP_Q22e = c("D","C","B","A"), TX_RESP_Q22f = c("D","C","B","A"),
  TX_RESP_Q22g = c("D","C","B","A"), TX_RESP_Q22h = c("D","C","B","A"),

  # Q23 ? concordancia: Discordo totalmente(D)=1 ... Concordo totalmente(A)=4
  TX_RESP_Q23a = c("D","C","B","A"), TX_RESP_Q23b = c("D","C","B","A"),
  TX_RESP_Q23c = c("D","C","B","A"), TX_RESP_Q23d = c("D","C","B","A"),
  TX_RESP_Q23e = c("D","C","B","A"), TX_RESP_Q23f = c("D","C","B","A"),
  TX_RESP_Q23g = c("D","C","B","A"), TX_RESP_Q23h = c("D","C","B","A"),
  TX_RESP_Q23i = c("D","C","B","A"),

  # Q19 ? reprovacao: Nao(A)=1, 1x(B)=2, 2x+(C)=3
  TX_RESP_Q19 = c("A","B","C"),

  # Q20 ? abandono: Nunca(A)=1, 1x(B)=2, 2x+(C)=3
  TX_RESP_Q20 = c("A","B","C")
)

# -------------------------------------------------------------------------
# NOMINAIS_SAEB: Variaveis categoricas sem ordem (convertem para dummies)
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
# CONTINUAS_SAEB: Variaveis numericas continuas (sem transformacao)
# -------------------------------------------------------------------------
CONTINUAS_SAEB <- c("INSE_ALUNO", "NU_TIPO_NIVEL_INSE")

# -------------------------------------------------------------------------
# CONFIGURACAO COMPARTILHADA: Parametros globais dos filtros
# -------------------------------------------------------------------------
# Limiar de correlacao minima (Cohen 1988: 0.30 = efeito pequeno a moderado)
LIMIAR_COR_PADRAO <- 0.30

# Metodo de deteccao de degeneracao:
#   "zero_variancia" - remove apenas colunas sem variacao (var = 0)
#   "near_zero"      - aplica somente nearZeroVar
#   "hibrido"        - zero_variancia + nearZeroVar (quando n >= min_linhas)
METODO_DEGENERACAO_PADRAO <- "zero_variancia"

# Minimo de linhas para aplicar nearZeroVar (evita falsos positivos com n pequeno)
MIN_LINHAS_NEAR_ZERO <- 30L

# Parametros do caret::nearZeroVar (se aplicavel)
FREQ_CUT_NZV <- 19      # razao freq(1a)/freq(2a); 19 ? padrao 95/5
UNIQUE_CUT_NZV <- 10    # % minima de valores unicos

# =========================================================================
# TEMA VISUAL CENTRALIZADO ? Para todos os graficos do projeto
# =========================================================================
# Uso: tema_saeb() + labs(title = "Figura X ? ...")
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
PALETA_PUBLICA_PRIVADA <- c("Publica" = "#2E86AB", "Privada" = "#A23B72")
PALETA_URBANA_RURAL    <- c("Urbana" = "#06A77D", "Rural" = "#D5622B")
PALETA_CAPITAL_INTERIOR <- c("Capital" = "#4A90E2", "Interior" = "#F5A623")
PALETA_INSE            <- c("Baixo_INSE" = "#E74C3C", "Medio_INSE" = "#F39C12", "Alto_INSE" = "#27AE60")
PALETA_DISCIPLINA      <- c("Matematica" = "#1B4F9A", "Lingua Portuguesa" = "#1A6B3A")

# -------------------------------------------------------------------------
# Constantes de saida
# -------------------------------------------------------------------------
DPI_PADRAO <- 600
LARGURA_PADRAO <- 12
ALTURA_PADRAO <- 7

# -------------------------------------------------------------------------
# Funcao auxiliar: formatar p-valor para anotacao em graficos
# -------------------------------------------------------------------------
formatar_p_annot <- function(p) {
  if (p < 0.001) return("p < 0,001")
  if (p < 0.01)  return("p < 0,01")
  if (p < 0.05)  return("p < 0,05")
  return(paste0("p = ", format(round(p, 3), nsmall = 3)))
}

# -------------------------------------------------------------------------
# Funcao auxiliar: interpretar tamanho de efeito (Cohen)
# -------------------------------------------------------------------------
interpretar_efeito <- function(r) {
  abs_r <- abs(r)
  if (abs_r < 0.1) return("desprezivel")
  if (abs_r < 0.3) return("pequeno")
  if (abs_r < 0.5) return("moderado")
  return("grande")
}

# -------------------------------------------------------------------------
# Funcao auxiliar: detectar raiz do projeto automaticamente
# -------------------------------------------------------------------------
detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("? Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho nao selecionado.")
    message("? Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Nao foi possivel detectar o caminho automaticamente.")
  }
}
