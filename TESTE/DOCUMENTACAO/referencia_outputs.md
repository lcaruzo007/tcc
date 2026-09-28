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
[3_GRUPOS]  → outputs/<YYYY-MM-DD>/metadados/metadados_escolas_*.csv
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

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/metadados/metadados_escolas_HHMMSS.csv`
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
| AREA_LOCAL | Combinação de localização e área |
| GRUPO_INSE | Baixo_INSE / Medio_INSE / Alto_INSE |

## PASSO 5: Comparações

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/tabelas/resultados_comparacao_HHMMSS.csv`
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
| p_valor_ajustado_bh | P-valor ajustado por Benjamini-Hochberg |
| r_rank_biserial | Tamanho de efeito (-1 a +1) |
| Significância | ns, *, **, *** |
| Significancia_ajustada | Significância após ajuste de multiplicidade |

**Nota:** Cada par de grupos aparece em ambas as direções. Categorias de
`AREA_LOCAL` sem escolas são informadas no console e não geram comparações vazias.

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/figuras/01_boxplot_tipo_escola_HHMMSS.png`
Boxplot: Pública vs Privada

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/figuras/02_boxplot_urbano_rural_HHMMSS.png`
Boxplot: Urbana vs Rural

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/figuras/03_boxplot_capital_interior_HHMMSS.png`
Boxplot: Capital vs Interior

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/figuras/04_boxplot_inse_HHMMSS.png`
Boxplot: Grupos de INSE

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/figuras/05_boxplot_area_local_HHMMSS.png`
Boxplot: quatro categorias de `AREA_LOCAL`

## PASSO 6: Comparação 2 Escolas

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/comparacoes/escola_{A}_vs_escola_{B}/`
- `comparacao_escola_*_vs_*_*.csv` — Comparação lado a lado
- `perfis_escolas_*.csv` — Resumo das escolas
- `visualizacao_comparacao_*.png` — Gráfico

## PASSO 7: Clustering

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/figuras/alto_baixo/dendrograma_geral_ALTO_BAIXO_*.png`
Árvore hierárquica de escolas com desempenho extremo.

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/tabelas/tabela_escolas_ALTO_BAIXO_HHMMSS.csv`
Atribuição das escolas de desempenho extremo aos clusters.

## PASSO 8: Regressão Linear

### `4_REGRESSAO_LINEAR/outputs/<YYYY-MM-DD>/tabelas/sensibilidade_coeficientes_HC3_*.csv`
Comparação auxiliar dos coeficientes OLS e WLS com inferência robusta HC3.

### `4_REGRESSAO_LINEAR/outputs/<YYYY-MM-DD>/tabelas/sensibilidade_ajustes_OLS_WLS_*.csv`
Métricas de ajuste da análise de sensibilidade. Não substitui o modelo principal.

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

## PASSO 10: Análise de Mediação

### `6_ANALISE_MEDIACAO/outputs/tabelas/mediacao_*.csv`
Efeitos direto, indireto e total.

| Coluna | Descrição |
|--------|-----------|
| Variavel_Independente | Tipo Escola / Localização |
| Mediador | INSE_MEDIO |
| Disciplina | MT ou LP |
| Efeito_Direto | Efeito direto (c') |
| IC95_Direto_Inferior / Superior | Intervalo bootstrap do efeito direto |
| p_Direto | P-valor do efeito direto |
| Efeito_Indireto | Efeito indireto (a×b) |
| IC95_Indireto_Inferior / Superior | Intervalo bootstrap do efeito indireto |
| p_Indireto | P-valor do efeito indireto |
| Efeito_Total | Efeito total (c' + a×b) |
| p_Total | P-valor do efeito total |
| Proporcao_Mediada | % do efeito mediado por INSE |

### `6_ANALISE_MEDIACAO/outputs/figuras/caminhos_mediacao_MT_*.png`
Figura 21: Diagrama de caminhos (MT).

### `6_ANALISE_MEDIACAO/outputs/figuras/caminhos_mediacao_LP_*.png`
Figura 22: Diagrama de caminhos (LP).
