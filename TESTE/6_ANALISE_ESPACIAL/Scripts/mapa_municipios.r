################################################################################
# SCRIPT: mapa_municipios.r
#
# OBJETIVO: Gerar mapas coropléticos de proficiência e INSE por município de MG
#
# ENTRADA:
#   - metadados_escolas_*.csv (PASSO 4)
#   - TS_ESCOLA.csv (para obter ID_MUNICIPIO)
#
# SAÍDA:
#   - outputs/figuras/mapa_MT_municipios.png (Figura 16)
#   - outputs/figuras/mapa_LP_municipios.png (Figura 17)
#   - outputs/figuras/mapa_INSE_municipios.png (Figura 18)
#   - outputs/tabelas/municipios_agregados_*.csv
#
# VERSÃO: 1.0 — Julho 2026
################################################################################

library(tidyverse)
library(data.table)

# =========================================================================
# CAMINHOS
# =========================================================================

RAIZ <- detectar_raiz()
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_MICRODADOS <- file.path(RAIZ, "MICRODADOS_SAEB_2023/DADOS")
DIR_ANALISE <- file.path(DIR_TESTE, "3_ANALISE_DE_GRUPOS")
DIR_METADADOS <- file.path(DIR_ANALISE, "outputs/metadados")

DIR_BASE <- file.path(DIR_TESTE, "6_ANALISE_ESPACIAL")
DIR_FIGURAS <- file.path(DIR_BASE, "outputs/figuras")
DIR_TABELAS <- file.path(DIR_BASE, "outputs/tabelas")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

dir.create(DIR_FIGURAS, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_TABELAS, showWarnings = FALSE, recursive = TRUE)

ts_global <- format(Sys.time(), "%Y%m%d_%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSÁRIOS (se não instalados)
# =========================================================================

pacotes_necessarios <- c("sf", "geobr", "tmap")
for (pkg in pacotes_necessarios) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Instalando pacote: ", pkg)
    install.packages(pkg, dependencies = TRUE)
  }
}

library(sf)
library(geobr)
library(tmap)

# =========================================================================
# PASSO 1: CARREGAR E INTEGRAR DADOS
# =========================================================================

message(strrep("=", 70))
message("ANÁLISE ESPACIAL — MAPAS DE PROFICIÊNCIA POR MUNICÍPIO")
message(strrep("=", 70))

# Carregar metadados
arq_meta <- encontrar_arquivo_mais_recente(DIR_METADADOS, "metadados_escolas")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv não encontrado.")

metadados <- read_csv(arq_meta, show_col_types = FALSE)
message("Metadados: ", nrow(metadados), " escolas")

# Carregar TS_ESCOLA.csv para obter ID_MUNICIPIO
ts_escola <- fread(file.path(DIR_MICRODADOS, "TS_ESCOLA.csv"), sep = ";")
message("TS_ESCOLA: ", nrow(ts_escola), " registros")

# Selecionar colunas relevantes
ts_escola_sel <- ts_escola %>%
  select(ID_ESCOLA, ID_MUNICIPIO, NO_MUNICIPIO) %>%
  distinct()

# Integrar metadados com município
dados_municipio <- metadados %>%
  left_join(ts_escola_sel, by = "ID_ESCOLA") %>%
  filter(!is.na(ID_MUNICIPIO))

message("Escolas com município: ", nrow(dados_municipio))

# =========================================================================
# PASSO 2: AGREGAR POR MUNICÍPIO
# =========================================================================

message("\n>>> Agregando por município...")

municipios_agg <- dados_municipio %>%
  group_by(ID_MUNICIPIO, NO_MUNICIPIO) %>%
  summarise(
    N_ESCOLAS = n(),
    MEDIA_MT = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP = mean(MEDIA_LP, na.rm = TRUE),
    INSE_MEDIO = mean(INSE_MEDIO, na.rm = TRUE),
    N_PUBLICA = sum(TIPO_ESCOLA == "Pública", na.rm = TRUE),
    N_PRIVADA = sum(TIPO_ESCOLA == "Privada", na.rm = TRUE),
    .groups = "drop"
  )

message("Municípios agregados: ", nrow(municipios_agg))

# Salvar tabela
write_csv(municipios_agg, file.path(DIR_TABELAS, paste0("municipios_agregados_", ts_global, ".csv")))
message("Tabela salva em: municipios_agregados_", ts_global, ".csv")

# =========================================================================
# PASSO 3: BAIXAR SHAPEFILE DE MG
# =========================================================================

message("\n>>> Baixando shapefile dos municípios de MG...")

mg_shape <- tryCatch({
  read_municipality(code_muni = "MG", year = 2022)
}, error = function(e) {
  message("Erro ao baixar shapefile via geobr. Tentando com código numérico...")
  read_municipality(code_muni = 31, year = 2022)
})

message("Shapefile carregado: ", nrow(mg_shape), " municípios")

# Padronizar código do município para merge
mg_shape$code_muni <- as.character(mg_shape$code_muni)
municipios_agg$ID_MUNICIPIO <- as.character(municipios_agg$ID_MUNICIPIO)

