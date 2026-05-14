################################################################################
# SCRIPT: classificar_escolas.r
# 
# OBJETIVO: Agregar dados por escola e criar metadados com classificações
#           (tipo escola, localização, área, faixa de nota)
#
# ENTRADA: Dados limpos (dados_escola_em_numeros.csv por escola)
#          + TS_ESCOLA.csv (metadados das escolas)
#          + TS_ALUNO.csv (notas dos alunos)
#
# SAÍDA: metadados_escolas_YYYYMMDD_HHMMSS.csv
#        (um arquivo único para alimentar comparações e dendrogramas)
#
# VERSÃO: 1.0 — Maio 2026
################################################################################

# ============================================================================
# PASSO 0: CARREGAR PACOTES E DEFINIR CAMINHOS (DETECÇÃO AUTOMÁTICA)
# ============================================================================

library(tidyverse)
library(data.table)

# Detectar raiz automaticamente
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

RAIZ <- detectar_raiz()
DIR_MICRODADOS <- file.path(RAIZ, "MICRODADOS_SAEB_2023/DADOS")
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_SAIDA <- file.path(DIR_TESTE, "dados_por_escola")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_PROCESSADOS <- file.path(DIR_ANALISE, "outputs_escolas")

# Criar diretório de saída se não existir
if (!dir.exists(DIR_PROCESSADOS)) {
  dir.create(DIR_PROCESSADOS, showWarnings = FALSE, recursive = TRUE)
}

# Timestamp para versionamento
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

# ============================================================================
# PASSO 1: CARREGAR DADOS BRUTOS DAS ESCOLAS
# ============================================================================

cat(">>> Carregando dados dos alunos...\n")

# Alunos (dados brutos com informações das escolas)
alunos <- fread(file.path(DIR_MICRODADOS, "TS_ALUNO_34EM.csv"),
                 encoding = "Latin-1") %>%
  as_tibble()

# Selecionar apenas colunas necessárias dos alunos
alunos <- alunos %>%
  select(
    ID_ESCOLA,
    ID_AREA,          # 1 = Capital, 2 = Interior
    ID_LOCALIZACAO,   # 1 = Urbana, 2 = Rural
    IN_PUBLICA,       # 1 = Público, 0 = Privado
    PROFICIENCIA_MT_SAEB,
    PROFICIENCIA_LP_SAEB,
    INSE_ALUNO,
    NU_TIPO_NIVEL_INSE
  )

# Carregar escolas (apenas para pegar nome e tipo)
escolas <- fread(file.path(DIR_MICRODADOS, "TS_ESCOLA.csv"),
                  encoding = "Latin-1") %>%
  as_tibble() %>%
  select(ID_ESCOLA, IN_PUBLICA, ID_AREA, ID_LOCALIZACAO)

cat("   ✓ Dados carregados\n")
cat(sprintf("   • Escolas: %d\n", n_distinct(alunos$ID_ESCOLA)))
cat(sprintf("   • Alunos: %d\n", nrow(alunos)))

# ============================================================================
# PASSO 2: AGREGAR PROFICIÊNCIA E INSE POR ESCOLA
# ============================================================================

cat("\n>>> Agregando dados por escola...\n")

agregados <- alunos %>%
  group_by(ID_ESCOLA) %>%
  summarise(
    # Proficiência média
    MEDIA_MT = mean(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    MEDIA_LP = mean(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    
    # INSE médio
    INSE_MEDIO = mean(INSE_ALUNO, na.rm = TRUE),
    
    # Nível INSE mais frequente
    NIVEL_INSE_MODAL = as.numeric(names(sort(table(NU_TIPO_NIVEL_INSE), 
                                               decreasing = TRUE)[1]))[1],
    
    # Localização (modal — deveria ser igual pra toda a escola)
    ID_AREA_MODAL = as.numeric(names(sort(table(ID_AREA), 
                                            decreasing = TRUE)[1]))[1],
    ID_LOCALIZACAO_MODAL = as.numeric(names(sort(table(ID_LOCALIZACAO), 
                                                   decreasing = TRUE)[1]))[1],
    
    # Contagem de alunos com dados válidos
    N_ALUNOS = n(),
    N_ALUNOS_MT_VALIDOS = sum(!is.na(PROFICIENCIA_MT_SAEB)),
    N_ALUNOS_LP_VALIDOS = sum(!is.na(PROFICIENCIA_LP_SAEB)),
    
    .groups = 'drop'
  )

cat("   ✓ Agregação completa\n")
cat(sprintf("   • Escolas com dados: %d\n", nrow(agregados)))

# ============================================================================
# PASSO 3: CALCULAR QUARTIS (faixas de desempenho)
# ============================================================================

cat("\n>>> Calculando quartis de desempenho...\n")

# Quartis de Matemática
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
      MEDIA_MT < Q_MT[2] ~ "Q2_Médio-Baixo",
      MEDIA_MT < Q_MT[3] ~ "Q3_Médio-Alto",
      TRUE ~ "Q4_Alto"
    ),
    FAIXA_LP = case_when(
      MEDIA_LP < Q_LP[1] ~ "Q1_Baixo",
      MEDIA_LP < Q_LP[2] ~ "Q2_Médio-Baixo",
      MEDIA_LP < Q_LP[3] ~ "Q3_Médio-Alto",
      TRUE ~ "Q4_Alto"
    )
  )

