# Análise de Grupos (Inter-Escolas)

Scripts para análise de GRUPOS de escolas — comparações estatísticas e clustering.

## Scripts

| Script | Passo | Descrição |
|--------|-------|-----------|
| `classificar_escolas.r` | 4 | Agrega dados por escola, cria metadados |
| `comparar_grupos.r` | 5 | Testes estatísticos entre grupos |
| `comparar_duas_escolas.r` | 6 | Comparação lado a lado de 2 escolas (opcional) |
| `dendrograma_analise_completa.r` | 7 | Clustering hierárquico |

## Execução

```r
# PASSO 4 (necessário antes dos outros)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r")

# PASSO 5
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_grupos.r")

# PASSO 6 (opcional — altere IDs no topo do script)
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/comparar_duas_escolas.r")

# PASSO 7
source("TESTE/3_ANALISE_DE_GRUPOS/Scripts/dendrograma_analise_completa.r")
```

## Outputs (pastas datadas)

> **Convenção** (refatoração julho/2026): saídas com timestamp vão para
> `<modulo>/outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>`. Os arquivos
> antigos deste módulo já foram migrados para pastas datadas (vide
> `diario.md`). Os scripts deste módulo ainda não usam o helper
> `caminho_saida()` — pendente da Fase 3. Até lá, executar o script gera um
> novo nível `outputs/<tipo>/` no estilo antigo além das pastas datadas já
> migradas.

```
outputs/
+-- <YYYY-MM-DD>/               (uma pasta por dia, contém runs migradas/atuais)
|   +-- metadados/
|   |   +-- metadados_escolas_<HHMMSS>.csv       (perfil de cada escola)
|   |   +-- resultados_comparacao_<HHMMSS>.csv    (testes Wilcoxon)
|   |   +-- clusters_escolas_<HHMMSS>.csv        (atribuicao de clusters)
|   +-- figuras/
|       +-- dendrograma_geral_ALTO_BAIXO_<HHMMSS>.png
|       +-- tabela_escolas_ALTO_BAIXO_<HHMMSS>.csv
|
+-- comparacoes/                  (mantem subpasta por par - agrupa arquivos)
|   +-- Escola_{A}_vs_{B}_{YYYYMMDD_HHMMSS}/
|       +-- Comparacao_Escola_A_vs_B_*.csv
|       +-- Perfis_Escolas_*.csv
|       +-- visualizacao_comparacao_*.png
|
+-- figuras/                      (boxplots sem timestamp - estilo antigo)
    +-- 01_boxplot_tipo_escola.png
    +-- 02_boxplot_urbano_rural.png
    +-- 03_boxplot_capital_interior.png
    +-- 04_boxplot_inse.png
    +-- capital_vs_interior/      (dendrograma Modo 2)
    +-- publica_vs_particular/
    +-- urbana_vs_rural/
```

## Comparações realizadas (PASSO 5)

| Grupo A | Grupo B | Objetivo |
|---------|---------|----------|
| Pública | Privada | Tipo de escola influencia proficiência? |
| Urbana | Rural | Localização importa? |
| Capital | Interior | Proximidade da capital afeta resultado? |
| Alto INSE | Baixo INSE | Nível socioeconômico é determinante? |

**Nota:** Cada comparação é feita em **ambas as direções** (ex: Pública→Privada E Privada→Pública), gerando 16 linhas na tabela de resultados (8 comparações × 2 disciplinas).

### Teste estatístico
- **Wilcoxon** (não-paramétrico, não assume normalidade)
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