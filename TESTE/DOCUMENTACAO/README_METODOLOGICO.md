# README Metodologico

Base consolidada para a redacao da secao metodologica do TCC.

> **Objetivo deste documento**: reunir, em um unico lugar, todas as
> justificativas estatisticas, decisoes de modelagem e referencias teoricas
> que fundamentam cada passo do pipeline de analise dos microdados do SAEB 2023.

---

## 1. Dados e Amostra

| Item | Valor |
|------|-------|
| Fonte | INEP -- SAEB 2023 |
| Escopo | Minas Gerais |
| Nivel | 3a serie do Ensino Medio |
| Alunos | 173.918 |
| Escolas | 2.338 |
| Municipios | 851 |
| Disciplinas-alvo | `MEDIA_MT` (Matematica) e `MEDIA_LP` (Lingua Portuguesa) |
| Proxy socioeconomico | `INSE_ALUNO` (individual) -> `INSE_MEDIO` (agregado por escola) |

### 1.1 Por que o INSE e nao itens brutos do questionario

O INSE (Indicador Nivel Socioeconomico dos Estudantes) e a sintese TRI (Teoria
de Resposta ao Item) dos 72 itens do questionario socioeconomico do SAEB, com
calibracao psicometrica publicada pelo INEP. Usar os 72 itens brutos como
preditores introduziria:

- **Multicolinearidade severa** (itens correlacionados entre si);
- **Explosao dimensional** inviavel para OLS com ~2.338 escolas;
- **Perda de interpretabilidade** (72 coeficientes vs. 1 score sintetico).

A Fase 9 (`regressao_itens_brutos_dummy.r`) faz a exploracao complementar com
os itens, apos filtragem iterativa por VIF.

---

## 2. Pipeline em 10 Passos

```
PASSO 1  ->  PASSO 2  ->  [PASSO 3]  ->  PASSO 4  ->  PASSO 5
->  [PASSO 6]  ->  PASSO 7  ->  PASSO 8  ->  [PASSO 9]  ->  PASSO 10
```

Passos entre colchetes sao opcionais.

| Passo | Fase | Script | Finalidade |
|:-----:|------|--------|------------|
| 1 | Limpeza | `ajeitar_dados.r` | Transformar variaveis A/B/C em numeros; limpar respostas invalidas |
| 2 | Correlacoes | `correlacao.r` | Spearman/Pearson por escola; filtrar \|r\| >= 0.30 |
| 3 | Dashboard | `graficos.r` | Shiny interativo (opcional) |
| 4 | Metadados | `classificar_escolas.r` | Agregar por escola; criar INSE_MEDIO, AREA_LOCAL, GRUPO_INSE |
| 5 | Comparacoes | `comparar_grupos.r` | Wilcoxon + rank-biserial entre grupos |
| 6 | 2 escolas | `comparar_duas_escolas.r` | Comparacao lado a lado (opcional) |
| 7 | Clustering | `dendrograma_analise_completa.r` | Ward.D2 em 2D e 3D |
| 8 | Regressao | `regressao_linear_multipla.r` | Modelo linear com dummies (INSE + TIPO_ESCOLA + AREA_LOCAL) |
| 9 | Itens brutos | `regressao_itens_brutos_dummy.r` | Regressao exploratoria com ~150 itens |
| 10 | Mediacao | `analise_mediacao.r` | INSE como mediador (bootstrap BCa) |

---

## 3. Justificativas Metodologicas por Passo

### 3.1 PASSO 1 -- Transformacao de Variaveis

**Classificacao por tipo**:

| Tipo | Variaveis | Transformacao | Correlacao |
|------|-----------|---------------|------------|
| Ordinais | Q10, Q21, Q22, Q23, Q19, Q20 | Factor ordenado (A->1, B->2...) | Spearman |
| Nominais | Q01 (sexo), Q04 (raca) | Dummies 0/1 | Spearman |
| Continuas | INSE_ALUNO, NU_TIPO_NIVEL_INSE | Mantidas numericas | Pearson + Spearman |

