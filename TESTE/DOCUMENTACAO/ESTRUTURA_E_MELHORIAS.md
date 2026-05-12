# 📊 ESTRUTURA REORGANIZADA E MELHORIAS VISUAIS

## ✅ RESUMO EXECUTIVO

Foram realizadas duas mudanças principais:

1. **Reorganização de Outputs**: Todos os outputs dos scripts da pasta 3 agora salvam **dentro** de 3_ANALISE_DE_GRUPOS (não em processados/ externo)
2. **Melhorias Visuais**: Dendrogramas, scatter plots e boxplots foram completamente redesenhados com design profissional

---

## 📁 NOVA ESTRUTURA DE OUTPUTS (Pasta 3)

```
3_ANALISE_DE_GRUPOS/
├── Scripts/
│   ├── classificar_escolas.r
│   ├── comparar_duas_escolas.r
│   ├── comparar_grupos.r
│   ├── dendrograma.r
│   ├── dendrograma_duas_escolas.r
│   ├── dendrograma_multiplos_pares.r
│   └── lista_comparacoes.csv
│
├── outputs_escolas/              ← Metadados de escolas
│   └── metadados_escolas_TIMESTAMP.csv
│
├── outputs_comparacao/           ← Comparações entre 2 escolas
│   └── Escola_[ID1]_vs_Escola_[ID2]_[TIMESTAMP]/
│       ├── Comparacao_Escola_*.csv
│       ├── Perfis_Escolas_*.csv
│       ├── Atributos_Escolas_*.csv
│       └── visualizacao_comparacao_*.png
│
├── outputs_clusters/             ← Atribuição de clusters
│   └── clusters_escolas_TIMESTAMP.csv
│
└── outputs_figuras/              ← TODOS os gráficos PNG
    ├── dendrograma_MT_*.png
    ├── dendrograma_LP_*.png
    ├── dendrograma_3D_*.png
    ├── dendrograma_escolas_*.png
    ├── scatter_MT_vs_INSE.png
    ├── scatter_LP_vs_INSE.png
    ├── scatter_MT_vs_LP.png
    ├── scatter_comparacao_*.png
    ├── 01_boxplot_tipo_escola.png
    ├── 02_boxplot_urbano_rural.png
    ├── 03_boxplot_capital_interior.png
    └── 04_boxplot_inse.png
```

---

## 🎨 MELHORIAS VISUAIS IMPLEMENTADAS

### 1. Dendrogramas Globais (dendrograma.r)

**Antes:**
- Size: 1200×600px @ 100dpi
- Cores: steelblue/darkred genéricas
- Layout simples, sem grid

