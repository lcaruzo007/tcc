# Fase 7 — Modelos Hierárquicos Lineares (HLM)

Modelos multinível para dados aninhados (alunos dentro de escolas).

## Execução

```r
source("TESTE/7_MODELOS_HIERARQUICOS/Scripts/modelos_hierarquicos.r")
```

## Dependências

```r
install.packages(c("lme4", "performance", "lmerTest"))
```

## Saídas

| Arquivo | Descrição |
|---------|-----------|
| `outputs/figuras/icc_varianca_*.png` | Figura 19: Decomposição da variância (ICC) |
| `outputs/figuras/efeitos_aleatorios_*.png` | Figura 20: Efeitos aleatórios por escola |
| `outputs/tabelas/icc_*.csv` | Coeficiente de correlação intraclasse |
| `outputs/tabelas/resumo_hlm_*.csv` | Comparação de modelos (AIC, BIC, R²) |

## Metodologia

1. **Modelo Nulo**: Intercepto aleatório por escola → calcula ICC
2. **Modelo 1**: INSE_ALUNO como preditor fixo + intercepto aleatório
3. **Modelo 2**: INSE individual + INSE médio da escola
4. Comparação via Likelihood Ratio Test (ANOVA)
5. R² marginal (efeitos fixos) e condicional (fixos + aleatórios)

## Interpretação do ICC

- ICC > 20%: estrutura hierárquica forte — HLM necessário
- ICC 10-20%: moderado — HLM recomendado
- ICC < 10%: estrutura hierárquica fraca
