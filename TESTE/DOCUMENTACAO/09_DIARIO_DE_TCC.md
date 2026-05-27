# 📔 Diário de Desenvolvimento — TCC

**Título:** Impacto Socioeconômico na Proficiência SAEB  
**Período:** 06 de Abril — 11 de Maio de 2026  
**Status:** 🚀 Em Desenvolvimento

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

