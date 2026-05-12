# 📊 ESTRUTURA ATUALIZADA DE OUTPUTS - TCC SAEB 2023

## ✅ RESUMO DAS MUDANÇAS

### 1️⃣ **Pasta 3 - Análise de Grupos (3_ANALISE_DE_GRUPOS)**

#### Nova Estrutura de Diretórios:
```
3_ANALISE_DE_GRUPOS/
├── Scripts/
│   ├── classificar_escolas.r        → Gera metadados das escolas
│   ├── comparar_duas_escolas.r      → Compara 2 escolas específicas
│   ├── comparar_grupos.r            → Compara públicas/privadas, urbano/rural, etc
│   ├── dendrograma.r                → Clustering hierárquico de todas as escolas
│   ├── dendrograma_duas_escolas.r   → Dendrograma para 2 escolas
│   ├── dendrograma_multiplos_pares.r → Processa múltiplos pares em lote
│   └── lista_comparacoes.csv        → Entrada para batch processing
│
├── outputs_escolas/                 ← Metadados e CSVs de escolas
│   └── metadados_escolas_TIMESTAMP.csv
│
├── outputs_comparacao/              ← Comparações de 2 escolas
│   └── Escola_[ID1]_vs_Escola_[ID2]_[TIMESTAMP]/
│       ├── Comparacao_Escola_*.csv
│       ├── Perfis_Escolas_*.csv
│       ├── Atributos_Escolas_*.csv
│       └── visualizacao_comparacao_*.png
│
├── outputs_clusters/                ← Resultados de clustering
│   └── clusters_escolas_TIMESTAMP.csv
│
└── outputs_figuras/                 ← Todas as visualizações (PNG)
    ├── dendrograma_MT_*.png         (Dendrograma Matemática)
    ├── dendrograma_LP_*.png         (Dendrograma Língua Portuguesa)
    ├── dendrograma_3D_*.png         (Dendrograma 3D: MT+LP+INSE)
    ├── dendrograma_escolas_*.png    (Dendrograma para 2 escolas)
    ├── scatter_MT_vs_INSE.png       (Proficiência MT × INSE)
    ├── scatter_LP_vs_INSE.png       (Proficiência LP × INSE)
    ├── scatter_MT_vs_LP.png         (MT × LP)
    ├── scatter_comparacao_*.png     (Comparação de 2 escolas)
    ├── 01_boxplot_tipo_escola.png   (Pública vs Privada)
    ├── 02_boxplot_urbano_rural.png  (Urbana vs Rural)
    ├── 03_boxplot_capital_interior.png (Capital vs Interior)
    └── 04_boxplot_inse.png          (Por nível socioeconômico)
```

#### ✨ **Melhorias Visuais Implementadas**

