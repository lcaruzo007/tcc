# TCC: Impacto Socioeconômico na Proficiência SAEB 2023

**Análise Estatística de Dados do SAEB 2023 — Microdados de Minas Gerais**

---

## 📊 Contexto

- **Período**: SAEB 2023
- **Geografia**: Minas Gerais (MG)
- **Amostra**: 173.918 alunos, 2.338 escolas, 851 municípios
- **Disciplinas**: Matemática (MT) e Língua Portuguesa (LP)
- **Foco**: Relação entre variáveis socioeconômicas (respondidas em questionário) e proficiência nas disciplinas

---

## 🗂️ Estrutura do Repositório

```
tcc/
├── README.md (este arquivo)
├── 26_04.txt (Diário de desenvolvimento — atualizações de progresso)
├── MICRODADOS_SAEB_2023/
│   ├── DADOS/ (CSV brutos do INEP)
│   │   ├── TS_ALUNO_34EM.csv (alunos do EM — foco principal)
│   │   ├── TS_ALUNO_9EF.csv, TS_ALUNO_2EF.csv, TS_ALUNO_5EF.csv
│   │   ├── TS_ESCOLA.csv (metadados das escolas)
│   │   ├── TS_DIRETOR.csv, TS_PROFESSOR.csv, TS_SECRETARIO_MUNICIPAL.csv
│   │   └── TS_ITEM.csv (itens das provas)
│   ├── DICIONÁRIO/ (glossário de variáveis)
│   ├── ESCALAS DE PROFICIÊNCIA/ (descrição das faixas de desempenho)
│   ├── INPUTS/ (scripts de validação do INEP em R)
│   ├── LEIA-ME E DOCUMENTOS TÉCNICOS/
│   └── MATRIZES DE REFERÊNCIA/ (habilidades avaliadas)
│
└── TESTE/ (Diretório de análises — **foco de trabalho**)
    ├── Scripts de Processamento
    │   ├── ajeitar_dados.r (PASSO 1: Limpeza e transformação de variáveis)
    │   ├── correlacao.r (PASSO 2: Cálculo de correlações com método apropriado)
    │   ├── graficos.r (PASSO 3: Dashboard Shiny interativo)
    │   └── [NOVOS - PASSO 4, 5, 6]
    │       ├── classificar_escolas.r (Agregação e criação de metadados)
    │       ├── comparar_grupos.r (Testes estatísticos entre grupos)
    │       └── dendrograma.r (Clustering hierárquico + dendrogramas)
    │
    ├── Documentação
    │   ├── DOCUMENTACAO_PASSOS_TCC.txt (Detalhado com justificativas)
    │   ├── REQUIREMENTS.md (Dependências e troubleshooting)
    │   ├── GUIA_3_NOVOS_SCRIPTS.txt (Instruções dos scripts 4, 5, 6)
    │   └── utils_saeb.r (Funções auxiliares reutilizáveis)
    │
    ├── dados_por_escola/ (Saídas por escola)
    │   ├── 61432986/ (ID da escola)
    │   │   ├── dados_escola_em_numeros.csv
    │   │   ├── variaveis_degeneradas.csv
    │   │   ├── diagnostico_degeneracao.csv
    │   │   ├── todas_correlacoes_calculadas.csv
    │   │   ├── correlacoes_mantidas_MT.csv
    │   │   ├── correlacoes_mantidas_LP.csv
    │   │   ├── dados_FINAL_MT_Filtrado.csv (escalados)
    │   │   └── dados_FINAL_LP_Filtrado.csv (escalados)
    │   ├── 61458788/, 61466120/, 61466123/ (outras escolas)
    │   └── resumo_processamento.csv (status agregado)
    │
    └── processados/ (Saídas dos novos scripts — PASSO 4, 5, 6)
        ├── metadados_escolas_*.csv (Arquivo unificado de metadados)
        ├── resultados_comparacao_*.csv (Testes estatísticos)
        ├── clusters_escolas_*.csv (Atribuição de clusters)
        ├── figuras_comparacao/
        │   ├── 01_boxplot_tipo_escola.png
        │   ├── 02_boxplot_urbano_rural.png
        │   ├── 03_boxplot_capital_interior.png
        │   └── 04_boxplot_inse.png
        └── figuras_dendrogramas/
            ├── dendrograma_MT_*.png
            ├── dendrograma_LP_*.png
            ├── dendrograma_3D_*.png
            ├── scatter_MT_vs_INSE.png
            ├── scatter_LP_vs_INSE.png
            └── scatter_MT_vs_LP.png
```

---

## 🔧 Pipeline de Análise

### **FASE 1: Limpeza e Transformação (Passos 1-3)**

#### **PASSO 1: ajeitar_dados.r**
Transforma respostas do questionário de **letras para números**, diferenciando por tipo:
- **Ordinais** (com ordem): Q10 (frequência pais), Q21 (tempo fora), Q22, Q23, Q19, Q20
  - Transformação: A→1, B→2, C→3, etc (respeitando ordem)
  - Método de correlação futuro: Spearman
