# Documentação — Análise SAEB 2023

Guia de uso do pipeline de análise.

## Comece aqui

1. Verifique as dependências em [requisitos.md](requisitos.md)
2. Execute os scripts na ordem indicada no [README principal](../../README.md)
3. Consulte [referencia_outputs.md](referencia_outputs.md) para entender os CSVs gerados
4. Use [metodologia.md](metodologia.md) para escrever o TCC

## Fluxo de Dados

```
MICRODADOS → [PASSO 1] → 1_LIMPEZA/outputs/{ID}/
                              ↓
                [PASSO 2] → 2_ANALISE/outputs/{ID}/
                              ↓
                [PASSO 3] → Dashboard Shiny (opcional)
                              
                [PASSO 4] → 3_GRUPOS/outputs/metadados/
                              ↓
                [PASSO 5] → 3_GRUPOS/outputs/metadados/ + figuras/
                              ↓
                [PASSO 7] → 3_GRUPOS/outputs/figuras/
                              ↓
                [PASSO 8] → 4_REGRESSAO/outputs/
                              ↓
                [PASSO 9] → 5_ITENS/outputs/
                              ↓
                [PASSO 11] → 7_HLM/outputs/ (modelos hierárquicos)
                              ↓
                [PASSO 12] → 8_MEDIACAO/outputs/ (mediação)
                              ↓
                [PASSO 13] → 9_CV/outputs/ (validação cruzada)
                              ↓
                [PASSO 15] → 11_INDICE/outputs/ (PCA)
```

## Estrutura de cada fase

| Fase | Pasta | Script principal | Entrada | Saída |
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
| 11 | `7_HLM/` | `modelos_hierarquicos.r` | MICRODADOS | `outputs/{tabelas,figuras}/` |
| 12 | `8_MEDIACAO/` | `analise_mediacao.r` | metadados | `outputs/{tabelas,figuras}/` |
| 13 | `9_CV/` | `validacao_cruzada.r` | metadados | `outputs/{tabelas,figuras}/` |
| 15 | `11_INDICE/` | `indice_composto.r` | metadados | `outputs/{tabelas,figuras}/` |

## Ordem de execução

```
PASSO 1 → PASSO 2 → [PASSO 3] → PASSO 4 → PASSO 5 → [PASSO 6] → PASSO 7 → PASSO 8 → [PASSO 9]
                                                                                               ↓
                                                                             PASSO 11 → PASSO 12 → PASSO 13 → PASSO 15
```

Passos entre colchetes são opcionais.

## Detecção Automática de Caminhos

Todos os scripts detectam automaticamente a pasta raiz do projeto. Funciona em qualquer computador, independente do nome da pasta de usuário.

Se a detecção falhar, o script pedirá para selecionar a pasta raiz manualmente.

## Configurações

Cada script tem configurações no topo. As principais:

### correlacao.r
```r
modo_execucao <- "pendentes"   # "todas", "pendentes", "especificas"
limiar_cor <- 0.30             # |r| mínimo para manter
```

### comparar_duas_escolas.r
```r
ID_ESCOLA_A <- 61432986        # Altere para a escola desejada
ID_ESCOLA_B <- 61466120        # Altere para a escola desejada
```

## Troubleshooting

| Problema | Solução |
|----------|---------|
| "Arquivo não encontrado" | Use `/` não `\` nos caminhos |
| "Pacote X não instalado" | Execute `install.packages("X")` |
| "metadados_escolas não encontrado" | Execute PASSO 4 antes |
| "dados_FINAL não encontrado" | Execute PASSO 2 antes |
| Demora muito | Normal: 173k registros na primeira execução |
