################################################################################
# SCRIPT: dendrograma_multiplos_pares.r
#
# OBJETIVO: Gerar dendrogramas para MÚLTIPLOS pares de escolas
#           Lê lista de pares de um CSV
#           Cria pasta separada para cada comparação
#
# ENTRADA: 
#   - lista_comparacoes.csv (ID_ESCOLA_A, ID_ESCOLA_B)
#   - metadados_escolas_*.csv
#
# SAÍDA:
#   - Pasta separada para cada par
#   - dendrograma_escolas_*.png por par
#   - scatter_comparacao_*.png por par
#
# VERSÃO: 1.0 — Maio 2026
################################################################################

# ============================================================================
# PASSO 0: CARREGAR PACOTES
# ============================================================================

library(tidyverse)
library(data.table)
library(ggdendro)    # install.packages("ggdendro")
library(patchwork)   # install.packages("patchwork")

# Paths
RAIZ <- "C:/Users/13756596699/tcc"
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_OUTPUTS_ESCOLAS <- file.path(DIR_ANALISE, "outputs_escolas")
DIR_PROCESSADOS <- file.path(DIR_ANALISE, "outputs_escolas")
DIR_FIGURAS_BASE <- file.path(DIR_ANALISE, "outputs_figuras")

# Criar diretório base se não existir
if (!dir.exists(DIR_FIGURAS_BASE)) {
  dir.create(DIR_FIGURAS_BASE, showWarnings = FALSE, recursive = TRUE)
}

# Timestamp global para versionamento
timestamp_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

# ============================================================================
# PASSO 1: CARREGAR LISTA DE COMPARAÇÕES
# ============================================================================

cat(">>> Carregando lista de comparações...\n\n")

# Procurar arquivo de lista de comparações (no diretório Scripts)
arquivo_lista <- file.path(dirname(getwd()), "Scripts", "lista_comparacoes.csv")
if (!file.exists(arquivo_lista)) {
  arquivo_lista <- "lista_comparacoes.csv"  # fallback para diretório atual
}

if (!file.exists(arquivo_lista)) {
  cat("⚠️  Arquivo não encontrado: lista_comparacoes.csv\n")
  cat("   Criando arquivo exemplo...\n\n")
  
  # Criar arquivo exemplo
  lista_exemplo <- data.frame(
    ID_ESCOLA_A = c(61432986, 61425355),
    ID_ESCOLA_B = c(61466120, 61458788 ),
    DESCRICAO = c(
      "Escola Pública Interior vs Capital",
      "Escola Pública Interior vs Outra",
      "Primeira vs Terceira",
      "Segunda vs Quarta"
    )
  )
  
  write_csv(lista_exemplo, arquivo_lista)
  cat(sprintf("✓ Arquivo criado: %s\n", arquivo_lista))
  cat("   Edite o arquivo com os pares que deseja comparar\n")
  cat("   Depois rode o script novamente\n\n")
  stop("Por favor, edite lista_comparacoes.csv e rode novamente!")
}

# Carregar lista
lista_comparacoes <- read_csv(arquivo_lista, show_col_types = FALSE)

cat(sprintf("✓ Lista carregada: %d comparações\n\n", nrow(lista_comparacoes)))

# ============================================================================
# PASSO 2: CARREGAR METADADOS
# ============================================================================

cat(">>> Carregando metadados das escolas...\n")

# Encontrar arquivo mais recente de metadados
arquivos_meta <- list.files(DIR_PROCESSADOS,
                             pattern = "^metadados_escolas_.*\\.csv$",
                             full.names = TRUE)

if (length(arquivos_meta) == 0) {
  stop("❌ Nenhum arquivo de metadados encontrado! Execute classificar_escolas.r primeiro.")
}

arquivo_meta <- sort(arquivos_meta, decreasing = TRUE)[1]
cat(sprintf("   Usando: %s\n", basename(arquivo_meta)))

metadados <- read_csv(arquivo_meta, show_col_types = FALSE)

