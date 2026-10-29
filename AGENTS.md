# AGENTS.md

Guia de contexto e convenções para agentes autonomos (e colaboradores) que
trabalham neste repositorio. Leiam este arquivo ANTES de editar codigo ou
documentacao.

## Resumo do projeto

TCC de mestrado / especializacao que analisa os microdados do **SAEB 2023**
(Minas Gerais) para estudar o **impacto socioeconomico na proficiencia escolar**
de alunos da 3a serie do Ensino Medio. Pipeline inteiramente em **R** (tidyverse).

- ~173.918 alunos, 2.338 escolas, 851 municipios de MG
- Variaveis alvo: `MEDIA_MT` (Matematica) e `MEDIA_LP` (Lingua Portuguesa)
- Proxy socioeconomico: `INSE_ALUNO` (score TRI do INEP), agregado por escola
  como `INSE_MEDIO`.

## Stack / comandos

- Linguagem: **R** (>= 4.x). Pacotes principais: `tidyverse`, `broom`,
  `patchwork`, `car`, `lmtest` (ver `TESTE/DOCUMENTACAO/requisitos.md`).
- Executar um script (exemplo):
  ```powershell
  Rscript TESTE/4_REGRESSAO_LINEAR/Scripts/regressao_linear_multipla.r
  ```
- **Nao ha linter/formatter configurado**. Validacao se faz rodando o script OU
  carregando no RStudio. Use `parse(path)` para checar sintaxe sem executar.
- Nao commitar arquivos de output gerados (renam o R). A regra do `.gitignore`
  exclui pastas `outputs/` (verifique antes de forcar add).

## Estrutura

```
tcc/
+-- README.md            Visao geral / pipeline
+-- diario.md            Registro cronologico de mudancas (SEMPRE atualize)
+-- AGENTS.md            Este arquivo
+-- MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv   (dados brutos - nao commitar)
+-- refs/                PDFs de referencia
+-- TESTE/
    +-- DOCUMENTACAO/
    |   +-- utils_saeb.r            Funcoes e dicionarios compartilhados
    |   +-- metodologia.md / referencia_outputs.md / requisitos.md / README.md
    +-- 1_LIMPEZA_E_TRANSFORMACAO/        PASSO 1 (ajeitar_dados.r)
    +-- 2_ANALISE_POR_ESCOLA/             PASSO 2-3 (correlacao, graficos)
    +-- 3_ANALISE_DE_GRUPOS/              PASSO 4-7
    +-- 4_REGRESSAO_LINEAR/               PASSO 8
    +-- 5_REGRESSAO_ITENS_BRUTOS/         PASSO 9
    +-- 6_ANALISE_MEDIACAO/               PASSO 10 (mediacao INSE)
```

## Conventoes OBRIGATORIAS

### 1. Pastas datadas (Refatoracao #2 - Julho 2026)

TODO output deve ser gravado em:

```
<modulo>/outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>
```

- `<tipo>` = `tabelas` | `figuras` | `diagnosticos` | `modelos` | `metadados`
  | `comparacoes` (o que fizer sentido para o modulo).
- Use a funcao `caminho_saida(DIR_BASE_MODULO, subpasta, nome, ext)` definida em
  `TESTE/DOCUMENTACAO/utils_saeb.r`. Ela cria a pasta automaticamente.
- NUNCA escreva direto em `outputs/tabelas/`, `outputs/figuras/` etc. (estilo
  antigo). Esse padrao so existe por compatibilidade de LEITURA.
- Para LER o arquivo mais recente de um modulo, use
  `encontrar_arquivo_mais_recente(pasta, nome_base, tipo)`. Ela procura antes
  nas subpastas datadas e depois no padrao antigo (fallback).
- NAO sobrescreva arquivos antigos; o novo timestamp de HHMMSS dentro da pasta
  datada garante rastreabilidade.

### 2. Deteccao de caminhos

NUNCA hard-code caminhos absolutos (`C:/Users/...`). Todo script DEVE:

1. Definir localmente a funcao `detectar_raiz()` (ou source-a-la `utils_saeb.r`
   apos ter uma RAIZ) que sobe diretorios ate achar a pasta `TESTE/`.
2. `source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))` para
   reutilizar helpers (`caminho_saida`, `encontrar_arquivo_mais_recente`,
   `tema_saeb`, paletas, dicionarios de variaveis).
