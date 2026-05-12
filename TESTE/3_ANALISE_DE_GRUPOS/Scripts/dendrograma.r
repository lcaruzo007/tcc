################################################################################
# SCRIPT: dendrograma.r
#
# OBJETIVO: Agregar escolas por perfil socioeconômico médio (INSE_ALUNO)
#           e desempenho, criar dendrograma com clustering hierárquico,
#           colorir por tipo de escola (pública vs privada)
#
# ENTRADA: metadados_escolas_*.csv (saída de classificar_escolas.r)
#
# SAÍDA:
#   - dendrograma_MT_YYYYMMDD_HHMMSS.png (por Matemática)
#   - dendrograma_LP_YYYYMMDD_HHMMSS.png (por Língua Portuguesa)
#   - dendrograma_INSE_YYYYMMDD_HHMMSS.png (por INSE + Proficiência)
#   - clusters_escolas_YYYYMMDD_HHMMSS.csv (atribuição de clusters)
#
# VERSÃO: 1.0 — Maio 2026
################################################################################

# ============================================================================
# PASSO 0: CARREGAR PACOTES
# ============================================================================

library(tidyverse)
library(data.table)
library(dendextend)
library(ggdendro)
library(ggplot2)

# Paths
RAIZ <- "C:/Users/Usuario/Desktop/tcc"
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_PROCESSADOS <- file.path(DIR_TESTE, "processados")
DIR_FIGURAS <- file.path(DIR_PROCESSADOS, "figuras_dendrogramas")

# Criar diretório de figuras se não existir
if (!dir.exists(DIR_FIGURAS)) {
  dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
}

# Timestamp para versionamento
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

# ============================================================================
# PASSO 1: CARREGAR METADADOS
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

cat(sprintf("   ✓ Metadados carregados: %d escolas\n", nrow(metadados)))

# ============================================================================
# PASSO 2: PREPARAR DADOS PARA CLUSTERING
# ============================================================================

cat("\n>>> Preparando dados para clustering...\n")

# Selecionar e escalar variáveis para clustering
dados_cluster <- metadados %>%
  filter(!is.na(MEDIA_MT) & !is.na(INSE_MEDIO)) %>%
  mutate(
    # Escalar variáveis (z-score) para não haver dominância de uma sobre a outra
    MEDIA_MT_escala = scale(MEDIA_MT)[, 1],
    MEDIA_LP_escala = scale(MEDIA_LP)[, 1],
    INSE_escala = scale(INSE_MEDIO)[, 1]
  ) %>%
  select(
    ID_ESCOLA,
    NO_ESCOLA,
    GRUPO_TIPO,
    MEDIA_MT,
    MEDIA_LP,
    INSE_MEDIO,
    MEDIA_MT_escala,
    MEDIA_LP_escala,
    INSE_escala
  ) %>%
  arrange(ID_ESCOLA)

cat(sprintf("   ✓ Dados preparados: %d escolas (após remover NAs)\n", nrow(dados_cluster)))

# ============================================================================
# PASSO 3: DENDROGRAMA 1 — BASEADO EM MATEMÁTICA + INSE
# ============================================================================

cat("\n>>> Gerando Dendrograma 1: Matemática + INSE...\n")

# Matriz de características para clustering
mat_cluster_mt <- dados_cluster %>%
  select(MEDIA_MT_escala, INSE_escala) %>%
  as.matrix()

rownames(mat_cluster_mt) <- dados_cluster$ID_ESCOLA

# Calcular distância euclidiana
dist_mt <- dist(mat_cluster_mt, method = "euclidean")

# Clustering hierárquico com método Ward
hc_mt <- hclust(dist_mt, method = "ward.D2")

# Cortar dendrograma em 4 clusters (apropriado estatisticamente)
clusters_mt <- cutree(hc_mt, k = 4)