**Dendrogramas:**
- ✅ Cores profissionais: Azul (#2E86AB) para públicas, Rosa (#A23B72) para privadas
- ✅ Tamanho aumentado: 1400×750px @ 100dpi
- ✅ Grid horizontal para facilitar leitura
- ✅ Background cinzento leve (#F8F9FA) para melhor contraste
- ✅ Legends melhoradas com contagens (n=2297, n=41)
- ✅ Layout lado-a-lado para dendrograma + informações

**Scatter Plots:**
- ✅ Cores personalizadas por tipo de escola
- ✅ Linhas de tendência (LOESS/LM) com intervalo de confiança
- ✅ Tamanho dos pontos representa dimensão adicional
- ✅ Labels automáticas nas 2 escolas comparadas (ggrepel)
- ✅ Resolução aumentada: 11×7" @ 300dpi
- ✅ Subtítulos informativos

**Boxplots:**
- ✅ Violin plots combinados com boxplots para distribuição completa
- ✅ Pontos de dados visíveis (jitter)
- ✅ Paletas de cores profissionais por variável
- ✅ Facets por disciplina (Matemática | Língua Portuguesa)
- ✅ Títulos e subtítulos descritivos
- ✅ Resolução aumentada: 10×6" @ 300dpi

---

### 2️⃣ **Pasta 2 - Análise por Escola (2_ANALISE_POR_ESCOLA)**

#### Nova Estrutura de Diretórios:
```
2_ANALISE_POR_ESCOLA/
├── Scripts/
│   ├── correlacao.r    → Calcula correlações por escola
│   └── graficos.r      → Dashboard Shiny interativo
│
├── outputs_correlacoes/    ← CSVs de correlações por escola
│   └── resumo_processamento.csv
│
└── outputs_graficos/       ← Gráficos do dashboard (Shiny)
    └── (gerados dinamicamente)
```

**Caminhos Atualizados:**
- Antes: `C:/Users/Usuario/Desktop/tcc` (hardcoded, incorreto)
- Depois: `C:/Users/13756596699/tcc` (real, atualizado)

---

## 🔄 FLUXO DE EXECUÇÃO RECOMENDADO

### Passo 1: Classificar Escolas
```
3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r
└─ Saída: outputs_escolas/metadados_escolas_TIMESTAMP.csv
```

### Passo 2: Comparar Duas Escolas (Exemplo)
```
3_ANALISE_DE_GRUPOS/Scripts/comparar_duas_escolas.r
└─ Saída: outputs_comparacao/Escola_61432986_vs_Escola_61466120_[...]
```

### Passo 3: Comparar Grupos (Público/Privado, Urbano/Rural, etc)
```
3_ANALISE_DE_GRUPOS/Scripts/comparar_grupos.r
└─ Saída: outputs_figuras/{boxplots 4 PNG} + outputs_escolas/resultados_comparacao.csv
```

### Passo 4: Clustering de Todas as Escolas
```
3_ANALISE_DE_GRUPOS/Scripts/dendrograma.r
└─ Saída: outputs_figuras/{6 dendrogramas + 3 scatters PNG}
         outputs_clusters/clusters_escolas_TIMESTAMP.csv
```

### Passo 5: Dendrograma de 2 Escolas
```
3_ANALISE_DE_GRUPOS/Scripts/dendrograma_duas_escolas.r
(Configurar ID_ESCOLA_A e ID_ESCOLA_B no início do script)
└─ Saída: outputs_figuras/{dendrograma + scatter PNG}
```

### Passo 6 (OPCIONAL): Processar Múltiplos Pares em Lote
```
3_ANALISE_DE_GRUPOS/Scripts/dendrograma_multiplos_pares.r
(Editar: lista_comparacoes.csv com IDs das escolas)
└─ Saída: outputs_figuras/{múltiplos pares} + resumo_dendrogramas_TIMESTAMP.csv
```

---

## 📊 ESPECIFICAÇÕES VISUAIS

### Paleta de Cores
```
Tipo de Escola:
  • Pública:  #2E86AB (Azul Profissional)
  • Privada:  #A23B72 (Rosa/Violeta)

Localização:
  • Urbana:   #06A77D (Verde Esmeralda)
  • Rural:    #D5622B (Laranja Queimado)

Área:
  • Capital:  #4A90E2 (Azul Claro)
  • Interior: #F5A623 (Ouro)

INSE:
  • Baixo:    #E74C3C (Vermelho)
  • Médio:    #F39C12 (Âmbar)
  • Alto:     #27AE60 (Verde)
```

### Dimensões Padrão
- Dendrogramas: 1400×750px @ 100dpi (PNG)
- Scatters: 11×7" @ 300dpi (PNG)
- Boxplots: 10×6" @ 300dpi (PNG)

### Fonte e Estilos
- Background: #F8F9FA (cinzento suave)
- Texto título: #1A1A1A (quase preto), bold
- Texto normal: #333333, regular
- Grid: #E8E8E8, linha tracejada

---

## 📝 NOTAS IMPORTANTES

✅ **Todos os scripts estão conectados** - outputs de um alimentam inputs de outro
✅ **Caminhos absolutos corrigidos** - RAIZ aponta para `C:/Users/13756596699/tcc`
✅ **Estrutura organizada** - outputs separados por tipo (clusters, comparações, figuras)
✅ **Design profissional** - visualizações com cores coerentes, fontes legíveis, backgrounds apropriados
✅ **Batch processing disponível** - processe múltiplos pares sem reexecutar scripts

---

## 🚀 PRÓXIMAS ETAPAS

1. Executar todos os scripts em sequência
2. Revisar qualidade das visualizações
3. Gerar relatório final com insights
4. Considerar criar shiny app para exploração interativa

**Última Atualização:** 2026-05-12
**Status:** ✅ Pronto para Execução
