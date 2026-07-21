################################################################################
# SCRIPT: comparar_duas_escolas.r
#
# OBJETIVO: Comparar perfil de 2 escolas específicas (lado a lado)
#           Permite ler dados de:
#           a) IDs de escolas (puxando do metadados ou dados brutos)
#           b) Arquivo XLSX já separado
#
# ENTRADA: 
#   - Opção A: IDs das escolas (configurável no topo)
#   - Opção B: Arquivo XLSX com dados das 2 escolas
#
# SAÍDA: 
#   - Comparacao_Escola_A_vs_B_YYYYMMDD.csv
#   - Perfis_Escolas.csv (resumo lado a lado)
#   - visualizacao_comparacao.png (gráfico)
#
# VERSÃO: 1.0 — Maio 2026
################################################################################

# ============================================================================
# PASSO 0: CARREGAR PACOTES (DETECÇÃO AUTOMÁTICA DE CAMINHOS)
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

# Paths
RAIZ <- detectar_raiz()
DIR_MICRODADOS <- file.path(RAIZ, "MICRODADOS_SAEB_2023/DADOS")
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_PROCESSADOS <- file.path(DIR_ANALISE, "outputs/metadados")
DIR_COMPARACOES <- file.path(DIR_ANALISE, "outputs/comparacoes")

# Timestamp
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

# ============================================================================
# FUNÇÃO: Carregar metadados das escolas (para comparação de atributos)
# ============================================================================

carregar_metadados_escola <- function(ID) {
  # Encontrar arquivo mais recente de metadados
  arquivos_meta <- list.files(DIR_PROCESSADOS, 
                               pattern = "^metadados_escolas_.*\\.csv$",
                               full.names = TRUE)
  if (length(arquivos_meta) == 0) return(NULL)
  
  arquivo_meta <- sort(arquivos_meta, decreasing = TRUE)[1]
  metadados <- read_csv(arquivo_meta, show_col_types = FALSE)
  
  metadados %>%
    filter(ID_ESCOLA == ID) %>%
    select(ID_ESCOLA, TIPO_ESCOLA, AREA, LOCALIZACAO, GRUPO_INSE) %>%
    slice(1)
}

# ============================================================================
# CONFIGURAÇÃO: ESCOLHA OPÇÃO A OU B
# ============================================================================

# ✅ OPÇÃO A: Definir IDs das 2 escolas manualmente
USAR_IDS <- TRUE
ID_ESCOLA_A <- 61432986    # ← ALTERAR AQUI
ID_ESCOLA_B <- 61466120    # ← ALTERAR AQUI

# ✅ OPÇÃO B: Ler dados de arquivo XLSX (descomente para usar)
# USAR_IDS <- FALSE
# ARQUIVO_XLSX_A <- "C:/caminho/para/escola_A_dados.xlsx"
# ARQUIVO_XLSX_B <- "C:/caminho/para/escola_B_dados.xlsx"

# ============================================================================
# PASSO 1: CARREGAR DADOS
# ============================================================================

cat(">>> Carregando dados das escolas...\n\n")

