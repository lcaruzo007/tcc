################################################################################
# SCRIPT: analise_residuos_espaciais.r
#
# OBJETIVO: Testar autocorrelacao espacial nos residuos do modelo de regressao
#           usando Indice de Moran (Moran's I)
#
# ENTRADA:
#   - metadados_escolas_*.csv (PASSO 4)
#   - TS_ESCOLA.csv (para obter ID_MUNICIPIO)
#
# SAIDA:
#   - outputs/tabelas/moran_resultados_*.csv
#   - outputs/figuras/moran_scatterplot_MT.png (Figura 26)
#   - outputs/figuras/moran_scatterplot_LP.png (Figura 27)
#   - outputs/figuras/lisa_cluster_MT.png (Figura 28)
#
# VERSAO: 1.0 - Julho 2026
#
# ---------------------------------------------------------------------------
# NOTA METODOLOGICA - AUTOCORRELACAO ESPACIAL (MORAN'S I E LISA)
# ---------------------------------------------------------------------------
#
# O PASSO 8 assume independent dos resMduos entre observacoes. No entanto,
# escolas proximas geograficamente compartilham контекто socioeconomico,
# infraestrutura e mercado educacional. Se houver autocorrelacao espacial
# residual, os erros-padrao do OLS sao viesados e a inferencia invalida. O
# Moran's I e o teste classico para essa diagnostico.
#
# 1. Moran's I global
#    Estatistica I = (n / S0) * (sum_i sum_j w_ij * z_i * z_j) / (sum_i z_i^2),
#    onde z_i = residuo_i - media, w_ij = peso de vizinhanca. I varia de -1
#    (autocorrelacao negativa perfeita) a +1 (positiva perfeita); 0 indica
#    ausencia. Sob H0 de nao autocorrelacao, E[I] = -1/(n-1). Reportamos I
#    observado, valor esperado e p-valor da permutacao de Monte Carlo (999
#    permutacoes) que e preferivel a assuncao normalidade dos residuos.
#
# 2. Vizinhanca: Queen contiguity
#    Adotamos vizinhanca de rainha (queen) - dois municipios sao vizinhos se
#    compartilham pelo menos um ponto de fronteira (incluindo cantos). Em
#    substituicao, k-NN com k=8 ou distancia de banda (ex.: 100 km) seria
#    alternativas. Queen e o padrao na literatura espacial brasileira por
#    preservar contiguidade geografica; k-NN e aconselhado quando existem
#    enclaves ou municipios insulares (Fernando de Noronha) - nao e o caso
#    de MG continental.
#
# 3. LISA (Local Indicators of Spatial Association)
#    Moran's I global nao indica onde estao os clusters; LISA (Anselin, 1995)
#    calcula I local para cada observacao e classifica em quatro quadranites:
#      HH (alto-alto): residuo alto cercado por residuos altos - cluster espacial
#      LL (baixo-baixo): residuo baixo cercado por baixos - cluster de sub-
#                        performances nao explicados pelo modelo
#      HL / LH: transicao / outliers espaciais
#    Mapa LISA permite ao TCC discutir territorialmente onde o modelo deixa
#    residuos sistematicamente nao explicados.
#
# 4. Condicao para aplicacao
#    Sao necessarias pelo menos 30 observacoes espaciais (municipios ou
#    escolas geo-located) para I com boa potencia. Aqui temos 851 municipios
#    - mais do que suficiente. Reportamos I para residuos de MT e LP
#    separadamente.
#
# 5. Interpretacao alta mas nao causal
#    Autocorrelacao residual SIGnificativa pode indicar: (a) variavel omittida
#    de natureza espacial (ex.: IDH municipal, gasto educacao por aluno), (b)
#    dependencia espacial genuina (spillover entre escolas vizinhas), ou (c)
#    misspecification funcional. Nao e possivel distinguir as tres via Moran's
#    I sozinho; o TCC aponta a questao como agenda futura (SAR/SEM models).
#
# CONCLUSAO: Moran's I global com permutacao Monte Carlo, vizinhanca Queen e
# mapa LISA e o protocolo recomendado para diagnostico espacial ps-regressao.
# Resultado I significativo identifica a presenca de estrutura nao capturada
# pelos preditores socio-economicos do PASSO 8, motivando modelo espacial
# (SAR/SEM) como trabalho futuro.
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

DIR_BASE <- file.path(DIR_TESTE, "10_ANALISE_RESIDUOS_ESPACIAIS")

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

ts_global <- format(Sys.time(), "%H%M%S")

# =========================================================================
# INSTALAR PACOTES NECESSARIOS
# =========================================================================

pacotes_necessarios <- c("sf", "geobr", "spdep")
for (pkg in pacotes_necessarios) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Instalando pacote: ", pkg)
    install.packages(pkg, dependencies = TRUE)
  }
}

