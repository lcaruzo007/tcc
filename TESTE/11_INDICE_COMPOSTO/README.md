# Fase 11 — Índice Composto de Vulnerabilidade (PCA)

Criação de indicador próprio combinando variáveis socioeconômicas e de proficiência.

## Execução

```r
source("TESTE/11_INDICE_COMPOSTO/Scripts/indice_composto.r")
```

## Dependências

```r
install.packages(c("FactoMineR", "factoextra"))
```

## Saídas

| Arquivo | Descrição |
|---------|-----------|
| `outputs/figuras/pca_scree_*.png` | Figura 29: Scree plot (variância por componente) |
| `outputs/figuras/pca_biplot_*.png` | Figura 30: Biplot PCA (variáveis + escolas) |
| `outputs/figuras/indice_mapa_distribuicao_*.png` | Figura 31: Distribuição do índice |
| `outputs/tabelas/indice_composto_*.csv` | Scores por escola (IC 0-100) |
| `outputs/tabelas/pca_contribuicoes_*.csv` | Contribuição de cada variável |

## Metodologia

1. Inverte variáveis (menor proficiência = maior vulnerabilidade)
2. Padroniza todas as variáveis (z-score)
3. Executa PCA com 5 componentes
4. Retém componentes até explicar ≥ 80% da variância
5. PC1 como índice composto (maior variância explicada)
6. Normaliza para escala 0-100
7. Classifica em 4 níveis: Muito Baixa, Baixa, Alta, Muito Alta

## Variáveis no PCA

- INV_MT: -MEDIA_MT (inverso da proficiência MT)
- INV_LP: -MEDIA_LP (inverso da proficiência LP)
- INV_INSE: -INSE_MEDIO (inverso do INSE)
- TIPO_PRIVADA: escola privada (0/1)
- LOCAL_RURAL: escola rural (0/1)