- **Nominais** (sem ordem): Q01 (sexo), Q04 (raça/cor)
  - Transformação: dummies 0/1 por categoria
  - Método de correlação futuro: Spearman
- **Contínuas**: INSE_ALUNO, NU_TIPO_NIVEL_INSE
  - Mantém como numéricas
  - Método de correlação futuro: Pearson + Spearman

**Saída**: `dados_escola_em_numeros.csv` (por escola)

#### **PASSO 2: correlacao.r**
Calcula correlações com método apropriado para cada tipo:
- Detecta variáveis degeneradas (nearZeroVar + zero variância)
- Calcula correlações Spearman (ordinais/nominais) e Pearson (contínuas)
- Filtra por limiar de correlação: |r| ≥ 0.30 (Cohen pequeno/moderado)
- Exporta CSV com todas as correlações + aquelas mantidas

**Saída**: 
- `todas_correlacoes_calculadas.csv`
- `correlacoes_mantidas_MT.csv` / `correlacoes_mantidas_LP.csv`
- `dados_FINAL_*_Filtrado.csv` (escalados para modelagem)

#### **PASSO 3: graficos.r**
Dashboard Shiny interativo com 2 abas:
- **Aba 1**: Scatterplot de variável vs proficiência + Reta OLS + Painel estatístico
- **Aba 2**: Dendrogramas com 4 métodos de ligação (single, complete, average, ward)

**Execução**: `shiny::runApp("graficos.r")`

---

### **FASE 2: Análise de GRUPOS (Passos 4-6) — NOVO**

#### **PASSO 4: classificar_escolas.r**
Agrega dados ao nível de **ESCOLA** (não aluno):
- Calcula proficiência média (MT, LP) por escola
- Calcula INSE médio por escola
- Cria classificações:
  - **TIPO_ESCOLA**: Federal, Estadual, Municipal, Privada
  - **GRUPO_TIPO**: Pública vs Privada ⭐ (agregação principal)
  - **AREA**: Capital (Belo Horizonte) vs Interior
  - **LOCALIZACAO**: Urbana vs Rural
  - **FAIXA_MT / FAIXA_LP**: Quartis Q1-Q4 (calculados dinamicamente)
  - **GRUPO_INSE**: Baixo, Médio, Alto (terços)

**Saída**: `metadados_escolas_YYYYMMDD_HHMMSS.csv` (arquivo unificado com todas as escolas)

#### **PASSO 5: comparar_grupos.r**
Compara 4 pares de grupos com teste **Wilcoxon** (não-paramétrico):
1. **Pública vs Privada** — Diferença já clara? (MT: 268 vs 324 na população)
2. **Urbana vs Rural**
3. **Capital vs Interior**
4. **Alto INSE vs Baixo INSE**

Para cada comparação e disciplina (MT, LP):
- **Teste Wilcoxon**: p-valor (significância)
- **Tamanho de efeito**: rank-biserial r (0.0 a 1.0)
- **Interpretação**: 
  - r < 0.10: negligenciável
  - 0.10-0.30: pequeno
  - 0.30-0.50: médio
  - > 0.50: grande

**Saída**:
- `resultados_comparacao_YYYYMMDD_HHMMSS.csv` (tabela com 8 testes: 4 comparações × 2 disciplinas)
- `01_boxplot_tipo_escola.png`, `02_boxplot_urbano_rural.png`, etc (4 figuras)

#### **PASSO 6: dendrograma.r**
Clustering hierárquico com **Ward.D2** (agrupa escolas por similiaridade):
- Distância: Euclidiana
- Variáveis escaladas (z-score) para evitar dominância
- Três perspectivas:
  1. **MT + INSE** (2D)
  2. **LP + INSE** (2D)
  3. **MT + LP + INSE** (3D)
- Dendrogramas coloridos:
  - **Azul**: Escola Pública
  - **Vermelho**: Escola Privada
- Corta em **k=4 clusters** (apropriado estatisticamente)

**Saída**:
- `dendrograma_MT_*.png`, `dendrograma_LP_*.png`, `dendrograma_3D_*.png`
- `clusters_escolas_YYYYMMDD_HHMMSS.csv` (atribuição de cada escola a um cluster)
- `scatter_MT_vs_INSE.png`, `scatter_LP_vs_INSE.png`, `scatter_MT_vs_LP.png`

---

## 📈 Fluxo de Execução

### **Ordem Recomendada**

```r
# Fase 1: Limpeza (executar uma única vez)
source("TESTE/ajeitar_dados.r")

# Fase 1: Correlações (por escola ou todas)
source("TESTE/correlacao.r")  # modo_execucao = "pendentes" (padrão)

# Fase 1: Dashboard Interativo
shiny::runApp("TESTE/graficos.r")

# ─────────────────────────────────────────────────────────────────

# Fase 2: Agregação e Metadados (executar uma única vez)
source("TESTE/classificar_escolas.r")

# Fase 2: Comparações Estatísticas entre Grupos
source("TESTE/comparar_grupos.r")

# Fase 2: Clustering e Dendrogramas
source("TESTE/dendrograma.r")
```

---

## 📦 Dependências

