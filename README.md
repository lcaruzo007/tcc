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
    ├── 1_LIMPEZA_E_TRANSFORMACAO/
    │   ├── ajeitar_dados.r      (PASSO 1)
    │   └── outputs/
    │
    ├── 2_ANALISE_POR_ESCOLA/
    │   ├── Scripts/
    │   │   ├── correlacao.r     (PASSO 2)
    │   │   └── graficos.r       (PASSO 3 - opcional)
    │   └── outputs/
    │
    ├── 3_ANALISE_DE_GRUPOS/
    │   ├── Scripts/
    │   │   ├── classificar_escolas.r   (PASSO 4)
    │   │   ├── comparar_grupos.r       (PASSO 5)
    │   │   ├── comparar_duas_escolas.r (PASSO 6 - opcional)
    │   │   └── dendrograma_analise_completa.r (PASSO 7)
    │   ├── README.md
    │   └── outputs/
    │
    ├── 4_REGRESSAO_LINEAR/
    │   ├── Scripts/
    │   │   └── regressao_linear_multipla.r (PASSO 8)
    │   ├── README.md
    │   └── outputs/
    │
    └── 5_REGRESSAO_ITENS_BRUTOS/
        ├── Scripts/
        │   └── regressao_itens_brutos_dummy.r (PASSO 9)
        ├── README.md
        └── outputs/
```

## Pipeline de Execução

```r
# PASSO 1: Limpeza (1x)
source("TESTE/1_LIMPEZA_E_TRANSFORMACAO/ajeitar_dados.r")

# PASSO 2: Correlações
source("TESTE/2_ANALISE_POR_ESCOLA/Scripts/correlacao.r")

# PASSO 3: Dashboard (opcional)
shiny::runApp("TESTE/2_ANALISE_POR_ESCOLA/Scripts/graficos.r")

# PASSO 4: Metadados das escolas (1x, necessário para 5-7)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r")

# PASSO 5: Comparações entre grupos
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_grupos.r")

# PASSO 6: Comparar 2 escolas (opcional)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_duas_escolas.r")

# PASSO 7: Clustering
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_analise_completa.r")

# PASSO 8: Regressão linear
source("TESTE/4_REGRESSAO_LINEAR/Scripts/regressao_linear_multipla.r")

# PASSO 9: Regressão com itens brutos
source("TESTE/5_REGRESSAO_ITENS_BRUTOS/Scripts/regressao_itens_brutos_dummy.r")
```

## Detecção Automática de Caminhos

Todos os scripts detectam automaticamente a pasta raiz do projeto. Funciona em qualquer computador, independente do nome da pasta de usuário (ex: `Usuario`, `13756596699`, etc).

Se a detecção automática falhar, o script pedirá para selecionar a pasta raiz manualmente.

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
