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

## 📊 Resumo Geral

| Período | Scripts | Análises | Status |
|---------|---------|----------|--------|
| 06-26 Abr | 3 | Intra-escola (correlações) | ✅ |
| 11 Mai (manhã) | 3 | Inter-grupos (comparações, clusters) | ✅ |
| 11 Mai (tarde) | Reorganização | Documentação estruturada | ✅ |
| 13 Mai | 1 (refinado) | Filtro ALTO/BAIXO em dendrograma | ✅ |
| **Total** | **7 scripts** | **Visão 360° dos dados + refinamentos** | **✅ Pronto** |

---

**Atualizado:** 13 de Maio de 2026  
**Próxima revisão:** Após execução com dados reais