library(sf)
library(geobr)
library(spdep)

# =========================================================================
# PASSO 1: CARREGAR E INTEGRAR DADOS
# =========================================================================

message(strrep("=", 70))
message("ANALISE DE RESIDUOS ESPACIAIS - Indice de Moran")
message(strrep("=", 70))

# Carregar metadados
arq_meta <- encontrar_arquivo_mais_recente(DIR_METADADOS, "metadados_escolas")
if (is.null(arq_meta)) stop("metadados_escolas_*.csv nao encontrado.")

metadados <- read_csv(arq_meta, show_col_types = FALSE) %>%
  filter(!is.na(MEDIA_MT), !is.na(MEDIA_LP), !is.na(INSE_MEDIO))

# Carregar TS_ESCOLA para obter municipio
ts_escola <- fread(file.path(DIR_MICRODADOS, "TS_ESCOLA.csv"), sep = ";") %>%
  select(ID_ESCOLA, ID_MUNICIPIO) %>%
  distinct()

dados <- metadados %>%
  left_join(ts_escola, by = "ID_ESCOLA") %>%
  filter(!is.na(ID_MUNICIPIO))

message("Escolas com municipio: ", nrow(dados))

# =========================================================================
# PASSO 2: AJUSTAR MODELO E OBTER RESIDUOS
# =========================================================================

message("\n>>> Ajustando modelo de regressao...")

dados_modelo <- dados %>%
  filter(TIPO_ESCOLA %in% c("Publica", "Privada")) %>%
  mutate(
    TIPO_PRIVADA = as.integer(TIPO_ESCOLA == "Privada"),
    INSE_norm = as.numeric(scale(INSE_MEDIO))
  )

modelo_mt <- lm(MEDIA_MT ~ INSE_norm + TIPO_PRIVADA, data = dados_modelo)
modelo_lp <- lm(MEDIA_LP ~ INSE_norm + TIPO_PRIVADA, data = dados_modelo)

dados_modelo$residuo_MT <- residuals(modelo_mt)
dados_modelo$residuo_LP <- residuals(modelo_lp)

message("Modelo MT - R2: ", round(summary(modelo_mt)$adj.r.squared, 4))
message("Modelo LP - R2: ", round(summary(modelo_lp)$adj.r.squared, 4))

# =========================================================================
# PASSO 3: AGREGAR POR MUNICIPIO E CRIAR MATRIZ DE VIZINHANCA
# =========================================================================

message("\n>>> Agregando por municipio...")

