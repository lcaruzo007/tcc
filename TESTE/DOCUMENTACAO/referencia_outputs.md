# Referência de Outputs

Dicionário de todos os CSVs gerados pelo pipeline.

## Fluxo de Dados

```
MICRODADOS_SAEB_2023/DADOS/
    ↓
[1_LIMPEZA] → outputs/{ID_ESCOLA}/dados_escola_em_numeros.csv
    ↓
[2_ANALISE] → outputs/{ID_ESCOLA}/correlacoes_*.csv, dados_FINAL_*.csv
    ↓
[3_GRUPOS]  → outputs/metadados/metadados_escolas_*.csv
    ↓
[4/5_REGRESSAO] → outputs/{modelos,tabelas,figuras}/
```

## PASSO 1: Limpeza

### `1_LIMPEZA_E_TRANSFORMACAO/outputs/{ID_ESCOLA}/dados_escola_em_numeros.csv`
Dados de alunos com variáveis transformadas.

| Coluna | Descrição |
|--------|-----------|
| ID_ALUNO | Identificador do aluno |
| ID_ESCOLA | Identificador da escola |
| PROFICIENCIA_MT_SAEB | Nota de Matemática (0-500) |
| PROFICIENCIA_LP_SAEB | Nota de Língua Portuguesa (0-500) |
| TX_RESP_Q* | Respostas do questionário (numéricas) |
| INSE_ALUNO | Índice socioeconômico do aluno |

## PASSO 2: Correlações

### `2_ANALISE_POR_ESCOLA/outputs/{ID_ESCOLA}/correlacoes_mantidas_MT.csv` / `_LP.csv`
Correlações que passaram no filtro |r| >= 0.30.

| Coluna | Descrição |
|--------|-----------|
| Variavel | Nome da variável |
| Metodo | Spearman ou Pearson |
| Correlacao_Matematica | Correlação com MT (-1 a +1) |
| Correlacao_Portugues | Correlação com LP (-1 a +1) |
| Status_Calculo | "OK" = válida |

### `2_ANALISE_POR_ESCOLA/outputs/{ID_ESCOLA}/dados_FINAL_MT_Filtrado.csv` / `_LP_Filtrado.csv`
Dados escalados (z-score) para modelagem e dashboard.

## PASSO 4: Metadados

### `3_ANALISE_DE_GRUPOS/outputs/metadados/metadados_escolas_YYYYMMDD_HHMMSS.csv`
Perfil agregado de cada escola (1 linha = 1 escola).

| Coluna | Descrição |
|--------|-----------|
| ID_ESCOLA | Identificador |
| N_ALUNOS | Quantidade de alunos |
| MEDIA_MT | Proficiência média em Matemática |
| MEDIA_LP | Proficiência média em LP |
| INSE_MEDIO | Índice socioeconômico médio |
| TIPO_ESCOLA | Pública / Privada |
| AREA | Capital / Interior |
| LOCALIZACAO | Urbana / Rural |
| GRUPO_INSE | Baixo_INSE / Medio_INSE / Alto_INSE |

## PASSO 5: Comparações

### `3_ANALISE_DE_GRUPOS/outputs/metadados/resultados_comparacao_YYYYMMDD_HHMMSS.csv`
Testes estatísticos entre grupos (comparações bidirecionais).

| Coluna | Descrição |
|--------|-----------|
| Variável | PROFICIÊNCIA_MT ou PROFICIÊNCIA_LP |
| Grupo1 | Primeiro grupo da comparação |
| Grupo2 | Segundo grupo da comparação |
| N1, N2 | Número de escolas em cada grupo |
| Mediana1, Mediana2 | Nota mediana de cada grupo |
| U | Estatística de Wilcoxon |
| p_valor | P-valor |
| r_rank_biserial | Tamanho de efeito (-1 a +1) |
| Significância | ns, *, **, *** |

**Nota:** Cada par de grupos aparece em ambas as direções (ex: Pública→Privada e Privada→Pública), resultando em 16 linhas (8 comparações × 2 disciplinas).

### `3_ANALISE_DE_GRUPOS/outputs/figuras/01_boxplot_tipo_escola.png`
Boxplot: Pública vs Privada

### `3_ANALISE_DE_GRUPOS/outputs/figuras/02_boxplot_urbano_rural.png`
Boxplot: Urbana vs Rural

### `3_ANALISE_DE_GRUPOS/outputs/figuras/03_boxplot_capital_interior.png`
Boxplot: Capital vs Interior

### `3_ANALISE_DE_GRUPOS/outputs/figuras/04_boxplot_inse.png`
Boxplot: Grupos de INSE

## PASSO 6: Comparação 2 Escolas

### `3_ANALISE_DE_GRUPOS/outputs/comparacoes/Escola_{A}_vs_{B}_{timestamp}/`
- `Comparacao_Escola_A_vs_B_*.csv` — Comparação lado a lado
- `Perfis_Escolas_*.csv` — Resumo das escolas
- `visualizacao_comparacao_*.png` — Gráfico

## PASSO 7: Clustering

### `3_ANALISE_DE_GRUPOS/outputs/figuras/dendrograma_geral_ALTO_BAIXO_*.png`
Árvore hierárquica de escolas com desempenho extremo.

### `3_ANALISE_DE_GRUPOS/outputs/metadados/clusters_escolas_YYYYMMDD_HHMMSS.csv`
Atribuição de cada escola a um cluster.

## PASSO 8: Regressão Linear

### `4_REGRESSAO_LINEAR/outputs/tabelas/resumo_modelos_*.csv`
Diagnósticos dos modelos.

| Coluna | Descrição |
|--------|-----------|
| Disciplina | MT ou LP |
| R2_ajustado | Variância explicada |
| RMSE | Erro médio de previsão |
| AIC / BIC | Critérios de informação |

### `4_REGRESSAO_LINEAR/outputs/tabelas/coeficientes_MT_*.csv` / `_LP_*.csv`
Coeficientes da regressão.

| Coluna | Descrição |
|--------|-----------|
| Preditor | Nome da variável |
| Beta | Efeito estimado |
| EP | Erro padrão |
| t | Estatística t |
| p_valor | Significância |
| Significancia | * p<0.05, ** p<0.01, *** p<0.001 |

### `4_REGRESSAO_LINEAR/outputs/figuras/diagnosticos_residuos_MT_*.png`
Painel 2x2: Resíduos vs Fitted, Q-Q, Scale-Location, Histograma.

## PASSO 9: Itens Brutos

### `5_REGRESSAO_ITENS_BRUTOS/outputs/tabelas/resumo_modelos_itens_*.csv`
Mesmo formato do PASSO 8, para modelos com itens brutos.

### `5_REGRESSAO_ITENS_BRUTOS/outputs/tabelas/coeficientes_MT_itens_*.csv`
Coeficientes dos ~150 itens mantidos após VIF.

### `5_REGRESSAO_ITENS_BRUTOS/outputs/figuras/coeficientes_top_MT_itens_*.png`
Top 20 variáveis por magnitude do efeito.