if (USAR_IDS) {
  
  # ─────────────────────────────────────────────────────────────────────────
  # OPÇÃO A: Usar IDs
  # ─────────────────────────────────────────────────────────────────────────
  
  cat(sprintf("OPÇÃO A: Carregando por IDs\n"))
  cat(sprintf("Escola A: ID = %d\n", ID_ESCOLA_A))
  cat(sprintf("Escola B: ID = %d\n\n", ID_ESCOLA_B))
  
  # Carregar dados brutos
  alunos <- fread(file.path(DIR_MICRODADOS, "TS_ALUNO_34EM.csv"),
                   encoding = "Latin-1") %>%
    as_tibble()
  
  # Filtrar Escola A
  dados_A <- alunos %>%
    filter(ID_ESCOLA == ID_ESCOLA_A) %>%
    select(
      ID_ESCOLA,
      PROFICIENCIA_MT_SAEB,
      PROFICIENCIA_LP_SAEB,
      INSE_ALUNO,
      NU_TIPO_NIVEL_INSE,
      ID_AREA,
      ID_LOCALIZACAO
    )
  
  # Filtrar Escola B
  dados_B <- alunos %>%
    filter(ID_ESCOLA == ID_ESCOLA_B) %>%
    select(
      ID_ESCOLA,
      PROFICIENCIA_MT_SAEB,
      PROFICIENCIA_LP_SAEB,
      INSE_ALUNO,
      NU_TIPO_NIVEL_INSE,
      ID_AREA,
      ID_LOCALIZACAO
    )
  
  # Validar se escolas existem
  if (nrow(dados_A) == 0) {
    stop(sprintf("❌ Escola A (ID=%d) não encontrada!", ID_ESCOLA_A))
  }
  if (nrow(dados_B) == 0) {
    stop(sprintf("❌ Escola B (ID=%d) não encontrada!", ID_ESCOLA_B))
  }
  
  # Usar IDs como nomes das escolas
  nome_A <- sprintf("Escola A (ID: %d)", ID_ESCOLA_A)
  nome_B <- sprintf("Escola B (ID: %d)", ID_ESCOLA_B)
  
  cat(sprintf("✓ Escola A: %s (n=%d alunos)\n", nome_A, nrow(dados_A)))
  cat(sprintf("✓ Escola B: %s (n=%d alunos)\n\n", nome_B, nrow(dados_B)))
  
  # Criar subpasta única para esta comparação
  DIR_SAIDA <- file.path(DIR_COMPARACOES, 
                         sprintf("Escola_%d_vs_Escola_%d_%s", 
                                 ID_ESCOLA_A, ID_ESCOLA_B, timestamp))
  if (!dir.exists(DIR_SAIDA)) {
    dir.create(DIR_SAIDA, showWarnings = FALSE, recursive = TRUE)
  }
  cat(sprintf("📁 Pasta de saída: %s\n\n", basename(DIR_SAIDA)))
  
} else {
  
  # ─────────────────────────────────────────────────────────────────────────
  # OPÇÃO B: Ler XLSX
  # ─────────────────────────────────────────────────────────────────────────
  
  cat(sprintf("OPÇÃO B: Carregando de arquivos XLSX\n"))
  cat(sprintf("Arquivo A: %s\n", ARQUIVO_XLSX_A))
  cat(sprintf("Arquivo B: %s\n\n", ARQUIVO_XLSX_B))
  
  # Precisaria de readxl
  if (!require(readxl, quietly = TRUE)) {
    install.packages("readxl")
    library(readxl)
  }
  
  dados_A <- read_excel(ARQUIVO_XLSX_A) %>%
    as_tibble()
  
  dados_B <- read_excel(ARQUIVO_XLSX_B) %>%
    as_tibble()
  
  # Tentar extrair info do arquivo
  nome_A <- "Escola A (XLSX)"
  nome_B <- "Escola B (XLSX)"
  ID_ESCOLA_A <- "N/A"
  ID_ESCOLA_B <- "N/A"
  
  cat(sprintf("✓ Escola A: %d alunos carregados\n", nrow(dados_A)))
  cat(sprintf("✓ Escola B: %d alunos carregados\n\n", nrow(dados_B)))
  
  # Criar subpasta única para esta comparação
  DIR_SAIDA <- file.path(DIR_COMPARACOES, 
                         sprintf("Comparacao_XLSX_%s", timestamp))
  if (!dir.exists(DIR_SAIDA)) {
    dir.create(DIR_SAIDA, showWarnings = FALSE, recursive = TRUE)
  }
  cat(sprintf("📁 Pasta de saída: %s\n\n", basename(DIR_SAIDA)))
}

# ============================================================================
# PASSO 2: AGREGAÇÃO POR ESCOLA
# ============================================================================

cat(">>> Agregando dados por escola...\n")

