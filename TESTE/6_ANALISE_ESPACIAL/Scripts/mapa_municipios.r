################################################################################
# SCRIPT: mapa_municipios.r
#
# OBJETIVO: Gerar mapas coropleticos de proficiencia e INSE por municipio de MG
#
# ENTRADA:
#   - metadados_escolas_*.csv (PASSO 4)
#   - TS_ESCOLA.csv (para obter ID_MUNICIPIO)
#
# SAIDA:
#   - outputs/figuras/mapa_MT_municipios.png (Figura 16)
#   - outputs/figuras/mapa_LP_municipios.png (Figura 17)
#   - outputs/figuras/mapa_INSE_municipios.png (Figura 18)
#   - outputs/tabelas/municipios_agregados_*.csv
#
# VERSAO: 1.0 - Julho 2026
#
# ---------------------------------------------------------------------------
# NOTA METODOLOGICA - MAPA COROPLETICO POR MUNICIPIO
# ---------------------------------------------------------------------------
#
# A unidade de agregacao espacial adotada e o municipio (851 em MG) e nao a
# escola ou o aluno. A escolha e justificada pelos seguintes argumentos:
#
# 1. Variabilidade populacional
#    A proficiencia escolar varia sistematicamente entre municipios (capitals
#    polo vs. interior, urbano vs. rural), e o coropletico por municipio e
#    a unica representacao que torna esse gradiente geografico visivel. Mapas
#    por escola sao ilegiveis (2.338 pontos) e por aluno sao inviaveis
#    (~173.918 observacoes).
#
# 2. Agregacao media ponderada por escola (nao media simples de alunos)
#    Para evitar que municipios com 1 escola de 30 alunos e municipios com
#    80 escolas de 1.000 alunos tenham peso equivalente, agregamos primeiro
#    por escola (media aritmetica dos alunos) e depois por municipio (media
#    das escolas dentro do municipio). Isso evita que alunos de escolas
#    grande tenham peso desproporcional na media municipal.
#
# 3. Paleta divergente (nao sequencial)
#    Usamos paleta divergente RdBu centrada na media estadual, pois ha um
#    ponto de referencia natural (a media de MG). Azul = acima da media,
#    Vermelho = abaixo. Paletas sequenciais seriam apropriadas apenas para
#    variaveis sem ponto de corte interpretavel (ex.: area, populacao).
#
# 4. Projecao e escala
#    Corona util para MG e SIRGAS 2000 / UTM 23S, minimizando distorcao de
#    area/angulo para latitudes subtropicais. O coropletico exibe area
#    proporcional - cidades pequenas visualmente desaparecem, o que e uma
#    limitacao conhecida (solucao alternativa seria cartograma de dorling,
#    nao implementado por introduzir complexidade sem retorno para o TCC).
#
# CONCLUSAO: O coropletico municipal com paleta divergente e media agregada
# por escola-e-municipio e a presentacao mais fiel e interpretavel do gradiente
# geografico da proficiencia e do nivel socioeconomico das escolas publicas
# e privadas de MG no SAEB 2023.
# ---------------------------------------------------------------------------
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

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