**Limpeza de respostas invalidas**: caracteres `.`, `*`, ` `, `F` sao
convertidos para NA. Justificativa: evita atribuir valores numericos a
"nao sei / nao quero responder".

### 3.2 PASSO 2 -- Correlacoes

- **Detecao de variaveis degeneradas**: `nearZeroVar` (pacote `caret`),
  criterio >95% dos valores em uma unica categoria. Sem variancia, nao ha
  poder explicativo.
- **Metodo por tipo**: Spearman para ordinais/nominais (nao assume
  linearidade); Pearson para continuas (assume linearidade e normalidade).
- **Filtragem**: limiar |r| >= 0.30 (Cohen, 1988: efeito pequeno a moderado).
- **Autoescalamento**: z-score para comparabilidade.
- **Paradoxo correlacao x degeneracao**: variavel degenerada (falta de
  variancia) e diferente de variavel com correlacao baixa (variancia existe,
  mas sem associacao).

### 3.3 PASSO 3 -- Dashboard Shiny

Substitui geracao de PNGs estaticos; permite interacao da banca com os dados;
exibe reta OLS + intervalo de confianca visual.

### 3.4 PASSO 4 -- Agregacao por Escola

Transforma dados de aluno (173k) em escola (2.3k). Cria:

- `INSE_MEDIO`: proxy socioeconomico agregado (media do INSE dos alunos);
- `AREA_LOCAL`: variavel combinada urbano/rural x capital/interior (4 categorias);
- `GRUPO_INSE`: tercil de INSE medio (Baixo / Medio / Alto).

**Por que AREA_LOCAL e nao AREA + LOCALIZACAO separadas?** A interacao
urbano/rural x capital/interior captura efeito combinado que variaveis
marginais nao revelam. Exemplo: escola rural na capital tem dinamica distinta
de escola rural no interior.

| Categoria | Composicao | Frequencia |
|-----------|------------|------------|
| `Urbana_Capital` | urbana + BH/Capital | alta (referencia) |
| `Urbana_Interior` | urbana + demais municipios | dominante |
| `Rural_Capital` | rural + Capital | baixa |
| `Rural_Interior` | rural + Interior | moderada |

### 3.5 PASSO 5 -- Comparacoes entre Grupos

**Teste de Wilcoxon (Mann-Whitney)**:

- Nao-parametrico: nao assume normalidade;
- Robusto para dados de proficiencia (distribuicoes assimetricas);
- Comparações bidirecionais (A->B e B->A).

**Tamanho de efeito**: rank-biserial r.

| Faixa | Interpretacao |
|-------|---------------|
| 0.0--0.1 | Negligenciavel |
| 0.1--0.3 | Pequeno |
| 0.3--0.5 | Medio |
| >0.5 | Grande |

**Comparacoes realizadas**:

1. Publica vs Privada
2. Urbana vs Rural
3. Capital vs Interior
4. Alto INSE vs Baixo INSE

### 3.6 PASSO 7 -- Clustering Hierarquico

**Metodo**: Ward.D2 (minimiza variancia intra-cluster, distancia euclidiana).

**Preparacao**: z-score para evitar dominancia de escala.

**Perspectivas**:

- MT + INSE (2D)
- LP + INSE (2D)
- MT + LP + INSE (3D)

**Colorizacao**: azul = Publica; vermelho = Privada.

### 3.7 PASSO 8 -- Regressao Linear Multipla

**Modelo**:

```
Proficiencia_i = beta_0 + beta_1 * INSE_i^(z) + beta_2 * Privada_i
               + sum(beta_k * D_{ik}) + epsilon_i
```

**Referencias**:

- `TIPO_ESCOLA`: referencia = `Publica`
- `AREA_LOCAL`: referencia = `Urbana_Capital`
- `INSE_MEDIO`: normalizado por z-score

