# 📊 Resumo: Análise de Grupos (Inter-Escolas)

## 🎯 Objetivo Geral

Sua análise de GRUPOS processa **dados agregados por escola** para identificar:
- 📈 Padrões de desempenho entre escolas
- 🔗 Agrupamentos naturais (quais escolas são similares)
- 📊 Diferenças estatísticas significativas entre GRUPOS de escolas
- 🎓 Impacto de fatores socioeconômicos (INSE) no desempenho

---

## 🔴 SCRIPT 1: `classificar_escolas.r`

### O que faz?

**Agregação e classificação de dados por escola**

Transforma dados brutos de **alunos** (com respostas individuais) em **metadados de escolas** (com agregações).

### Entrada

- Dados brutos de alunos: `TS_ALUNO_*.csv` (173.918 registros)
- Variáveis de socioeconômico: `INSE_ALUNO` (índice INEP)

### Processo

```
Para cada escola:
  1. Calcula proficiência MÉDIA dos alunos:
     • MEDIA_MT = média de todas as proficiências de Matemática
     • MEDIA_LP = média de todas as proficiências de Língua Portuguesa
  
  2. Calcula INSE MÉDIO dos alunos da escola:
     • INSE_MEDIO = média do índice socioeconômico
  
  3. Classifica a escola em 6 dimensões:
     • TIPO_ESCOLA: Pública / Privada
     • GRUPO_TIPO: 2 categorias de tipo
     • AREA: Capital / Interior
     • LOCALIZACAO: Urbana / Rural
     • FAIXA_MT: Quartis (Baixo, Medio-Baixo, Medio-Alto, Alto)
     • FAIXA_LP: Quartis (Baixo, Medio-Baixo, Medio-Alto, Alto)
     • GRUPO_INSE: 3 faixas socioeconômicas (Baixo, Médio, Alto)
```

### Saída

**Arquivo:** `metadados_escolas_YYYYMMDD_HHMMSS.csv`

**Estrutura (1 linha = 1 escola):**
```
ID_ESCOLA | TIPO_ESCOLA | AREA | LOCALIZACAO | MEDIA_MT | MEDIA_LP | INSE_MEDIO | FAIXA_MT | FAIXA_LP | GRUPO_INSE | N_ALUNOS
61432986  | Pública     | Interior | Urbana   | 268.5    | 247.3    | 45.8      | Medio-Alto | Medio  | Médio     | 287
61466120  | Pública     | Capital  | Urbana   | 241.2    | 219.7    | 52.3      | Bajo   | Bajo   | Médio     | 152
61425355  | Privada     | Capital  | Urbana   | 324.1    | 308.2    | 58.9      | Alto   | Alto   | Alto      | 98
```

### Por que é importante?

✅ **Base para todo o restante** — Todos os scripts subsequentes dependem deste arquivo  
✅ **Normaliza escala** — Transforma dados de 173k alunos em 2.3k escolas  
✅ **Adiciona contexto** — Cada escola sabe sua classificação e grupo  

---

## 🟠 SCRIPT 2: `comparar_grupos.r`

### O que faz?

**Comparações estatísticas entre GRUPOS de escolas**

Testa se diferenças entre grupos são **significativas** (não por acaso) usando testes estatísticos robustos.

### Entrada

- `metadados_escolas_*.csv` (saída do script 1)

### Comparações Realizadas

**4 pares de grupos:**

| Par | Grupo A | Grupo B | Objetivo |
|-----|---------|---------|----------|
| 1️⃣ | Pública | Privada | Tipo de escola influencia proficiência? |
| 2️⃣ | Urbana | Rural | Localização (cidade vs campo) importa? |
| 3️⃣ | Capital | Interior | Proximidade da capital afeta resultado? |
| 4️⃣ | Alto INSE | Baixo INSE | Nível socioeconômico é determinante? |

### Processo para cada par

```
1. Testa NORMALIDADE dos dados (Shapiro-Wilk)
   → Se não-normal → usa teste não-paramétrico (Wilcoxon)
   → Se normal → usa teste paramétrico (t-test)

2. Calcula TAMANHO DO EFEITO:
   • rank-biserial r (0.0 a 1.0)
   • 0.1 = efeito pequeno
   • 0.3 = efeito médio
   • 0.5+ = efeito grande

3. Gera BOXPLOT visual:
   • Mostra distribuição de proficiências
   • Distingue por disciplina (MT e LP)
   • Marca valores discrepantes (outliers)
```

