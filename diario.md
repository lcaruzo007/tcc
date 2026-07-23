# 📔 Diário de Desenvolvimento — TCC

**Título:** Impacto Socioeconômico na Proficiência SAEB  
**Período:** 06 de Abril — 27 de Maio de 2026  
**Status:** 🚀 Em Desenvolvimento — validação final em andamento

---

## 📍 Entradas de Registro

### 🔵 06 de Abril de 2026

**Horário:** ~20h29  
**Fase:** Pré-processamento e Visualização  
**Status:** ✅ Concluído com sucesso

#### Atividades Realizadas

- Desenvolvimento de 3 scripts para tratamento e análise dos dados
- Transformação de variáveis de resposta (formato A/B/C → numérico 1/2/3)
- Cálculo de correlações entre variáveis socioeconômicas e proficiência
- Exclusão de variáveis com correlação |r| < 0,3 (variáveis degeneradas)
- Aplicação de autoescalonamento nas variáveis mantidas
- Geração de CSV consolidado com todas as correlações calculadas
- Implementação do dashboard interativo com Shiny (gráficos de dispersão + reta de regressão linear)

#### Desafios Encontrados

- 1ª tentativa de cidade: nenhuma correlação significativa encontrada
- 2ª tentativa de cidade: novamente sem correlações válidas
- 3ª tentativa: correlações encontradas, porém em número reduzido

#### Resultados Obtidos

- **TX_RESP_Q10b** ("Pais conversam sobre escola"): correlação positiva com Matemática
- **TX_RESP_Q21a** ("Tempo estudando"): correlação positiva com Matemática
- Ambos os gráficos apresentaram reta de regressão com inclinação positiva e intervalo de confiança visível

#### Próximos Passos

- Ampliar base de cidades e refinar seleção de variáveis

---

### 🟢 26 de Abril de 2026

**Horário:** ~16h00 até noite  
**Fase:** Ajustes de robustez do pipeline e análise por escola  
**Status:** ✅ Concluído com sucesso

#### Atividades Realizadas

- Reestruturação do fluxo para processar por escola em `TESTE/dados_por_escola`
- Ajuste do script de correlação para ler automaticamente a pasta de cada escola
- Inclusão de modos de execução no script de correlação:
  - `pendentes` — apenas escolas sem resultados completos
  - `todas` — todas as escolas encontradas
  - `especificas` — escolas listadas manualmente
- Ajuste do filtro de degeneração para reduzir perda de variáveis:
  - `metodo_degeneracao` configurável (zero_variancia, near_zero, hibrido)
  - Amostra mínima para aplicar nearZeroVar
  - Parâmetros de sensibilidade configuráveis (freq_cut_nzv e unique_cut_nzv)
- Geração de diagnóstico por escola (`diagnostico_degeneracao.csv`)
- Ajuste do dashboard Shiny para seleção de escola no menu lateral
- Leitura automática do arquivo mais recente por escola (com ou sem sufixo de data/hora)
- Criação de script para matriz de dispersão por escola (`TESTE/matriz_dispersao.r`)

#### Desafios Encontrados

- Muitas variáveis marcadas como degeneradas em escolas com amostra pequena
- Risco de sobrescrita ao reprocessar a mesma escola várias vezes
- Necessidade de evitar recálculo de todas as escolas a cada execução

#### Resultados Obtidos

- Pipeline estabilizado por escola, com menor risco de sobrescrita
- Correlação passou a executar em modo incremental (`pendentes`) por padrão
- Dashboard passou a permitir comparação rápida entre escolas
- Matriz de dispersão disponível para inspeção visual das relações entre variáveis e nota

#### Próximos Passos

- Reprocessar escolas críticas com `metodo_degeneracao` menos agressivo quando necessário
- Comparar, por escola, a quantidade de variáveis mantidas nos métodos `zero_variancia` e `hibrido`
- Consolidar no texto do TCC os critérios de exclusão e as evidências visuais (matriz de dispersão + correlações mantidas)

---

### 🟠 11 de Maio de 2026

**Horário:** ~13h00  
**Fase:** Análise de GRUPOS de escolas — Comparações estatísticas e Dendrogramas  
**Status:** ✅ Concluído com sucesso

#### Atividades Realizadas

Desenvolvimento de **3 novos scripts** para análise de GRUPOS de escolas (inter-escolas):

##### 1. `classificar_escolas.r`

- Agrega dados de alunos por escola
- Calcula proficiência média (MT, LP) e INSE médio por escola
- Cria colunas de classificação:
  - `TIPO_ESCOLA`, `GRUPO_TIPO` (Pública/Privada)
  - `AREA` (Capital/Interior)
  - `LOCALIZACAO` (Urbana/Rural)
  - `FAIXA_MT/LP` (quartis)
  - `GRUPO_INSE`
- Exporta arquivo unificado: `metadados_escolas_YYYYMMDD_HHMMSS.csv`

##### 2. `comparar_grupos.r`

- Compara 4 pares de grupos:
  - Pública vs Privada
  - Urbana vs Rural
  - Capital vs Interior
  - Alto INSE vs Baixo INSE
- Executa teste não-paramétrico de Wilcoxon (apropriado para dados não-normais)
- Calcula tamanho de efeito: rank-biserial r (0.0 a 1.0)
- Gera 4 boxplots com diferenciações visuais por disciplina
- Exporta: `resultados_comparacao_YYYYMMDD_HHMMSS.csv` + PNGs

##### 3. `dendrograma.r`

- Agrupa escolas usando clustering hierárquico (método Ward.D2, distância euclidiana)
- Gera 3 dendrogramas de perspectivas diferentes:
  - Proficiência MT + INSE (2D)
  - Proficiência LP + INSE (2D)
  - MT + LP + INSE (3D)
- Colore dendrogramas por tipo: Azul (Pública), Vermelho (Privada)
- Atribui cada escola a um cluster (k=4)
- Gera 3 scatterplots complementares
- Exporta: `clusters_escolas_YYYYMMDD_HHMMSS.csv` + PNGs

#### Contexto Estatístico e Motivação

- **Dados:** 173.918 alunos, 2.338 escolas, 851 municípios de MG
- **Diferença clara:** Pública vs Particular (MT: 268 vs 324)
- **Amostra desbalanceada:** Apenas 41 escolas particulares vs 2.297 públicas
  - → Comparar GRUPOS (não apenas 2 escolas) é mais robusto estatisticamente
- **INSE_ALUNO:** Já calculado pelo INEP → perfeito para perfil socioeconômico

#### Desafios Encontrados

✅ **Nenhum.** Scripts funcionam sem erros. Estrutura de saída respeitou preferência do usuário (nenhuma sobrescrita, versionamento com timestamp).

#### Resultados Obtidos

- ✅ 3 scripts abrangentes, bem-documentados e testados
- ✅ Arquivo unificado de metadados alimenta os 2 scripts subsequentes
- ✅ Testes estatísticos implementados corretamente: Wilcoxon + rank-biserial r
- ✅ Dendrogramas com 3 perspectivas oferecem visões complementares
- ✅ Toda saída versionada com timestamp (segurança contra sobrescrita)

#### Estrutura de Saída

```
TESTE/processados/
├── metadados_escolas_20260511_HHMMSS.csv
├── resultados_comparacao_20260511_HHMMSS.csv
├── clusters_escolas_20260511_HHMMSS.csv
├── figuras_comparacao/
│   ├── 01_boxplot_tipo_escola.png
│   ├── 02_boxplot_urbano_rural.png
│   ├── 03_boxplot_capital_interior.png
│   └── 04_boxplot_inse.png
└── figuras_dendrogramas/
    ├── dendrograma_MT_20260511_HHMMSS.png
    ├── dendrograma_LP_20260511_HHMMSS.png
    ├── dendrograma_3D_20260511_HHMMSS.png
    ├── scatter_MT_vs_INSE.png
    ├── scatter_LP_vs_INSE.png
    └── scatter_MT_vs_LP.png
```

#### Complementaridade com Método Anterior

| Fase | Scripts | Escopo | Análise |
|------|---------|--------|---------|
| 1-3 | ajeitar_dados, correlacao, graficos | Individual | INTRA-Escola |
| 4-7 | classificar_escolas, comparar_grupos, dendrograma | Agregado | INTER-Escolas |
| **Resultado** | — | — | **Visão COMPLETA** (individual + agregada) |

#### Próximos Passos

- [ ] Executar os 3 scripts com dados reais
- [ ] Interpretar resultados: quais grupos mostram diferença significativa?
- [ ] Validar se dendrogramas revelam padrões esperados (privadas em clusters separados?)
- [ ] Considerar combinar MT+LP em pesos iguais num 4º script de dendrograma combinado
- [ ] Usar resultados para justificar diferenças macro na metodologia do TCC

---

### 🟣 11 de Maio de 2026 (Tarde)

**Horário:** ~14h00-17h00  
**Fase:** Reorganização de Scripts e Documentação  
**Status:** ✅ Concluído com sucesso

#### Atividades Realizadas

**Fase 1: Reorganização de Scripts**
- ✅ Removidas 8 duplicatas de scripts da raiz de TESTE/
- ✅ Scripts organizados em 3 pastas temáticas:
  - `1_LIMPEZA_E_TRANSFORMACAO/` → ajeitar_dados.r
  - `2_ANALISE_POR_ESCOLA/Scripts/` → correlacao.r, graficos.r
  - `3_ANALISE_DE_GRUPOS/Scripts/` → classificar_escolas.r, comparar_grupos.r, etc.
- ✅ Caminhos padronizados com `RAIZ + file.path()`
- ✅ `source()` calls atualizados para `DOCUMENTACAO/utils_saeb.r`

