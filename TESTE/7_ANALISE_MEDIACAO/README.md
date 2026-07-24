# Fase 8 — Análise de Mediação

Testa se INSE media o efeito de variáveis de contexto sobre a proficiência.

## Execução

```r
source("TESTE/8_ANALISE_MEDIACAO/Scripts/analise_mediacao.r")
```

## Dependências

```r
install.packages(c("mediation", "boot"))
```

## Saídas

| Arquivo | Descrição |
|---------|-----------|
| `outputs/figuras/caminhos_mediacao_MT_*.png` | Figura 21: Diagrama de caminhos (MT) |
| `outputs/figuras/caminhos_mediacao_LP_*.png` | Figura 22: Diagrama de caminhos (LP) |
| `outputs/tabelas/mediacao_*.csv` | Efeitos direto, indireto e total |

## Metodologia

1. **Caminho A**: Variável independente → INSE (mediador)
2. **Caminho B + C'**: INSE + variável independente → Proficiência
3. **Efeito indireto** (A × B): bootstrap com 1000 simulações
4. **Proporção mediada**: |indireto| / |total| × 100

## Análises

- TIPO_ESCOLA → INSE → Proficiência (MT e LP)
- LOCALIZACAO → INSE → Proficiência (MT e LP)