cat(sprintf("   ✓ Metadados carregados: %d escolas\n\n", nrow(metadados)))

# ============================================================================
# PASSO 3: FUNÇÃO PARA GERAR DENDROGRAMA DE UM PAR
# ============================================================================

gerar_dendrograma_par <- function(ID_A, ID_B, indice, total) {
  
  cat(sprintf("[%d/%d] Processando: Escola %d vs Escola %d\n", indice, total, ID_A, ID_B))
  
  # Verificar se as escolas existem
  escola_a <- metadados %>% filter(ID_ESCOLA == ID_A)
  escola_b <- metadados %>% filter(ID_ESCOLA == ID_B)
  
  if (nrow(escola_a) == 0) {
    cat(sprintf("   ⚠️  Escola A (ID=%d) não encontrada. Pulando...\n\n", ID_A))
    return(NULL)
  }
  if (nrow(escola_b) == 0) {
    cat(sprintf("   ⚠️  Escola B (ID=%d) não encontrada. Pulando...\n\n", ID_B))
    return(NULL)
  }
  
  # Criar pasta para este par
  nome_pasta <- sprintf("Escola_%d_vs_Escola_%d_%s", ID_A, ID_B, timestamp_global)
  dir_saida <- file.path(DIR_FIGURAS_BASE, nome_pasta)
  
  if (!dir.exists(dir_saida)) {
    dir.create(dir_saida, showWarnings = FALSE, recursive = TRUE)
  }
  
  # Preparar dados para as 2 escolas
  dados_cluster <- metadados %>%
    filter(ID_ESCOLA %in% c(ID_A, ID_B)) %>%
    filter(!is.na(MEDIA_MT) & !is.na(INSE_MEDIO)) %>%
    mutate(
      MEDIA_MT_escala = scale(MEDIA_MT)[, 1],
      MEDIA_LP_escala = scale(MEDIA_LP)[, 1],
      INSE_escala = scale(INSE_MEDIO)[, 1]
    ) %>%
    select(
      ID_ESCOLA,
      TIPO_ESCOLA,
      MEDIA_MT,
      MEDIA_LP,
      INSE_MEDIO,
      MEDIA_MT_escala,
      MEDIA_LP_escala,
      INSE_escala
    ) %>%
    arrange(ID_ESCOLA)
  
  if (nrow(dados_cluster) < 2) {
    cat(sprintf("   ⚠️  Dados insuficientes. Pulando...\n\n"))
    return(NULL)
  }
  
  # Matriz de características para clustering
  mat_cluster_mt <- dados_cluster %>%
    select(MEDIA_MT_escala, INSE_escala) %>%
    as.matrix()
  
  rownames(mat_cluster_mt) <- sprintf("Escola %d", dados_cluster$ID_ESCOLA)
  
  # Calcular distância euclidiana
  dist_mt <- dist(mat_cluster_mt, method = "euclidean")
  
  # Clustering hierárquico
  hc_mt <- hclust(dist_mt, method = "ward.D2")
  
  # Dendrograma via ggdendro (visual consistente com dendrograma_duas_escolas.r)
  cor_a   <- "#1B4F9A"
  cor_b   <- "#D62728"
  ts_local <- format(Sys.time(), "%Y%m%d_%H%M%S")

  dend_data <- dendro_data(hc_mt, type = "rectangle")
  seg       <- dend_data$segments
  lab       <- dend_data$labels

  label_a_full <- sprintf("Escola %d", ID_A)
  label_b_full <- sprintf("Escola %d", ID_B)

  # Proficiencias formatadas
  prof_a <- sprintf("MT: %.1f  |  LP: %.1f", escola_a$MEDIA_MT, escola_a$MEDIA_LP)
  prof_b <- sprintf("MT: %.1f  |  LP: %.1f", escola_b$MEDIA_MT, escola_b$MEDIA_LP)

  lab <- lab |>
    mutate(
      cor  = if_else(label == label_a_full, cor_a, cor_b),
      prof = if_else(label == label_a_full, prof_a, prof_b)
    )

  y_max   <- max(seg$y)
  y_label <- -0.08 * y_max
  y_prof  <- -0.22 * y_max

  distancia  <- round(as.matrix(dist_mt)[1, 2], 2)
  interp_txt <- ifelse(distancia < 1, "  |  muito similares",
                       ifelse(distancia < 2, "  |  moderadamente similares",
                              "  |  bem diferentes"))

  p_dend <- ggplot() +
    geom_segment(data = seg,
                 aes(x = x, y = y, xend = xend, yend = yend),
                 colour = "#555555", linewidth = 1.2, lineend = "round") +
    geom_point(data = lab,
               aes(x = x, y = 0, colour = cor),
               size = 7, shape = 19) +
    # Nome da escola
    geom_text(data = lab,
              aes(x = x, y = y_label, label = label, colour = cor),
              size = 3.8, fontface = "bold", hjust = 0.5, lineheight = 0.9) +
    # Valores MT e LP
    geom_text(data = lab,
              aes(x = x, y = y_prof, label = prof, colour = cor),
              size = 3.2, fontface = "italic", hjust = 0.5) +
    scale_colour_identity() +
    scale_y_continuous(
      expand = expansion(mult = c(0.32, 0.07)),
      name   = "Distancia Euclidiana (Ward.D2)"
    ) +
    annotate("text",
             x     = mean(range(lab$x)),
             y     = y_max * 1.02,
             label = paste0("Distancia: ", distancia, interp_txt),
             size = 3.5, colour = "#7B2D8B", fontface = "bold.italic", hjust = 0.5) +
    labs(
      title    = paste0("Escola ", ID_A, "  vs  Escola ", ID_B),
      subtitle = paste0("Variaveis: MEDIA_MT, MEDIA_LP, INSE_MEDIO   |   Metodo: Ward.D2")
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title         = element_text(face = "bold", size = 14, colour = "#1A1A1A"),
      plot.subtitle      = element_text(size = 10, colour = "#555555"),
      axis.title.x       = element_blank(),
      axis.text.x        = element_blank(),
      axis.ticks.x       = element_blank(),
      axis.title.y       = element_text(size = 10),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.background    = element_rect(fill = "#F8F9FA", colour = NA),
      panel.background   = element_rect(fill = "#FFFFFF", colour = NA),
      plot.margin        = margin(16, 16, 8, 16)
    )

  # Scatter plot (MT vs INSE, tamanho = LP)
  dados_plot <- dados_cluster |>
    mutate(
      Nome = sprintf("Escola %d", ID_ESCOLA),
      cor  = if_else(ID_ESCOLA == ID_A, cor_a, cor_b)
    )

  p_scatter <- ggplot(dados_plot,
                      aes(x = INSE_MEDIO, y = MEDIA_MT, colour = cor, size = MEDIA_LP)) +
    geom_point(alpha = 0.85, shape = 19) +
    geom_text(aes(label = paste0(Nome, "\nLP: ", round(MEDIA_LP, 1))),
              vjust = -1.1, size = 3, show.legend = FALSE,
              colour = dados_plot$cor, fontface = "bold") +
    scale_colour_identity() +
    scale_size_continuous(range = c(5, 12), name = "Profic. LP") +
    labs(
      title    = sprintf("Dispersao: Escola %d vs Escola %d", ID_A, ID_B),
      subtitle = "Proficiencia MT  x  INSE Medio  (tamanho = LP)",
      x = "INSE Medio",
      y = "Proficiencia MT"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title      = element_text(face = "bold", size = 12, colour = "#1A1A1A"),
      plot.subtitle   = element_text(size = 9, colour = "#555555"),
      plot.background = element_rect(fill = "#F8F9FA", colour = NA),
      panel.background= element_rect(fill = "#FFFFFF", colour = NA),
      plot.margin     = margin(16, 16, 8, 16)
    )

  # Salvar dendrograma
  nome_dendro <- file.path(dir_saida,
                            sprintf("dendrograma_escolas_%d_vs_%d_%s.png",
                                    ID_A, ID_B, ts_local))
  ggsave(nome_dendro, p_dend, width = 10, height = 6, dpi = 180, bg = "#F8F9FA")

  # Salvar scatter
  nome_scatter <- file.path(dir_saida,
                             sprintf("scatter_comparacao_%d_vs_%d_%s.png",
                                     ID_A, ID_B, ts_local))
  ggsave(nome_scatter, p_scatter, width = 8, height = 5, dpi = 180, bg = "#F8F9FA")

  # Calcular distância (já calculada acima como 'distancia')
  dist_valor <- distancia

  interpretacao <- ifelse(dist_valor < 1, "Muito similares",
                          ifelse(dist_valor < 2, "Moderadamente similares",
                                 "Bem diferentes"))

  # Resultado
  cat(sprintf("   ✓ MT: %.1f vs %.1f | LP: %.1f vs %.1f | INSE: %.1f vs %.1f\n",
              escola_a$MEDIA_MT, escola_b$MEDIA_MT,
              escola_a$MEDIA_LP, escola_b$MEDIA_LP,
              escola_a$INSE_MEDIO, escola_b$INSE_MEDIO))
  cat(sprintf("   ✓ Distância: %.2f (%s)\n", dist_valor, interpretacao))
  cat(sprintf("   ✓ Pasta: %s\n\n", nome_pasta))
  
  # Retornar resumo
  tibble(
    ID_A = ID_A,
    ID_B = ID_B,
    TIPO_A = escola_a$TIPO_ESCOLA,
    TIPO_B = escola_b$TIPO_ESCOLA,
    MT_A = round(escola_a$MEDIA_MT, 2),
    MT_B = round(escola_b$MEDIA_MT, 2),
    LP_A = round(escola_a$MEDIA_LP, 2),
    LP_B = round(escola_b$MEDIA_LP, 2),
    INSE_A = round(escola_a$INSE_MEDIO, 2),
    INSE_B = round(escola_b$INSE_MEDIO, 2),
    Distancia = round(dist_valor, 2),
    Interpretacao = interpretacao,
    Pasta = nome_pasta
  )
}