3. Usar `file.path(...)` e barras normais `/` (nunca `\`).

### 3. Variavel AREA_LOCAL

A partir da refatoracao de julho/2026, os modelos de regressao NAO usam mais
`AREA` e `LOCALIZACAO` como preditores separados. Usam a variavel combinada
`AREA_LOCAL` (4 categorias: `Urbana_Capital`, `Urbana_Interior`,
`Rural_Capital`, `Rural_Interior`). Isso captura a interacao urbano/ural x
capital/interior identificada como lacuna na apresentacao do TCC.
No recorte MG/2023, `Rural_Capital` nao foi observada; scripts devem ignorar
categorias sem variacao em vez de ajustar coeficientes nao estimaveis.

- Modelo principal: referencias = `TIPO_ESCOLA = "Publica"` e
  `AREA_LOCAL = "Urbana_Capital"`.
- Script auxiliar `grafico_coeficientes_referencia_oposta.r`: gerar o mesmo
  grafico com referencias opostas (`Privada` + `Rural_Interior`).
- Mantenha `AREA` e `LOCALIZACAO` separadas apenas para referencia descritiva.

### 4. Estilo de codigo

- **Sem acentos** em strings/mensagens de scripts R (conventao adotada na
  refatoracao de julho/2026 para evitar problemas de encoding entre
  Windows/UTF-8/Latin1). Comentarios sem acento tambem.
- Indentacao com 2 espacos. Sem `;` para encadear comandos logicos (
  use `if (condicao) { ... }` na linha seguinte).
- `library(tidyverse)` no topo; use pipe nativo `|>`.
- Nao adicionar comentarios explicativos no codigo a nao ser que o padrao do
  arquivo ja os tenha. Mantenha cabecalhos descritivos (titulo, ENTRADA,
  SAIDA, VERSAO) no topo de cada script.

### 5. Versionamento e diario

- **Atualize `diario.md`** ao final de cada sessao de trabalho significativa
  (nova entrada com data, horario, fase, atividades, desafios, resultados e
  proximos passos - siga o formato das entradas existentes).
- Mensagens de commit em portugues, estilo: `refactor: ...`, `feat: ...`,
  `fix: ...`, `docs: ...`.
- Nao commitar secrets/credenciais. Nao commitar arquivos `outputs/` (sao
  regeneraveis). Use `git status` antes de commitar.

## Estado atual (Outubro 2026)

- Pipeline enxuto de **10 passos** em **6 modulos** (1-6). Os modulos de HLM
  (modelos hierarquicos), validacao cruzada + ROC e indice composto (PCA)
  foram removidos — o TCC foca no eixo limpeza -> agrupamento -> regressao
  -> mediacao (vide `diario.md`, entrada ago/2026).
- Scripts dos modulos 4, 5 e 6 ja usam `caminho_saida()` (pastas datadas).
- Modulo 3 (classificar_escolas, comparar_grupos, comparacao de escolas e
  dendrogramas) usa `caminho_saida()` e le os formatos datado e legado.
- O script do modulo 5 foi migrado na refatoracao de 30/07.
- Outputs antigos dos modulos 3, 4, 5 ja foram migrados para pastas datadas
  (organizadas por data da run; vide `diario.md`).
- Modulo 6 (`analise_mediacao.r`) define `detectar_raiz()` localmente antes de
  carregar `utils_saeb.r` e pode ser iniciado em sessao R limpa.
- `executar_pipeline.r` executa as etapas nao interativas em sessoes R isoladas.
- `TESTE/DOCUMENTACAO/validar_pipeline.r` verifica sintaxe e invariantes basicos.
- Microdados CSV e pastas `outputs/` sao locais e ignorados pelo Git.
- Todos os seis modulos gravam novas saidas datadas; os modulos 1 e 2 usam
  `tabelas/<ID_ESCOLA>/` dentro da pasta datada e preservam leitura legada.
- `dados_saeb.r` centraliza recorte MG/2023, validade, dominios, agregacao e
  elegibilidade. Medias descritivas e pareadas tem denominadores explicitos.
- Mediacao de AREA_LOCAL usa contrastes par a par com Urbana_Capital.
- `renv.lock` fixa R/pacotes; o executor confere versoes, resolve produtores e
  vincula entradas ao catalogo da execucao. Manifestos/logs ficam em
  `TESTE/DOCUMENTACAO/outputs/<data>/`.
- `testar_contratos.r` usa dados sinteticos. `validar_pipeline.r --exigir-dados`
  tambem exige metadados locais; `--somente-sintaxe` verifica apenas parse.
- `metodologia.md` e a fonte metodologica principal; `README_METODOLOGICO.md`
  e um indice para evitar justificativas divergentes.

## Fontes de verdade

| Topico | Arquivo |
|--------|---------|
| Helpers e dicionarios de variaveis | `TESTE/DOCUMENTACAO/utils_saeb.r` |
| Dicionario de outputs | `TESTE/DOCUMENTACAO/referencia_outputs.md` |
| Base metodologica do TCC | `TESTE/DOCUMENTACAO/metodologia.md` |
| Historico de mudancas | `diario.md` |
| Dependencias R | `TESTE/DOCUMENTACAO/requisitos.md` |