# Atribuir cores por tipo de escola
cores_tipo <- dados_cluster %>%
  select(ID_ESCOLA, GRUPO_TIPO) %>%
  mutate(
    cor = if_else(GRUPO_TIPO == "Privada", "darkred", "steelblue")
  ) %>%
  pull(cor, name = ID_ESCOLA)

# Converter para dendextend
dend_mt <- hc_mt %>%
  as.dendrogram() %>%
  set("labels_col", cores_tipo[labels(.)]) %>%
  set("leaves_pch", 16) %>%
  set("leaves_cex", 1)

# Salvar figura
png(file.path(DIR_FIGURAS, paste0("dendrograma_MT_", timestamp, ".png")),
    width = 1200, height = 600, res = 100)

plot(dend_mt,
     main = "Dendrograma: Escolas Agrupadas por Proficiência em Matemática + INSE",
     xlab = "ID Escola (Azul=Pública, Vermelho=Privada)",
     ylab = "Distância Euclidiana",
     cex.main = 1.2)

legend("topright", 
       legend = c("Pública", "Privada"),
       col = c("steelblue", "darkred"),
       pch = 16,
       cex = 1)

dev.off()

cat("   ✓ Dendrograma 1 salvo\n")

# ============================================================================
# PASSO 4: DENDROGRAMA 2 — BASEADO EM LÍNGUA PORTUGUESA + INSE
# ============================================================================

cat("\n>>> Gerando Dendrograma 2: Língua Portuguesa + INSE...\n")

# Matriz de características
mat_cluster_lp <- dados_cluster %>%
  select(MEDIA_LP_escala, INSE_escala) %>%
  as.matrix()

rownames(mat_cluster_lp) <- dados_cluster$ID_ESCOLA

# Distância e clustering
dist_lp <- dist(mat_cluster_lp, method = "euclidean")
hc_lp <- hclust(dist_lp, method = "ward.D2")
clusters_lp <- cutree(hc_lp, k = 4)

# Dendrograma com cores
dend_lp <- hc_lp %>%
  as.dendrogram() %>%
  set("labels_col", cores_tipo[labels(.)]) %>%
  set("leaves_pch", 16) %>%
  set("leaves_cex", 1)

# Salvar figura
png(file.path(DIR_FIGURAS, paste0("dendrograma_LP_", timestamp, ".png")),
    width = 1200, height = 600, res = 100)

plot(dend_lp,
     main = "Dendrograma: Escolas Agrupadas por Proficiência em Língua Portuguesa + INSE",
     xlab = "ID Escola (Azul=Pública, Vermelho=Privada)",
     ylab = "Distância Euclidiana",
     cex.main = 1.2)

legend("topright",
       legend = c("Pública", "Privada"),
       col = c("steelblue", "darkred"),
       pch = 16,
       cex = 1)

dev.off()

cat("   ✓ Dendrograma 2 salvo\n")

# ============================================================================
# PASSO 5: DENDROGRAMA 3 — TRIDIMENSIONAL (MT + LP + INSE)
# ============================================================================

cat("\n>>> Gerando Dendrograma 3: Todas as Dimensões (MT + LP + INSE)...\n")

# Matriz com 3 dimensões
mat_cluster_3d <- dados_cluster %>%
  select(MEDIA_MT_escala, MEDIA_LP_escala, INSE_escala) %>%
  as.matrix()

rownames(mat_cluster_3d) <- dados_cluster$ID_ESCOLA

# Distância e clustering
dist_3d <- dist(mat_cluster_3d, method = "euclidean")
hc_3d <- hclust(dist_3d, method = "ward.D2")
clusters_3d <- cutree(hc_3d, k = 4)

# Dendrograma
dend_3d <- hc_3d %>%
  as.dendrogram() %>%
  set("labels_col", cores_tipo[labels(.)]) %>%
  set("leaves_pch", 16) %>%
  set("leaves_cex", 1)

