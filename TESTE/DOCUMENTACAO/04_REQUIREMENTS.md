# Requirements — Análise SAEB 2023

## Dependências de Sistema
- **R**: >= 4.0.0 (testado em 4.2.0+)
- **RStudio**: Recomendado (opcional, mas facilita)

## Pacotes R Necessários

### Core (Obrigatório)
```r
install.packages(c(
  "tidyverse",      # data manipulation (ggplot2, dplyr, readr, etc)
  "data.table",     # fast data reading
  "caret"           # machine learning utilities
))
```

### Dashboard & Visualização (Para Passo 3)
```r
install.packages(c(
  "shiny",          # interactive web dashboard
  "dendextend",     # dendrogram visualization
  "ggdendro"        # ggplot2 dendrogram support
))
```

### Versões Testadas & Compatíveis
```
tidyverse >= 1.3.0
data.table >= 1.14.0
caret >= 6.0.88
shiny >= 1.6.0
dendextend >= 1.16.0
ggdendro >= 0.1.23
```

## Instalação Rápida

Copie e cole no RStudio Console:

```r
# Instalar todas as dependências de uma vez
pkgs <- c("tidyverse", "data.table", "caret", "shiny", "dendextend", "ggdendro")
install.packages(pkgs)

# Verificar que tudo foi instalado
sapply(pkgs, require, character.only = TRUE)
```

## Estrutura de Diretórios Esperada

```
tcc/
├── TESTE/
│   ├── ajeitar_dados.r                    # PASSO 1
│   ├── correlacao.r                       # PASSO 2
│   ├── graficos.r                         # PASSO 3
│   ├── utils_saeb.r                       # Funções auxiliares
│   ├── DOCUMENTACAO_PASSOS_TCC.txt        # This file (atualizado)
│   ├── REQUIREMENTS.md                    # This file
│   │
│   ├── MICRODADOS_SAEB_2023/
│   │   └── DADOS/
│   │       ├── TS_ALUNO_34EM.csv
│   │       ├── TS_ALUNO_9EF.csv
│   │       └── ... (outros arquivos INEP)
│   │
│   └── dados_por_escola/
│       ├── 61432986/
│       │   ├── dados_escola_em_numeros.csv
│       │   ├── variaveis_degeneradas.csv
│       │   ├── todas_correlacoes_calculadas.csv
│       │   ├── correlacoes_mantidas_MT.csv
│       │   ├── correlacoes_mantidas_LP.csv
│       │   ├── dados_FINAL_MT_Filtrado.csv
│       │   ├── dados_FINAL_LP_Filtrado.csv
│       │   └── diagnostico_degeneracao.csv
│       │
│       ├── 61466120/
│       │   └── ... (mesma estrutura)
│       │
│       ├── resumo_processamento.csv          (consolidado)
│       └── escolas_nao_processadas.csv       (consolidado)
```

## Roteiro de Execução

### 1️⃣ PRIMEIRA EXECUÇÃO (Completa)

```r
setwd("C:/Users/Usuario/Desktop/tcc/TESTE")

# PASSO 1: Limpeza e transformação
source("ajeitar_dados.r")
# Saída: dados_por_escola/*/dados_escola_em_numeros.csv

# PASSO 2: Correlações
source("correlacao.r")
# Saída: dados_por_escola/*/correlacoes_*, diagnostico_*, etc

# PASSO 3: Dashboard
source("graficos.r")
# Abre: http://127.0.0.1:XXXX
```

### 2️⃣ EXECUÇÕES POSTERIORES (Exploração)

```r
# Se só quiser gerar gráficos:
setwd("C:/Users/Usuario/Desktop/tcc/TESTE")
source("graficos.r")

# Se quiser rodar correlações apenas para escolas pendentes:
source("correlacao.r")  # Com modo_execucao <- "pendentes"
```

## Configurações Importantes

### Em `ajeitar_dados.r`
```r
arquivo_entrada        <- "C:/Users/.../TS_ALUNO_34EM.csv"
sobrescrever_por_escola <- FALSE  # Respeita sua preferência
```

### Em `correlacao.r`
```r
limiar_cor <- 0.30                    # Mínimo |r| para manter
metodo_degeneracao <- "hibrido"       # "zero_variancia", "near_zero", ou "hibrido"
modo_execucao <- "pendentes"          # "todas", "pendentes", ou "especificas"
```

### Em `graficos.r`
```r
dir_resultados_por_escola <- "C:/Users/.../dados_por_escola"
```

## Validação

Para verificar se tudo está funcionando:

```r
# Testar leitura de dados
df <- read.csv("dados_por_escola/61432986/dados_escola_em_numeros.csv")
head(df)
nrow(df)  # Deve ser > 0

# Testar estrutura de correlações
cors <- read.csv("dados_por_escola/61432986/todas_correlacoes_calculadas.csv")
head(cors)
table(cors$Metodo)  # Deve ter Pearson e Spearman

# Testar Shiny (no console)
shiny::runApp("graficos.r")
```

## Troubleshooting

### ❌ "Pacote X não encontrado"
```r
install.packages("nome_do_pacote")
```

### ❌ "Arquivo not found"
- Verificar caminho (use `/` ao invés de `\`)
- Verificar se arquivo realmente existe
- Use `file.exists()` para validar

### ❌ Shiny diz "Nenhuma pasta de escola encontrada"
- Confirmar que `dados_por_escola/` existe
- Confirmar que há pastas com nomes numéricos (ex: `61432986/`)
- Verificar que `dados_FINAL_MT_Filtrado.csv` e `LP` existem dentro

### ❌ Dendogramas não aparecem
- Instalar: `install.packages("dendextend")` e `install.packages("ggdendro")`
- Mínimo 2 variáveis devem estar disponíveis

## Performance

- **ajeitar_dados.r**: ~1-2 min (para arquivo TS_ALUNO_34EM.csv completo)
- **correlacao.r**: ~2-5 min (por escola, depende de n_alunos)
- **graficos.r**: Interativo, renderiza em <1s por gráfico

## Notas

- Sempre execute **Passo 1 → Passo 2 → Passo 3** na primeira vez
- Não sobrescreva manualmente arquivos de correlação (use versionamento)
- Guarde logs do console (use `sink("log.txt")` se necessário)
- Para banca, capture screenshots do dashboard ou exporte gráficos com `ggsave()`

---

**Última atualização**: Maio 2026
**Responsável**: Seu Nome
**Email**: seu.email@universidade.edu.br