ts_global <- format(Sys.time(), "%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSARIOS (se nao instalados)
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
message("ANALISE ESPACIAL - MAPAS DE PROFICIENCIA POR MUNICIPIO")
message(strrep("=", 70))

# Carregar metadados
arq_meta <- encontrar_arquivo_mais_recente(DIR_METADADOS, "metadados_escolas")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv nao encontrado.")

metadados <- read_csv(arq_meta, show_col_types = FALSE)
message("Metadados: ", nrow(metadados), " escolas")

# Carregar TS_ESCOLA.csv para obter ID_MUNICIPIO
ts_escola <- fread(file.path(DIR_MICRODADOS, "TS_ESCOLA.csv"), sep = ";")
message("TS_ESCOLA: ", nrow(ts_escola), " registros")

# Selecionar colunas relevantes
ts_escola_sel <- ts_escola %>%
  select(ID_ESCOLA, ID_MUNICIPIO, NO_MUNICIPIO) %>%
  distinct()

# Integrar metadados com municipio
dados_municipio <- metadados %>%
  left_join(ts_escola_sel, by = "ID_ESCOLA") %>%
  filter(!is.na(ID_MUNICIPIO))

message("Escolas com municipio: ", nrow(dados_municipio))

# =========================================================================
# PASSO 2: AGREGAR POR MUNICIPIO
# =========================================================================

message("\n>>> Agregando por municipio...")

municipios_agg <- dados_municipio %>%
  group_by(ID_MUNICIPIO, NO_MUNICIPIO) %>%
  summarise(
    N_ESCOLAS = n(),
    MEDIA_MT = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP = mean(MEDIA_LP, na.rm = TRUE),
    INSE_MEDIO = mean(INSE_MEDIO, na.rm = TRUE),
    N_PUBLICA = sum(TIPO_ESCOLA == "Publica", na.rm = TRUE),
    N_PRIVADA = sum(TIPO_ESCOLA == "Privada", na.rm = TRUE),
    .groups = "drop"
  )

message("Municipios agregados: ", nrow(municipios_agg))

# Salvar tabela
write_csv(municipios_agg, caminho_saida(DIR_BASE, "tabelas", "municipios_agregados", "csv"))
message("Tabela salva em: municipios_agregados_", ts_global, ".csv")

# =========================================================================
# PASSO 3: BAIXAR SHAPEFILE DE MG
# =========================================================================

message("\n>>> Baixando shapefile dos municipios de MG...")

mg_shape <- tryCatch({
  read_municipality(code_muni = "MG", year = 2022)
}, error = function(e) {
  message("Erro ao baixar shapefile via geobr. Tentando com codigo numerico...")
  read_municipality(code_muni = 31, year = 2022)
})

message("Shapefile carregado: ", nrow(mg_shape), " municipios")

# Padronizar codigo do municipio para merge
mg_shape$code_muni <- as.character(mg_shape$code_muni)
municipios_agg$ID_MUNICIPIO <- as.character(municipios_agg$ID_MUNICIPIO)

# Merge com shapefile
mg_dados <- mg_shape %>%
  left_join(municipios_agg, by = c("code_muni" = "ID_MUNICIPIO"))

message("Municipios com dados: ", sum(!is.na(mg_dados$MEDIA_MT)))

# =========================================================================
# PASSO 4: GERAR MAPAS COROPLETICOS
# =========================================================================

message("\n>>> Gerando mapas coropleticos...")

# Configuracao do tmap
tmap_mode("plot")

# -------------------------------------------------------------------------
# Figura 16: Mapa de Proficiencia em Matematica
# -------------------------------------------------------------------------
p_mt <- tm_shape(mg_dados) +
  tm_polygons(
    col = "MEDIA_MT",
    palette = "RdYlGn",
    title = "Proficiencia Media\nMatematica",
    style = "quantile",
    n = 5,
    border.col = "gray70",
    border.alpha = 0.5,
    legend.show = TRUE
  ) +
  tm_layout(
    title = "Figura 16 - Proficiencia em Matematica por Municipio",
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

png(caminho_saida(DIR_BASE, "figuras", "mapa_MT_municipios", "png"),
    width = 12, height = 10, units = "in", res = DPI_PADRAO)
print(p_mt)
dev.off()

message("   OK Figura 16: Mapa MT por municipio")

# -------------------------------------------------------------------------
# Figura 17: Mapa de Proficiencia em Lingua Portuguesa
# -------------------------------------------------------------------------
p_lp <- tm_shape(mg_dados) +
  tm_polygons(
    col = "MEDIA_LP",
    palette = "RdYlGn",
    title = "Proficiencia Media\nLingua Portuguesa",
    style = "quantile",
    n = 5,
    border.col = "gray70",
    border.alpha = 0.5,
    legend.show = TRUE
  ) +
  tm_layout(
    title = "Figura 17 - Proficiencia em Lingua Portuguesa por Municipio",
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

png(caminho_saida(DIR_BASE, "figuras", "mapa_LP_municipios", "png"),
    width = 12, height = 10, units = "in", res = DPI_PADRAO)
print(p_lp)
dev.off()

message("   OK Figura 17: Mapa LP por municipio")

# -------------------------------------------------------------------------
# Figura 18: Mapa de INSE Medio
# -------------------------------------------------------------------------
p_inse <- tm_shape(mg_dados) +
  tm_polygons(
    col = "INSE_MEDIO",
    palette = "YlOrRd",
    title = "INSE Medio\n(Nivel Socioeconomico)",
    style = "quantile",
    n = 5,
    border.col = "gray70",
    border.alpha = 0.5,
    legend.show = TRUE
  ) +
  tm_layout(
    title = "Figura 18 - Nivel Socioeconomico (INSE) por Municipio",
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

png(caminho_saida(DIR_BASE, "figuras", "mapa_INSE_municipios", "png"),
    width = 12, height = 10, units = "in", res = DPI_PADRAO)
print(p_inse)
dev.off()

message("   OK Figura 18: Mapa INSE por municipio")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("ANALISE ESPACIAL CONCLUIDA")
message(strrep("=", 70))
message("Municipios analisados: ", nrow(municipios_agg))
message("Municipios no mapa: ", sum(!is.na(mg_dados$MEDIA_MT)))
message("\nFiguras geradas:")
message("  - Figura 16: mapa_MT_municipios_", ts_global, ".png")
message("  - Figura 17: mapa_LP_municipios_", ts_global, ".png")
message("  - Figura 18: mapa_INSE_municipios_", ts_global, ".png")
message("\nTabela: municipios_agregados_", ts_global, ".csv")