### Instalar uma única vez:

```r
install.packages(c(
  "tidyverse",       # data manipulation (dplyr, ggplot2, etc)
  "data.table",      # efficient data reading
  "caret",           # nearZeroVar(), variable preprocessing
  "dendextend",      # dendrogram manipulation
  "ggdendro",        # ggplot2 dendrogram support
  "shiny"            # interactive dashboard
))
```

### Versões Testadas:
- R ≥ 4.0.0
- tidyverse ≥ 1.3.0
- data.table ≥ 1.14.0
- caret ≥ 6.0.88
- dendextend ≥ 1.16.0
- ggdendro ≥ 0.1.23
- shiny ≥ 1.6.0

---

## 🎯 Questões Científicas Respondidas

### **Fase 1 (Por Escola)**
1. **Quais variáveis socioeconômicas correlacionam com proficiência em cada escola?**
   - Resultado: Listas de correlações mantidas (|r| ≥ 0.30) por disciplina
   
2. **Existem padrões visuais nesses dados? (Não-linearidade?)**
   - Resultado: Dendrogramas interativos com 4 métodos de agrupamento

### **Fase 2 (Entre Escolas)**
3. **Escolas públicas e privadas diferem significativamente em proficiência?**
   - Resultado: Wilcoxon + tamanho de efeito (rank-biserial r)
   
4. **Localização (urbana vs rural) importa?**
   - Resultado: Comparação estatística com visualização
   
5. **Nível socioeconômico (INSE) confere com proficiência?**
   - Resultado: Scatter MT vs INSE + LP vs INSE
   
6. **Quais escolas são "similares" em perfil?**
   - Resultado: Clusters definidos por dendrogramas

---

## 💡 Decisões Metodológicas

| Decisão | Justificativa |
|---------|---------------|
| **Wilcoxon** (não paramétrico) | Dados de proficiência podem ser não-normais; mais robusto que t-test |
| **Rank-biserial r** (tamanho de efeito) | Adequado para Wilcoxon; interpretação intuitiva (0.0-1.0) |
| **Spearman para ordinais/nominais** | Não assume linearidade; apropriado para dados categóricos mapeados |
| **Ward.D2** (clustering) | Minimiza variância intra-cluster; dendrogramas bem-separados |
| **Distância euclidiana** | Métricas diretas em espaço 2D/3D; interpretável |
| **z-score scaling** | Impede que uma variável domine (ex: INSE domina MT se não escalado) |
| **Quartis dinamicamente** | Adaptam-se aos dados; refletem distribuição real |
| **Arquivo unificado de metadados** | Evita duplicação; uma única fonte de verdade |

---

## 📝 Versionamento de Saídas

Todos os arquivos de saída incluem **timestamp**:
```
metadados_escolas_20260511_143025.csv
resultados_comparacao_20260511_143256.csv
clusters_escolas_20260511_143412.csv
dendrograma_MT_20260511_143412.png
```

**Benefício**: Nenhuma sobrescrita acidental. Todas as versões coexistem.

---

## 🔍 Validações Implementadas

- ✅ Detecção automática de variáveis degeneradas
- ✅ Limpeza de caracteres inválidos (., *, F) antes de correlação
- ✅ Verificação de NAs durante agregação
- ✅ Escalagem apropriada para clustering
- ✅ Colorização de dendrogramas por tipo de escola
- ✅ Resumos consolidados (por grupo, por cluster)
- ✅ Exportação estruturada em diretórios organizados

---

## 📚 Documentação Adicional

| Arquivo | Conteúdo |
|---------|----------|
| [DOCUMENTACAO_PASSOS_TCC.txt](TESTE/DOCUMENTACAO_PASSOS_TCC.txt) | Justificativas estatísticas detalhadas (para a metodologia do TCC) |
| [REQUIREMENTS.md](TESTE/REQUIREMENTS.md) | Checklist, troubleshooting, dependências |
| [GUIA_3_NOVOS_SCRIPTS.txt](TESTE/GUIA_3_NOVOS_SCRIPTS.txt) | Instruções passo a passo + interpretação de resultados |
| [26_04.txt](26_04.txt) | Diário de desenvolvimento com progresso cronológico |

---

## 🚀 Próximos Passos

1. **Executar os 3 novos scripts** com dados reais
2. **Interpretar resultados**:
   - Qual grupo mostra maior diferença significativa?
   - Os dendrogramas separam privadas de públicas?
3. **Validações estatísticas**:
   - Verificar se tamanhos de efeito condizem com expectativas
   - Comparar resultados com literatura sobre SAEB
4. **Possíveis extensões**:
   - Dendrograma combinado (MT + LP com pesos iguais)
   - Análise de clusters específicos (ex: "Privadas de alto desempenho")
   - Regressão múltipla ao nível de escola

---

## 📧 Contato & Notas

**Data de criação**: Maio de 2026  
**Status**: Pronto para execução dos scripts 4, 5, 6  
**Última atualização**: 11 de Maio de 2026

---

**Documentação preparada para facilitar a escrita da metodologia do TCC e reprodutibilidade da análise.**
