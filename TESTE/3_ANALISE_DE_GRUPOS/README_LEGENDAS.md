# Documentação dos Arquivos CSV Gerados

## Sumário
Este documento descreve todos os arquivos CSV gerados pelos scripts de análise em `/TESTE/3_ANALISE_DE_GRUPOS/Scripts/`.

---

## 1. **metadados_escolas_YYYYMMDD_HHMMSS.csv**
**Script de origem:** `classificar_escolas.r`  
**Descrição:** Agregação completa de todas as escolas com proficiência, INSE e classificações.

### Colunas:

| Coluna | Descrição |
|--------|-----------|
| **ID_ESCOLA** | Identificador único da escola (código SAEB) |
| **TIPO_ESCOLA** | Classificação: Pública ou Privada (baseado em IN_PUBLICA) |
| **AREA** | Localização geográfica: Capital ou Interior |
| **LOCALIZACAO** | Tipo de localização: Urbana ou Rural |
| **MEDIA_MT** | Proficiência média em Matemática (escala 0-500) |
| **MEDIA_LP** | Proficiência média em Língua Portuguesa (escala 0-500) |
| **FAIXA_MT** | Classificação em quartis de Matemática (Q1_Baixo até Q4_Alto) |
| **FAIXA_LP** | Classificação em quartis de Língua Portuguesa (Q1_Baixo até Q4_Alto) |
| **INSE_MEDIO** | Índice Socioeconômico médio da escola (escala 0-10) |
| **GRUPO_INSE** | Classificação em 3 grupos: Baixo_INSE, Medio_INSE, Alto_INSE |
| **NIVEL_INSE_MODAL** | Nível INSE mais frequente entre os alunos |
| **N_ALUNOS** | Número total de alunos avaliados na escola |
| **N_ALUNOS_MT_VALIDOS** | Número de alunos com proficiência válida em Matemática |
| **N_ALUNOS_LP_VALIDOS** | Número de alunos com proficiência válida em Língua Portuguesa |

---

## 2. **Comparacao_Escola_*_vs_*_YYYYMMDD_HHMMSS.csv**
**Script de origem:** `comparar_duas_escolas.r`  
**Descrição:** Comparação lado a lado de duas escolas específicas.  
**Local:** `comparacao_duas_escolas/`

### Colunas:

| Coluna | Descrição |
|--------|-----------|
| **Métrica** | Nome do indicador ou métrica de comparação |
| **Escola_A** | Valor do indicador para a Escola A |
| **Escola_B** | Valor do indicador para a Escola B |
| **Diferença** | Diferença entre Escola B e Escola A (B - A) |

### Métricas incluídas:
- ID Escola
- Nome
- N Alunos
- Estatísticas de Matemática: Média, Desvio Padrão, Mín, Q1, Mediana, Q3, Máx
- Estatísticas de Língua Portuguesa: Média, Desvio Padrão, Mín, Q1, Mediana, Q3, Máx
- INSE: Média e Desvio Padrão

---

## 3. **Perfis_Escolas_YYYYMMDD_HHMMSS.csv**
**Script de origem:** `comparar_duas_escolas.r`  
**Descrição:** Resumo agregado das duas escolas comparadas.  
**Local:** `comparacao_duas_escolas/`

### Colunas:

| Coluna | Descrição |
|--------|-----------|
| **ID_ESCOLA** | Identificador único da escola |
| **NOME** | Nome descritivo da escola |
| **N_ALUNOS** | Número total de alunos avaliados |
| **MEDIA_MT** | Proficiência média em Matemática |
| **MEDIA_LP** | Proficiência média em Língua Portuguesa |
| **SD_MT** | Desvio padrão de Matemática (variação das notas) |
| **SD_LP** | Desvio padrão de Língua Portuguesa (variação das notas) |
| **MIN_MT** | Proficiência mínima em Matemática |
| **MAX_MT** | Proficiência máxima em Matemática |
| **Q1_MT** | Primeiro quartil (25º percentil) de Matemática |
| **Q2_MT** | Mediana (50º percentil) de Matemática |
| **Q3_MT** | Terceiro quartil (75º percentil) de Matemática |
| **MIN_LP** | Proficiência mínima em Língua Portuguesa |
| **MAX_LP** | Proficiência máxima em Língua Portuguesa |
| **Q1_LP** | Primeiro quartil (25º percentil) de Língua Portuguesa |
| **Q2_LP** | Mediana (50º percentil) de Língua Portuguesa |
| **Q3_LP** | Terceiro quartil (75º percentil) de Língua Portuguesa |
| **INSE_MEDIO** | Índice Socioeconômico médio |
| **SD_INSE** | Desvio padrão do INSE |

---