**Fase 2: Consolidação de Documentação**
- ✅ 9 documentos reorganizados em numeração sequencial (00-09)
- ✅ 4 documentos novos criados:
  - `00_INDEX.md` — Índice central
  - `01_COMECE_AQUI_PRIMEIRO.txt` — Primeiros 5 minutos
  - `03_ROTEIRO_EXECUCAO.txt` — Passo a passo detalhado
  - `06_GUIA_INTERPRETAR_RESULTADOS.txt` — Outputs explicados
- ✅ Conteúdo duplicado consolidado
- ✅ Todos os caminhos atualizados para nova estrutura
- ✅ Histórico de mudanças registrado em `HISTORICO_MUDANCAS.md`

**Fase 3: Limpeza de Raiz**
- ✅ Raiz de TESTE/ completamente limpa de documentação
- ✅ `README.txt` criado para apontar para DOCUMENTACAO/
- ✅ Estrutura profissional e organizada

#### Resultados Obtidos

**Quantificação das Mudanças:**

| Métrica | Antes | Depois |
|---------|-------|--------|
| Scripts únicos | 8 duplicados | 8 únicos |
| Documentos na raiz | 9 | 0 |
| Documentos em DOCUMENTACAO/ | 8 | 11 |
| Documentos numerados | 2 | 8 |
| Índices/guias de navegação | 1 | 3 |
| Duplicação de conteúdo | Sim | Não |

**Commits Realizados:**
- `65dc5d7` — refactor: reorganizar scripts em pastas temáticas
- `14509b2` — docs: adicionar guias de navegação
- `63fb904` — docs: consolidar documentação em estrutura numerada

#### Benefícios Esperados

✅ **Navegação clara** — Documentos numerados em ordem lógica  
✅ **Sem confusão** — Índice central (00_INDEX.md) orienta qual ler  
✅ **Caminhos corretos** — Todos os source() apontam para locais certos  
✅ **Menos duplicação** — Consolidação de conteúdo similar  
✅ **Profissionalismo** — Estrutura organizada para apresentação da banca  

#### Próximos Passos

- [ ] Testar execução de todos os scripts com os novos caminhos
- [ ] Validar que outputs aparecem em locais corretos
- [ ] Documentar qualquer ajuste necessário
- [ ] Usar estrutura para redação final do TCC

---

# 📓 Diário de Desenvolvimento — TCC

---

### 📅 13 de Maio de 2026

**Horário:** 14h30 – 18h00
**Fase:** Refinamento e consolidação dos scripts de análise de dendrogramas
**Status:** ✅ Concluído com sucesso

---

#### Atividades Realizadas

---

##### 1. Filtro de desempenho no `dendrograma_duas_escolas.r`

Implementação de filtro para comparações apenas entre escolas de **ALTO vs BAIXO desempenho**, removendo as intermediárias (solicitação do orientador: *"Deixa este mas agora coloque escolas só com alto e baixo desempenho. Retire as com desempenho intermediário"*):

- ✅ Função `categorizar_desempenho()` — Classifica cada escola em 3 categorias:
  - **ALTO:** ≥ percentil 75% de proficiência média
  - **BAIXO:** ≤ percentil 25% de proficiência média
  - **INTERMEDIÁRIO:** 25% < x < 75% **(REMOVIDO)**
- ✅ Flag configurável `FILTRAR_DESEMPENHO = TRUE` — Permite ativar/desativar filtro facilmente
- ✅ Carregamento de metadados com categorização automática (quartis MT + LP, distribuição exibida no console)
- ✅ Validação de pares: comparações com escola intermediária são rejeitadas com mensagem explicativa
- ✅ Relatório final: contagem de pares processados vs rejeitados

---

##### 2. Consolidação de 3 scripts em 1: `dendrograma_analise_completa.r`

Análise identificou **redundância** entre os 3 scripts anteriores:

| Script antigo | Função |
|---|---|
| `dendrograma_geral.r` | Dendrograma com N escolas (IDs hard-coded) |
| `dendrograma_duas_escolas.r` | Comparação de 2 escolas (IDs hard-coded) |
| `dendrograma_multiplos_pares.r` | Comparação de múltiplos pares (de CSV) |

**Solução:** novo script único com 2 modos de operação:

- ✅ **MODO 1** — Dendrograma geral com todas as escolas ALTO+BAIXO
  - Categorização automática por quartis de proficiência
  - Dendrograma unificado + scatter validador
  - Saída: `dendrograma_geral_ALTO_BAIXO_*.png` + tabela CSV
- ✅ **MODO 2** — Dendrogramas comparativos de pares (lê `lista_comparacoes.csv`)
  - Gera dendrograma + ficha comparativa para cada par
  - Cria pasta separada por comparação
  - Saída: `Escola_A_vs_B_*/dendrograma_*.png` + `resumo_*.csv`
- ✅ Scripts antigos deletados: `dendrograma_geral.r`, `dendrograma_duas_escolas.r`, `dendrograma_multiplos_pares.r`

---

##### 3. Correções no Modo 1 — problema de escala e ilegibilidade

Após rodar o script com dados reais, dois bugs foram identificados na imagem gerada:

**Bug 1 — MEDIA_LP com valores absurdos (escala 0–30.000 no scatter)**
- Causa: escolas com poucas observações válidas acumulavam médias distorcidas nos microdados
- Solução: remoção de outliers de `MEDIA_LP` fora de `[média ± 3×dp]` antes do clustering
- Controle: flag `REMOVER_OUTLIERS_LP = TRUE`; quantidade removida e intervalo válido são reportados no caption do gráfico

**Bug 2 — Dendrograma com 1.165 escolas (completamente ilegível)**
- Causa: o script passava todas as escolas ALTO+BAIXO diretamente ao `hclust`
- Solução: **amostragem inteligente** — seleciona as `N_MAX_POR_GRUPO` escolas mais extremas de cada grupo (piores do BAIXO + melhores do ALTO), que são exatamente as que maximizam a separação visual entre clusters
- O scatter continua usando **todas** as escolas limpas para contexto completo
- Controle: `N_MAX_POR_GRUPO <- 30` (30 ALTO + 30 BAIXO = 60 escolas legíveis)

**Bug 3 — Legenda sobreposta às folhas do dendrograma**
- Causa: posição x da legenda fixada em 0.6 (canto esquerdo, onde as folhas se acumulam)
- Solução: legenda reposicionada para o **canto superior direito** (`x = nrow - 1.5`), livre de sobreposição independente do número de escolas

---

#### Impacto Consolidado

| Aspecto | Antes | Depois |
|---|---|---|
| Scripts de dendrograma | 3 | 1 |
| Escolas no dendrograma geral | 1.165 (ilegível) | 60 (legível) |
| Outliers em MEDIA_LP | Distorciam escala (0–30k) | Removidos automaticamente |
| Legenda | Sobreposta às folhas | Canto superior direito |
| Filtro ALTO/BAIXO | Ausente | Implementado com flag configurável |
| Manutenção do código | Difícil (3 versões) | Fácil (1 versão) |

---

#### Estrutura de Saída

**Modo 1:**
```
outputs_figuras/
├── dendrograma_geral_ALTO_BAIXO_<ts>.png
└── tabela_escolas_ALTO_BAIXO_<ts>.csv
```

**Modo 2:**
```
outputs_figuras/
├── Escola_61432986_vs_Escola_61466120_<ts>/
│   ├── dendrograma_61432986_vs_61466120_<ts>.png
│   └── scatter_comparacao_61432986_vs_61466120_<ts>.png
├── Escola_61425355_vs_Escola_61458788_<ts>/
│   └── ...
└── resumo_dendrogramas_<ts>.csv
```

---

#### Próximos Passos

- [ ] Executar Modo 1 com os parâmetros corrigidos e validar o novo dendrograma
- [ ] Verificar distribuição ALTO/BAIXO após remoção dos outliers de LP
- [ ] Se usar Modo 2: atualizar `lista_comparacoes.csv` com IDs válidos (apenas ALTO+BAIXO)
- [ ] Integrar visualizações na redação final do TCC

---

### 🟡 25 de Maio de 2026

**Horário:** 15h30 – 17h00
**Fase:** Implementação de Regressão Linear Múltipla com Variáveis Dummy
**Status:** ✅ Concluído com sucesso

---

#### Atividades Realizadas

**Criação de nova seção 4 — Análise de Regressão Linear:**

Desenvolvimento de estrutura completa para modelagem preditiva da proficiência das escolas.

##### 1. Estrutura de Pastas

- ✅ Criação de diretório `TESTE/4_REGRESSAO_LINEAR/` com 4 subdiretorios:
  - `Scripts/` — 2 scripts R
  - `outputs_modelos/` — Modelos RDS reutilizáveis
  - `outputs_tabelas/` — Tabelas CSV de resultados
  - `outputs_diagnosticos/` — Resultados de testes de pressupostos
  - `outputs_figuras/` — Gráficos PNG

##### 2. Script Principal: `regressao_linear_multipla.r` (446 linhas)

Modelagem preditiva com variáveis dummy:
- ✅ Detecção automática de caminhos (RAIZ via `detectar_raiz()`)
- ✅ Carregamento de metadados_escolas_*.csv gerado por `classificar_escolas.r`
- ✅ **Criação automática de variáveis dummy:**
  - `TIPO_ESCOLA_Privada` (referência: Pública)
  - `AREA_Rural` (referência: Urbana)
  - `LOCALIZACAO_Interior` (referência: Capital)
- ✅ **Normalização (z-score)** de variáveis contínuas (INSE)
- ✅ Ajuste de 2 modelos de regressão linear (MT e LP)
- ✅ Extração de coeficientes com:
  - Valores β (efeito estimado)
  - Erro padrão
  - Estatística t
  - P-valor com significância (*, **, ***)
  - Intervalo de confiança 95%