**Script auxiliar** (`grafico_coeficientes_referencia_oposta.r`): mesmo modelo
com referencia oposta (`Privada` + `Rural_Interior`).

**Diagnosticos**:

| Diagnostico | Metodo | Criterio |
|-------------|--------|----------|
| Variância explicada | R² ajustado | Quanto maior, melhor |
| Erro de previsao | RMSE | Quanto menor, melhor |
| Multicolinearidade | VIF (pacote `car`) | <5 aceitavel; >10 severo |
| Normalidade dos residuos | Shapiro-Wilk | p > 0.05 = normal |
| Homocedasticidade | Breusch-Pagan (pacote `lmtest`) | p > 0.05 = homocedastico |

### 3.8 PASSO 9 -- Regressao com Itens Brutos

**Motivacao**: a Fase 8 usa INSE agregado (sintetico); a Fase 9 usa itens
brutos para exploracao de dimensoes especificas.

**Controle de multicolinearidade**: VIF iterativo com limiar 10 -- remove a
variavel com maior VIF ate todos ficarem abaixo do limiar.

**Comparacao Fase 8 vs Fase 9**:

| Aspecto | Fase 8 (INSE) | Fase 9 (Itens) |
|---------|---------------|----------------|
| Preditores | 4 | ~150 |
| Interpretabilidade | Alta | Complexa |
| Multicolinearidade | Nenhuma | Severa -> VIF |
| Uso | Modelagem final | Exploracao |

### 3.9 PASSO 10 -- Analise de Mediacao

**Objetivo**: testar se o INSE media o efeito de variaveis de contexto
(tipo de escola, localizacao) sobre a proficiencia.

**Pergunta substantiva**: "Escolas privadas tem melhor desempenho PORQUE
tem INSE maior?"

**Estrutura** (Preacher & Hayes, 2008):

1. **Caminho A**: VI -> INSE (mediador)
2. **Caminho B + C'**: INSE + VI -> Proficiencia
3. **Efeito indireto** (A x B): bootstrap BCa com 1.000 simulacoes
4. **Proporcao mediada**: |indireto| / |total| x 100

**Análises realizadas**:

- `TIPO_ESCOLA` -> `INSE` -> Proficiencia (MT e LP; ref.: Publica)
- `AREA_LOCAL` -> `INSE` -> Proficiencia (MT e LP; 3 dummies --
  `Rural_Interior`, `Rural_Capital`, `Urbana_Interior` -- com ref. `Urbana_Capital`)

**Justificativa para politicas publicas**: separar efeito direto (tipo de
escola) do efeito indireto (via INSE) informa se investimentos em
condicoes socioeconomicas reduzem a diferenca entre redes.

---

## 4. Referencias Teoricas

| Tema | Referencia |
|------|------------|
| Tamanho de efeito | Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* |
| Mediacao bootstrap | Preacher, K. J. & Hayes, A. F. (2008). Asymptotic and resampling strategies for assessing and comparing indirect effects in multiple mediator models. *Behavior Research Methods*, 40(3), 879--891 |
| TRI (INSE) | INEP (2023). *Nota tecnica do INSE -- SAEB 2023* |
| VIF | Hair, J. F. et al. (2010). *Multivariate Data Analysis* (7th ed.) |
| Clustering Ward | Murtagh, F. & Legendre, P. (2014). Ward's hierarchical clustering method. *Journal of Classification*, 31(3), 274--295 |
| Wilcoxon / rank-biserial | Kerby, D. S. (2014). The simple difference formula. *Comprehensive Psychology*, 3, 11 |

---

## 5. Fluxo de Dados

