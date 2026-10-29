# Referência de Outputs

Dicionário de todos os CSVs gerados pelo pipeline.

## Convenção e rastreabilidade

Novas saídas de todos os módulos usam `outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>`.
Nos passos 1 e 2, as tabelas individuais ficam em `tabelas/<ID_ESCOLA>/`.
O [guia operacional](README.md) descreve manifestos, hashes MD5, logs e versões.

## PASSO 1: Limpeza

### `1_LIMPEZA_E_TRANSFORMACAO/outputs/<YYYY-MM-DD>/tabelas/<ID_ESCOLA>/dados_escola_em_numeros_<HHMMSS>.csv`
Dados de alunos com variáveis transformadas.

| Coluna | Descrição |
|--------|-----------|
| ID_ALUNO | Identificador do aluno |
| ID_ESCOLA | Identificador da escola |
| PROFICIENCIA_MT_SAEB | Nota válida de Matemática; filtro operacional 150–800 |
| PROFICIENCIA_LP_SAEB | Nota válida de LP; filtro operacional 150–800 |
| TX_RESP_Q* | Respostas categóricas limpas; ordinais em colunas _num e nominais em dummies |
| INSE_ALUNO | Índice socioeconômico do aluno |

### Relatórios de respostas do passo 1

`diagnosticos/<ID_ESCOLA>/resumo_missings_*.csv` informa `N_Total`,
`N_Ausente_Original`, `N_Invalido`, `N_Nao_Informado`, `N_NA` e `Pct_NA`.
`N_NA` soma ausência original e códigos fora do domínio. Categorias válidas de
não declaração ou desconhecimento são contadas separadamente.

## PASSO 2: Correlações

### `2_ANALISE_POR_ESCOLA/outputs/<YYYY-MM-DD>/tabelas/<ID_ESCOLA>/correlacoes_mantidas_MT.csv` / `_LP.csv`
Correlações que passaram no filtro |r| >= 0.30.

| Coluna | Descrição |
|--------|-----------|
| Variavel | Nome da variável |
| Metodo | Spearman ou Pearson |
| Correlacao_Matematica | Correlação com MT (-1 a +1) |
| Correlacao_Portugues | Correlação com LP (-1 a +1) |
| Status_Calculo | OK nas duas disciplinas ou PARCIAL; consultar status individual |
| Status_MT, Status_LP | Situação do cálculo em cada disciplina |
| N_Pares_MT, N_Pares_LP | Quantidade de pares finitos no cálculo |

### `2_ANALISE_POR_ESCOLA/outputs/<YYYY-MM-DD>/tabelas/<ID_ESCOLA>/dados_FINAL_MT_Filtrado.csv` / `_LP_Filtrado.csv`
Dados escalados (z-score) para modelagem e dashboard.

## PASSO 4: Metadados

### `3_ANALISE_DE_GRUPOS/outputs/<YYYY-MM-DD>/metadados/metadados_escolas_HHMMSS.csv`
Perfil agregado de cada escola (1 linha = 1 escola).

| Coluna | Descrição |
|--------|-----------|
| ID_ESCOLA | Identificador |
| N_ALUNOS | Total de registros da escola |
| N_ALUNOS_MT_VALIDOS, N_ALUNOS_LP_VALIDOS | Notas válidas por disciplina |
| N_ALUNOS_PAREADOS | Alunos com ambas as notas válidas |
| N_ALUNOS_INSE | INSE válido |
| MEDIAS_PAREADAS | Indica se as médias usam o subconjunto com ambas as notas |
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

## Fluxos de elegibilidade

`diagnosticos/fluxo_amostra_INSE_*.csv`, `fluxo_amostra_itens_*.csv` e
`fluxo_amostra_mediacao_*.csv` preservam denominadores, `Incluida` e `Motivo`.
O passo 9 também grava `fluxo_casos_completos_itens_*.csv` para perdas por preditores.

## PASSO 8: Regressão Linear

### `4_REGRESSAO_LINEAR/outputs/<YYYY-MM-DD>/tabelas/sensibilidade_coeficientes_HC3_*.csv`
Comparação auxiliar dos coeficientes OLS e WLS com inferência robusta HC3.

### `4_REGRESSAO_LINEAR/outputs/<YYYY-MM-DD>/tabelas/sensibilidade_ajustes_OLS_WLS_*.csv`
Métricas de ajuste da análise de sensibilidade. Não substitui o modelo principal.

### `4_REGRESSAO_LINEAR/outputs/<YYYY-MM-DD>/tabelas/resumo_modelos_*.csv`
Diagnósticos dos modelos.

| Coluna | Descrição |
|--------|-----------|
| Disciplina | MT ou LP |
| R2_ajustado | Variância explicada |
| RMSE | Erro médio de previsão |
| AIC / BIC | Critérios de informação |

### `4_REGRESSAO_LINEAR/outputs/<YYYY-MM-DD>/tabelas/coeficientes_MT_*.csv` / `_LP_*.csv`
Coeficientes da regressão.

| Coluna | Descrição |
|--------|-----------|
| Preditor | Nome da variável |
| Beta | Efeito estimado |
| EP | Erro padrão |
| t | Estatística t |
| p_valor | Significância |
| Significancia | * p<0.05, ** p<0.01, *** p<0.001 |

### `4_REGRESSAO_LINEAR/outputs/<YYYY-MM-DD>/figuras/diagnosticos_residuos_MT_*.png`
Painel 2x2: Resíduos vs Fitted, Q-Q, Scale-Location, Histograma.

## PASSO 9: Itens Brutos

### `5_REGRESSAO_ITENS_BRUTOS/outputs/<YYYY-MM-DD>/tabelas/resumo_modelos_itens_*.csv`
Mesmo formato do PASSO 8, para modelos com itens brutos.

### `5_REGRESSAO_ITENS_BRUTOS/outputs/<YYYY-MM-DD>/tabelas/coeficientes_MT_itens_*.csv`
Coeficientes dos ~150 itens mantidos após VIF.

### `5_REGRESSAO_ITENS_BRUTOS/outputs/<YYYY-MM-DD>/figuras/coeficientes_top_MT_itens_*.png`
Top 20 variáveis por magnitude do efeito.

## PASSO 10: Análise de Mediação

### `6_ANALISE_MEDIACAO/outputs/<YYYY-MM-DD>/tabelas/mediacao_*.csv`
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
| Proporcao_Mediada | Proporção estimada × 100; interpretação exploratória |
| N_Escolas, N_Referencia, N_Tratamento | Tamanho do contraste efetivamente ajustado |
| Referencia | Pública ou Urbana_Capital, conforme a análise |
| Ajuste | Informa a ausência de covariáveis adicionais |

### `6_ANALISE_MEDIACAO/outputs/<YYYY-MM-DD>/figuras/caminhos_mediacao_MT_*.png`
Figura 21: Diagrama de caminhos (MT).

### `6_ANALISE_MEDIACAO/outputs/<YYYY-MM-DD>/figuras/caminhos_mediacao_LP_*.png`
Figura 22: Diagrama de caminhos (LP).