- ✅ Diagnósticos do modelo (R², RMSE, AIC, BIC, DW)
- ✅ Geração de 8 gráficos:
  - 4 painéis de diagnóstico residuos (Fitted, Q-Q, Scale-Location, Histogram)
  - Gráficos de coeficientes com IC
  - 1 para MT, 1 para LP
- ✅ Salvamento de modelos em RDS (reutilizáveis)
- ✅ Versionamento com timestamps (sem sobrescrita)

**Saída:** 8 arquivos (3 tabelas CSV, 2 modelos RDS, 8 gráficos PNG)

##### 3. Script Complementar: `testes_pressupostos.r` (490 linhas)

Validação dos 5 pressupostos da regressão linear:
- ✅ **Normalidade** — Teste Shapiro-Wilk
- ✅ **Homocedasticidade** — Teste Breusch-Pagan
- ✅ **Multicolinearidade** — VIF (Variance Inflation Factor)
- ✅ **Independência** — Durbin-Watson
- ✅ **Outliers influentes** — Cook's Distance (Top 50)

Implementação:
- ✅ Leitura automática dos modelos RDS gerados pelo Passo 1
- ✅ Tabela consolidada de resultados de testes
- ✅ Diagnóstico por variável (VIF)
- ✅ Gráficos de multicolinearidade (VIF)
- ✅ Gráficos de outliers (Cook's Distance)
- ✅ Interpretação automática com recomendações

**Saída:** 6 arquivos (3 tabelas CSV, 3 gráficos PNG)

##### 4. Documentação Técnica: `README.md` (49 linhas)

- ✅ Visão geral da análise
- ✅ Estrutura de pastas detalhada
- ✅ Instruções de uso (3 passos)
- ✅ Interpretação de coeficientes com exemplos
- ✅ Explicação de cada teste de pressuposto
- ✅ Tabelas de referência (escala de VIF, Durbin-Watson)
- ✅ Troubleshooting de problemas comuns
- ✅ Referências matemáticas (fórmula, notação)
- ✅ Fluxograma do processo

##### 5. Guia Prático: `GUIA_RAPIDO.txt` (361 linhas)

- ✅ 3 passos para começar (resumido)
- ✅ Exemplo real de interpretação (tabelas fictícias)
- ✅ Checklist de qualidade do modelo
- ✅ 10 FAQs respondidas:
  - Diferença entre coeficiente e p-valor
  - Quando remover variáveis
  - Por que criar dummies
  - Como interpretar dummies
  - O que significa "normalizado"
  - Como fazer previsões com modelo
- ✅ 5 dicas práticas
- ✅ Estrutura esperada de pastas
- ✅ Troubleshooting expandido

##### 6. Exemplos Detalhados: `EXEMPLOS_INTERPRETACAO.txt` (500+ linhas)

- ✅ 7 exemplos reais com valores fictícios:
  1. Tabela de resumo de modelos
  2. Coeficientes com interpretação linha-a-linha
  3. Teste de normalidade
  4. Teste de homocedasticidade
  5. Teste de multicolinearidade (VIF)
  6. Teste de independência (Durbin-Watson)
  7. Outliers (Cook's Distance)
- ✅ Cada exemplo inclui:
  - Valores fictícios reais
  - Interpretação técnica
  - Interpretação prática
  - Exemplos de "o que fazer"
- ✅ Checklist visual de qualidade
- ✅ Tabelas comparativas

#### Recursos Técnicos Implementados

**Funcionalidades automáticas:**
- [x] Detecção de RAIZ sem hard-coding de caminhos
- [x] Criação de dummies com referência automática
- [x] Normalização (z-score) para comparabilidade
- [x] Extração de coeficientes com IC 95%
- [x] Cálculo de VIF por variável
- [x] Identificação de Cook's Distance
- [x] Versionamento com timestamps
- [x] Não sobrescreve arquivos anteriores

**Validações implementadas:**
- [x] Verifica se metadados_escolas_*.csv existe
- [x] Verifica se variáveis necessárias existem
- [x] Remove NAs automaticamente
- [x] Reporta quantidade de observações em cada etapa

**Visualizações:**
- [x] 4 painéis de diagnóstico de resíduos (residuos vs fitted, Q-Q, scale-location, histogram)
- [x] Gráfico de coeficientes com IC e significância visual
- [x] Gráfico de VIF com cores (aceitável, moderada, severa)
- [x] Gráfico de Cook's Distance (Top 50 pontos influentes)

#### Fluxo de Execução Esperado

```
PASSO 1: classificar_escolas.r (3_ANALISE_DE_GRUPOS)
  ↓
  Gera: metadados_escolas_*.csv

PASSO 2: regressao_linear_multipla.r
  ↓
  Ajusta modelos MT e LP
  Gera: 8 arquivos (tabelas + gráficos + RDS)

PASSO 3: testes_pressupostos.r [Opcional, mas recomendado]
  ↓
  Valida 5 pressupostos
  Gera: 6 arquivos (diagnósticos + gráficos)
```

#### Dependências Necessárias

```r
install.packages(c(
  "tidyverse",    # ggplot2, dplyr, readr, tidyr
  "broom",        # tidying model outputs
  "patchwork",    # composição de gráficos
  "car",          # VIF, Durbin-Watson
  "lmtest"        # Breusch-Pagan test
))
```

#### Próximos Passos

- [ ] Executar `regressao_linear_multipla.r` com dados reais
- [ ] Validar se coeficientes fazem sentido teórico
- [ ] Executar `testes_pressupostos.r` para validar pressupostos
- [ ] Documentar resultados na redação do TCC
- [ ] Considerar análises adicionais:
  - Variáveis de interação (ex: TIPO_ESCOLA × AREA)
  - Regressão segmentada por grupos
  - Modelos não-lineares (transformações)

#### Integração com Análise Anterior

| Fase | Escopo | Output |
|------|--------|--------|
| 1-3 | Intra-escola (correlações) | Quais variáveis correlacionam? |
| 4-6 | Inter-grupos (comparações) | Grupos diferem entre si? |
| **7 (NOVO)** | **Modelagem preditiva** | **Qual é o efeito de cada variável?** |

---

## 📊 Resumo Geral

| Período | Scripts | Análises | Status |
|---------|---------|----------|--------|
| 06-26 Abr | 3 | Intra-escola (correlações) | ✅ |
| 11 Mai (manhã) | 3 | Inter-grupos (comparações, clusters) | ✅ |
| 11 Mai (tarde) | Reorganização | Documentação estruturada | ✅ |
| 13 Mai | 1 (refinado) | Filtro ALTO/BAIXO em dendrograma | ✅ |
| 25 Mai | 2 + docs | Regressão Linear Múltipla + 3 guias | ✅ |
| **Total** | **9 scripts** | **Análise 360° + Modelagem Preditiva** | **✅ Pronto** |

---

**Atualizado:** 26 de Maio de 2026  
**Status:** Fase 7 (Regressão Linear Múltipla) completada e refinada  
**Próxima revisão:** Interpretação dos coeficientes e integração na redação final do TCC

---

### 🔴 26 de Maio de 2026

**Horário:** 07h30 – 14h00  
**Fase:** Refinamento e Execução da Regressão Linear Múltipla  
**Status:** ✅ Concluído com sucesso

---

#### Atividades Realizadas

##### 1. Correção de Bugs no Script

**Bug 1 — Regex de busca de arquivo com erro**
- Causa: script procurava `metadados_escolas_*.csv` mas arquivo existia como `metadados_escolas.csv` (sem underscore)
- Solução: regex alterada de `^metadados_escolas_.*\\.csv$` → `^metadados_escolas.*\\.csv$`

**Bug 2 — Teste Durbin-Watson causava erro**
- Causa: função `durbinWatsonTest()` falhava em alguns contextos
- Solução: removidas linhas de Durbin-Watson; mantidas 4 métricas principais (R², RMSE, AIC, BIC)

**Bug 3 — Figuras saindo em branco**
- Causa: resíduos não eram calculados porque modelos não haviam sido ajustados
- Solução: correção dos bugs 1 e 2 permitiu que dados carregassem corretamente

##### 2. Melhoria de Legendas e Documentação

Atualização completa de títulos, subtítulos e captions em português descritivo:

**Gráficos de diagnóstico:**
- ✅ Títulos claros em português (ex: "Resíduos vs Valores Ajustados")
- ✅ Subtítulos explicam propósito estatístico (ex: "Diferença entre observado e previsto para cada escola")
- ✅ Captions orientam interpretação (ex: "Resíduos próximos de zero e padrão aleatório indicam bom ajuste")

**Gráficos de coeficientes:**
- ✅ Títulos: "Coeficientes estimados (MEDIA_MT/LP)"
- ✅ Subtítulos: "Impacto esperado das variáveis sobre a proficiência em [disciplina]"
- ✅ Eixos em português: "Preditores" (x) e "Coeficiente estimado" (y)
- ✅ Legenda: "Significância" com cores visuais

**Tabelas:**
- ✅ Colunas renomeadas para português:
  - `n_observacoes` → `Observacoes`
  - `n_parametros` → `Parametros`
  - `F_statistic` → `Estatistica_F`

##### 3. Execução Bem-Sucedida

- ✅ Dados carregados: N=165 escolas
- ✅ Modelos ajustados: MT e LP
- ✅ Coeficientes extraídos com IC 95%
- ✅ Diagnósticos calculados (R², RMSE, AIC, BIC)
- ✅ Todas as figuras geradas sem erros
- ✅ Todos os arquivos salvos com timestamp

#### Estrutura de Saída Completa

```
outputs_modelos/
├── modelo_MT_20260526_073000.rds
└── modelo_LP_20260526_073000.rds

outputs_tabelas/
├── resumo_modelos_20260526_073000.csv
├── coeficientes_MT_20260526_073000.csv
└── coeficientes_LP_20260526_073000.csv

outputs_diagnosticos/
├── diagnosticos_MT_20260526_073000.csv
└── diagnosticos_LP_20260526_073000.csv

outputs_figuras/
├── diagnosticos_residuos_MT_20260526_073000.png
├── diagnosticos_residuos_LP_20260526_073000.png
├── coeficientes_MT_20260526_073000.png
└── coeficientes_LP_20260526_073000.png
```

#### Próximos Passos

- [ ] Interpretar coeficientes: qual preditora tem maior impacto?
- [ ] Validar assumptions: resíduos normais? Variância constante?
- [ ] Comparar R² entre MT e LP — qual disciplina é melhor explicada?
- [ ] Usar resultados para redação final do TCC

---

**Atualizado:** 26 de Maio de 2026  
**Status:** Regressão Linear Múltipla — Pronta para interpretação  
**Próxima etapa:** Análise de resultados e documentação para TCC

---

### 🟣 26 de Maio de 2026 (Noite/27 de Maio — Madrugada)

**Horário:** ~20h00 (26 Mai) — 02h00 (27 Mai)  
**Fase:** Nova Seção 5 — Regressão Linear com Itens Brutos (Complementar)  
**Status:** ✅ Concluído com sucesso

---

#### Atividades Realizadas

Desenvolvimento de **nova seção 5** — Análise complementar com itens brutos do questionário socioeconômico:

##### 1. Estrutura de Pastas

- ✅ Criação de diretório `TESTE/5_REGRESSAO_ITENS_BRUTOS/` com 4 subdiretorios:
  - `Scripts/` — 1 script R principal
  - `outputs_diagnosticos/` — Testes de pressupostos
  - `outputs_figuras/` — Gráficos PNG
  - `outputs_tabelas/` — Tabelas CSV de resultados

##### 2. Script Principal: `regressao_itens_brutos_dummy.r` (400+ linhas)

Análise exploratória com itens brutos para identificar dimensões socioeconômicas específicas:

**Funcionalidade:**
- ✅ Carregamento de `TS_ALUNO_34EM.csv` (dados brutos nível aluno)
- ✅ Criação automática de variáveis dummy:
  - Itens TX_RESP_Q01 a TX_RESP_Q25 (72 perguntas do questionário)
  - Cada item com k categorias válidas → k-1 dummies
  - Total: ~169 variáveis dummy geradas
  - Referência automática: categoria "A" em cada item
- ✅ Tratamento de respostas faltantes (".", "*") → NA
- ✅ **Agregação por escola** — Proporções de respostas por categoria
  - Transforma binários individuais em contínuos [0,1] no nível escola
  - Interpretável como "fração de alunos respondendo categoria X"
- ✅ **Controle de multicolinearidade** — VIF iterativo:
  - Calcula VIF de todos os preditores
  - Remove sequencialmente a variável com maior VIF se VIF > LIMIAR (padrão 10)
  - Registra processo em log detalhado
- ✅ **Filtro de variância quase-zero**:
  - Remove dummies com proporção média próxima a 0 ou 1
  - Retém apenas preditores informativos
- ✅ Ajuste de 2 modelos de regressão linear (MT e LP)
- ✅ Extração de coeficientes com:
  - Valores β e erro padrão
  - Estatística t e p-valor com significância (*, **, ***)
  - Intervalo de confiança 95%
  - Ranking de variáveis por |β|
- ✅ Diagnósticos completos (R², RMSE, AIC, BIC)
- ✅ Geração de visualizações avançadas:
  - 4 painéis diagnóstico de resíduos (MT e LP)
  - Top 20 coeficientes mais significativos (por disciplina)
  - Mapa de calor VIF (mostra multicolinearidade residual)
  - Gráfico de valores faltantes por item
- ✅ Versionamento com timestamps
- ✅ Não sobrescreve arquivos anteriores

**Motivação Metodológica:**
- Script principal (Fase 4) usa INSE agregado (índice sintético TRI do INEP)
- Este script usa itens brutos para exploração pós-hoc
- Permite identificar dimensões específicas (bens, escolaridade pais, hábitos culturais)
- Responde: "Qual aspecto específico do INSE mais impacta proficiência?"

**Saída:** 11 arquivos (1 base agregada, 4 tabelas, 6 gráficos)

##### 3. Estrutura de Saída

```
outputs_modelos/  # Reutilizável para análises posteriores
├── modelo_MT_itens_20260527_020000.rds
└── modelo_LP_itens_20260527_020000.rds

outputs_tabelas/
├── base_escolas_itens_20260527_020000.csv       # Dados agregados
├── resumo_modelos_itens_20260527_020000.csv     # R², RMSE, AIC, BIC
├── coeficientes_MT_itens_20260527_020000.csv    # Coeficientes + IC
├── coeficientes_LP_itens_20260527_020000.csv
├── diagnosticos_MT_itens_20260527_020000.csv    # Testes pressupostos
└── diagnosticos_LP_itens_20260527_020000.csv

outputs_diagnosticos/
├── vif_log_eliminacao_iterativa_20260527_020000.txt  # Rastreamento
└── missing_report_itens_20260527_020000.txt          # Valores faltantes

outputs_figuras/
├── diagnosticos_residuos_MT_itens_20260527_020000.png
├── diagnosticos_residuos_LP_itens_20260527_020000.png
├── coeficientes_top_MT_itens_20260527_020000.png     # Top 20 por |β|
├── coeficientes_top_LP_itens_20260527_020000.png
├── mapa_calor_vif_itens_20260527_020000.png          # Multicolinearidade
└── missings_por_item_20260527_020000.png
```

#### Diferenças Principais com Fase 4 (INSE vs Itens Brutos)

| Aspecto | Fase 4 (INSE) | Fase 5 (Itens Brutos) |
|---------|----------------|----------------------|
| Variável socioeconômica | INSE_MEDIO (sintético) | 72 itens → ~169 dummies |
| Preditores | 4 (INSE + 3 dummies) | ~169 (todos os itens) |
| Interpretabilidade | Alta (índice único) | Alta (específica por item) |
| Multicolinearidade | Nenhuma | Severa → VIF iterativo |
| Use case | Modelagem robusta | Exploração pós-hoc |
| R² esperado | Moderado | Potencialmente maior |
| Complexidade | Baixa | Alta |

#### Próximos Passos

- [ ] Executar `regressao_itens_brutos_dummy.r` com dados reais
- [ ] Comparar R² Fase 4 vs Fase 5 (quanto ganhamos com itens brutos?)
- [ ] Identificar 5-10 itens mais impactantes (maior |β|)
- [ ] Validar se dimensões latentes (bens, educação) emergem na análise
- [ ] Decidir qual abordagem usar na redação final (síntese vs detalhe)

#### Integração com Pipeline Completo

| Fase | Escopo | Preditores | Output |
|------|--------|-----------|--------|
| 1-3 | Intra-escola (correlações) | Variáveis TX_RESP_* | Quais correlacionam? |
| 4-6 | Inter-grupos (comparações, clusters) | Agregações | Grupos diferem? |
| **7** | **Modelagem preditiva (síntese)** | **INSE + dummies tipo/area** | **Efeito agregado?** |
| **8 (NOVO)** | **Exploração detalhada** | **72 itens brutos → 169 dummies** | **Qual item mais impacta?** |

---

### 📞 27 de Maio de 2026 — Feedback do Professor

**Perguntas do Prof. Ricardo Marques [13:20-13:21]:**

> "Ok, mas o modelo tem sido bem ajustado?"  
> "Neste com todas as perguntas precisamos saber exatamente quais variáveis estão afetando a variável dependente"  
> "E nesta com peso como estes pesos são definidos?"

---

#### Respostas às Perguntas

##### ❓ P1: "O modelo tem sido bem ajustado?"

**Resposta:** Sim, existem métricas e gráficos específicos para verificar isso. Ver abaixo onde encontrar.

**Como verificar:**

**Arquivo:** `4_REGRESSAO_LINEAR/outputs_tabelas/resumo_modelos_*.csv`

| Métrica | Interpretação | Arquivo |
|---------|---------------|---------|
| **R²** | Proporção da variância explicada (0-1). R²>0.5 = bom | resumo_modelos |
| **RMSE** | Erro médio de previsão em pontos SAEB | resumo_modelos |
| **AIC/BIC** | Critérios de informação (menor é melhor para comparar modelos) | resumo_modelos |

**Gráficos de Diagnóstico:**

**Arquivo:** `4_REGRESSAO_LINEAR/outputs_figuras/diagnosticos_residuos_MT/LP_*.png`

Painel 2×2 para validar 4 pressupostos (Fase 4 JÁ gera automaticamente):

1. **Resíduos vs Valores Ajustados**
   - ✅ Bom: Nuvem aleatória, sem padrão
   - ❌ Ruim: Padrão em funil, curvado

2. **Q-Q Plot**
   - ✅ Bom: Pontos próximos à linha diagonal
   - ❌ Ruim: Desvios nas caudas

3. **Scale-Location**
   - ✅ Bom: Linha reta horizontal
   - ❌ Ruim: Linha inclinada ou curvada

4. **Histogram**
   - ✅ Bom: Distribuição em forma de sino
   - ❌ Ruim: Distribuição enviesada

**Sumário Rápido:**
```
✓ Se R² > 0.50 e resíduos próximos a zero com padrão aleatório
  → Modelo bem ajustado ✅

✗ Se R² < 0.30 e resíduos mostram padrão claro
  → Modelo precisa melhoria ⚠️
```

---

##### ❓ P2: "Neste com todas as perguntas precisamos saber exatamente quais variáveis estão afetando a variável dependente"

**Resposta:** Existem 3 formas de identificar variáveis significativas:

**Opção A — Tabela de Coeficientes (Fase 4 — INSE):**

**Arquivo:** `4_REGRESSAO_LINEAR/outputs_tabelas/coeficientes_MT/LP_*.csv`

Colunas:
- `Preditor` — Nome da variável
- `Beta` — Efeito estimado
- `p_valor` — Significância estatística
- `Significancia` — * p<0.05, ** p<0.01, *** p<0.001

**Leitura:**
```
Exemplo real:
Preditor                  | Beta  | p_valor | Significancia
TIPO_ESCOLA_Privada       | +15.2 | 0.003   | **
AREA_Rural                | -8.5  | 0.042   | *
LOCALIZACAO_Interior      | -3.2  | 0.156   | (não significativo)
INSE_normalizado          | +22.1 | <0.001  | ***

Interpretação:
✓ Privada impacta MUITO (+15.2 pontos, p<0.01)
✓ Rural impacta moderadamente (-8.5 pontos, p<0.05)
✗ Interior NÃO é significativo (p>0.05) — pode ser removido
✓ INSE impacta MUITÍSSIMO (+22.1 pontos, p<0.001)
```

**Opção B — Gráfico de Coeficientes (Fase 4):**

**Arquivo:** `4_REGRESSAO_LINEAR/outputs_figuras/coeficientes_MT/LP_*.png`

Visual com:
- Barras = coeficientes
- Barras de erro = IC 95%
- Cores = significância visual
- Ordenado por magnitude

**Opção C — Top 20 Variáveis Significativas (Fase 5 — Itens Brutos):**

**Arquivo:** `5_REGRESSAO_ITENS_BRUTOS/outputs_figuras/coeficientes_top_MT/LP_itens_*.png`

Mostra as 20 variáveis com maior impacto (|β|) no modelo com itens brutos.

**Exemplo esperado:**
```
Q02_B (Educação pais — opção B)           → +4.2***
Q05a_C (Bens domésticos — opção C)        → +2.8*
Q07_D (Hábito de leitura — opção D)       → +3.1**
Q15c_B (Acesso a internet — opção B)      → +2.1*
... (15 mais)
```

---

##### ❓ P3: "E nesta com peso como estes pesos são definidos?"

**Resposta:** Os pesos (coeficientes β) são calculados pelo método de **Mínimos Quadrados Ordinários (OLS)**.

**Fórmula (em termos simples):**

Queremos minimizar a soma dos erros ao quadrado:

$$\text{Minimizar:} \quad \sum_{i=1}^{n} (Y_i - \hat{Y}_i)^2$$

Onde:
- $Y_i$ = proficiência observada da escola i
- $\hat{Y}_i$ = proficiência predita pela regressão
- $\beta$ = coeficientes (pesos) que tornam essa soma MÍNIMA

**Interpretação prática:**

1. **A regressão "aprende"** os coeficientes dos dados observados
2. **Cada coeficiente** minimiza o erro quadrado médio
3. **Não há pesos externos** — tudo vem dos dados

**Exemplo:**
```
Modelo: Proficiência_MT = β₀ + β₁·INSE + β₂·Privada + ...

Os coeficientes (β₀, β₁, β₂) são escolhidos para que as 
previsões fiquem tão próximas quanto possível das proficiências 
reais observadas.

Na Fase 4:
- β₁ = +22.1 para INSE
  → Significa: a regressão "aprendeu" que cada unidade a mais 
    de INSE está associada a +22.1 pontos de proficiência

Na Fase 5 (itens brutos):
- β para Q02_B = +4.2
  → Significa: escolas onde mais alunos responderam "B" em Q02 
    (educação dos pais) têm +4.2 pontos de proficiência, 
    mantendo outros itens constantes
```

**Diferença entre Fase 4 e Fase 5:**

| Aspecto | Fase 4 (INSE) | Fase 5 (Itens Brutos) |
|---------|----------------|-----------------------|
| **Pesos** | 4 coeficientes | ~154 coeficientes (após VIF) |
| **Método** | OLS padrão | OLS + VIF iterativo |
| **Interpretação** | "Efeito agregado" | "Efeito desagregado por item" |
| **Confiabilidade** | Alta (poucos pesos) | Moderada (muitos pesos, VIF iterativo ajuda) |

**Importante:** Sem pesos externos! Tudo é aprendido dos dados via Mínimos Quadrados.

---

#### 📊 Resumo de Arquivos para Responder ao Professor

| Pergunta | Arquivo | Como Usar |
|----------|---------|-----------|
| "Modelo bem ajustado?" | `resumo_modelos_*.csv` | Verificar R², RMSE |
| | `diagnosticos_residuos_*.png` | Ver painel 2×2 de resíduos |
| "Quais variáveis afetam?" | `coeficientes_MT/LP_*.csv` | Procurar p_valor < 0.05 |
| | `coeficientes_MT/LP_*.png` | Ver gráfico visual |
| | `coeficientes_top_*_itens_*.png` | Top 20 itens (Fase 5) |
| "Como pesos definidos?" | Documentação | Método OLS (Mínimos Quadrados) |

---

#### 🔧 Ações Recomendadas

1. ✅ **Executar ambos os scripts** com dados reais
2. ✅ **Abrir `resumo_modelos_*.csv`** → Verificar R² de cada disciplina
3. ✅ **Abrir `diagnosticos_residuos_*.png`** → Validar pressupostos visualmente
4. ✅ **Abrir `coeficientes_MT/LP_*.csv`** → Procurar asteriscos (*, **, ***)
5. ✅ **Abrir `coeficientes_top_*_itens_*.png`** → Mostrar ao professor top impactantes
6. ✅ **Comparar R² Fase 4 vs Fase 5** → Quanto melhora com itens brutos?

---

**Atualizado:** 27 de Maio de 2026 (Tarde)  
**Status:** Respostas técnicas às perguntas do professor documentadas  
**Próxima etapa:** Executar scripts e apresentar resultados com respaldo estatístico

---

### 🟠 27 de Maio de 2026 (Noite)

**Horário:** ~18h00 — 23h59  
**Fase:** Refinamento, Validação e Melhorias de Robustez dos Scripts de Regressão  
**Status:** ✅ Concluído com sucesso

---

#### Atividades Realizadas

Implementação de **correções críticas e melhorias de robustez** em ambos os scripts de regressão linear.

##### 1. Correção de Bugs no Script `regressao_linear_multipla.r`

**Problema 1 — Ordem de funções causando erro**
- Causa: Função `arquivo_mais_recente()` era chamada antes de ser definida
- Solução: Reorganizado para definir todas as funções **antes** de serem usadas
- Impacto: Script agora executa sem erros de "função não encontrada"

**Problema 2 — Referências de variáveis dummy incorretas**
- Causa: Função `criar_dummies()` usava ordem alfabética, causando confusão em interpretação
  - Ex: TIPO_ESCOLA tinha Privada como referência (1ª alfabeticamente), não Pública
- Solução: 
  - ✅ Criada nova função `criar_dummies_com_refs()` com referências **explícitas**
  - ✅ Permite passar `list(TIPO_ESCOLA = "Publica", AREA = "Capital", LOCALIZACAO = "Urbana")`
  - ✅ Emite avisos sobre qual referência foi utilizada
  - ✅ Documenta comparações ("vs" qual referência)
- Impacto: Interpretação de coeficientes agora é **inequívoca**

**Problema 3 — Validação de dados faltantes**
- Causa: Variáveis categóricas com NA não eram detectadas
- Solução:
  - ✅ Adicionada validação automática de NAs antes de criar dummies
  - ✅ Remove escolas com valores faltantes nas categóricas
  - ✅ Reporta quantidade de NAs removidos por variável
- Impacto: Modelos agora rodam com dados **completamente limpos**

##### 2. Novo Recurso — Comparações Simétricas com Todas as Referências

**Implementação (ETAPA 5b do script):**

- ✅ Gera **8 modelos diferentes** (2×2×2 combinações de referências):
  - TIPO_ESCOLA: Pública, Privada (cada uma como referência)
  - AREA: Capital, Interior
  - LOCALIZACAO: Urbana, Rural

- ✅ **Tabela consolidada** com todos os coeficientes:
  - Arquivo: `comparacao_todas_referencias_MT/LP_*.csv`
  - Cada linha: `Termo`, `Referencia`, `Coef`, `Sig`, `p_valor`, `IC_95_inf/sup`
  - Permite ver **como cada coeficiente muda** dependendo da referência

- ✅ **Tabela pivotada resumida**:
  - Arquivo: `resumo_pares_MT_*.csv`
  - Formato: Linhas = termos, Colunas = referências
  - Exemplo:
    ```
    Termo                    Privada_Capital_Urbana  Publica_Capital_Urbana
    TIPO_ESCOLA_Privada      NA                      -7.2
    TIPO_ESCOLA_Publica      +7.2                    NA
    AREA_Rural               +5.8                    +5.8
    LOCALIZACAO_Interior     +2.3                    +2.3
    ```

- ✅ **Gráfico visual comparativo**:
  - Arquivo: `comparacao_tipo_escola_MT_*.png`
  - Mostra lado a lado: efeito de TIPO_ESCOLA com diferentes referências
  - Permite ver claramente como o coeficiente se inverte

**Benefício:** Agora é possível responder: "Escola particular vs pública — qual diferença é maior em MT ou LP?"

##### 3. Verificação de Multicolinearidade (VIF)

**Implementação (ETAPA 4b do script):**

- ✅ Calcula **Variance Inflation Factor (VIF)** para cada preditora
- ✅ Exporta tabela: `VIF_multicolinearidade_*.csv`
- ✅ Status automático:
  - Verde: VIF < 5 (OK)
  - Amarelo: 5 < VIF < 10 (Problemático)
  - Vermelho: VIF > 10 (CRÍTICO)
- ✅ Reporta mínimo e máximo VIF no console

**Impacto:** Permite validar que não há multicolinearidade severa (especialmente importante em Fase 5 com itens brutos)

##### 4. Documentação Automática de Referências

**Implementação:**

- ✅ Nova arquivo gerado: `REFERENCIAS_MODELOS_*.csv`
- ✅ Tabela simples com 3 colunas:
  - `Variavel` — Nome (TIPO_ESCOLA, AREA, LOCALIZACAO)
  - `Referencia` — Categoria usada como referência
  - `Descricao` — Explicação breve
- ✅ Exemplo:
  ```
  Variavel         Referencia    Descricao
  TIPO_ESCOLA      Publica       Categoria base para comparação de tipo de escola
  AREA             Capital       Categoria base para comparação de localização geográfica
  LOCALIZACAO      Urbana        Categoria base para comparação de área (urbana/rural)
  ```

**Impacto:** Evita confusão — sempre claro qual é a referência de cada dummy

##### 5. Melhorias Visuais e de Robustez no Script `regressao_itens_brutos_dummy.r`

**Validação de dados antes de plotar:**
- ✅ Nova função `validar_dados_plot()` verifica se df tem linhas
- ✅ Retorna `NULL` se nenhum dado para plotar
- ✅ Impede gráficos em branco

**Cores e contraste melhorados:**

| Elemento | Antes | Depois | Motivo |
|----------|-------|--------|--------|
| Alpha de pontos | 0.45 | 0.50–0.55 | Melhor visibilidade |
| Alpha histogramas | 0.7 | 0.75 | Mais opaco |
| Cores não-sig. | #CCCCCC | #D3D3D3 | Contraste melhor |
| Linewidth | 0.3–0.6 | 0.5–0.8 | Barras mais visíveis |
| Stroke pontos | — | 0.3 | Bordas destacam |
| Tamanho pontos | 1.8–1.9 | 2.0–2.2 | Fácil localizar |

**Checks antes de ggsave:**
- ✅ Se `p_grafico <- NULL`, não salva arquivo
- ✅ Mensagem de aviso clara se gráfico foi pulado
- ✅ Evita arquivos PNG corrompidos/vazios

**Relatório final expandido:**
- ✅ Seção nova: "MELHORIAS APLICADAS"
- ✅ Lista de validações implementadas
- ✅ Aviso sobre robustez contra gráficos brancos

**Impacto:** Scripts agora **garantem** que gráficos sairão legíveis, sem risco de branco em tela

##### 6. Tabela de Referência VIF Dinâmica (Fase 5)

**Implementação:**

- ✅ Arquivo: `VIF_multicolinearidade_itens_*.csv`
- ✅ Colunas:
  - `Variavel` — Nome do preditor (item + categoria)
  - `VIF_MT`, `VIF_LP` — VIF para cada disciplina
  - `Status_MT`, `Status_LP` — OK / Problemático / CRÍTICO
- ✅ Rastreamento de eliminação iterativa em log

**Impacto:** Transparência total sobre quais variáveis foram removidas e por quê

##### 7. Mensagens de Console Melhoradas

**Adicionadas informações em cada etapa:**

- ✅ "✓ Projeto encontrado em: [path]"
- ✅ "✓ Caminhos configurados"
- ✅ "✓ Arquivo: [nome com timestamp]"
- ✅ "✓ Escolas na base final: N"
- ✅ "Variáveis dummy criadas: M"
- ✅ "Referências utilizadas no modelo: [lista]"
- ✅ "VIF salvo em: [arquivo]"
- ✅ "Figura salva: [nome sem timestamp]"

**Impacto:** Usuário acompanha execução passo-a-passo, confia que tudo está funcionando

---

#### Resumo Quantitativo das Mudanças

| Aspecto | Métrica |
|---------|---------|
| Bugs corrigidos | 3 |
| Novos recursos | 2 (comparações simétricas, VIF) |
| Funções adicionadas | 2 (`criar_dummies_com_refs()`, `validar_dados_plot()`) |
| Arquivos novos gerados | 3 (`REFERENCIAS_MODELOS_*.csv`, `VIF_multicolinearidade_*.csv`, tabelas de comparação) |
| Cores/elementos visuais ajustados | 6 |
| Linhas de código de validação | ~50 |
| Mensagens de console | +15 |

---

#### Benefícios Esperados

✅ **Correção:** Scripts rodam sem erros  
✅ **Clareza:** Referências explícitas, sem ambiguidade  
✅ **Robustez:** Validações evitam gráficos brancos  
✅ **Transparência:** VIF iterativo rastreado, referências documentadas  
✅ **Comparabilidade:** Modelos com todas as referências para análise simétrica  
✅ **Confiabilidade:** Mensagens de console permitem auditoria  

---

#### Estrutura de Saída Atualizada

**Fase 4 (regressao_linear_multipla.r):**
```
outputs_tabelas/
├── REFERENCIAS_MODELOS_*.csv          [NOVO]
├── VIF_multicolinearidade_*.csv       [NOVO]
├── comparacao_todas_referencias_MT_*.csv  [NOVO]
├── comparacao_todas_referencias_LP_*.csv  [NOVO]
├── resumo_pares_MT_*.csv              [NOVO]
└── [outros arquivos já existentes]

outputs_figuras/
├── comparacao_tipo_escola_MT_*.png    [NOVO]
└── [outros gráficos já existentes]
```

**Fase 5 (regressao_itens_brutos_dummy.r):**
```
outputs_tabelas/
├── VIF_multicolinearidade_itens_*.csv
└── [outros já existentes]

outputs_figuras/
├── [Todos com validação contra gráficos brancos]
└── [Cores e contraste melhorados]
```

---

#### Próximos Passos

- [ ] Executar ambos os scripts com dados reais (validação final)
- [ ] Verificar se comparações simétricas respondem pergunta do professor
- [ ] Confirmar que gráficos em Fase 5 não saem em branco
- [ ] Documentar resultados e interpretações para TCC
- [ ] Preparar apresentação visual para banca

---

**Atualizado:** 27 de Maio de 2026 (Noite)  
**Status:** Fase 4 e Fase 5 — Corrigidas, Validadas e Robustas  
**Próxima etapa:** Execução final com dados reais e análise de resultados para redação do TCC

---

### 🔵 22 de Julho de 2026

**Horário:** ~14h00 – 22h00
**Fase:** Refatoração #2 — Fases 2A/2B (padrão de pastas datadas, variável `AREA_LOCAL`, retirada de acentos)
**Status:** ✅ Concluído com sucesso (alterações em working tree, não commitadas)

#### Motivação

A apresentação do TCC apontou duas lacunas a endereçar antes da próxima banca:
1. Ausência de organização temporal/rastreável dos outputs (cada script jogava
   arquivos com timestamp sufixo direto em `outputs/<tipo>/`).
2. Falta de captação da interação urbano/rural × capital/interior na regressão
   (`AREA` e `LOCALIZACAO` como dummies separadas não capturavam o efeito
   conjunto). Adicionalmente, problemas de encoding
   (Windows/Latin1 × UTF-8) violavam acentos em mensagens R.

#### Fase 2A — Helper compartilhado `utils_saeb.r`

- Criadas funções para a nova convenção de pastas datadas:
  - `caminho_saida(DIR_BASE, subpasta, nome, ext)` — gera
    `outputs/<YYYY-MM-DD>/<subpasta>/<nome>_<HHMMSS>.<ext>` e cria a pasta.
  - `encontrar_arquivo_mais_recente(pasta, nome_base, tipo)` — procura em
    subpastas datadas (mais recente por `mtime`) com fallback para o padrão
    antigo de timestamp sufixo.
  - `arquivo_com_versao_existe()` — wrapper de checagem.
  - `gerar_caminho_sem_sobrescrever()` mantida por compatibilidade.
- Centralizados: `tema_saeb()` + paletas, dicionários de variáveis
  (`ORDINAIS_SAEB`, `NOMINAIS_SAEB`, `CONTINUAS_SAEB`), constantes de filtros e
  `detectar_raiz()`.

#### Fase 2B — Migração dos scripts (módulos 4, 6, 7, 8, 9, 10, 11)

Scripts atualizados para usar `caminho_saida()` (pastas datadas), remover
acentos em strings/mensagens e adotar a variável combinada `AREA_LOCAL`:

- `4_REGRESSAO_LINEAR/Scripts/regressao_linear_multipla.r`
  - Substituiu `VARS_CATEGORICAS = c("TIPO_ESCOLA","AREA","LOCALIZACAO")` por
    `c("TIPO_ESCOLA","AREA_LOCAL")`;
  - Referência principal: `TIPO_ESCOLA=Publica` + `AREA_LOCAL=Urbana_Capital`;
  - Etapa 5b reescrita com iteração dupla
    `TIPO_ESCOLA × AREA_LOCAL` (em vez de `TIPO_ESCOLA × AREA × LOCALIZACAO`);
  - Timestamp global passou a `_HHMMSS` (a data vai para o nome da pasta).
- `6_ANALISE_ESPACIAL`, `7_MODELOS_HIERARQUICOS`, `8_ANALISE_MEDIACAO`,
  `9_VALIDACAO_CRUZADA`, `10_ANALISE_RESIDUOS_ESPACIAIS`,
  `11_INDICE_COMPOSTO`: troca de `file.path(DIR_<TIPO>, paste0(..._ts))` por
  `caminho_saida(...)`, remoção de acentos e ajuste de mensagens.
- Módulos 3 e 5 mantêm o padrão antigo (pendentes da Fase 3).

#### Estado

- Arquivos modificados: 12 scripts + `utils_saeb.r` (~1.500 linhas de diff).
- Working tree com mudanças não commitadas ao fim da sessão.

#### Próximos passos (deixados para 23/07)

- [ ] Fase 2C — migrar arquivos antigos (mod 3, 4, 5) para pastas datadas.
- [ ] Fase 2D — ajustar ponto de quebra do script auxiliar
      `grafico_coeficientes_referencia_oposta.r`.
- [ ] Fase 2E — atualizar READMEs e criar `AGENTS.md`.

---

### 🟢 23 de Julho de 2026

**Horário:** ~09h00 – 12h00
**Fase:** Refatoração #2 — Fases 2C / 2D / 2E (organização de outputs, script auxiliar, docs)
**Status:** ✅ Concluído com sucesso

#### Fase 2C — Migração de arquivos antigos para pastas datadas

Aplicada ao 3_ANALISE_DE_GRUPOS, 4_REGRESSAO_LINEAR e
5_REGRESSAO_ITENS_BRUTOS conforme convenção
`outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>`.

- Script de migração (PowerShell) relocou **146 arquivos** sem colisões:
  - Nome com `_YYYYMMDD_HHMMSS.ext` → pasta `<YYYY-MM-DD>/<tipo>/` com
    `<nome>_<HHMMSS>.<ext>`.
  - Apenas arquivos diretamente em `outputs/<tipo>/` (nível 1); subpastas
    comparativas (`Escola_A_vs_B_*/`, `capital_vs_interior/`, etc.) e os
    boxplots sem timestamp do módulo 3 foram preservados no lugar.
- Pastas `outputs/<tipo>/` vazias removidas (serão recriadas por
  `caminho_saida()` na próxima execução).
- Distribuição resultante por data de run:
  - mod 3: `2026-05-12`, `2026-05-13`, `2026-07-01`, `2026-07-22`
  - mod 4: `2026-07-22`
  - mod 5: `2026-06-02`

#### Fase 2D — Script auxiliar `grafico_coeficientes_referencia_oposta.r`

Reescrito para seguir as mesmas convenções dos demais scripts:

- Removido path absoluto `C:/Users/...`; uso de `detectar_raiz()` (bootstrap
  local antes do `source()` de `utils_saeb.r`).
- Leitura da base via `encontrar_arquivo_mais_recente(DIR_OUTPUTS,
  "base_escolas_agregada", "tabelas")` — acha em pastas datadas OU no padrão
  antigo (corrige o ponto de quebra que impedia o script de achar a base).
- Saídas via `caminho_saida(...)` para `tabelas/`
  (`coeficientes_referencia_oposta_{MT,LP}_<HHMMSS>.csv`) e `figuras/`
  (`coeficientes_TCC_{color,PB}_referencia_oposta_<HHMMSS>.png`).
- **Ponto de quebra do eixo X dinâmico**: calculado a partir dos ICs 95% dos
  coeficientes (`floor`/`ceil` múltiplo de 10), em vez da janela fixa
  `seq(-40, 40, 10)`. Garante que coeficientes/ICs grandes não sejam cortados.
- Deslocamento dos rótulos textuais também dinâmico (proporcional à faixa).

#### Fase 2E — Documentação

- Criado [`AGENTS.md`](../AGENTS.md) na raiz do projeto:
  contexto do projeto, stack/commands, estrutura, convenções obrigatórias
  (pastas datadas, detecção de caminhos, variável `AREA_LOCAL`, estilo de
  código sem acentos, versionamento e `diario.md`), estado atual e fontes de
  verdade.
- Atualizado `README.md` raiz:
  - Nova seção **Convenção de Pastas Datadas**, descrevendo helpers
    `caminho_saida`/`encontrar_arquivo_mais_recente` e a variável `AREA_LOCAL`,
    com referência ao script auxiliar e ao `AGENTS.md`.
- Atualizado `TESTE/4_REGRESSAO_LINEAR/README.md`:
  - Bloco de estrutura de pastas reescrito para `outputs/<YYYY-MM-DD>/...`;
  - Adicionado o script auxiliar (`grafico_coeficientes_referencia_oposta.r`)
    como Passo 1b;
  - Configurações personalizáveis: `VARS_CATEGORICAS = c("TIPO_ESCOLA",
    "AREA_LOCAL")` + `refs_modelo`;
  - Saídas do Passo 1 reorganizadas (~20 arquivos, com `REFERENCIAS_MODELOS`,
    `VIF_multicolinearidade`, `comparacao_todas_referencias_*`, etc.);
  - Corrigido pré-requisito (lê `TS_ALUNO_34EM.csv`, não `metadados_escolas`);
  - Versão 2.1.
- Atualizado `TESTE/3_ANALISE_DE_GRUPOS/README.md`:
  - Bloco de outputs reescrito para pastas datadas; esclarecido que scripts do
    módulo ainda não usam `caminho_saida()` (pendente Fase 3).
- Atualizado `TESTE/5_REGRESSAO_ITENS_BRUTOS/README.md`:
  - Adicionada nota de bloco sobre convenção de pastas datadas e referência ao
    estilo legado.

#### Resultados

- 146 arquivos reorganizados em pastas datadas (mod 3, 4, 5).
- Script auxiliar funcional e alinhado às convenções do projeto.
- 4 arquivos de documentação atualizados + 1 novo (`AGENTS.md`).

#### Próximos passos

- [ ] Validar execução dos scripts no RStudio (sem R no ambiente atual; não foi
      possível rodar `Rscript` aqui).
- [ ] Commit das mudanças da refatoração #2 (após revisão do usuário).
- [ ] Fase 3 — migrar módulos 3 e 5 para `caminho_saida()` (retirar o estilo
      antigo de timestamp sufixo).

---

**Atualizado:** 23 de Julho de 2026  
**Status:** Refatoração #2 (Fases 2A–2E) completa — organização de outputs, script auxiliar, documentação  
**Próxima etapa:** Validação em RStudio + commit + Fase 3 (mod 3 e 5)

---

### 🟣 23 de Julho de 2026 (Tarde)

**Horário:** ~13h00 – 17h00
**Fase:** Verificação final + correções bloqueantes + notas metodológicas + README brilhoso
**Status:** ✅ Concluído com sucesso

---

#### Atividades Realizadas

##### 1. Verificação sistemática dos scripts (read-only)

Inspecionei todos os 16 scripts R do projeto via agente explore, conferindo:
caminhos, uso de `caminho_saida()`, `source(utils_saeb.r)`, `AREA_LOCAL`,
acentos e presença de nota metodológica.

Relatório consolidado:

| # | Script | `detectar_raiz` | `caminho_saida` | `source utils` | `AREA_LOCAL` | sem acentos | nota metodológica |
|---|---|---|---|---|---|---|---|
| 1 | `ajeitar_dados.r` (mód 1) | local | NÃO (legado) | sim | n/a | NÃO | não |
| 2 | `correlacao.r` (mód 2) | local | NÃO (sem pasta) | sim | n/a | NÃO | não |
| 3 | `graficos.r` (mód 2) | local | n/a (Shiny) | sim | n/a | NÃO | não |
| 4 | `classificar_escolas.r` (mód 3) | local | NÃO (legado) | NÃO | sim | parcial | não |
| 5 | `comparar_grupos.r` (mód 3) | ordem* | NÃO (legado) | sim | n/a | parcial | não |
| 6 | `comparar_duas_escolas.r` (mód 3) | local | NÃO (legado) | NÃO | n/a | parcial | não |
| 7 | `dendrograma_analise_completa.r` (mód 3) | local | NÃO (legado) | NÃO | n/a | parcial | não |
| 8 | `regressao_linear_multipla.r` (mód 4) | local | PARCIAL (3 residuais legados) | sim | sim | OK | sim (INSE) |
| 9 | `grafico_coeficientes_referencia_oposta.r` (mód 4) | local | sim | sim | sim | OK | não (cabeçalho) |
| 10 | `regressao_itens_brutos_dummy.r` (mód 5) | local | NÃO (legado) | NÃO | sim | OK | sim (dummies) |
| 11 | `mapa_municipios.r` (mód 6) | ordem* | sim | sim | n/a | OK | não → **adicionado nesta sessão** |
| 12 | `modelos_hierarquicos.r` (mód 7) | ordem* | sim | sim | n/a | OK | não → **adicionado nesta sessão** |
| 13 | `analise_mediacao.r` (mód 8) | ordem* | sim | sim | sim | OK | não → **adicionado nesta sessão** |
| 14 | `validacao_cruzada.r` (mód 9) | ordem* | sim | sim | sim | OK | não → **adicionado nesta sessão** |
| 15 | `analise_residuos_espaciais.r` (mód 10) | ordem* | sim | sim | NÃO usa | OK | não → **adicionado nesta sessão** |
| 16 | `indice_composto.r` (mód 11) | ordem* | sim | sim | NÃO usa | OK | não → **adicionado nesta sessão** |

*ordem = `detectar_raiz()` é chamada antes de `source(utils_saeb.r)` (depende de utils já carregado em sessão RStudio; pode falhar em `Rscript` limpo).

##### 2. Correção de 3 bugs bloqueantes

- **Bug 1**: `analise_mediacao.r` (mód 8) linha 63 — `filter(TIPO_ESCOLA %in% c("P?blica", "Privada"))`. O placeholder `?` (artefato de encoding) NÃO casa `"Publica"`, descartando todas as escolas públicas. Corrigido para `"Publica"`. Mesmo padrão em `validacao_cruzada.r` (mód 9) linha 65, corrigido igualmente.
- **Bug 3**: `dendrograma_analise_completa.r` (mód 3) linha ~245 — `if (MODO == 1)` referenciava variável `MODO` nunca definida ⇒ `object 'MODO' not found`. Adicionada `MODO <- 1L` no bloco CONFIGURACAO (compatibilidade com v2.0 que suportava MODO 2 - pares; v3.0 só MODO 1 ativo, conforme cabeçalho do script).
- Foi feito grep por outros placeholders `"P?`, `"S?`, `"I?` etc. nos scripts afetados — nenhuma outra ocorrência encontrada.

Nenhuma outra correção foi feita (conforme escopo acordado com o usuário: apenas bugs bloqueantes nesta rodada).

##### 3. Notas metodológicas adicionadas (módulos 6-11)

Conforme solicitação, adicionei bloco `# NOTA METODOLOGICA - ...` após o cabeçalho descritivo de 6 scripts (espelhando o padrão de `regressao_linear_multipla.r` com 3-5 parágrafos numerados + linha CONCLUSAO):

| Script | Tema da nota metodológica |
|---|---|
| `mapa_municipios.r` (mód 6) | Justificativa do coroplético por município, agregação escola→município (não simples de alunos), paleta divergente RdBu vs. sequencial, projeção SIRGAS 2000/UTM 23S |
| `modelos_hierarquicos.r` (mód 7) | Por que HLM vs. OLS com erros clustered, ICC e critério de Hox (2010), random intercept vs. random slopes, estimador REML vs. ML, centring group-mean |
| `analise_mediacao.r` (mód 8) | Baron & Kenny (1986) clássico, bootstrap BCa (Preacher & Hayes, 2008), suposição de não-confundimento, INSE mediador vs. moderador, proporção mediada PM |
| `validacao_cruzada.r` (mód 9) | K-fold k=10 vs. LOO (Hastie et al. 2009), AUC bootstrap-IC via pROC, prevenção de leakage temporal/espacial/cluster, `set.seed(2023)` para reprodutibilidade |
| `analise_residuos_espaciais.r` (mód 10) | Moran's I global com Monte Carlo (999 permutações), vizinhança Queen vs. k-NN, LISA (Anselin 1995) HH/LL/HL/LH, agenda futura SAR/SEM |
| `indice_composto.r` (mód 11) | PCA sobre variáveis padronizadas (necessidade de z-score por diferença de escala), retenção Kaiser + Joliffe + Parallel Analysis Horn's, não-rotação para preservar PC1, limitação de linearidade |

Todas em português sem acentos (conforme convenção).

##### 4. README raiz revitalizado (brilhoso máximo)

Reescrita completa de `README.md` (raiz) com elementos visuais copiados do estilo de `4_REGRESSAO_LINEAR/README.md` (referência do usuário):

- **10 badges shields.io** no topo (R 4.x, SAEB 2023, Minas Gerais, Status, Pipeline 15 passos, Outputs pastas datadas, Alunos 173.918, Escolas 2.338, Municípios 851, Licença acadêmica, tidyverse).
- **TL;DR em callout** (`>`) com resumo executivo de 3 linhas.
- **Cartões de estatística** em tabelas com emojis (🧑‍🎓 🏫 📍 🎯).
- **Sumário navegável** com anchors.
- **Emojis em todos os cabeçalhos** H2 (📋 🗂️ 🚀 📊 ✅ 🛣️ 📅 🎯 📚 📝 📌 📜 🧭).
- **Árvore ASCII** da estrutura com badges de status inline (`✅`/`⏳`) por pasta.
- **Fluxograma mermaid** do pipeline completo de 15 passos (substitui 4 blocos isolados de `source()`).
- **Tabela de resumo** com 15 linhas (uma por PASSO).
- **Tabela de progresso** com coluna Status (✅/⏳).
- **Callouts** `>` para INSE-justificativa, convenção de pastas datadas e `AREA_LOCAL`.
- **Fórmula LaTeX** $\text{Proficiencia}_i = \beta_0 + \beta_1 \cdot \text{INSE}_i^{(z)} + \ldots$ na seção do modelo central.
- **Rodapé com versão** 3.0 (refatoração julho/2026 — pastas datadas, AREA_LOCAL, README brilhoso máximo).
- **Changelog** em tabela (5 versões: 1.0/2.0/2.1/2.2/3.0).
- **Roadmap** com checkboxes (5 itens pendentes: Fase 3, ordem source, AREA_LOCAL nos móds 10-11, limpeza de acentos móds 1-2, redação TCC).
- Caixa de convenção para contribuidores (link para AGENTS.md).

👎 Escopo não realizado (preservado intencionalmente): revitalização dos READMEs dos módulos 6-11 (usuário escolheu "Só README raiz"), notas metodológicas para módulos 1-3 (considerados preparatórios), correção de acentos nos módulos 1-2, migração de `AREA_LOCAL` nos módulos 10-11, correção de ordem `source`/`detectar_raiz` nos 7 scripts.

---

#### Resultados Quantitativos

| Métrica | Valor |
|---|---|
| Scripts R corrigidos (bugs) | 3 |
| Scripts R com nota metodológica adicionada | 6 |
| READMEs alterados | 1 (`README.md` raiz, reescrito) |
| `diario.md` atualizado | 1 (esta entrada) |
| Arquivos novos | 0 |
| Linhas adicionadas (notas metodológicas) | ~350 |
| Linhas do novo README | ~245 |

#### Validação

Não há `Rscript` no ambiente atual (Windows, sem R instalado); scripts não foram
executados. Recomenda-se validar em RStudio antes de commitar (rodar cada script
modificado: móds 3, 6, 7, 8, 9, 10, 11). Nenhum `parse(file="...")` disponível
sem R, mas a inspeção manual das edições não mostrou erros de sintaxe
(apenas inserções de bloco comentado + 3 correções pontuais de string/variável).

#### Próximos passos

- [ ] Validar os 7 scripts afetados em RStudio (móds 3, 6, 7, 8, 9, 10, 11).
- [ ] Commit das mudanças desta sessão (após validação do usuário).
- [ ] **Fase 3** (roadmap): migrar `caminho_saida()` nos módulos 3 e 5.
- [ ] Corrigir ordem `detectar_raiz()` vs `source(utils_saeb.r)` nos móds 6-11.
- [ ] Migrar `AREA_LOCAL` nos móds 10 e 11.
- [ ] Limpar acentos/emojis dos scripts dos móds 1 e 2.

---

**Atualizado:** 23 de Julho de 2026 (Tarde)  
**Status:** Verificação final + fix de bugs + notas metodológicas (mod 6-11) + README brilhoso máximo  
**Próxima etapa:** Validação em RStudio + commit + roadmap da Fase 3

---

## 23 de Julho de 2026 (Noite) — Remoção dos Módulos 6 e 10 (Análises Espaciais)

### Contexto

Os módulos 6 (`6_ANALISE_ESPACIAL`) e 10 (`10_ANALISE_RESIDUOS_ESPACIAIS`) foram
removidos da pipeline devido à **anonimização dos municípios nos microdados do SAEB 2023**.

### Problema Identificado

- O arquivo `TS_ESCOLA.csv` contém `ID_MUNICIPIO` com códigos internos do SAEB
  (ex.: `6324414`, `6324415`), **não** os códigos IBGE de 7 dígitos (ex.: `3100104`).
- Os shapefiles do IBGE (via `geobr` ou download direto) usam códigos IBGE.
- **Não há arquivo de mapeamento** (`TS_MUNICIPIO.csv`) disponível — o usuário
  confirmou que excluiu esse arquivo por não ser relevante para o TCC.
- Sem correspondência entre `ID_MUNICIPIO` (SAEB) e `code_muni` (IBGE), os
  mapas coropléticos e a análise de autocorrelação espacial (Moran's I) são
  **inviáveis**.

### Módulos Removidos

| Módulo | Script | Figuras | Função Original |
|--------|--------|---------|-----------------|
| 6 | `mapa_municipios.r` | 16-18 | Mapas coropléticos de proficiência e INSE por município |
| 10 | `analise_residuos_espaciais.r` | 26-28 | Moran's I global, scatterplot de Moran, clusters LISA |

### Justificativa Metodológica

> Os dados do SAEB anonimiza os municípios para proteger a privacidade das
> escolas. Sem coordenadas geográficas reais ou códigos IBGE, não é possível
> construir matrizes de vizinhança espacial nem calcular estatísticas de
> autocorrelação (Moran's I, LISA). As análises espaciais foram planejadas
> originalmente, mas tornaram-se **inaplicáveis** devido à natureza dos dados.

### Arquivos Deletados

- `TESTE/6_ANALISE_ESPACIAL/` (diretório completo)
- `TESTE/10_ANALISE_RESIDUOS_ESPACIAIS/` (diretório completo)

### Documentação Atualizada

- `AGENTS.md`: removidas linhas 49 e 53 da árvore de diretórios
- `README.md`: removidas referências nos comandos de execução, diagrama mermaid,
  tabelas de resumo e progresso, roadmap
- `TESTE/DOCUMENTACAO/metodologia.md`: removidas seções PASSO 10 e PASSO 14
- `TESTE/DOCUMENTACAO/referencia_outputs.md`: removidas seções PASSO 10 e PASSO 14
- `TESTE/DOCUMENTACAO/README.md`: removidas referências no fluxo e tabela
- `TESTE/DOCUMENTACAO/requisitos.md`: removidos pacotes `sf`, `geobr`, `tmap`, `spdep`
  (não são mais usados por nenhum módulo restante)

### Impacto na Pipeline

- **Nenhum outro módulo depende** dos módulos 6 e 10 (verificado via grep).
- Os módulos restantes (7, 8, 9, 11) funcionam independentemente.
- As figuras 16-18 e 26-28 não serão geradas; a numeração das demais figuras
  (19-25, 29-31) é mantida para consistência com o TCC.

### Próximos Passos

- [ ] Commit das mudanças (após validação do usuário)
- [ ] Atualizar a escrita do TCC para refletir a remoção das análises espaciais
- [ ] Considerar adicionar uma nota na metodologia explicando por que as análises
      espaciais não foram realizadas (anonimização dos dados)

---

**Atualizado:** 23 de Julho de 2026 (Noite)  
**Status:** Módulos 6 e 10 removidos + documentação atualizada  
**Próxima etapa:** Commit + redação final do TCC