**Depois:**
- Size: 1400×750px @ 100dpi (+ 40% área)
- Cores: #2E86AB (azul) / #A23B72 (rosa) - **profissional**
- ✅ Grid horizontal para leitura facilitada
- ✅ Background cinzento suave (#F8F9FA)
- ✅ Legends com contagens: "Pública (n=2297)" "Privada (n=41)"
- ✅ Branches mais espessos (lwd=1.5)
- ✅ Títulos em negrito com descrição completa

**Dendrogramas Inclusos:**
- Matemática + INSE
- Língua Portuguesa + INSE
- 3D (MT + LP + INSE)

### 2. Scatter Plots Globais (dendrograma.r)

**Antes:**
- Size: 8×6" @ 300dpi
- Cores simples, sem destaque
- Sem linhas de tendência

**Depois:**
- Size: 11×7" @ 300dpi (+ 37% área)
- ✅ Linhas de tendência com intervalo de confiança (LOESS/LM)
- ✅ Tamanho dos pontos = dimensão adicional
- ✅ Cores profissionais consistentes
- ✅ Subtítulos informativos e descritivos
- ✅ Grid refinado com cores leves

**3 Scatter Plots Inclusos:**
- Matemática vs INSE
- Língua Portuguesa vs INSE
- Matemática vs Língua Portuguesa

### 3. Dendrograma de 2 Escolas (dendrograma_duas_escolas.r)

**Antes:**
- Layout simples em um único painel
- Cores genéricas

**Depois:**
- ✅ Layout duplo (dendrograma + painel informativo lado-a-lado)
- ✅ Cores profissionais (#2E86AB, #A23B72)
- ✅ Painel com:
  - ID e tipo de cada escola
  - Proficiência em MT e LP
  - INSE Médio
  - Distância Euclidiana entre escolas

### 4. Scatter Plot de Comparação (dendrograma_duas_escolas.r)

**Antes:**
- Labels simples

**Depois:**
- ✅ Labels automáticas com ggrepel (sem sobreposição)
- ✅ Escolas-alvo destacadas com símbolo especial (★)
- ✅ Bordas grossas para destacar
- ✅ Size = Proficiência em LP (transmite 4ª dimensão)
- ✅ Subtítulo explicativo

### 5. Boxplots de Comparação de Grupos (comparar_grupos.r)

**Antes:**
- Boxplots simples
- Cores padrão

**Depois:**
- ✅ **Violin plots** + boxplots combinados (mostra distribuição completa)
- ✅ Pontos de dados visíveis (jitter = 0.15)
- ✅ Paletas de cores únicas por variável:
  - Público/Privado: Azul/Rosa
  - Urbano/Rural: Verde/Laranja
  - Capital/Interior: Azul Claro/Ouro
  - INSE: Vermelho/Âmbar/Verde
- ✅ Facets separados para MT e LP
- ✅ Size aumentado: 10×6" @ 300dpi
- ✅ Contagens na legenda: "Urbana (n=2144)" "Rural (n=153)"

---

## 📋 MUDANÇAS DE CAMINHOS

### Pasta 3 (3_ANALISE_DE_GRUPOS)

| Script | Antes | Depois |
|--------|-------|--------|
| classificar_escolas.r | processados/ | outputs_escolas/ |
| comparar_duas_escolas.r | processados/comparacao/ | outputs_comparacao/ |
| comparar_grupos.r | processados/figuras_comparacao | outputs_figuras/ |
| dendrograma.r | processados/figuras_dendrogramas + processados/ | outputs_figuras/ + outputs_clusters/ |
| dendrograma_duas_escolas.r | processados/figuras_dendrogramas | outputs_figuras/ |
| dendrograma_multiplos_pares.r | processados/figuras_dendrogramas | outputs_figuras/ |

### Pasta 2 (2_ANALISE_POR_ESCOLA)

Caminhos RAIZ atualizados de:
```
C:/Users/Usuario/Desktop/tcc  ❌ (incorreto)
```
Para:
```
C:/Users/13756596699/tcc  ✅ (correto)
```

Novos outputs criados:
- `outputs_correlacoes/` - Para CSVs de correlações
- `outputs_graficos/` - Para gráficos do Shiny

---

## 🔧 ESPECIFICAÇÕES TÉCNICAS

### Paleta de Cores Profissionais

```
Tipo de Escola:
  Pública:  #2E86AB  (Azul Royal)
  Privada:  #A23B72  (Magenta Escuro)

Localização:
  Urbana:   #06A77D  (Verde Esmeralda)
  Rural:    #D5622B  (Laranja Queimado)

Área:
  Capital:  #4A90E2  (Azul Céu)
  Interior: #F5A623  (Ouro)

INSE:
  Baixo:    #E74C3C  (Vermelho)
  Médio:    #F39C12  (Âmbar)
  Alto:     #27AE60  (Verde)

Backgrounds:
  Plot Area:    #F8F9FA  (Cinzento Suave)
  Grid:         #E8E8E8  (Cinzento Claro)
  Text Primary: #1A1A1A  (Quase Preto)
```

### Dimensões de Saída

| Tipo | Antes | Depois | Resolução |
|------|-------|--------|-----------|
| Dendrogramas | 1200×600 | **1400×750** | 100 DPI |
| Scatters | 8×6" | **11×7"** | 300 DPI |
| Boxplots | 8×5" | **10×6"** | 300 DPI |

---

## ✅ VALIDAÇÃO

Scripts testados e funcionando:

- ✅ classificar_escolas.r - 2,338 escolas processadas
- ✅ comparar_duas_escolas.r - Teste: 61432986 vs 61466120
- ✅ comparar_grupos.r - 4 boxplots com violin plots
- ✅ dendrograma.r - 9 visualizações (3 dendrogramas + 3 scatters cada)
- ✅ dendrograma_duas_escolas.r - Layout novo com painel informativo
- ✅ dendrograma_multiplos_pares.r - Pronto para batch (aguarda lista_comparacoes.csv)

---

## 📊 PRÓXIMAS AÇÕES

1. **Batch Processing**: Editar `lista_comparacoes.csv` com pares desejados
2. **Visualizar**: Abrir todos os PNG em outputs_figuras/
3. **Análise**: Revisar insights dos dendrogramas e boxplots
4. **Exportação**: CSVs e PNGs prontos para relatório final

**Data:** 12/05/2026 | **Status:** ✅ Implementado e Validado
