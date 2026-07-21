# Fase 9 — Validação Cruzada + Curva ROC

Avaliação da qualidade preditiva dos modelos via K-fold CV e classificação binária.

## Execução

```r
source("TESTE/9_VALIDACAO_CRUZADA/Scripts/validacao_cruzada.r")
```

## Dependências

```r
install.packages(c("caret", "pROC"))
```

## Saídas

| Arquivo | Descrição |
|---------|-----------|
| `outputs/figuras/roc_curve_MT_*.png` | Figura 23: Curva ROC (MT) |
| `outputs/figuras/roc_curve_LP_*.png` | Figura 24: Curva ROC (LP) |
| `outputs/figuras/cv_metricas_*.png` | Figura 25: Métricas por fold |
| `outputs/tabelas/cv_resultados_*.csv` | Métricas por fold (RMSE, MAE, R²) |
| `outputs/tabelas/cv_resumo_*.csv` | Resumo com AUC e IC 95% |

## Metodologia

### Validação Cruzada (Regressão)
- 10-fold CV estratificado por tipo de escola
- Métricas: RMSE, MAE, R² por fold
- Média e desvio padrão das métricas

### Curva ROC (Classificação)
- Define "alto desempenho" como top 25% de proficiência
- Modelo logístico com preditores: INSE, TIPO_ESCOLA, LOCALIZACAO, AREA
- AUC com IC 95% (bootstrap)

## Interpretação do AUC

- AUC > 0.8: excelente discriminação
- AUC 0.7-0.8: boa discriminação
- AUC 0.6-0.7: discriminação moderada
- AUC < 0.6: discriminação fraca
