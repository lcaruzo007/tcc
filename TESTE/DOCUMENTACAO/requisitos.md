# Requisitos

Dependências e instalação.

## Sistema

- **R**: >= 4.0.0 (testado em 4.2.0+)
- **RStudio**: Recomendado (opcional)

## Pacotes R

### Instalação rápida (todas as fases)

```r
pkgs <- c(
  # Base (PASSO 1-9)
  "tidyverse",    # ggplot2, dplyr, readr, tidyr
  "data.table",   # leitura rápida de CSVs grandes
  "caret",        # nearZeroVar, preprocessamento
  "shiny",        # dashboard interativo (PASSO 3)
  "dendextend",   # dendrogramas
  "ggdendro",     # dendrogramas com ggplot2
  "broom",        # tidy models (PASSO 8-9)
  "patchwork",    # composição de gráficos
  "car",          # VIF, Durbin-Watson
  "lmtest",       # Breusch-Pagan
  
  # Análises avançadas (PASSO 10-15)
  "sf",           # dados espaciais (PASSO 10, 14)
  "geobr",        # shapefiles do Brasil (PASSO 10, 14)
  "tmap",         # mapas temáticos (PASSO 10)
  "lme4",         # modelos hierárquicos (PASSO 11)
  "performance",  # R², ICC (PASSO 11)
  "lmerTest",     # testes para HLM (PASSO 11)
  "mediation",    # análise de mediação (PASSO 12)
  "boot",         # bootstrap (PASSO 12)
  "pROC",         # curva ROC (PASSO 13)
  "spdep",        # Moran's I (PASSO 14)
  "FactoMineR",   # PCA (PASSO 15)
  "factoextra"    # visualização PCA (PASSO 15)
)
install.packages(pkgs[!pkgs %in% rownames(installed.packages())])
```

### Verificação

```r
sapply(pkgs, require, character.only = TRUE)
# Todos devem retornar TRUE
```

## Versões testadas

| Pacote | Versão mínima | Fase |
|--------|---------------|------|
| tidyverse | 1.3.0 | 1-9 |
| data.table | 1.14.0 | 1-9 |
| caret | 6.0.88 | 1-9 |
| shiny | 1.6.0 | 3 |
| dendextend | 1.16.0 | 3, 7 |
| ggdendro | 0.1.23 | 3, 7 |
| sf | 1.0.0 | 10, 14 |
| geobr | 1.5.0 | 10, 14 |
| tmap | 3.0 | 10 |
| lme4 | 1.1.27 | 11 |
| performance | 0.8.0 | 11 |
| lmerTest | 3.1.3 | 11 |
| mediation | 4.5.0 | 12 |
| boot | 1.3.28 | 12 |
| pROC | 1.18.0 | 13 |
| spdep | 1.2.0 | 14 |
| FactoMineR | 2.8.0 | 15 |
| factoextra | 1.0.7 | 15 |

## Troubleshooting

| Problema | Solução |
|----------|---------|
| "Pacote X não encontrado" | `install.packages("X")` |
| Erro de compilação | Instalar Rtools (Windows) |
| "namespace X not found" | Reiniciar R e recarregar |
| Erro ao baixar shapefile | Verificar conexão com internet |
| Erro em `geobr` | Tentar `code_muni = 31` em vez de `"MG"` |
