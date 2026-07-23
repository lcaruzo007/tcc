################################################################################
# SCRIPT: classificar_escolas.r
# 
# OBJETIVO: Agregar dados por escola e criar metadados com classificacoes
#           (tipo escola, localizacao, area, faixa de nota)
#
# ENTRADA: Dados limpos (dados_escola_em_numeros.csv por escola)
#          + TS_ESCOLA.csv (metadados das escolas)
#          + TS_ALUNO.csv (notas dos alunos)
#
# SAIDA: metadados_escolas_YYYYMMDD_HHMMSS.csv
#        (um arquivo unico para alimentar comparacoes e dendrogramas)
#
# VERSAO: 1.0 - Maio 2026
################################################################################

# ============================================================================
# PASSO 0: CARREGAR PACOTES E DEFINIR CAMINHOS (DETECCAO AUTOMATICA)
# ============================================================================

library(tidyverse)
library(data.table)

# Detectar raiz automaticamente
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
DIR_MICRODADOS <- file.path(RAIZ, "MICRODADOS_SAEB_2023/DADOS")
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_SAIDA <- file.path(DIR_TESTE, "1_LIMPEZA_E_TRANSFORMACAO/outputs")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_PROCESSADOS <- file.path(DIR_ANALISE, "outputs/metadados")

# Criar diretorio de saida se nao existir
if (!dir.exists(DIR_PROCESSADOS)) {
  dir.create(DIR_PROCESSADOS, showWarnings = FALSE, recursive = TRUE)
}

# Timestamp para versionamento
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

# ============================================================================
# PASSO 1: CARREGAR DADOS BRUTOS DAS ESCOLAS
# ============================================================================

cat(">>> Carregando dados dos alunos...\n")

# Alunos (dados brutos com informacoes das escolas)
alunos <- fread(file.path(DIR_MICRODADOS, "TS_ALUNO_34EM.csv"),
                 encoding = "Latin-1") %>%
  as_tibble()

# Selecionar apenas colunas necessarias dos alunos
alunos <- alunos %>%
  select(
    ID_ESCOLA,
    ID_AREA,          # 1 = Capital, 2 = Interior
    ID_LOCALIZACAO,   # 1 = Urbana, 2 = Rural
    IN_PUBLICA,       # 1 = Publico, 0 = Privado
    PROFICIENCIA_MT_SAEB,
    PROFICIENCIA_LP_SAEB,
    INSE_ALUNO,
    NU_TIPO_NIVEL_INSE
  )


# ============================================================================
# PASSO 2: AGREGAR PROFICIENCIA E INSE POR ESCOLA
# ============================================================================

cat("\n>>> Agregando dados por escola...\n")

