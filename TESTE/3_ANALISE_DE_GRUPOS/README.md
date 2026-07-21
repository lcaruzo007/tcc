# Análise de Grupos (Inter-Escolas)

Scripts para análise de GRUPOS de escolas — comparações estatísticas e clustering.

## Scripts

| Script | Passo | Descrição |
|--------|-------|-----------|
| `classificar_escolas.r` | 4 | Agrega dados por escola, cria metadados |
| `comparar_grupos.r` | 5 | Testes estatísticos entre grupos |
| `comparar_duas_escolas.r` | 6 | Comparação lado a lado de 2 escolas (opcional) |
| `dendrograma_analise_completa.r` | 7 | Clustering hierárquico |

## Execução

```r
# PASSO 4 (necessário antes dos outros)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r")

# PASSO 5
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_grupos.r")

# PASSO 6 (opcional — altere IDs no topo do script)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_duas_escolas.r")

# PASSO 7
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_analise_completa.r")
```

## Outputs

```
outputs/
├── metadados/
│   ├── metadados_escolas_YYYYMMDD_HHMMSS.csv    (perfil de cada escola)
│   ├── resultados_comparacao_YYYYMMDD_HHMMSS.csv (testes Wilcoxon)
│   └── clusters_escolas_YYYYMMDD_HHMMSS.csv     (atribuição de clusters)
│
├── comparacoes/
│   └── Escola_{A}_vs_{B}_{timestamp}/
│       ├── Comparacao_Escola_A_vs_B_*.csv
│       ├── Perfis_Escolas_*.csv
│       └── visualizacao_comparacao_*.png
│
└── figuras/
    ├── 01_boxplot_tipo_escola.png
    ├── 02_boxplot_urbano_rural.png
    ├── 03_boxplot_capital_interior.png
    ├── 04_boxplot_inse.png
    ├── dendrograma_geral_ALTO_BAIXO_*.png
    ├── tabela_escolas_ALTO_BAIXO_*.csv
    ├── capital_vs_interior/
    ├── publica_vs_particular/
    └── urbana_vs_rural/
```

## Comparações realizadas (PASSO 5)

| Grupo A | Grupo B | Objetivo |
|---------|---------|----------|
| Pública | Privada | Tipo de escola influencia proficiência? |
| Urbana | Rural | Localização importa? |
| Capital | Interior | Proximidade da capital afeta resultado? |
| Alto INSE | Baixo INSE | Nível socioeconômico é determinante? |

**Nota:** Cada comparação é feita em **ambas as direções** (ex: Pública→Privada E Privada→Pública), gerando 16 linhas na tabela de resultados (8 comparações × 2 disciplinas).

### Teste estatístico
- **Wilcoxon** (não-paramétrico, não assume normalidade)
- **Tamanho de efeito**: rank-biserial r (0.0 a 1.0)
  - 0.1-0.3: pequeno
  - 0.3-0.5: médio
  - >0.5: grande

## Clustering (PASSO 7)

### Dendrograma geral
- Filtra escolas ALTO (>=P75) e BAIXO (<=P25) desempenho
- Remove INTERMEDIÁRIO
- Método: Ward.D2, distância euclidiana
- Colorido por tipo: Azul=Pública, Vermelho=Privada

### Interpretação
- Ramos próximos = escolas similares
- Distância < 1.0 = muito similares
- Distância > 2.0 = bem diferentes