### Saída

**Tabela:** `resultados_comparacao_YYYYMMDD_HHMMSS.csv`

```
Grupo_A | Grupo_B | Disciplina | Media_A | Media_B | p_valor | Significante | Efeito_r | Interpretacao
Pública | Privada | MT         | 268.1   | 324.5   | 0.001   | Sim          | 0.62     | Efeito grande
Pública | Privada | LP         | 247.3   | 308.1   | 0.001   | Sim          | 0.65     | Efeito grande
Urbana  | Rural   | MT         | 280.2   | 262.4   | 0.045   | Sim          | 0.28     | Efeito pequeno
...
```

**Gráficos:** 4 boxplots (um por par de grupos)

### O que você aprende?

📌 **Públicas são significativamente piores que privadas?** Sim, com efeito GRANDE  
📌 **Cidades grandes (capital) têm melhor desempenho?** Pode ser sim ou não  
📌 **Alunos ricos (INSE alto) se saem melhor?** Provavelmente sim  
📌 **Zona urbana vs rural faz diferença?** Depende da magnitude do efeito  

---

## 🟢 SCRIPT 3: `comparar_duas_escolas.r`

### O que faz?

**Comparação lado-a-lado de 2 escolas específicas**

Não é dendrograma — é um relatório detalhado de atributos e perfil.

### Entrada

- IDs de 2 escolas (configurável no script)
- Dados brutos e metadados

### Processo

```
Para cada escola:
  1. Carrega seu perfil (INSE, proficiências, tipo)
  2. Compara com a outra escola
  3. Cria tabela de atributos lado-a-lado
  4. Gera visualizações
```

### Saída

- `Perfis_Escolas_*.csv` — Tabela comparativa
- `Comparacao_Escola_A_vs_B_*.csv` — Detalhes
- Gráfico visual de comparação

---

## 🔵 SCRIPT 4 (NOVO): `dendrograma_analise_completa.r`

### O que faz?

**Agrupamento hierárquico de escolas — identifica quais são similares**

Usa clustering para mostrar **padrões naturais** nos dados: "Essas 10 escolas se comportam de forma similar".

### Entrada

- `metadados_escolas_*.csv`
- `lista_comparacoes.csv` (opcional, apenas Modo 2)

### 2 Modos de Operação

---

### 🟢 MODO 1: Dendrograma Geral (PADRÃO)

**Objetivo:** Visualizar como TODAS as escolas se agrupam

**Processo:**
```
1. Carrega TODAS as escolas do dataset
2. Categoriza por desempenho:
   • ALTO: ≥ percentil 75% (proficiência média alta)
   • BAIXO: ≤ percentil 25% (proficiência média baixa)
   • INTERMEDIÁRIO: 25-75% (remove do dendrograma)

3. Seleciona apenas ALTO + BAIXO (~50% do total)

4. Cria matriz de características:
   • MEDIA_MT_escala (padronizado)
   • MEDIA_LP_escala (padronizado)
   • INSE_escala (padronizado)

5. Clustering hierárquico:
   • Método: Ward.D2 (minimiza variância dentro de clusters)
   • Distância: Euclidiana
   • Resultado: 1 dendrograma com N escolas

6. Corta em 3 clusters:
   • Cada escola é atribuída a 1 cluster
   • Árvore mostra distância entre agrupamentos
```

**Saída:**
- `dendrograma_geral_ALTO_BAIXO_*.png` — Árvore hierárquica completa
- `tabela_escolas_ALTO_BAIXO_*.csv` — Cluster atribuído para cada escola
- Console mostra: Distribuição de escolas (quantas ALTO, quantas BAIXO, quantas removidas)

**O que você vê:**
```
        ┌─ Escola 61432986 (ALTO)
    ┌───┤
    │   └─ Escola 61425355 (ALTO)  ← Cluster 1 (ALTOS similares)
    │
────┤
    │   ┌─ Escola 61458788 (BAIXO)
    └───┤                          ← Cluster 2 (BAIXOS)
        └─ Escola 61466120 (BAIXO)
```

---