agregados <- alunos %>%
  group_by(ID_ESCOLA) %>%
  summarise(

    MEDIA_MT = mean(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    MEDIA_LP = mean(PROFICIENCIA_LP_SAEB, na.rm = TRUE),

    INSE_MEDIO = mean(INSE_ALUNO, na.rm = TRUE),

    NIVEL_INSE_MODAL =
      as.numeric(names(sort(table(NU_TIPO_NIVEL_INSE),
                            decreasing=TRUE)[1])),

    TIPO_ESCOLA_MODAL =
      as.numeric(names(sort(table(IN_PUBLICA),
                            decreasing=TRUE)[1])),

    ID_AREA_MODAL =
      as.numeric(names(sort(table(ID_AREA),
                            decreasing=TRUE)[1])),

    ID_LOCALIZACAO_MODAL =
      as.numeric(names(sort(table(ID_LOCALIZACAO),
                            decreasing=TRUE)[1])),

    N_ALUNOS = n(),
    N_ALUNOS_MT_VALIDOS = sum(!is.na(PROFICIENCIA_MT_SAEB)),
    N_ALUNOS_LP_VALIDOS = sum(!is.na(PROFICIENCIA_LP_SAEB)),

    .groups="drop"
  )
cat("   OK Agregacao completa\n")
cat(sprintf("   ? Escolas com dados: %d\n", nrow(agregados)))

# ============================================================================
# PASSO 3: CALCULAR QUARTIS (faixas de desempenho)
# ============================================================================

cat("\n>>> Calculando quartis de desempenho...\n")

# Quartis de Matematica
Q_MT <- quantile(agregados$MEDIA_MT, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
Q_LP <- quantile(agregados$MEDIA_LP, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)

cat(sprintf("   Quartis MT: Q1=%.1f | Q2=%.1f | Q3=%.1f\n", 
            Q_MT[1], Q_MT[2], Q_MT[3]))
cat(sprintf("   Quartis LP: Q1=%.1f | Q2=%.1f | Q3=%.1f\n", 
            Q_LP[1], Q_LP[2], Q_LP[3]))

# Classificar em quartis
agregados <- agregados %>%
  mutate(
    FAIXA_MT = case_when(
      MEDIA_MT < Q_MT[1] ~ "Q1_Baixo",
      MEDIA_MT < Q_MT[2] ~ "Q2_Medio-Baixo",
      MEDIA_MT < Q_MT[3] ~ "Q3_Medio-Alto",
      TRUE ~ "Q4_Alto"
    ),
    FAIXA_LP = case_when(
      MEDIA_LP < Q_LP[1] ~ "Q1_Baixo",
      MEDIA_LP < Q_LP[2] ~ "Q2_Medio-Baixo",
      MEDIA_LP < Q_LP[3] ~ "Q3_Medio-Alto",
      TRUE ~ "Q4_Alto"
    )
  )

# ============================================================================
# PASSO 4: JUNTAR COM METADADOS DAS ESCOLAS
# ============================================================================

cat("\n>>> Juntando com informacoes das escolas...\n")
metadados <- agregados

# ============================================================================
# PASSO 5: CRIAR VARIAVEIS DE CLASSIFICACAO
# ============================================================================

cat("\n>>> Criando variaveis de classificacao...\n")

# Classificar area (capital vs interior)
area_map <- tribble(
  ~ID_AREA, ~AREA,
  1, "Capital",
  2, "Interior"
)

# Classificar localizacao (urbana vs rural)
localizacao_map <- tribble(
  ~ID_LOCALIZACAO, ~LOCALIZACAO,
  1, "Urbana",
  2, "Rural"
)

# Aplicar mapeamentos
metadados <- metadados %>%
  left_join(area_map,
          by=c("ID_AREA_MODAL"="ID_AREA")) %>%
left_join(localizacao_map,
          by=c("ID_LOCALIZACAO_MODAL"="ID_LOCALIZACAO")) %>%
  # Criar variavel de grupo (publica vs privada)
  mutate(
    TIPO_ESCOLA = if_else(TIPO_ESCOLA_MODAL == 1,
                      "Publica",
                      "Privada"),

    # INSE categorizado
    GRUPO_INSE = case_when(
      INSE_MEDIO < quantile(INSE_MEDIO, 0.33, na.rm = TRUE) ~ "Baixo_INSE",
      INSE_MEDIO < quantile(INSE_MEDIO, 0.67, na.rm = TRUE) ~ "Medio_INSE",
      TRUE ~ "Alto_INSE"
    ),

    # Variavel combinada AREA x LOCALIZACAO (4 categorias)
    # Usada como preditor unico nos modelos de regressao (substitui AREA e
    # LOCALIZACAO separados), permitindo capturar interacoes como
    # "escolas rurais do interior" vs. "urbanas da capital".
    AREA_LOCAL = paste0(LOCALIZACAO, "_", AREA)
  ) %>%
  select(
    ID_ESCOLA,
    TIPO_ESCOLA,
    AREA,
    LOCALIZACAO,
    AREA_LOCAL,
    MEDIA_MT,
    MEDIA_LP,
    FAIXA_MT,
    FAIXA_LP,
    INSE_MEDIO,
    GRUPO_INSE,
    NIVEL_INSE_MODAL,
    N_ALUNOS,
    N_ALUNOS_MT_VALIDOS,
    N_ALUNOS_LP_VALIDOS
  ) %>%
  arrange(desc(MEDIA_MT))

cat("   OK Classificacoes criadas\n")
cat(sprintf("   ? Publica: %d | Privada: %d\n",
            sum(metadados$TIPO_ESCOLA == "Publica"),
            sum(metadados$TIPO_ESCOLA == "Privada")))
cat(sprintf("   ? Urbana: %d | Rural: %d\n",
            sum(metadados$LOCALIZACAO == "Urbana"),
            sum(metadados$LOCALIZACAO == "Rural")))
cat(sprintf("   ? Capital: %d | Interior: %d\n",
            sum(metadados$AREA == "Capital"),
            sum(metadados$AREA == "Interior")))
cat("   ? Distribuicao AREA_LOCAL (4 categorias):\n")
print(table(metadados$AREA_LOCAL))

# ============================================================================
# PASSO 6: EXPORTAR METADADOS
# ============================================================================

cat("\n>>> Exportando metadados...\n")

nome_saida <- file.path(DIR_PROCESSADOS, 
                         paste0("metadados_escolas_", timestamp, ".csv"))

write_csv(metadados, nome_saida)

cat(sprintf("   OK Arquivo salvo: metadados_escolas_%s.csv\n", timestamp))
cat(sprintf("   ? Caminh: %s\n", nome_saida))
cat(sprintf("   ? Linhas: %d (escolas) | Colunas: %d\n", 
            nrow(metadados), ncol(metadados)))

cat("\n? Script finalizado com sucesso!\n")


