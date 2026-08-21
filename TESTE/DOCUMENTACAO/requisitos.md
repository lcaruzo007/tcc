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
  
  # Mediação (PASSO 10)
  "mediation",    # análise de mediação bootstrap
  "boot"          # bootstrap
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
| broom | 0.8.0 | 8-9 |
| patchwork | 1.1.0 | 8-9 |
| car | 3.1.0 | 8-9 |
| lmtest | 0.9.0 | 8-9 |
| mediation | 4.5.0 | 10 |
| boot | 1.3.28 | 10 |

## Troubleshooting

| Problema | Solução |
|----------|---------|
| "Pacote X não encontrado" | `install.packages("X")` |
| Erro de compilação | Instalar Rtools (Windows) |
| "namespace X not found" | Reiniciar R e recarregar |