# Salvar figura
png(file.path(DIR_FIGURAS, paste0("dendrograma_3D_", timestamp, ".png")),
    width = 1200, height = 600, res = 100)

plot(dend_3d,
     main = "Dendrograma: Escolas Agrupadas por Proficiência (MT + LP) + INSE",
     xlab = "ID Escola (Azul=Pública, Vermelho=Privada)",
     ylab = "Distância Euclidiana",
     cex.main = 1.2)

legend("topright",
       legend = c("Pública", "Privada"),
       col = c("steelblue", "darkred"),
       pch = 16,
       cex = 1)

dev.off()

cat("   ✓ Dendrograma 3 salvo\n")

# ============================================================================
# PASSO 6: ATRIBUIR CLUSTERS ÀS ESCOLAS
# ============================================================================

cat("\n>>> Atribuindo clusters às escolas...\n")

resultado_clustering <- dados_cluster %>%
  mutate(
    Cluster_MT = clusters_mt[as.character(ID_ESCOLA)],
    Cluster_LP = clusters_lp[as.character(ID_ESCOLA)],
    Cluster_3D = clusters_3d[as.character(ID_ESCOLA)]
  ) %>%
  select(
    ID_ESCOLA,
    NO_ESCOLA,
    GRUPO_TIPO,
    MEDIA_MT,
    MEDIA_LP,
    INSE_MEDIO,
    Cluster_MT,
    Cluster_LP,
    Cluster_3D
  ) %>%
  arrange(ID_ESCOLA)

# ============================================================================
# PASSO 7: EXPORTAR RESULTADOS DE CLUSTERING
# ============================================================================

cat("\n>>> Exportando atribuição de clusters...\n")

nome_saida_clusters <- file.path(DIR_PROCESSADOS,
                                  paste0("clusters_escolas_", timestamp, ".csv"))

write_csv(resultado_clustering, nome_saida_clusters)

cat(sprintf("   ✓ Arquivo salvo: clusters_escolas_%s.csv\n", timestamp))

# ============================================================================
# PASSO 8: RESUMOS POR CLUSTER
# ============================================================================

cat("\n>>> Análise de Clusters:\n")