# ============================================================================
# PASSO 4: PROCESSAR TODAS AS COMPARAÇÕES
# ============================================================================

cat(">>> Gerando dendrogramas para todos os pares...\n")
cat(strrep("=", 80) , "\n\n", sep="")

resultados_lista <- list()

for (i in 1:nrow(lista_comparacoes)) {
  ID_A <- lista_comparacoes$ID_ESCOLA_A[i]
  ID_B <- lista_comparacoes$ID_ESCOLA_B[i]
  
  resultado <- gerar_dendrograma_par(ID_A, ID_B, i, nrow(lista_comparacoes))
  
  if (!is.null(resultado)) {
    resultados_lista[[i]] <- resultado
  }
}

# Combinar resultados
resultados_final <- bind_rows(resultados_lista)

# ============================================================================
# PASSO 5: SALVAR RESUMO
# ============================================================================

cat(strrep("=", 80) , "\n\n", sep="")
cat(">>> RESUMO DE TODAS AS COMPARAÇÕES\n\n")

print(resultados_final %>% select(ID_A, ID_B, MT_A, MT_B, LP_A, LP_B, Distancia, Interpretacao))

# Salvar resumo
arquivo_resumo <- file.path(DIR_FIGURAS_BASE, 
                            sprintf("resumo_dendrogramas_%s.csv", timestamp_global))

write_csv(resultados_final, arquivo_resumo)

cat(sprintf("\n✅ Processamento concluído!\n"))
cat(sprintf("   Total de pares: %d\n", nrow(lista_comparacoes)))
cat(sprintf("   Pares processados: %d\n", nrow(resultados_final)))
cat(sprintf("   Resumo salvo: %s\n", basename(arquivo_resumo)))
cat(sprintf("   Pastas: %s\n", DIR_FIGURAS_BASE))