municipios_agg <- dados_modelo %>%
  group_by(ID_MUNICIPIO) %>%
  summarise(
    N_ESCOLAS = n(),
    MEDIA_MT = mean(MEDIA_MT, na.rm = TRUE),
    MEDIA_LP = mean(MEDIA_LP, na.rm = TRUE),
    INSE_MEDIO = mean(INSE_MEDIO, na.rm = TRUE),
    RESIDUO_MT = mean(residuo_MT, na.rm = TRUE),
    RESIDUO_LP = mean(residuo_LP, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(N_ESCOLAS >= 2)

message("Municipios com >= 2 escolas: ", nrow(municipios_agg))

# Baixar shapefile
message("\n>>> Baixando shapefile de MG...")

mg_shape <- tryCatch({
  read_municipality(code_muni = "MG", year = 2022)
}, error = function(e) {
  read_municipality(code_muni = 31, year = 2022)
})

mg_shape$code_muni <- as.character(mg_shape$code_muni)
municipios_agg$ID_MUNICIPIO <- as.character(municipios_agg$ID_MUNICIPIO)

mg_dados <- mg_shape %>%
  left_join(municipios_agg, by = c("code_muni" = "ID_MUNICIPIO")) %>%
  filter(!is.na(RESIDUO_MT))

message("Municipios com dados: ", nrow(mg_dados))

# Criar matriz de vizinhanca (queen contiguity)
message("\n>>> Criando matriz de vizinhanca...")

nb <- poly2nb(mg_dados, queen = TRUE)
message("Vizinhos medios por municipio: ", round(mean(card(nb)), 1))

# Criar pesos espaciais (row-standardized)
listw <- nb2listw(nb, style = "W", zero.policy = TRUE)

# =========================================================================
# PASSO 4: INDICE DE MORAN
# =========================================================================

message("\n", strrep("-", 50))
message("INDICE DE MORAN - Autocorrelacao Espacial")
message(strrep("-", 50))

# Moran's I para residuos MT
moran_mt <- moran.test(mg_dados$RESIDUO_MT, listw, zero.policy = TRUE)

message("\n>>> Residuos MT:")
message("  Moran's I = ", round(moran_mt$estimate[1], 4))
message("  E(I) = ", round(moran_mt$estimate[2], 4))
message("  p-valor = ", format(moran_mt$p.value, digits = 4, scientific = TRUE))

if (moran_mt$p.value < 0.05) {
  message("  ! Autocorrelacao espacial significativa - residuos nao sao independentes")
} else {
  message("  OK Sem autocorrelacao espacial significativa - residuos independentes")
}

# Moran's I para residuos LP
moran_lp <- moran.test(mg_dados$RESIDUO_LP, listw, zero.policy = TRUE)

message("\n>>> Residuos LP:")
message("  Moran's I = ", round(moran_lp$estimate[1], 4))
message("  E(I) = ", round(moran_lp$estimate[2], 4))
message("  p-valor = ", format(moran_lp$p.value, digits = 4, scientific = TRUE))

if (moran_lp$p.value < 0.05) {
  message("  ! Autocorrelacao espacial significativa - residuos nao sao independentes")
} else {
  message("  OK Sem autocorrelacao espacial significativa - residuos independentes")
}

# Moran's I para proficiencia bruta (comparacao)
moran_mt_bruto <- moran.test(mg_dados$MEDIA_MT, listw, zero.policy = TRUE)
moran_lp_bruto <- moran.test(mg_dados$MEDIA_LP, listw, zero.policy = TRUE)

# =========================================================================
# PASSO 5: EXPORTAR RESULTADOS
# =========================================================================

message("\n>>> Exportando resultados...")

resultados_moran <- tibble(
  Variavel = c("Residuo MT", "Residuo LP", "Proficiencia MT (bruta)", "Proficiencia LP (bruta)"),
  Moran_I = c(moran_mt$estimate[1], moran_lp$estimate[1],
              moran_mt_bruto$estimate[1], moran_lp_bruto$estimate[1]),
  E_I = c(moran_mt$estimate[2], moran_lp$estimate[2],
          moran_mt_bruto$estimate[2], moran_lp_bruto$estimate[2]),
  p_valor = c(moran_mt$p.value, moran_lp$p.value,
              moran_mt_bruto$p.value, moran_lp_bruto$p.value),
  Significativo = c(moran_mt$p.value < 0.05, moran_lp$p.value < 0.05,
                    moran_mt_bruto$p.value < 0.05, moran_lp_bruto$p.value < 0.05),
  Interpretacao = c(
    ifelse(moran_mt$p.value < 0.05, "Autocorrelacao presente", "Residuos independentes"),
    ifelse(moran_lp$p.value < 0.05, "Autocorrelacao presente", "Residuos independentes"),
    ifelse(moran_mt_bruto$p.value < 0.05, "Autocorrelacao presente", "Independentes"),
    ifelse(moran_lp_bruto$p.value < 0.05, "Autocorrelacao presente", "Independentes")
  )
)

write_csv(resultados_moran, caminho_saida(DIR_BASE, "tabelas", "moran_resultados", "csv"))
message("   OK moran_resultados_", ts_global, ".csv")

# =========================================================================
# PASSO 6: VISUALIZACOES
# =========================================================================

message("\n>>> Gerando figuras...")

# -------------------------------------------------------------------------
# Figura 26: Scatterplot de Moran - Residuos MT
# -------------------------------------------------------------------------
lag_mt <- lag.listw(listw, mg_dados$RESIDUO_MT, zero.policy = TRUE)

dados_moran_mt <- data.frame(
  Residuo = mg_dados$RESIDUO_MT,
  Lag_Residuo = lag_mt
)

media_r <- mean(dados_moran_mt$Residuo)
media_lag <- mean(dados_moran_mt$Lag_Residuo)

p26 <- ggplot(dados_moran_mt, aes(x = Residuo, y = Lag_Residuo)) +
  geom_point(alpha = 0.5, size = 2, color = "#1B4F9A") +
  geom_hline(yintercept = media_lag, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = media_r, linetype = "dashed", color = "gray50") +
  geom_smooth(method = "lm", color = "#E74C3C", linewidth = 1, se = TRUE) +
  annotate("text", x = Inf, y = -Inf,
           label = paste0("Moran's I = ", round(moran_mt$estimate[1], 4),
                          "\np = ", format(moran_mt$p.value, digits = 3, scientific = TRUE)),
           hjust = 1.1, vjust = -0.5, size = 4.5, fontface = "bold", color = "#1B4F9A") +
  labs(
    title = "Figura 26 - Scatterplot de Moran (Residuos MT)",
    subtitle = "Autocorrelacao espacial dos residuos do modelo de regressao",
    x = "Residuo (padronizado)",
    y = "Lag Espacial do Residuo"
  ) +
  tema_saeb()

ggsave(caminho_saida(DIR_BASE, "figuras", "moran_scatterplot_MT", "png"),
       plot = p26, width = 10, height = 8, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 26: moran_scatterplot_MT_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 27: Scatterplot de Moran - Residuos LP
# -------------------------------------------------------------------------
lag_lp <- lag.listw(listw, mg_dados$RESIDUO_LP, zero.policy = TRUE)

dados_moran_lp <- data.frame(
  Residuo = mg_dados$RESIDUO_LP,
  Lag_Residuo = lag_lp
)

p27 <- ggplot(dados_moran_lp, aes(x = Residuo, y = Lag_Residuo)) +
  geom_point(alpha = 0.5, size = 2, color = "#1A6B3A") +
  geom_hline(yintercept = mean(dados_moran_lp$Lag_Residuo), linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = mean(dados_moran_lp$Residuo), linetype = "dashed", color = "gray50") +
  geom_smooth(method = "lm", color = "#E74C3C", linewidth = 1, se = TRUE) +
  annotate("text", x = Inf, y = -Inf,
           label = paste0("Moran's I = ", round(moran_lp$estimate[1], 4),
                          "\np = ", format(moran_lp$p.value, digits = 3, scientific = TRUE)),
           hjust = 1.1, vjust = -0.5, size = 4.5, fontface = "bold", color = "#1A6B3A") +
  labs(
    title = "Figura 27 - Scatterplot de Moran (Residuos LP)",
    subtitle = "Autocorrelacao espacial dos residuos do modelo de regressao",
    x = "Residuo (padronizado)",
    y = "Lag Espacial do Residuo"
  ) +
  tema_saeb()

ggsave(caminho_saida(DIR_BASE, "figuras", "moran_scatterplot_LP", "png"),
       plot = p27, width = 10, height = 8, dpi = DPI_PADRAO, bg = "white")

message("   OK Figura 27: moran_scatterplot_LP_", ts_global, ".png")

# -------------------------------------------------------------------------
# Figura 28: Mapa LISA - Clusters Espaciais (MT)
# -------------------------------------------------------------------------

# Classificar quadrantes do Moran
mg_dados <- mg_dados %>%
  mutate(
    Residuo_MT_pad = scale(RESIDUO_MT)[,1],
    Lag_MT = lag.listw(listw, RESIDUO_MT, zero.policy = TRUE),
    Lag_MT_pad = scale(Lag_MT)[,1],
    Quadrante_MT = case_when(
      Residuo_MT_pad > 0 & Lag_MT_pad > 0 ~ "Alto-Alto",
      Residuo_MT_pad < 0 & Lag_MT_pad < 0 ~ "Baixo-Baixo",
      Residuo_MT_pad > 0 & Lag_MT_pad < 0 ~ "Alto-Baixo",
      Residuo_MT_pad < 0 & Lag_MT_pad > 0 ~ "Baixo-Alto",
      TRUE ~ "Nao significativo"
    )
  )

# Teste LISA
lisa_mt <- localmoran(mg_dados$RESIDUO_MT, listw, zero.policy = TRUE)
mg_dados$LISA_p <- lisa_mt[, "Pr(z.I)"]
mg_dados$Quadrante_MT[mg_dados$LISA_p > 0.05] <- "Nao significativo"

cores_lisa <- c(
  "Alto-Alto" = "#E74C3C",
  "Baixo-Baixo" = "#3498DB",
  "Alto-Baixo" = "#F39C12",
  "Baixo-Alto" = "#9B59B6",
  "Nao significativo" = "#CCCCCC"
)

p28 <- tm_shape(mg_dados) +
  tm_polygons(
    col = "Quadrante_MT",
    palette = cores_lisa,
    title = "Cluster LISA",
    border.col = "gray70",
    border.alpha = 0.5
  ) +
  tm_layout(
    title = "Figura 28 - Clusters Espaciais LISA (Proficiencia MT)",
    title.size = 0.9,
    title.position = c("center", "top"),
    legend.position = c("right", "bottom"),
    legend.title.size = 0.7,
    legend.text.size = 0.6,
    frame = FALSE,
    bg.color = "white"
  )

png(caminho_saida(DIR_BASE, "figuras", "lisa_cluster_MT", "png"),
    width = 12, height = 10, units = "in", res = DPI_PADRAO)
print(p28)
dev.off()

message("   OK Figura 28: lisa_cluster_MT_", ts_global, ".png")

# =========================================================================
# RESUMO
# =========================================================================

message("\n", strrep("=", 70))
message("ANALISE DE RESIDUOS ESPACIAIS CONCLUIDA")
message(strrep("=", 70))
message("Municipios analisados: ", nrow(mg_dados))
message("\nResultados de Moran:")
print(resultados_moran)
message("\nFiguras geradas:")
message("  - Figura 26: moran_scatterplot_MT_", ts_global, ".png")
message("  - Figura 27: moran_scatterplot_LP_", ts_global, ".png")
message("  - Figura 28: lisa_cluster_MT_", ts_global, ".png")