cat("\n--- CLUSTERS BASEADOS EM MATEMÁTICA ---\n")
resultado_clustering %>%
  group_by(Cluster_MT) %>%
  summarise(
    N_Escolas = n(),
    N_Privadas = sum(GRUPO_TIPO == "Privada"),
    N_Públicas = sum(GRUPO_TIPO == "Pública"),
    MEDIA_MT_cluster = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP_cluster = mean(MEDIA_LP, na.rm = TRUE),
    INSE_cluster = mean(INSE_MEDIO, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(Cluster_MT) %>%
  print()

cat("\n--- CLUSTERS BASEADOS EM LÍNGUA PORTUGUESA ---\n")
resultado_clustering %>%
  group_by(Cluster_LP) %>%
  summarise(
    N_Escolas = n(),
    N_Privadas = sum(GRUPO_TIPO == "Privada"),
    N_Públicas = sum(GRUPO_TIPO == "Pública"),
    MEDIA_MT_cluster = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP_cluster = mean(MEDIA_LP, na.rm = TRUE),
    INSE_cluster = mean(INSE_MEDIO, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(Cluster_LP) %>%
  print()

cat("\n--- CLUSTERS 3D (MT + LP + INSE) ---\n")
resultado_clustering %>%
  group_by(Cluster_3D) %>%
  summarise(
    N_Escolas = n(),
    N_Privadas = sum(GRUPO_TIPO == "Privada"),
    N_Públicas = sum(GRUPO_TIPO == "Pública"),
    MEDIA_MT_cluster = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP_cluster = mean(MEDIA_LP, na.rm = TRUE),
    INSE_cluster = mean(INSE_MEDIO, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(Cluster_3D) %>%
  print()

# ============================================================================
# PASSO 9: GRÁFICOS DE DISPERSÃO POR CLUSTER
# ============================================================================

cat("\n>>> Gerando gráficos de dispersão...\n")

# Scatter 1: MT vs INSE
p1 <- resultado_clustering %>%
  ggplot(aes(x = INSE_MEDIO, y = MEDIA_MT, color = GRUPO_TIPO, shape = GRUPO_TIPO)) +
  geom_point(size = 3, alpha = 0.7) +
  labs(
    title = "Proficiência em Matemática vs INSE",
    x = "INSE Médio",
    y = "Proficiência Média (MT)",
    color = "Tipo de Escola",
    shape = "Tipo de Escola"
  ) +
  scale_color_manual(values = c("Pública" = "steelblue", "Privada" = "darkred")) +
  scale_shape_manual(values = c("Pública" = 16, "Privada" = 17)) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

ggsave(file.path(DIR_FIGURAS, "scatter_MT_vs_INSE.png"),
       plot = p1, width = 8, height = 6, dpi = 300)

cat("   ✓ Scatter 1: MT vs INSE\n")

# Scatter 2: LP vs INSE
p2 <- resultado_clustering %>%
  ggplot(aes(x = INSE_MEDIO, y = MEDIA_LP, color = GRUPO_TIPO, shape = GRUPO_TIPO)) +
  geom_point(size = 3, alpha = 0.7) +
  labs(
    title = "Proficiência em Língua Portuguesa vs INSE",
    x = "INSE Médio",
    y = "Proficiência Média (LP)",
    color = "Tipo de Escola",
    shape = "Tipo de Escola"
  ) +
  scale_color_manual(values = c("Pública" = "steelblue", "Privada" = "darkred")) +
  scale_shape_manual(values = c("Pública" = 16, "Privada" = 17)) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

ggsave(file.path(DIR_FIGURAS, "scatter_LP_vs_INSE.png"),
       plot = p2, width = 8, height = 6, dpi = 300)

cat("   ✓ Scatter 2: LP vs INSE\n")

# Scatter 3: MT vs LP
p3 <- resultado_clustering %>%
  ggplot(aes(x = MEDIA_MT, y = MEDIA_LP, color = GRUPO_TIPO, shape = GRUPO_TIPO)) +
  geom_point(size = 3, alpha = 0.7) +
  labs(
    title = "Proficiência em Língua Portuguesa vs Matemática",
    x = "Proficiência Média (MT)",
    y = "Proficiência Média (LP)",
    color = "Tipo de Escola",
    shape = "Tipo de Escola"
  ) +
  scale_color_manual(values = c("Pública" = "steelblue", "Privada" = "darkred")) +
  scale_shape_manual(values = c("Pública" = 16, "Privada" = 17)) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

ggsave(file.path(DIR_FIGURAS, "scatter_MT_vs_LP.png"),
       plot = p3, width = 8, height = 6, dpi = 300)

cat("   ✓ Scatter 3: MT vs LP\n")

# ============================================================================
# RESUMO FINAL
# ============================================================================

cat("\n" %&% strrep("=", 80) %&% "\n")
cat("ANÁLISE DE DENDROGRAMAS COMPLETA\n")
cat(strrep("=", 80) %&% "\n\n")

cat(sprintf("✅ Dendrogramas gerados! Arquivos salvos em: %s\n\n", DIR_FIGURAS))
cat("Figuras criadas:\n")
cat(sprintf("   • dendrograma_MT_%s.png\n", timestamp))
cat(sprintf("   • dendrograma_LP_%s.png\n", timestamp))
cat(sprintf("   • dendrograma_3D_%s.png\n", timestamp))
cat("   • scatter_MT_vs_INSE.png\n")
cat("   • scatter_LP_vs_INSE.png\n")
cat("   • scatter_MT_vs_LP.png\n\n")
cat(sprintf("Atribuição de clusters: clusters_escolas_%s.csv\n", timestamp))