# Merge com shapefile
mg_dados <- mg_shape %>%
  left_join(municipios_agg, by = c("code_muni" = "ID_MUNICIPIO"))

message("Municípios com dados: ", sum(!is.na(mg_dados$MEDIA_MT)))

# =========================================================================
# PASSO 4: GERAR MAPAS COROPLÉTICOS
# =========================================================================

message("\n>>> Gerando mapas coropléticos...")

# Configuração do tmap
tmap_mode("plot")

# -------------------------------------------------------------------------
# Figura 16: Mapa de Proficiência em Matemática
# -------------------------------------------------------------------------
p_mt <- tm_shape(mg_dados) +
  tm_polygons(
    col = "MEDIA_MT",
    palette = "RdYlGn",
    title = "Proficiência Média\nMatemática",
    style = "quantile",
    n = 5,
    border.col = "gray70",
    border.alpha = 0.5,
    legend.show = TRUE
  ) +
  tm_layout(
    title = "Figura 16 — Proficiência em Matemática por Município",
    title.size = 1.0,
    title.position = c("center", "top"),
    legend.position = c("right", "bottom"),
    legend.title.size = 0.7,
    legend.text.size = 0.6,
    frame = FALSE,
    bg.color = "white",
    inner.margins = c(0.02, 0.02, 0.08, 0.02)
  ) +
  tm_scale_bar(width = 0.25, position = c("left", "bottom")) +
  tm_compass(position = c("left", "top"), size = 2)

png(file.path(DIR_FIGURAS, paste0("mapa_MT_municipios_", ts_global, ".png")),
    width = 12, height = 10, units = "in", res = DPI_PADRAO)
print(p_mt)
dev.off()

message("   ✓ Figura 16: Mapa MT por município")

# -------------------------------------------------------------------------
# Figura 17: Mapa de Proficiência em Língua Portuguesa
# -------------------------------------------------------------------------
p_lp <- tm_shape(mg_dados) +
  tm_polygons(
    col = "MEDIA_LP",
    palette = "RdYlGn",
    title = "Proficiência Média\nLíngua Portuguesa",
    style = "quantile",
    n = 5,
    border.col = "gray70",
    border.alpha = 0.5,
    legend.show = TRUE
  ) +
  tm_layout(
    title = "Figura 17 — Proficiência em Língua Portuguesa por Município",
    title.size = 1.0,
    title.position = c("center", "top"),
    legend.position = c("right", "bottom"),
    legend.title.size = 0.7,
    legend.text.size = 0.6,
    frame = FALSE,
    bg.color = "white",
    inner.margins = c(0.02, 0.02, 0.08, 0.02)
  ) +
  tm_scale_bar(width = 0.25, position = c("left", "bottom")) +
  tm_compass(position = c("left", "top"), size = 2)

png(file.path(DIR_FIGURAS, paste0("mapa_LP_municipios_", ts_global, ".png")),
    width = 12, height = 10, units = "in", res = DPI_PADRAO)
print(p_lp)
dev.off()

message("   ✓ Figura 17: Mapa LP por município")

# -------------------------------------------------------------------------
# Figura 18: Mapa de INSE Médio
# -------------------------------------------------------------------------
p_inse <- tm_shape(mg_dados) +
  tm_polygons(
    col = "INSE_MEDIO",
    palette = "YlOrRd",
    title = "INSE Médio\n(Nível Socioeconômico)",
    style = "quantile",
    n = 5,
    border.col = "gray70",
    border.alpha = 0.5,
    legend.show = TRUE
  ) +
  tm_layout(
    title = "Figura 18 — Nível Socioeconômico (INSE) por Município",
    title.size = 1.0,
    title.position = c("center", "top"),
    legend.position = c("right", "bottom"),
    legend.title.size = 0.7,
    legend.text.size = 0.6,
    frame = FALSE,
    bg.color = "white",
    inner.margins = c(0.02, 0.02, 0.08, 0.02)
  ) +
  tm_scale_bar(width = 0.25, position = c("left", "bottom")) +
  tm_compass(position = c("left", "top"), size = 2)

png(file.path(DIR_FIGURAS, paste0("mapa_INSE_municipios_", ts_global, ".png")),
    width = 12, height = 10, units = "in", res = DPI_PADRAO)
print(p_inse)
dev.off()

message("   ✓ Figura 18: Mapa INSE por município")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("ANÁLISE ESPACIAL CONCLUÍDA")
message(strrep("=", 70))
message("Municípios analisados: ", nrow(municipios_agg))
message("Municípios no mapa: ", sum(!is.na(mg_dados$MEDIA_MT)))
message("\nFiguras geradas:")
message("  • Figura 16: mapa_MT_municipios_", ts_global, ".png")
message("  • Figura 17: mapa_LP_municipios_", ts_global, ".png")
message("  • Figura 18: mapa_INSE_municipios_", ts_global, ".png")
message("\nTabela: municipios_agregados_", ts_global, ".csv")
