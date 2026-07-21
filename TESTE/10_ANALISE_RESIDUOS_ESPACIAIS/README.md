# Fase 10 — Análise de Resíduos Espaciais

Teste de autocorrelação espacial nos resíduos do modelo (Índice de Moran).

## Execução

```r
source("TESTE/10_ANALISE_RESIDUOS_ESPACIAIS/Scripts/analise_residuos_espaciais.r")
```

## Dependências

```r
install.packages(c("sf", "geobr", "spdep"))
```

## Saídas

| Arquivo | Descrição |
|---------|-----------|
| `outputs/figuras/moran_scatterplot_MT_*.png` | Figura 26: Scatterplot de Moran (MT) |
| `outputs/figuras/moran_scatterplot_LP_*.png` | Figura 27: Scatterplot de Moran (LP) |
| `outputs/figuras/lisa_cluster_MT_*.png` | Figura 28: Clusters LISA (MT) |
| `outputs/tabelas/moran_resultados_*.csv` | Índice de Moran + p-valor |

## Metodologia

1. Agrega resíduos por município (média dos resíduos das escolas)
2. Cria matriz de vizinhança (queen contiguity) via `poly2nb()`
3. Calcula Moran's I global para resíduos MT e LP
4. Calcula LISA (Local Indicators of Spatial Association)
5. Classifica municípios em quadrantes: Alto-Alto, Baixo-Baixo, Alto-Baixo, Baixo-Alto

## Interpretação

- Moran's I > 0 e p < 0.05: autocorrelação positiva (clusters espaciais)
- Moran's I ≈ 0: resíduos independentes (modelo adequado)
- Moran's I < 0: padrão alternado (raro em dados socioeconômicos)
