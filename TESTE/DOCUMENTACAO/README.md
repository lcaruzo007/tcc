# Documentacao — Analise SAEB 2023

Guia de uso do pipeline de analise.

## Comece aqui

1. Verifique as dependencias em [requisitos.md](requisitos.md)
2. Execute os scripts na ordem indicada no [README principal](../../README.md)
3. Consulte [referencia_outputs.md](referencia_outputs.md) para entender os CSVs gerados
4. Use [metodologia.md](metodologia.md) para escrever o TCC

## Fluxo de Dados

```
MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv
    |
    v
[PASSO 1] 1_LIMPEZA  -> outputs/{ID_ESCOLA}/dados_escola_em_numeros.csv
    |
    v
[PASSO 2] 2_ANALISE  -> outputs/{ID_ESCOLA}/correlacoes_*.csv, dados_FINAL_*.csv
    |
    v
[PASSO 3] 2_ANALISE  -> Dashboard Shiny (opcional)
    |
    v
[PASSO 4] 3_GRUPOS   -> outputs/metadados/metadados_escolas_*.csv
    |
    v
[PASSO 5] 3_GRUPOS   -> outputs/metadados/resultados_comparacao_*.csv + figuras
    |
    v
[PASSO 7] 3_GRUPOS   -> outputs/figuras/dendrograma_*.png
    |
    v
[PASSO 8] 4_REGRESSAO -> outputs/{modelos,tabelas,figuras}/
    |
    v
[PASSO 9] 5_ITENS     -> outputs/{modelos,tabelas,figuras}/  (complementar)
    |
    v
[PASSO 10] 6_MEDIACAO -> outputs/{tabelas,figuras}/
```

> O `metadados_escolas_*.csv` gerado no PASSO 4 e a entrada dos PASSOS 5, 7 e 10.

## Estrutura de cada fase

| Fase | Pasta | Script principal | Entrada | Saida |
|------|-------|-----------------|---------|-------|
| 1 | `1_LIMPEZA/` | `ajeitar_dados.r` | MICRODADOS | `outputs/{ID}/dados_escola_em_numeros.csv` |
| 2 | `2_ANALISE/` | `correlacao.r` | `1_LIMPEZA/outputs/` | `outputs/{ID}/correlacoes_*.csv` |
| 3 | `2_ANALISE/` | `graficos.r` | `2_ANALISE/outputs/` | Dashboard Shiny |
| 4 | `3_GRUPOS/` | `classificar_escolas.r` | MICRODADOS | `outputs/metadados/metadados_*.csv` |
| 5 | `3_GRUPOS/` | `comparar_grupos.r` | `outputs/metadados/` | `outputs/metadados/resultados_*.csv` + figuras |
| 6 | `3_GRUPOS/` | `comparar_duas_escolas.r` | `outputs/metadados/` | `outputs/comparacoes/` |
| 7 | `3_GRUPOS/` | `dendrograma_analise_completa.r` | `outputs/metadados/` | `outputs/figuras/` |
| 8 | `4_REGRESSAO/` | `regressao_linear_multipla.r` | MICRODADOS | `outputs/{modelos,tabelas,figuras}/` |
| 9 | `5_ITENS/` | `regressao_itens_brutos_dummy.r` | MICRODADOS | `outputs/{modelos,tabelas,figuras}/` |
| 10 | `6_MEDIACAO/` | `analise_mediacao.r` | metadados | `outputs/{tabelas,figuras}/` |

> **Modulos removidos**: HLM (modelos hierarquicos), validacao cruzada + ROC e
> indice composto (PCA) nao fazem mais parte do pipeline. Vide `diario.md`.

## Ordem de execucao

```
PASSO 1 -> PASSO 2 -> [PASSO 3] -> PASSO 4 -> PASSO 5 -> [PASSO 6] -> PASSO 7 -> PASSO 8 -> [PASSO 9] -> PASSO 10
```

Passos entre colchetes sao opcionais.

## Deteccao Automatica de Caminhos

Todos os scripts detectam automaticamente a pasta raiz do projeto (funcao `detectar_raiz()`). Funciona em qualquer computador, independente do nome da pasta de usuario.

Se a deteccao falhar, o script pedira para selecionar a pasta raiz manualmente.

## Configuracoes

Cada script tem configuracoes no topo. As principais:

### correlacao.r
```r
modo_execucao <- "pendentes"   # "todas", "pendentes", "especificas"
limiar_cor <- 0.30             # |r| minimo para manter
```

### comparar_duas_escolas.r
```r
ID_ESCOLA_A <- 61432986        # Altere para a escola desejada
ID_ESCOLA_B <- 61466120        # Altere para a escola desejada
```

## Troubleshooting

| Problema | Solucao |
|----------|---------|
| "Arquivo nao encontrado" | Use `/` nao `\` nos caminhos |
| "Pacote X nao instalado" | Execute `install.packages("X")` |
| "metadados_escolas nao encontrado" | Execute PASSO 4 antes |
| "dados_FINAL nao encontrado" | Execute PASSO 2 antes |
| Demora muito | Normal: 173k registros na primeira execucao |