```
MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv
    |
    v
[PASSO 1] Limpeza     -> outputs/{ID}/dados_escola_em_numeros.csv
    |
    v
[PASSO 2] Correlacoes -> outputs/{ID}/correlacoes_*.csv, dados_FINAL_*.csv
    |
    v
[PASSO 3] Dashboard   -> Shiny (opcional)
    |
    v
[PASSO 4] Metadados   -> outputs/metadados/metadados_escolas_*.csv
    |
    +---> [PASSO 5] Comparacoes  -> resultados_comparacao_*.csv + figuras
    +---> [PASSO 6] 2 escolas    -> outputs/comparacoes/
    +---> [PASSO 7] Clustering   -> dendrograma_*.png
    |
    v
[PASSO 8] Regressao   -> outputs/{modelos,tabelas,figuras}/
    |
    v
[PASSO 9] Itens brutos -> outputs/{modelos,tabelas,figuras}/  (complementar)
    |
    v
[PASSO 10] Mediacao   -> outputs/{tabelas,figuras}/
```

> O `metadados_escolas_*.csv` (PASSO 4) e a entrada dos PASSOS 5, 7 e 10.

---

## 6. Diagnosticos e Criterios de Qualidade

| Verificacao | Quando | Criterio | Acao se falhar |
|-------------|--------|----------|----------------|
| Variaveis degeneradas | PASSO 2 | >95% em uma categoria | Remover |
| Correlacao baixa | PASSO 2 | \|r\| < 0.30 | Nao incluir no modelo |
| Multicolinearidade | PASSO 8-9 | VIF > 10 | Remover iterativamente |
| Normalidade residuos | PASSO 8 | Shapiro-Wilk p < 0.05 | Interpretar com cautela |
| Homocedasticidade | PASSO 8 | Breusch-Pagan p < 0.05 | Erros-padrao robustos |
| Convergencia bootstrap | PASSO 10 | IC nao inclui 0 | Nao mediacao significativa |

---

## 7. Decisoes de Modelagem -- Resumo

| Decisao | Escolha | Justificativa |
|---------|---------|---------------|
| Proxy socioeconomico | INSE (score TRI) | Sintese psicometrica dos 72 itens |
| Agregacao | Media por escola | Nivel de analise e a escola |
| Normalizacao | z-score | Comparabilidade entre escalas |
| Variavel de localizacao | AREA_LOCAL (4 cats) | Captura interacao urbano/rural x capital/interior |
| Referencia regressao | Publica + Urbana_Capital | Categoria majoritaria |
| Teste de grupos | Wilcoxon | Nao-parametrico; dados assimetricos |
| Tamanho de efeito | rank-biserial r | Equivalente nao-parametrico de Cohen's d |
| Clustering | Ward.D2 | Minimiza variancia intra-cluster |
| Mediacao | Bootstrap BCa (1000x) | Nao assume normalidade do efeito indireto |
| VIF iterativo | Limiar 10 | Controle de multicolinearidade (Fase 9) |

---

## 8. Modulos Removidos do Pipeline

Os seguintes modulos foram retirados (ago/2026) para focar o TCC no eixo
principal:

| Modulo removido | Motivo |
|-----------------|--------|
| HLM (modelos hierarquicos) | Complexidade excessiva; ganho marginal sobre OLS |
| Validacao cruzada + ROC | Foco do TCC nao e preditivo, e explicativo |
| PCA (indice composto) | INSE ja e sintese TRI; PCA seria redundante |
| Mapas geoespaciais (mod 6 antigo) | SAEB anonimiza municipios |
| Moran's I (mod 10 antigo) | Dados anonimizados impedem analise espacial |

---

## 9. Arquivos Relacionados

| Arquivo | Conteudo |
|---------|----------|
| [metodologia.md](metodologia.md) | Versao sucinta das justificativas |
| [referencia_outputs.md](referencia_outputs.md) | Dicionario de CSVs gerados |
| [requisitos.md](requisitos.md) | Dependencias e instalacao |
| [README.md](README.md) | Guia de uso do pipeline |
| [../../README.md](../../README.md) | README principal do projeto |
| [../../AGENTS.md](../../AGENTS.md) | Convencoes para contribuidores |
| [../../diario.md](../../diario.md) | Historico cronologico |
