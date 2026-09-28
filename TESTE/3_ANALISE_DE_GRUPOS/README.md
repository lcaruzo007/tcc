# Análise de Grupos (Inter-Escolas)

Scripts para análise de GRUPOS de escolas — comparações estatísticas e clustering.

## Scripts

| Script | Passo | Descrição |
|--------|-------|-----------|
| `classificar_escolas.r` | 4 | Agrega dados por escola, cria metadados |
| `comparar_grupos.r` | 5 | Testes estatísticos entre grupos |
| `comparar_duas_escolas.r` | 6 | Comparação lado a lado de 2 escolas (opcional) |
| `dendrograma_analise_completa.r` | 7 | Clustering hierárquico geral (ALTO x BAIXO) |
| `base_dendrograma.r` | — | Funções compartilhadas pelos 4 scripts comparativos abaixo (não executar diretamente) |
| `dendrograma_publica_vs_particular.r` | 7 | Clustering: Pública x Privada |
| `dendrograma_urbana_vs_rural.r` | 7 | Clustering: Urbana x Rural |
| `dendrograma_capital_vs_interior.r` | 7 | Clustering: Capital x Interior |
| `dendrograma_area_local.r` | 7 | Clustering: AREA_LOCAL (4 categorias combinadas) |
| `dendrogramas_artigo.r` | 7 | Gera somente os 5 dendrogramas, com legenda de cores, em alta resolução |

## Execução

```r
# PASSO 4 (necessário antes dos outros)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r")

# PASSO 5
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_grupos.r")

# PASSO 6 (opcional — altere IDs no topo do script)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_duas_escolas.r")

# PASSO 7 (geral: ALTO x BAIXO)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_analise_completa.r")

# PASSO 7 (comparativos - cada um roda independente, ja carrega base_dendrograma.r)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_publica_vs_particular.r")
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_urbana_vs_rural.r")
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_capital_vs_interior.r")
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_area_local.r")

# PASSO 7 (figuras limpas para artigo: geral + 4 comparativos)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrogramas_artigo.r")
```

## Outputs (pastas datadas)

Todos os scripts usam `caminho_saida()` e gravam em
`outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>`. A leitura procura primeiro
nas pastas datadas e mantém fallback para outputs antigos.

```
outputs/
+-- <YYYY-MM-DD>/
|   +-- metadados/
|   |   +-- metadados_escolas_<HHMMSS>.csv
|   +-- tabelas/
|   |   +-- resultados_comparacao_<HHMMSS>.csv
|   |   +-- tabela_*_<HHMMSS>.csv
|   +-- figuras/
|   |   +-- 01_boxplot_tipo_escola_<HHMMSS>.png
|   |   +-- dendrograma_geral_ALTO_BAIXO_<HHMMSS>.png
|   |   +-- capital_vs_interior/
|   |   +-- publica_vs_particular/
|   |   +-- urbana_vs_rural/
|   |   +-- area_local/
|   +-- comparacoes/
|       +-- escola_{A}_vs_escola_{B}/
|           +-- comparacao_escola_*_<HHMMSS>.csv
|           +-- perfis_escolas_<HHMMSS>.csv
|           +-- visualizacao_comparacao_<HHMMSS>.png
```

## Comparações realizadas (PASSO 5)

| Grupo A | Grupo B | Objetivo |
|---------|---------|----------|
| Pública | Privada | Tipo de escola influencia proficiência? |
| Urbana | Rural | Localização importa? |
| Capital | Interior | Proximidade da capital afeta resultado? |
| Alto INSE | Baixo INSE | Nível socioeconômico é determinante? |
| Urbana_Capital / Urbana_Interior / Rural_Capital / Rural_Interior | (todos os pares) | Localização e área geográfica interagem? |

**Nota:** Cada comparação é feita em **ambas as direções** (ex: Pública→Privada E Privada→Pública). As 4 primeiras comparações geram 16 linhas. A comparação AREA_LOCAL cobre os pares entre as categorias efetivamente observadas. Com as 4 categorias presentes, o total é 40 linhas; categorias sem escolas são registradas no console e não geram linhas vazias.

### Teste estatístico
- **Wilcoxon** (não-paramétrico, não assume normalidade)
- **Correção de multiplicidade**: Benjamini-Hochberg (`p_valor_ajustado_bh`)
- **Tamanho de efeito**: rank-biserial r (0.0 a 1.0)
  - 0.1-0.3: pequeno
  - 0.3-0.5: médio
  - >0.5: grande

## Clustering (PASSO 7)

### Dendrograma geral
- Filtra escolas ALTO (>=P75) e BAIXO (<=P25) desempenho
- Remove INTERMEDIÁRIO
- Método: Ward.D2, distância euclidiana
- Colorido por tipo: Azul=Pública, Vermelho=Privada

### Interpretação
- Ramos próximos = escolas similares
- Distância < 1.0 = muito similares
- Distância > 2.0 = bem diferentes

### Dendrogramas comparativos (Pública x Privada, Urbana x Rural, Capital x Interior, AREA_LOCAL)
- Cada script carrega `base_dendrograma.r` (funções de plot compartilhadas) e filtra as
  escolas válidas do grupo comparado, selecionando as `N_ESCOLAS_POR_GRUPO` mais extremas
  (melhor/pior desempenho) para manter o dendrograma legível
- Método: Ward.D2, distância euclidiana, sobre `MEDIA_MT`, `MEDIA_LP`, `INSE_MEDIO` escalados
- `dendrograma_area_local.r` corta em 4 clusters (um por categoria) e usa a mesma paleta de
  `comparar_grupos.r` (COMPARACAO 5) para manter identidade visual entre os gráficos