# Agregação A
agg_A <- dados_A %>%
  summarise(
    ID_ESCOLA = first(ID_ESCOLA),
    NOME = nome_A,
    N_ALUNOS = n(),
    MEDIA_MT = mean(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    MEDIA_LP = mean(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    SD_MT = sd(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    SD_LP = sd(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    MIN_MT = min(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    MAX_MT = max(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    Q1_MT = quantile(PROFICIENCIA_MT_SAEB, 0.25, na.rm = TRUE),
    Q2_MT = quantile(PROFICIENCIA_MT_SAEB, 0.50, na.rm = TRUE),
    Q3_MT = quantile(PROFICIENCIA_MT_SAEB, 0.75, na.rm = TRUE),
    MIN_LP = min(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    MAX_LP = max(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    Q1_LP = quantile(PROFICIENCIA_LP_SAEB, 0.25, na.rm = TRUE),
    Q2_LP = quantile(PROFICIENCIA_LP_SAEB, 0.50, na.rm = TRUE),
    Q3_LP = quantile(PROFICIENCIA_LP_SAEB, 0.75, na.rm = TRUE),
    INSE_MEDIO = mean(INSE_ALUNO, na.rm = TRUE),
    SD_INSE = sd(INSE_ALUNO, na.rm = TRUE)
  )

# Agregação B
agg_B <- dados_B %>%
  summarise(
    ID_ESCOLA = first(ID_ESCOLA),
    NOME = nome_B,
    N_ALUNOS = n(),
    MEDIA_MT = mean(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    MEDIA_LP = mean(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    SD_MT = sd(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    SD_LP = sd(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    MIN_MT = min(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    MAX_MT = max(PROFICIENCIA_MT_SAEB, na.rm = TRUE),
    Q1_MT = quantile(PROFICIENCIA_MT_SAEB, 0.25, na.rm = TRUE),
    Q2_MT = quantile(PROFICIENCIA_MT_SAEB, 0.50, na.rm = TRUE),
    Q3_MT = quantile(PROFICIENCIA_MT_SAEB, 0.75, na.rm = TRUE),
    MIN_LP = min(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    MAX_LP = max(PROFICIENCIA_LP_SAEB, na.rm = TRUE),
    Q1_LP = quantile(PROFICIENCIA_LP_SAEB, 0.25, na.rm = TRUE),
    Q2_LP = quantile(PROFICIENCIA_LP_SAEB, 0.50, na.rm = TRUE),
    Q3_LP = quantile(PROFICIENCIA_LP_SAEB, 0.75, na.rm = TRUE),
    INSE_MEDIO = mean(INSE_ALUNO, na.rm = TRUE),
    SD_INSE = sd(INSE_ALUNO, na.rm = TRUE)
  )

cat("   ✓ Agregação completa\n\n")

# ============================================================================
# PASSO 2B: COMPARAÇÃO DE ATRIBUTOS (Tipo, Área, Localização, INSE)
# ============================================================================

cat(">>> Comparação de Atributos (Características das Escolas)\n\n")

# Tentar carregar metadados para comparação de características
meta_A <- carregar_metadados_escola(ID_ESCOLA_A)
meta_B <- carregar_metadados_escola(ID_ESCOLA_B)

if (!is.null(meta_A) && !is.null(meta_B)) {
  
  # Montar tabela de atributos
  atributos <- data.frame(
    Característica = c(
      "Tipo de Escola",
      "Área",
      "Localização",
      "Nível Socioeconômico (INSE)"
    ),
    Escola_A = c(
      meta_A$TIPO_ESCOLA,
      meta_A$AREA,
      meta_A$LOCALIZACAO,
      meta_A$GRUPO_INSE
    ),
    Escola_B = c(
      meta_B$TIPO_ESCOLA,
      meta_B$AREA,
      meta_B$LOCALIZACAO,
      meta_B$GRUPO_INSE
    ),
    Diferença = c(
      if_else(meta_A$TIPO_ESCOLA == meta_B$TIPO_ESCOLA, "✓ Igual", "✗ DIFERENTE"),
      if_else(meta_A$AREA == meta_B$AREA, "✓ Igual", "✗ DIFERENTE"),
      if_else(meta_A$LOCALIZACAO == meta_B$LOCALIZACAO, "✓ Igual", "✗ DIFERENTE"),
      if_else(meta_A$GRUPO_INSE == meta_B$GRUPO_INSE, "✓ Igual", "✗ DIFERENTE")
    )
  )
  
  cat("📊 RESUMO DE CARACTERÍSTICAS:\n\n")
  print(atributos)
  
  # Resumo de diferenças
  cat("\n🔍 ANÁLISE DE DIFERENÇAS:\n")
  diferenças_encontradas <- atributos %>%
    filter(grepl("DIFERENTE", Diferença))
  
  if (nrow(diferenças_encontradas) == 0) {
    cat("   → As duas escolas têm as MESMAS características!\n\n")
  } else {
    cat(sprintf("   → %d característica(s) DIFERENTE(s):\n", nrow(diferenças_encontradas)))
    for (i in 1:nrow(diferenças_encontradas)) {
      carac <- diferenças_encontradas$Característica[i]
      val_a <- diferenças_encontradas$Escola_A[i]
      val_b <- diferenças_encontradas$Escola_B[i]
      cat(sprintf("      • %s: %s vs %s\n", carac, val_a, val_b))
    }
    cat("\n")
  }
  
} else {
  cat("   ⚠ Metadados não disponíveis para comparação de atributos\n\n")
}

# ============================================================================
# PASSO 3: COMPARAÇÃO LADO A LADO
# ============================================================================

cat(">>> Comparação: Perfil das Escolas\n\n")

# Montar tabela lado a lado
comparacao <- data.frame(
  Métrica = c(
    "ID Escola",
    "Nome",
    "N Alunos",
    "─── MATEMÁTICA ───",
    "Média MT",
    "Desvio Padrão MT",
    "Mín MT",
    "Q1 MT",
    "Mediana MT",
    "Q3 MT",
    "Máx MT",
    "─── LÍNGUA PORTUGUESA ───",
    "Média LP",
    "Desvio Padrão LP",
    "Mín LP",
    "Q1 LP",
    "Mediana LP",
    "Q3 LP",
    "Máx LP",
    "─── INSE (Socioeconômico) ───",
    "INSE Médio",
    "Desvio Padrão INSE"
  ),
  Escola_A = c(
    as.character(agg_A$ID_ESCOLA),
    agg_A$NOME,
    agg_A$N_ALUNOS,
    "────────────",
    round(agg_A$MEDIA_MT, 2),
    round(agg_A$SD_MT, 2),
    round(agg_A$MIN_MT, 2),
    round(agg_A$Q1_MT, 2),
    round(agg_A$Q2_MT, 2),
    round(agg_A$Q3_MT, 2),
    round(agg_A$MAX_MT, 2),
    "────────────",
    round(agg_A$MEDIA_LP, 2),
    round(agg_A$SD_LP, 2),
    round(agg_A$MIN_LP, 2),
    round(agg_A$Q1_LP, 2),
    round(agg_A$Q2_LP, 2),
    round(agg_A$Q3_LP, 2),
    round(agg_A$MAX_LP, 2),
    "────────────",
    round(agg_A$INSE_MEDIO, 2),
    round(agg_A$SD_INSE, 2)
  ),
  Escola_B = c(
    as.character(agg_B$ID_ESCOLA),
    agg_B$NOME,
    agg_B$N_ALUNOS,
    "────────────",
    round(agg_B$MEDIA_MT, 2),
    round(agg_B$SD_MT, 2),
    round(agg_B$MIN_MT, 2),
    round(agg_B$Q1_MT, 2),
    round(agg_B$Q2_MT, 2),
    round(agg_B$Q3_MT, 2),
    round(agg_B$MAX_MT, 2),
    "────────────",
    round(agg_B$MEDIA_LP, 2),
    round(agg_B$SD_LP, 2),
    round(agg_B$MIN_LP, 2),
    round(agg_B$Q1_LP, 2),
    round(agg_B$Q2_LP, 2),
    round(agg_B$Q3_LP, 2),
    round(agg_B$MAX_LP, 2),
    "────────────",
    round(agg_B$INSE_MEDIO, 2),
    round(agg_B$SD_INSE, 2)
  ),
  Diferença = c(
    "─",
    "─",
    agg_B$N_ALUNOS - agg_A$N_ALUNOS,
    "────────────",
    round(agg_B$MEDIA_MT - agg_A$MEDIA_MT, 2),
    round(agg_B$SD_MT - agg_A$SD_MT, 2),
    round(agg_B$MIN_MT - agg_A$MIN_MT, 2),
    round(agg_B$Q1_MT - agg_A$Q1_MT, 2),
    round(agg_B$Q2_MT - agg_A$Q2_MT, 2),
    round(agg_B$Q3_MT - agg_A$Q3_MT, 2),
    round(agg_B$MAX_MT - agg_A$MAX_MT, 2),
    "────────────",
    round(agg_B$MEDIA_LP - agg_A$MEDIA_LP, 2),
    round(agg_B$SD_LP - agg_A$SD_LP, 2),
    round(agg_B$MIN_LP - agg_A$MIN_LP, 2),
    round(agg_B$Q1_LP - agg_A$Q1_LP, 2),
    round(agg_B$Q2_LP - agg_A$Q2_LP, 2),
    round(agg_B$Q3_LP - agg_A$Q3_LP, 2),
    round(agg_B$MAX_LP - agg_A$MAX_LP, 2),
    "────────────",
    round(agg_B$INSE_MEDIO - agg_A$INSE_MEDIO, 2),
    round(agg_B$SD_INSE - agg_A$SD_INSE, 2)
  )
)

print(comparacao)

# ============================================================================
# PASSO 4: TESTE DE WILCOXON (se dados estão disponíveis)
# ============================================================================

cat("\n\n>>> Teste de Wilcoxon (diferença entre distribuições)\n")
cat("H0: As duas escolas têm a mesma distribuição de proficiência\n\n")

# Remover NAs
mt_a <- dados_A %>% pull(PROFICIENCIA_MT_SAEB) %>% na.omit()
mt_b <- dados_B %>% pull(PROFICIENCIA_MT_SAEB) %>% na.omit()
lp_a <- dados_A %>% pull(PROFICIENCIA_LP_SAEB) %>% na.omit()
lp_b <- dados_B %>% pull(PROFICIENCIA_LP_SAEB) %>% na.omit()

if (length(mt_a) > 0 & length(mt_b) > 0) {
  teste_mt <- wilcox.test(mt_a, mt_b, alternative = "two.sided")
  cat(sprintf("MATEMÁTICA:\n"))
  cat(sprintf("  U = %.2f\n", teste_mt$statistic))
  cat(sprintf("  p-valor = %e\n", teste_mt$p.value))
  sig <- if (teste_mt$p.value < 0.05) "✓ SIGNIFICATIVO" else "✗ Não significativo"
  cat(sprintf("  Resultado: %s\n\n", sig))
} else {
  cat("⚠ Dados insuficientes para testar Matemática\n\n")
}

if (length(lp_a) > 0 & length(lp_b) > 0) {
  teste_lp <- wilcox.test(lp_a, lp_b, alternative = "two.sided")
  cat(sprintf("LÍNGUA PORTUGUESA:\n"))
  cat(sprintf("  U = %.2f\n", teste_lp$statistic))
  cat(sprintf("  p-valor = %e\n", teste_lp$p.value))
  sig <- if (teste_lp$p.value < 0.05) "✓ SIGNIFICATIVO" else "✗ Não significativo"
  cat(sprintf("  Resultado: %s\n\n", sig))
} else {
  cat("⚠ Dados insuficientes para testar Língua Portuguesa\n\n")
}

# ============================================================================
# PASSO 5: EXPORTAR RESULTADOS
# ============================================================================

cat(">>> Exportando resultados...\n")

# CSV da comparação
nome_comparacao <- file.path(DIR_SAIDA,
                              sprintf("Comparacao_Escola_%s_vs_%s_%s.csv",
                                      str_sub(nome_A, 1, 10),
                                      str_sub(nome_B, 1, 10),
                                      timestamp))

write_csv(as_tibble(comparacao), nome_comparacao)
cat(sprintf("   ✓ Tabela: %s\n", basename(nome_comparacao)))

# Dados agregados
dados_agg <- bind_rows(agg_A, agg_B)
nome_agg <- file.path(DIR_SAIDA,
                      sprintf("Perfis_Escolas_%s.csv", timestamp))

write_csv(dados_agg, nome_agg)
cat(sprintf("   ✓ Perfis: %s\n", basename(nome_agg)))

# Exportar tabela de atributos (se disponível)
if (!is.null(meta_A) && !is.null(meta_B)) {
  nome_atributos <- file.path(DIR_SAIDA,
                              sprintf("Atributos_Escolas_%s.csv", timestamp))
  write_csv(as_tibble(atributos), nome_atributos)
  cat(sprintf("   ✓ Atributos: %s\n", basename(nome_atributos)))
}

# ============================================================================
# PASSO 6: VISUALIZAÇÃO
# ============================================================================

cat("\n>>> Gerando visualização...\n")

# Preparar dados para plot
dados_plot <- bind_rows(
  dados_A %>%
    select(PROFICIENCIA_MT_SAEB, PROFICIENCIA_LP_SAEB, INSE_ALUNO) %>%
    mutate(Escola = str_sub(nome_A, 1, 20)),
  dados_B %>%
    select(PROFICIENCIA_MT_SAEB, PROFICIENCIA_LP_SAEB, INSE_ALUNO) %>%
    mutate(Escola = str_sub(nome_B, 1, 20))
) %>%
  pivot_longer(
    cols = c(PROFICIENCIA_MT_SAEB, PROFICIENCIA_LP_SAEB),
    names_to = "Disciplina",
    values_to = "Proficiência"
  ) %>%
  mutate(
    Disciplina = recode(Disciplina,
                        PROFICIENCIA_MT_SAEB = "Matemática",
                        PROFICIENCIA_LP_SAEB = "Língua Portuguesa"),
    Escola = factor(Escola)
  )

# Boxplot
p <- dados_plot %>%
  ggplot(aes(x = Disciplina, y = Proficiência, fill = Escola)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.4) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1) +
  labs(
    title = sprintf("Comparação: %s vs %s", str_sub(nome_A, 1, 25), str_sub(nome_B, 1, 25)),
    x = "Disciplina",
    y = "Proficiência",
    fill = "Escola"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "right"
  )

nome_plot <- file.path(DIR_SAIDA,
                       sprintf("visualizacao_comparacao_%s.png", timestamp))

ggsave(nome_plot, plot = p, width = 10, height = 6, dpi = 300)
cat(sprintf("   ✓ Gráfico: %s\n", basename(nome_plot)))

# ============================================================================
# RESUMO FINAL
# ============================================================================

cat("\n" , strrep("=", 80) , "\n", sep="")
cat("COMPARAÇÃO COMPLETA\n")
cat(strrep("=", 80), "\n\n", sep="")

cat(sprintf("Arquivos salvos em: %s\n\n", DIR_SAIDA))

# Mostrar resumo de características se disponível
if (!is.null(meta_A) && !is.null(meta_B)) {
  cat("📊 RESUMO DE CARACTERÍSTICAS:\n")
  cat(sprintf("  • Tipo de Escola: %s (A) vs %s (B) %s\n",
              meta_A$TIPO_ESCOLA, meta_B$TIPO_ESCOLA,
              if_else(meta_A$TIPO_ESCOLA != meta_B$TIPO_ESCOLA, "← DIFERENTE", "")))
  cat(sprintf("  • Área: %s (A) vs %s (B) %s\n",
              meta_A$AREA, meta_B$AREA,
              if_else(meta_A$AREA != meta_B$AREA, "← DIFERENTE", "")))
  cat(sprintf("  • Localização: %s (A) vs %s (B) %s\n",
              meta_A$LOCALIZACAO, meta_B$LOCALIZACAO,
              if_else(meta_A$LOCALIZACAO != meta_B$LOCALIZACAO, "← DIFERENTE", "")))
  cat(sprintf("  • INSE: %s (A) vs %s (B) %s\n\n",
              meta_A$GRUPO_INSE, meta_B$GRUPO_INSE,
              if_else(meta_A$GRUPO_INSE != meta_B$GRUPO_INSE, "← DIFERENTE", "")))
}

cat("📈 RESUMO DE DESEMPENHO (Escola B - Escola A):\n")
cat(sprintf("  • Média MT: %.2f (diferença: %.2f)\n",
            agg_B$MEDIA_MT, agg_B$MEDIA_MT - agg_A$MEDIA_MT))
cat(sprintf("  • Média LP: %.2f (diferença: %.2f)\n",
            agg_B$MEDIA_LP, agg_B$MEDIA_LP - agg_A$MEDIA_LP))
cat(sprintf("  • INSE Médio: %.2f (diferença: %.2f)\n",
            agg_B$INSE_MEDIO, agg_B$INSE_MEDIO - agg_A$INSE_MEDIO))

cat("\n✅ Análise de comparação finalizada!\n")
