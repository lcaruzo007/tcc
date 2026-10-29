# Guia do pipeline · SAEB 2023

[Visão geral](../../README.md) · [Metodologia](metodologia.md) · [Outputs](referencia_outputs.md) · [Requisitos](requisitos.md)

## Executar

Abra o terminal na raiz. O executor confere as versões de R e pacotes contra
[renv.lock](../../renv.lock), resolve dependências e executa cada script em um
processo R isolado.

```powershell
Rscript TESTE/DOCUMENTACAO/verificar_dependencias.r
Rscript TESTE/DOCUMENTACAO/validar_pipeline.r --somente-sintaxe
Rscript executar_pipeline.r
Rscript TESTE/DOCUMENTACAO/validar_pipeline.r --exigir-dados
```

A validação completa usa casos sintéticos e os metadados locais. Sem metadados,
a execução sem `--exigir-dados` informa explicitamente que a validação foi parcial.

```powershell
# Acrescenta automaticamente o passo 4 antes da mediacao
Rscript executar_pipeline.r --passos=10

# Acrescenta o passo 1; limita apenas o ramo individual aos IDs informados
Rscript executar_pipeline.r --passos=2 --escolas=61399103,61432986

# Modelo principal, referencias alternativas e sensibilidade OLS/WLS com HC3
Rscript executar_pipeline.r --passos=8 --auxiliares
```

Os passos 3 (Shiny) e 6 (duas escolas) permanecem manuais. No R:

```r
shiny::runApp("TESTE/2_ANALISE_POR_ESCOLA/Scripts/graficos.r")
```

No passo 6, configure os IDs ou os arquivos XLSX. Ambos os modos exigem
indicadores de validade das notas e do INSE; campos ausentes provocam erro.

## Dependências reais

```text
CSV -> 1: limpeza -> 2: correlacoes -> 3: dashboard
CSV -> 4: metadados -> 5: grupos / 6: duas escolas / 7: dendrogramas / 10: mediacao
CSV -> 8: regressao principal -> auxiliares
CSV -> 9: itens brutos
```

O CSV deve conter exclusivamente `ID_SAEB = 2023`, `ID_UF = 31` e séries
`12/13`. A leitura interrompe o processamento se esse contrato não for cumprido.
Não há filtragem silenciosa do arquivo nacional.

A entrada `MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv` foi substituída em
29/10/2026 pelo recorte MG conferido na base nacional fornecida, mantendo os
173.918 alunos e 2.338 escolas. O arquivo anterior foi preservado em backup.
A proveniência está em `outputs/2026-10-29/metadados/atualizacao_fonte_MG_102852.json`.
As saídas anteriores permanecem históricas e precisam ser regeneradas com
essa entrada; validar o CSV não atualiza automaticamente os modelos salvos.

## Organização das saídas

Todos os módulos gravam novas saídas por meio de `caminho_saida()`:

```text
<modulo>/outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>
```

Nos módulos 1 e 2, tabelas escolares ficam em `tabelas/<ID_ESCOLA>/`.
Os relatórios de respostas do módulo 1 ficam em `diagnosticos/<ID_ESCOLA>/`.
Um contador evita colisões no mesmo segundo. Os leitores continuam aceitando
os caminhos antigos para consulta manual; arquivos históricos não são movidos.
Na consulta manual, a lista de escolas prioriza a pasta datada mais recente com
tabelas escolares. O ranking do buscador é exploratório e sensível ao tamanho da escola.

## Rastreabilidade

Cada execução gera em `DOCUMENTACAO/outputs/<data>/`:

| Artefato | Conteúdo |
|----------|----------|
| `metadados/manifesto_*.rds` | ID, argumentos, revisão e estado do Git, hashes MD5, ambiente e estado de cada etapa |
| `metadados/artefatos_*.csv` | Entradas e saídas declaradas, etapa e horário |
| `metadados/ambiente_*.csv` | Versões instaladas de pacotes e versão de compilação |
| `metadados/entradas_*.rds` | Catálogo de artefatos disponibilizados ao próximo subprocesso |
| `diagnosticos/etapa_*.log` | Console de cada script |

O executor só permite ler artefatos produzidos na execução corrente. A seleção
de `--passos` acrescenta seus produtores; uma dependência ausente gera erro.
Na consulta manual, a busca prioriza o layout datado e ordena por data, horário
e contador do nome, sem depender de quando o arquivo foi copiado.

Para inspecionar um manifesto no R:

```r
m <- readRDS("caminho/para/manifesto_da_execucao.rds")
m$Status
m$Etapas
m$MD5_Entrada
stopifnot(identical(
  unname(tools::md5sum(names(m$MD5_Artefatos))),
  unname(m$MD5_Artefatos)
))
```

## Infraestrutura compartilhada

| Arquivo | Responsabilidade |
|---------|------------------|
| `utils_saeb.r` | Dicionários, caminhos, temas e carregamento dos helpers |
| `dados_saeb.r` | Recorte, validade, respostas, médias, classificações e elegibilidade |
| `execucao_saeb.r` | Catálogo de artefatos e compatibilidade de leitura |
| `ambiente_saeb.r` | Conferência do ambiente contra o lockfile |
| `executar_etapa.r` | Inicialização de cada subprocesso |
| `testar_contratos.r` | Casos sintéticos de regressão |
| `validar_pipeline.r` | Sintaxe, testes e invariantes dos metadados reais |

A [análise do projeto](analise_projeto.md) preserva o diagnóstico inicial e
registra as correções. O [diário](../../diario.md) guarda as sessões.