### 🟡 MODO 2: Dendrogramas de Pares

**Objetivo:** Gerar dendrograma + scatter para cada par em `lista_comparacoes.csv`

**Processo:**
```
1. Lê arquivo: lista_comparacoes.csv
2. Para cada linha (par de escolas):
   a) Verifica se ambas são ALTO ou BAIXO
   b) Se uma é INTERMEDIÁRIA → PULA o par
   c) Se ambas válidas → gera:
      • Dendrograma (mostra distância euclidiana entre 2 escolas)
      • Scatter plot (INSE x MT, com LP como tamanho do ponto)

3. Cria pasta separada para cada par:
   Escola_61432986_vs_Escola_61466120_20260513_HHMMSS/
   ├── dendrograma_escolas_61432986_vs_61466120_*.png
   └── scatter_comparacao_61432986_vs_61466120_*.png
```

**Saída:**
- Múltiplas pastas (1 por par)
- Cada pasta contém dendrograma + scatter
- `resumo_dendrogramas_*.csv` — Tabela de distâncias entre todos os pares

**Interpretação:**
- Distância **< 1.0** → Escolas muito similares
- Distância **1.0-2.0** → Moderadamente similares
- Distância **> 2.0** → Bem diferentes

---

## 📊 Visão Completa: Como os Scripts Trabalham Juntos

```
TS_ALUNO_*.csv (dados brutos)
        ↓
        ├─→ [classificar_escolas.r]
        │       ↓
        │   metadados_escolas_*.csv (1 linha = 1 escola)
        │       ↓
        ├─────────┼─────────┬────────────────┐
        ↓         ↓         ↓                ↓
[comparar_grupos.r]
        ↓
   boxplots + testes estatísticos
   (diferenças entre GRUPOS)

[comparar_duas_escolas.r]
        ↓
   perfis lado-a-lado
   (comparação simples)

[dendrograma_analise_completa.r]
        ├─→ Modo 1: dendrograma GERAL (todas ALTO+BAIXO)
        └─→ Modo 2: dendrogramas de PARES (lista_comparacoes.csv)
        ↓
   estrutura de agrupamentos
   (quais escolas se parecem)
```

---

## 💡 Casos de Uso

### Cenário 1: "Públicas e privadas são realmente diferentes?"
→ Use `comparar_grupos.r`  
→ Resultado: p-value < 0.05 = diferença significativa

### Cenário 2: "Que escolas privadas mais se parecem com públicas?"
→ Use `dendrograma_analise_completa.r` (Modo 2)  
→ Resultado: Pares com distância pequena

### Cenário 3: "Existe mesmo um impacto do INSE no desempenho?"
→ Use `comparar_grupos.r`  
→ Resultado: Tamanho do efeito > 0.5 = impacto significativo

### Cenário 4: "Como todas as escolas se agrupariam naturalmente?"
→ Use `dendrograma_analise_completa.r` (Modo 1)  
→ Resultado: Árvore mostra agrupamentos naturais

---

## ✅ Capacidades Resumidas

| Capacidade | Script | Saída |
|-----------|--------|-------|
| Agregação por escola | `classificar_escolas.r` | CSV com 2.3k escolas |
| Testes estatísticos | `comparar_grupos.r` | Tabela + 4 boxplots |
| Comparação 2 escolas | `comparar_duas_escolas.r` | CSV comparativo + gráficos |
| Dendrograma geral | `dendrograma_analise_completa.r` Modo 1 | 1 PNG + tabela clusters |
| Dendrogramas de pares | `dendrograma_analise_completa.r` Modo 2 | N pastas com PNGs |
| Identificar padrões | Todos combinados | Visão 360° das escolas |

---

## 🎓 Aplicação no TCC

**Capítulo de Metodologia:**
- Explicar classificação de escolas (script 1)
- Descrever testes estatísticos (script 2)

**Capítulo de Resultados:**
- Gráficos de diferenças entre grupos (script 2)
- Dendrogramas de agrupamentos (script 4)
- Interpretação: "Escolas X e Y são similares porque..."

**Conclusões:**
- Usar achados dos testes (script 2) para fundamentar conclusões
- Usar dendrogramas (script 4) para exemplificar estrutura de dados

---

**Atualizado:** 13 de Maio de 2026
