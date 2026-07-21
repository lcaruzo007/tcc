# Requisitos

Dependências e instalação.

## Sistema

- **R**: >= 4.0.0 (testado em 4.2.0+)
- **RStudio**: Recomendado (opcional)

## Pacotes R

### Instalação rápida

```r
pkgs <- c(
  "tidyverse",    # ggplot2, dplyr, readr, tidyr
  "data.table",   # leitura rápida de CSVs grandes
  "caret",        # nearZeroVar, preprocessamento
  "shiny",        # dashboard interativo (PASSO 3)
  "dendextend",   # dendrogramas
  "ggdendro",     # dendrogramas com ggplot2
  "broom",        # tidy models (PASSO 8-9)
  "patchwork",    # composição de gráficos
  "car",          # VIF, Durbin-Watson
  "lmtest"        # Breusch-Pagan
)
install.packages(pkgs[!pkgs %in% rownames(installed.packages())])
```

### Verificação

```r
sapply(pkgs, require, character.only = TRUE)
# Todos devem retornar TRUE
```

## Versões testadas

| Pacote | Versão mínima |
|--------|---------------|
| tidyverse | 1.3.0 |
| data.table | 1.14.0 |
| caret | 6.0.88 |
| shiny | 1.6.0 |
| dendextend | 1.16.0 |
| ggdendro | 0.1.23 |

## Troubleshooting

| Problema | Solução |
|----------|---------|
| "Pacote X não encontrado" | `install.packages("X")` |
| Erro de compilação | Instalar Rtools (Windows) |
| "namespace X not found" | Reiniciar R e recarregar |