# ============================================================================
# PASSO 4: JUNTAR COM METADADOS DAS ESCOLAS
# ============================================================================

cat("\n>>> Juntando com informações das escolas...\n")

# Join com TS_ESCOLA
metadados <- agregados %>%
  left_join(escolas, by = "ID_ESCOLA")

# Verificar se houve perda de dados
cat(sprintf("   ✓ Escolas no agrupamento: %d\n", nrow(agregados)))
cat(sprintf("   ✓ Escolas após join: %d\n", nrow(metadados)))

if (nrow(metadados) < nrow(agregados)) {
  warning(sprintf("⚠ Perda de %d escolas no join!\n", 
                  nrow(agregados) - nrow(metadados)))
}

# ============================================================================
# PASSO 5: CRIAR VARIÁVEIS DE CLASSIFICAÇÃO
# ============================================================================

cat("\n>>> Criando variáveis de classificação...\n")

# Classificar área (capital vs interior)
area_map <- tribble(
  ~ID_AREA, ~AREA,
  1, "Capital",
  2, "Interior"
)

# Classificar localização (urbana vs rural)
localizacao_map <- tribble(
  ~ID_LOCALIZACAO, ~LOCALIZACAO,
  1, "Urbana",
  2, "Rural"
)

# Aplicar mapeamentos
metadados <- metadados %>%
  left_join(area_map, by = "ID_AREA") %>%
  left_join(localizacao_map, by = "ID_LOCALIZACAO") %>%
  # Criar variável de grupo (pública vs privada)
  mutate(
    TIPO_ESCOLA = if_else(IN_PUBLICA == 1, "Pública", "Privada"),
    
    # INSE categorizado
    GRUPO_INSE = case_when(
      INSE_MEDIO < quantile(INSE_MEDIO, 0.33, na.rm = TRUE) ~ "Baixo_INSE",
      INSE_MEDIO < quantile(INSE_MEDIO, 0.67, na.rm = TRUE) ~ "Medio_INSE",
      TRUE ~ "Alto_INSE"
    )
  ) %>%
  select(
    ID_ESCOLA,
    TIPO_ESCOLA,
    AREA,
    LOCALIZACAO,
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

cat("   ✓ Classificações criadas\n")
cat(sprintf("   • Pública: %d | Privada: %d\n",
            sum(metadados$TIPO_ESCOLA == "Pública"),
            sum(metadados$TIPO_ESCOLA == "Privada")))
cat(sprintf("   • Urbana: %d | Rural: %d\n",
            sum(metadados$LOCALIZACAO == "Urbana"),
            sum(metadados$LOCALIZACAO == "Rural")))
cat(sprintf("   • Capital: %d | Interior: %d\n",
            sum(metadados$AREA == "Capital"),
            sum(metadados$AREA == "Interior")))

# ============================================================================
# PASSO 6: EXPORTAR METADADOS
# ============================================================================

cat("\n>>> Exportando metadados...\n")

nome_saida <- file.path(DIR_PROCESSADOS, 
                         paste0("metadados_escolas_", timestamp, ".csv"))

write_csv(metadados, nome_saida)

cat(sprintf("   ✓ Arquivo salvo: metadados_escolas_%s.csv\n", timestamp))
cat(sprintf("   • Caminh: %s\n", nome_saida))
cat(sprintf("   • Linhas: %d (escolas) | Colunas: %d\n", 
            nrow(metadados), ncol(metadados)))

# ============================================================================
# PASSO 7: RESUMOS POR GRUPO
# ============================================================================

cat("\n>>> Resumos por grupo:\n")

# Por tipo de escola
cat("\n--- PÚBLICA vs PRIVADA ---\n")
metadados %>%
  group_by(TIPO_ESCOLA) %>%
  summarise(
    N_ESCOLAS = n(),
    MEDIA_MT_GRUPO = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP_GRUPO = mean(MEDIA_LP, na.rm = TRUE),
    INSE_GRUPO = mean(INSE_MEDIO, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  print()

# Por localização
cat("\n--- URBANA vs RURAL ---\n")
metadados %>%
  group_by(LOCALIZACAO) %>%
  summarise(
    N_ESCOLAS = n(),
    MEDIA_MT_GRUPO = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP_GRUPO = mean(MEDIA_LP, na.rm = TRUE),
    INSE_GRUPO = mean(INSE_MEDIO, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  print()

# Por INSE
cat("\n--- GRUPOS DE INSE ---\n")
metadados %>%
  group_by(GRUPO_INSE) %>%
  summarise(
    N_ESCOLAS = n(),
    MEDIA_MT_GRUPO = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP_GRUPO = mean(MEDIA_LP, na.rm = TRUE),
    INSE_GRUPO = mean(INSE_MEDIO, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  print()

cat("\n✅ Script finalizado com sucesso!\n")