## 4. **resultados_comparacao_YYYYMMDD_HHMMSS.csv**
**Script de origem:** `comparar_grupos.r`  
**Descrição:** Resultados de testes estatísticos (Wilcoxon) comparando grupos.  
**Local:** `/processados/`

### Colunas:

| Coluna | Descrição |
|--------|-----------|
| **Variável** | Nome da variável testada (PROFICIÊNCIA_MT, PROFICIÊNCIA_LP) |
| **Grupo1** | Nome do primeiro grupo (ex: Pública, Urbana, Alto_INSE) |
| **Grupo2** | Nome do segundo grupo (ex: Privada, Rural, Baixo_INSE) |
| **N1** | Número de escolas no Grupo 1 |
| **N2** | Número de escolas no Grupo 2 |
| **Mediana1** | Mediana da proficiência no Grupo 1 |
| **Mediana2** | Mediana da proficiência no Grupo 2 |
| **U** | Estatística do teste Wilcoxon |
| **p_valor** | P-valor do teste (significância estatística) |
| **r_rank_biserial** | Tamanho do efeito (coeficiente de correlação) |
| **Significância** | Indicador: ns (não significativo), * (p<0.05), ** (p<0.01), *** (p<0.001) |

### Grupos comparados:
1. **PÚBLICA vs PRIVADA**
2. **URBANA vs RURAL**
3. **CAPITAL vs INTERIOR**
4. **ALTO_INSE vs BAIXO_INSE**

---

## 5. **clusters_escolas_YYYYMMDD_HHMMSS.csv**
**Script de origem:** `dendrograma.r`  
**Descrição:** Atribuição de clusters para cada escola baseado em análise hierárquica.  
**Local:** `/processados/`

### Colunas:

| Coluna | Descrição |
|--------|-----------|
| **ID_ESCOLA** | Identificador único da escola |
| **NO_ESCOLA** | Nome da escola |
| **GRUPO_TIPO** | Classificação: Pública ou Privada |
| **MEDIA_MT** | Proficiência média em Matemática |
| **MEDIA_LP** | Proficiência média em Língua Portuguesa |
| **INSE_MEDIO** | Índice Socioeconômico médio |
| **Cluster_MT** | Atribuição de cluster baseado em Matemática + INSE |
| **Cluster_LP** | Atribuição de cluster baseado em Língua Portuguesa + INSE |
| **Cluster_3D** | Atribuição de cluster baseado em MT + LP + INSE |

### Interpretação:
- Escolas no mesmo cluster têm perfil semelhante
- 4 clusters criados por método Ward.D2
- Clustering hierárquico detecta similaridade em múltiplas dimensões

---

## Notas Técnicas

### Escalas de Proficiência
- **Escala SAEB:** 0 a 500 pontos
- **Matemática (MT):** Avalia habilidades matemáticas
- **Língua Portuguesa (LP):** Avalia leitura e compreensão

### Índice INSE (Nível Socioeconômico)
- **Escala:** 0 a 10 pontos
- **Baixo:** < 33º percentil (aproximadamente < 4.3)
- **Médio:** 33º a 67º percentil (aproximadamente 4.3 a 4.9)
- **Alto:** > 67º percentil (aproximadamente > 4.9)

### Medidas Estatísticas
- **Mediana (Q2):** Valor central que divide os dados ao meio (50º percentil)
- **Quartis:** Q1 (25%), Q2 (50%), Q3 (75%)
- **Desvio Padrão (SD):** Medida de variabilidade dos dados
- **Teste de Wilcoxon:** Teste não-paramétrico para comparar duas amostras
- **P-valor:** Probabilidade do resultado ocorrer por acaso (< 0.05 = significativo)

### Dados Geográficos
- **Região:** Minas Gerais (MG) - Dados filtrados apenas para este estado
- **Area:** Capital (Belo Horizonte) vs Interior
- **Localização:** Urbana vs Rural

### Datas e Timestamps
- **YYYYMMDD_HHMMSS:** Formato de data e hora (Ano-Mês-Dia_Hora-Minuto-Segundo)
- Exemplo: `20260512_081534` = 12/05/2026 às 08:15:34

---

## Como usar estes dados

1. **Para análise de perfil de escolas:** Use `metadados_escolas_*.csv`
2. **Para comparação detalhada de duas escolas:** Use `Comparacao_Escola_*_vs_*.csv` + `Perfis_Escolas_*.csv`
3. **Para testes estatísticos entre grupos:** Use `resultados_comparacao_*.csv`
4. **Para análise de clusters:** Use `clusters_escolas_*.csv` com os dendrogramas PNG

---

## Contato e Atualizações
- **Última atualização:** 12/05/2026
- **Scripts location:** `c:\Users\13756596699\tcc\TESTE\3_ANALISE_DE_GRUPOS\Scripts\`
- **Output location:** `c:\Users\13756596699\tcc\TESTE\processados\`
