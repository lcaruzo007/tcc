# 6. Análise de Mediação (PASSO 10)

Testa se o INSE media o efeito de variáveis de contexto (tipo de escola, área/localização) sobre a proficiência.

## Execução

```r
source("TESTE/6_ANALISE_MEDIACAO/Scripts/analise_mediacao.r")
```

## Pré-requisitos

- `metadados_escolas_*.csv` gerado pelo PASSO 4 (`3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r`)
- Pacotes R: `tidyverse`, `data.table`, `mediation`, `boot`

```r
install.packages(c("mediation", "boot"))
```

## Saídas (pastas datadas)

> Saídas via `caminho_saida()` em `6_ANALISE_MEDIACAO/outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>`.

| Arquivo | Descrição |
|---------|-----------|
| `outputs/<data>/tabelas/mediacao_*.csv` | Efeitos direto, indireto e total + proporção mediada |
| `outputs/<data>/figuras/caminhos_mediacao_MT_*.png` | Figura 21: Diagrama de caminhos (MT) |
| `outputs/<data>/figuras/caminhos_mediacao_LP_*.png` | Figura 22: Diagrama de caminhos (LP) |

## Metodologia

1. **Caminho A**: Variável independente → INSE (mediador)
2. **Caminho B + C'**: INSE + variável independente → Proficiência
3. **Efeito indireto** (A × B): bootstrap BCa com 1000 simulações (Preacher & Hayes, 2008)
4. **Proporção mediada**: |indireto| / |total| × 100

Base teórica: Baron & Kenny (1986), estendida por Preacher & Hayes. Detalhes no bloco `NOTA METODOLOGICA - MEDIACAO COM INSE` no cabeçalho do script.

## Análises

- `TIPO_ESCOLA` → INSE → Proficiência (MT e LP; referência: Pública)
- `AREA_LOCAL` → INSE → Proficiência (MT e LP; 3 dummies — `Rural_Interior`, `Rural_Capital`, `Urbana_Interior` — com referência `Urbana_Capital`, capturando a interação urbano/rural × capital/interior)

Tabela `mediacao_*.csv` consolida 8 linhas: 2 (TIPO_ESCOLA × {MT,LP}) + 6 (3 dummies de AREA_LOCAL × {MT,LP}).
