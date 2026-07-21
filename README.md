# TCC: Impacto Socioeconômico na Proficiência SAEB 2023

Análise estatística dos microdados do SAEB 2023 — Minas Gerais.

## Contexto

- **Dados**: 173.918 alunos, 2.338 escolas, 851 municípios de MG
- **Disciplinas**: Matemática (MT) e Língua Portuguesa (LP)
- **Foco**: Relação entre variáveis socioeconômicas e proficiência

## Estrutura

```
tcc/
├── README.md                    (este arquivo)
├── diario.md                    (registro de desenvolvimento)
├── refs/                        (PDFs de referência)
├── MICRODADOS_SAEB_2023/        (dados brutos do INEP)
│
└── TESTE/
    ├── DOCUMENTACAO/
    │   ├── README.md            (guia de uso)
    │   ├── metodologia.md       (base para o TCC)
    │   ├── referencia_outputs.md (dicionário de dados)
    │   ├── requisitos.md        (dependências R)
    │   └── utils_saeb.r         (funções compartilhadas)
    │
    ├── 1_LIMPEZA_E_TRANSFORMACAO/    (PASSO 1)
    ├── 2_ANALISE_POR_ESCOLA/         (PASSO 2-3)
    ├── 3_ANALISE_DE_GRUPOS/          (PASSO 4-7)
    ├── 4_REGRESSAO_LINEAR/           (PASSO 8)
    ├── 5_REGRESSAO_ITENS_BRUTOS/     (PASSO 9)
    ├── 6_ANALISE_ESPACIAL/           (PASSO 10 — mapas)
    ├── 7_MODELOS_HIERARQUICOS/       (PASSO 11 — HLM)
    ├── 8_ANALISE_MEDIACAO/           (PASSO 12 — mediação)
    ├── 9_VALIDACAO_CRUZADA/          (PASSO 13 — CV + ROC)
    ├── 10_ANALISE_RESIDUOS_ESPACIAIS/(PASSO 14 — Moran's I)
    └── 11_INDICE_COMPOSTO/           (PASSO 15 — PCA)
```

## Pipeline de Execução

### Fase 1: Limpeza e Correlações (PASSO 1-3)

```r
source("TESTE/1_LIMPEZA_E_TRANSFORMACAO/ajeitar_dados.r")
source("TESTE/2_ANALISE_POR_ESCOLA/Scripts/correlacao.r")
shiny::runApp("TESTE/2_ANALISE_POR_ESCOLA/Scripts/graficos.r")  # opcional
```

### Fase 2: Análise de Grupos (PASSO 4-7)

```r
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r")
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_grupos.r")
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_duas_escolas.r")  # opcional
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_analise_completa.r")
```

### Fase 3: Modelagem Preditiva (PASSO 8-9)

```r
source("TESTE/4_REGRESSAO_LINEAR/Scripts/regressao_linear_multipla.r")
source("TESTE/5_REGRESSAO_ITENS_BRUTOS/Scripts/regressao_itens_brutos_dummy.r")
```

### Fase 4: Análises Avançadas (PASSO 10-15)

```r
source("TESTE/6_ANALISE_ESPACIAL/Scripts/mapa_municipios.r")
source("TESTE/7_MODELOS_HIERARQUICOS/Scripts/modelos_hierarquicos.r")
source("TESTE/8_ANALISE_MEDIACAO/Scripts/analise_mediacao.r")
source("TESTE/9_VALIDACAO_CRUZADA/Scripts/validacao_cruzada.r")
source("TESTE/10_ANALISE_RESIDUOS_ESPACIAIS/Scripts/analise_residuos_espaciais.r")
source("TESTE/11_INDICE_COMPOSTO/Scripts/indice_composto.r")
```

## Resumo das Análises

| # | Fase | O que faz | Figuras |
|---|------|-----------|---------|
| 1 | Limpeza | Transforma variáveis A/B/C → números | — |
| 2 | Correlações | Spearman/Pearson por escola | — |
| 3 | Dashboard | Shiny interativo (opcional) | — |
| 4 | Metadados | Agrega por escola | — |
| 5 | Comparações | Wilcoxon entre grupos | Figuras 1-4 |
| 6 | 2 escolas | Comparação lado a lado | Figura 5 |
| 7 | Clustering | Dendrogramas | Figura 5 |
| 8 | Regressão | Modelos lineares (INSE) | Figuras 6-14 |
| 9 | Itens brutos | Regressão com 72 itens | Figuras 6-14 |
| 10 | Mapas | Coropléticos por município | Figuras 16-18 |
| 11 | HLM | Modelos hierárquicos | Figuras 19-20 |
| 12 | Mediação | INSE como mediador | Figuras 21-22 |
| 13 | Validação CV | K-fold + ROC/AUC | Figuras 23-25 |
| 14 | Resíduos espaciais | Moran's I + LISA | Figuras 26-28 |
| 15 | Índice composto | PCA + indicador próprio | Figuras 29-31 |

## Detecção Automática de Caminhos

Todos os scripts detectam automaticamente a pasta raiz do projeto. Funciona em qualquer computador, independente do nome da pasta de usuário.

## Documentação

| Arquivo | Conteúdo |
|---------|----------|
| [TESTE/DOCUMENTACAO/README.md](TESTE/DOCUMENTACAO/README.md) | Guia de uso completo |
| [TESTE/DOCUMENTACAO/metodologia.md](TESTE/DOCUMENTACAO/metodologia.md) | Base para escrever o TCC |
| [TESTE/DOCUMENTACAO/referencia_outputs.md](TESTE/DOCUMENTACAO/referencia_outputs.md) | Dicionário de CSVs gerados |
| [TESTE/DOCUMENTACAO/requisitos.md](TESTE/DOCUMENTACAO/requisitos.md) | Dependências e instalação |

## Notas

- Todos os outputs usam timestamp (não sobrescrevem)
- Caminhos usam `/` (não `\`)
- O PASSO 5 gera comparações bidirecionais (ex: Pública→Privada E Privada→Pública)
- Todos os gráficos usam DPI 600 e fundo branco (qualidade para impressão)
