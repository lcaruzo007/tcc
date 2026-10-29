# Análise e correções do projeto SAEB 2023

**Revisão e implementação:** 20/10/2026.

**Atualização da fonte em 29/10/2026:** o CSV usado pelo projeto passou a ser
o recorte MG conferido na base nacional fornecida, com os mesmos 173.918 alunos
e 2.338 escolas. Foram recuperadas 250 notas e atualizados os demais campos
divergentes da fonte. O arquivo anterior foi preservado em backup local.
Modelos, figuras e manifestos anteriores à troca ainda descrevem a base antiga;
seu reprocessamento não faz parte desta atualização do arquivo de entrada.

[README](../../README.md) · [Metodologia](metodologia.md) · [Guia operacional](README.md) · [Diário](../../diario.md)

## Correções implementadas

A divisão em seis módulos foi mantida. As regras de dados e a infraestrutura
foram centralizadas para corrigir as inconsistências sem uma renomeação ampla.

| Questão identificada | Correção |
|----------------------|----------|
| Ausentes classificados como alto desempenho/INSE | Médias vazias retornam `NA_real_`; cortes usam valores finitos; a ausência é preservada na classificação |
| Mediação com referência diferente da anunciada | Cada contraste usa somente a categoria de interesse e `Urbana_Capital`; diagramas reutilizam os modelos estimados |
| Dummies e contínuas omitidas nas correlações | Seleção explícita dos escores ordinais, dummies de Q01/Q04 e variáveis do INSE; sem respostas brutas em letras |
| Correlação válida de uma disciplina descartada pela outra | Status e pares por disciplina; filtros independentes para MT e LP |
| Relatório de ausências incompatível com a limpeza | Domínio por pergunta; distinção entre ausência, código inválido e respostas válidas de não declaração/desconhecimento |
| Validade e amostra divergentes sem registro | Leitura, agregação e elegibilidade compartilhadas; denominadores e fluxos de exclusão exportados |
| Recorte não verificado | Erro para ano diferente de 2023, UF diferente de 31, séries fora de 12/13 ou identificadores obrigatórios ausentes |
| Sobrescritas nos módulos 1 e 2 | Novas saídas datadas por escola; dashboard e buscador adaptados; leitura legada preservada |
| Busca por data de modificação | Consulta manual ordenada por data/horário/contador, priorizando o layout datado |
| Mistura de artefatos de execuções diferentes | Executor resolve produtores e restringe leituras ao catálogo corrente |
| Dependências sem versões fixadas | `renv.lock` e conferência exata do R/pacotes; biblioteca restaurada carregada explicitamente nos subprocessos |
| Temas e rótulos duplicados | Tema compartilhado e rótulos do dicionário central; seleção de IDs dos dendrogramas de artigo exportada |
| Guias contraditórios | `metodologia.md` como fonte principal; guia metodológico convertido em índice; comandos e outputs atualizados |

A comparação manual de duas escolas também usa os indicadores de validade,
inclusive no modo XLSX. Ela exporta contagens de notas/INSE válidos; entradas
sem esses indicadores não recebem inferências silenciosas de validade.

## Efeito nas amostras e na interpretação

Os metadados continuam com **2.338 escolas**. As nove escolas sem médias e as
dez sem INSE permanecem sem essas medidas e **sem as respectivas classificações**.

A regressão principal conserva a política de médias com alunos que têm ambas
as notas válidas, mínimo de cinco pares e três INSE válidos. A mediação usa
médias descritivas por disciplina, agora com mínimo de cinco notas válidas em
cada uma e três valores válidos de INSE. Os denominadores são deliberados e
estão descritos na [metodologia](metodologia.md).

Na execução corrigida, a mediação tem 2.326 escolas elegíveis. Os contrastes
de localização ficaram assim, em cada disciplina:

| Contraste | Referência: Urbana_Capital | Categoria estudada | Total |
|-----------|----------------------------:|-------------------:|------:|
| Rural_Interior | 139 | 157 | 296 |
| Urbana_Interior | 139 | 2.030 | 2.169 |

O contraste por tipo usa 2.294 escolas públicas e 32 privadas. São tamanhos
das amostras elegíveis, distintos dos totais descritivos de 2.297/41.
A correção altera resultados analíticos; não consiste apenas em trocar legendas.

Respostas válidas `F`, por exemplo idade ou “não sei” nos itens de escolaridade,
são preservadas conforme o dicionário. Q01/Q04 incluem categorias explícitas
de não declaração. Isso evita tratar códigos iguais como inválidos em todas
as perguntas.

## Verificação

- Casos sintéticos aprovados para recorte, validade, denominadores, ausentes,
  domínios de respostas, seleção de preditores, contrastes e rastreabilidade.
- Validação dos metadados corrigidos aprovada para 2.338 escolas.
- Passos 4, 5, 7, 8, 9 e 10 executados, incluindo os cinco scripts do passo 7
  e os auxiliares de referência oposta e sensibilidade HC3.
- Passo 6 executado para as duas escolas configuradas.
- Integridade de 99 artefatos da primeira execução agregada conferida por MD5.
- Passo 1 reprocessado para as 2.338 escolas; passo 2 concluído para 2.328,
  com 10 exclusões por ausência de preditores com variação.
- As 2.338 leituras do passo 2 foram conferidas contra as saídas do passo 1
  no mesmo catálogo, sem mistura de arquivos anteriores.
- Conferidos 88.725 registros de correlação e 168.336 linhas dos 2.338
  relatórios de respostas: status, pares, limites dos coeficientes e contagens de ausências.
- Integridade MD5 conferida para 20.977 artefatos do ramo individual,
  99 da execução agregada e 32 da execução final do passo 8 e auxiliares.
- Dashboard validado por teste reativo; buscador e cinco dendrogramas para
  artigo executados. A inclusão automática do passo 4 foi testada ao solicitar somente o 5.
- Testado o cálculo dos dendrogramas sem criar Rplots.pdf na raiz, preservando
  as figuras explícitas em pastas datadas e o dispositivo gráfico anterior.

Os resultados locais usam pastas datadas. Manifestos, ambiente e logs ficam em
`TESTE/DOCUMENTACAO/outputs/<data>/` e são ignorados pelo Git. A verificação
final do ramo individual está registrada no diário.

## Decisões mantidas e próximos cuidados

A faixa operacional 150–800 foi mantida e precisa de justificativa na redação.
O modelo principal permanece OLS com a sensibilidade WLS/HC3 já existente.
WLS por quantidade de alunos não equivale ao uso dos pesos amostrais do SAEB.

A mediação continua exploratória e sem covariáveis adicionais; a documentação
agora explicita essa escolha. Pressupostos causais, estratégia de ponderação,
estabilidade dos agrupamentos e integração dos resultados ao TCC exigem
avaliação substantiva. As correções de software não substituem essas decisões.

Não é necessário reintroduzir os módulos removidos nem trocar o executor
para resolver os problemas encontrados.

## Diagnóstico inicial preservado

<details>
<summary>Abrir a análise anterior às correções</summary>

Os achados e números abaixo descrevem o estado anterior à implementação.
Referências a linhas de código correspondem à revisão inicial; os arquivos
vinculados já contêm as correções. O plano original funciona como histórico.


## Avaliação geral

A divisão em **seis módulos é adequada ao objetivo do TCC**. Ela distingue
tratamento de dados individuais, exploração por escola, comparação entre escolas,
modelo principal, exploração de itens e mediação. O executor em sessões isoladas,
os helpers compartilhados e a retirada de dados gerados do Git são boas bases.

O principal problema atual é a **coerência entre os ramos da análise**:
as bases são reconstruídas com regras diferentes, há classificações incorretas
de ausentes e a mediação anuncia uma referência que suas fórmulas não isolam.
Esses pontos devem ser resolvidos antes de ampliar as análises ou fechar o texto.

Recomendo manter os seis módulos, corrigir primeiro a semântica dos dados e dos
contrastes e depois melhorar a reprodutibilidade. Uma renomeação ampla de pastas
agora teria benefício menor e exigiria atualizar muitos caminhos.

## O que foi efetivamente verificado

| Verificação | Resultado em 20/10/2026 |
|-------------|------------------------|
| `validar_pipeline.r` com R 4.6.0 | Sintaxe de 25 scripts; invariantes básicos de 2.338 escolas; sem erro |
| `verificar_dependencias.r` | 11 pacotes obrigatórios e 3 opcionais disponíveis |
| CSV local | 173.918 registros; 2.338 escolas; 851 códigos distintos de município |
| Recorte do CSV | Somente SAEB 2023 e UF 31; séries 12 e 13 |
| Metadados consultados | `outputs/2026-09-28/metadados/metadados_escolas_081536.csv` do módulo 3 |
| Base do passo 8 consultada | `outputs/2026-09-28/tabelas/base_escolas_agregada_082134.csv` do módulo 4; 2.326 escolas |
| Leitura dirigida do passo 2 | Sete dummies nominais existentes no arquivo escolar consultado são excluídas pela seleção; as duas contínuas também |
| Execução integral dos modelos e figuras | Não realizada nesta revisão |

A validação disponível inclui o arquivo obsoleto em `arquivo/` e o
`buscador.r` local, ainda não rastreado pelo Git. Portanto, “25 scripts com
sintaxe válida” não significa 25 etapas ativas nem comprova a validade científica
do pipeline. A contagem também não inclui os scripts de importação em `INPUTS/`.

O R emitiu avisos de configuração de locale; as duas verificações terminaram com
código de saída zero. `Rscript` não está no `PATH` deste terminal: foi utilizado
o executável instalado. As consultas aos CSVs produziram apenas resumos, sem
reescrever microdados ou resultados. Os artefatos de setembro não foram regenerados.

## Estrutura e divisão de responsabilidades

| Parte | Responsabilidade atual | Avaliação e melhoria |
|-------|------------------------|---------------------|
| Raiz | Apresentação, executor, diário e convenções | Boa separação; manter a raiz pequena |
| Módulo 1 | Conversão de respostas e exportação por escola | Concentrar a limpeza e os critérios de validade reutilizáveis |
| Módulo 2 | Correlações individuais dentro de cada escola e Shiny | Identificar explicitamente como ramo exploratório; revisar seleção de colunas |
| Módulo 3 | Agregação, classificações, testes e dendrogramas | É o módulo mais heterogêneo; distinguir preparação da base, comparação e apresentação |
| Módulo 4 | Regressão principal, referência alternativa e sensibilidade | Boa separação dos auxiliares; evitar reconstruir regras comuns dentro do script |
| Módulo 5 | Proporções de itens, seleção por VIF, modelos e figuras | Manter complementar; separar preparação dos itens, ajuste e apresentação |
| Módulo 6 | Modelos de mediação e diagramas | Rever contrastes e pressupostos antes da interpretação |
| `DOCUMENTACAO/` | Guias, helpers e validações | Mistura documentação com infraestrutura executável; organizar gradualmente |
| `refs/` e `INPUTS/` | Referências e importadores do INEP | Preservar a distinção entre material de origem e código autoral |

Os passos numerados são uma ordem de trabalho. O fluxo efetivo é:

```text
CSV -> passo 1 -> passo 2 -> passo 3
CSV -> passo 4 -> passos 5, 6, 7 e 10
CSV -> passo 8 -> referência oposta e sensibilidade
CSV -> passo 9
```

Assim, o passo 8 não depende dos dendrogramas, e o passo 4 não consome a
limpeza do passo 1. O [executor](../../executar_pipeline.r) conhece a ordem,
mas não calcula dependências nem garante que um artefato pertence à execução atual.

## Achados prioritários

### 1. Ausentes são classificados como alto desempenho ou alto INSE

**Prioridade: P0 · Erro confirmado no código e nos metadados locais.**

Em [classificar_escolas.r](../3_ANALISE_DE_GRUPOS/Scripts/classificar_escolas.r),
linhas 156–168 e 211–215, os `case_when()` terminam em `TRUE ~ "Q4_Alto"`
ou `TRUE ~ "Alto_INSE"`. Quando o valor é `NA/NaN`, as comparações anteriores
não são verdadeiras e o último ramo é utilizado.

Nos metadados consultados:

- nove escolas sem `MEDIA_MT` recebem `FAIXA_MT = "Q4_Alto"`;
- nove sem `MEDIA_LP` recebem `FAIXA_LP = "Q4_Alto"`;
- dez sem `INSE_MEDIO` recebem `GRUPO_INSE = "Alto_INSE"`.

Isso altera rótulos, contagens e potenciais subconjuntos. Remover ausentes da
variável resposta em um teste não corrige uma classificação socioeconômica falsa.

**Melhoria:** tratar ausentes antes dos cortes, normalizar médias de conjuntos
vazios para `NA_real_` e acrescentar invariantes que proíbam classificar valores
ausentes em faixas válidas. Regenerar metadados e seus consumidores após a correção.

### 2. A referência anunciada na mediação de localização está incorreta

**Prioridade: P0 · Contraste confirmado pela construção das fórmulas.**

Em [analise_mediacao.r](../6_ANALISE_MEDIACAO/Scripts/analise_mediacao.r),
linhas 136–149 e 218–229, cada tratamento binário é ajustado separadamente com
toda a amostra. `RURAL_INTERIOR = 0` inclui tanto escolas urbanas da capital
quanto urbanas do interior. A mensagem “vs Urbana_Capital” não corresponde a
esse grupo de comparação.

Na amostra de 2.328 escolas que satisfaz os filtros atuais da mediação:

| Dummy | Grupo 1 | Grupo 0 efetivo |
|-------|---------|----------------|
| `RURAL_INTERIOR` | 157 rurais do interior | 2.031 urbanas do interior + 140 urbanas da capital |
| `URBANA_INTERIOR` | 2.031 urbanas do interior | 157 rurais do interior + 140 urbanas da capital |

**Melhoria:** para um contraste par a par, restringir a base à categoria de
interesse e a `Urbana_Capital` antes de ajustar os modelos. Alternativamente,
especificar um modelo categórico e contrastes consistentes. A escolha muda a
pergunta e deve ser documentada; não basta trocar o texto da legenda.

O modelo de mediação por tipo de escola também não inclui `AREA_LOCAL` como
controle. Isso difere da regressão principal. O conjunto de ajuste precisa de
justificativa substantiva; não se deve inserir controles automaticamente.

### 3. O passo 2 descarta variáveis que afirma analisar

**Prioridade: P1 · Seleção reproduzida em arquivo escolar local.**

Em [correlacao.r](../2_ANALISE_POR_ESCOLA/Scripts/correlacao.r),
linhas 360–362, `select()` mantém as proficiências e nomes iniciados por
`TX_RESP_Q`. As dummies do passo 1 têm prefixos `Q01_` e `Q04_`;
`INSE_ALUNO` e `NU_TIPO_NIVEL_INSE` também não são selecionados.

No arquivo escolar consultado, havia sete dummies nominais; nenhuma entra nessa
seleção. As duas contínuas configuradas no dicionário também ficam de fora.
Colunas brutas de respostas em letras permanecem e geram avisos de coerção
quando o filtro de variância tenta processá-las.

**Melhoria:** montar explicitamente as colunas analíticas a partir dos dicionários
compartilhados e das colunas transformadas, selecionar somente tipos adequados
e verificar a presença das variáveis esperadas. O passo 2 também não aplica os
indicadores de validade de proficiência nem a faixa usada nos passos 4, 8 e 9;
a limpeza das respostas do questionário, sozinha, não garante notas válidas.

O dashboard mantém ainda um dicionário próprio com rótulos divergentes do
importador do INEP: em `graficos.r`, `Q04` aparece como língua falada em casa,
`Q06` como cor/raça e `Q09` como escolaridade da mãe. No
[importador de 34EM](../../MICRODADOS_SAEB_2023/INPUTS/INPUT_R_TS_ALUNO_34EM.R),
linhas 197, 201 e 208, esses itens são, respectivamente, cor/raça, número de
moradores e escolaridade do pai. Centralizar os rótulos e conferir todos os
itens com o dicionário da edição evita interpretar a pergunta errada.

### 4. O relatório de ausências não reflete toda a limpeza

**Prioridade: P1 · Divergência confirmada na implementação.**

Em [ajeitar_dados.r](../1_LIMPEZA_E_TRANSFORMACAO/ajeitar_dados.r),
`limpa()` é aplicada aos vetores usados nas transformações, mas as colunas brutas
`TX_RESP_Q*` não são substituídas. O relatório de ausências conta `is.na()` nas
colunas brutas, deixando códigos como `"."` e `"*"` fora dessa contagem.

Como exemplo da dimensão do problema, `TX_RESP_Q10a` no CSV contém
40.492 respostas `"."` e 201 `"*"`. Esses códigos não são ausências
estruturais do CSV, mas são tratados como inválidos pela limpeza.

O passo 1 trata `"F"` como ausente de forma geral, enquanto o passo 9 remove
`"."`, `"*"` e vazio. A validade de cada resposta deve ser conferida por item;
uma letra pode ser categoria válida em uma pergunta e inválida em outra.

**Melhoria:** centralizar o domínio de respostas por item e distinguir ausência,
resposta inválida e categoria válida. Gerar o relatório a partir da regra efetiva
de limpeza e conferir se o denominador corresponde aos respondentes elegíveis.

### 5. Os critérios de amostra diferem entre agregação, regressão e mediação

**Prioridade: P1 · Diferença confirmada; não é necessariamente um erro.**

O passo 4 calcula médias de MT e LP separadamente, com seus indicadores de
validade. O passo 8, linhas 287–322, exige que o mesmo aluno tenha ambas as
proficiências válidas, usa no mínimo cinco alunos para a média e três com INSE.
O passo 9 também exige ambas as proficiências e posteriormente remove escolas
com ausências nos preditores selecionados.

Isso explica por que não se deve apresentar 2.338 como tamanho de todos os
modelos. A base do passo 8 consultada tem 2.326 escolas; a amostra formada pelos
filtros atuais da mediação tem 2.328. A contagem final de cada ajuste deve ser
registrada no momento da estimação.

O passo 6 também calcula médias diretamente dos registros das duas escolas,
sem manter os indicadores de validade na seleção. Ele deve compartilhar as
mesmas regras de notas e INSE, inclusive no modo de entrada por XLSX.

**Melhoria:** definir uma base escolar comum e regras de elegibilidade por
análise, sem impor artificialmente o mesmo denominador a perguntas diferentes.
Exportar um fluxo de inclusões/exclusões e `N` por variável e modelo.
Comparações entre modelos devem explicitar quando utilizam escolas diferentes.

O CSV local já está em MG/2023, mas os leitores ativos não verificam esse
contrato. O arquivo contém as séries 12 e 13; o escopo não deve ser descrito
apenas como “3ª série” sem explicar a abrangência 3ª/4ª do arquivo de origem.

### 6. A regra de outputs ainda não é cumprida nos módulos 1 e 2

**Prioridade: P1 · Sobrescritas confirmadas no código.**

O passo 1 salva dados por escola usando um helper legado, mas grava
`resumo_missings.csv` com nome fixo. O passo 2 grava os resultados por escola
e os consolidados também com nomes fixos, linhas 508–549. Seu modo atual
é `"todas"`, linha 92.

**Melhoria:** migrar produtores e leitores dos dois módulos em conjunto,
incluindo o dashboard e auxiliares, para o padrão datado de `AGENTS.md`.
Não mover apenas os arquivos: os leitores atuais esperam pastas por escola.
Verificar que duas execuções sucessivas preservam os dois conjuntos de resultados.

### 7. “Arquivo mais recente” não garante uma execução coerente

**Prioridade: P1 · Limitação de rastreabilidade.**

[utils_saeb.r](utils_saeb.r), linhas 63–105, reúne candidatos datados e legados
e escolhe o maior `mtime`. Uma cópia ou restauração pode fazer um arquivo
antigo parecer recente. A implementação também não impõe a precedência das
pastas datadas sobre o legado descrita nas convenções.

O executor não registra um manifesto de execução nem fixa os caminhos de
entrada de cada consumidor. Timestamps por arquivo evitam várias colisões,
mas não vinculam todas as saídas à mesma versão dos dados e do código.

**Melhoria:** criar um identificador por execução e um manifesto com caminhos
exatos, hash da entrada, revisão Git, parâmetros, horários, versões dos pacotes,
status das etapas e contagens. Consumir caminhos explícitos do manifesto;
reservar a busca do “mais recente” para exploração manual.

## Melhorias metodológicas e de manutenção

### Precisar a interpretação dos resultados

A agregação escolar permite estudar diferenças entre escolas; não transfere
automaticamente as associações para estudantes individuais. Manter essa distinção
nos gráficos e na redação.

O bootstrap da mediação quantifica incerteza sob o modelo, mas não estabelece
por si só identificação causal. Explicitar temporalidade, confundidores e
pressupostos; considerar sensibilidade quando apropriado, conforme o
[artigo do pacote mediation](https://www.jstatsoft.org/article/view/v059i05).

A sensibilidade existente compara OLS com WLS por `N_ALUNOS_MT` e usa HC3.
Esse número é a contagem do subconjunto com ambas as notas válidas, também
usada no ajuste de LP. Ele não equivale aos pesos amostrais oficiais presentes
no CSV. Definir se o alvo é a escola média da amostra ou uma população
representada pelo desenho do SAEB antes de escolher ponderação.

Os passos 8 e 9 calculam RMSE nos próprios dados de ajuste. Descrever essa
medida como ajuste na amostra. Se o TCC fizer afirmações de previsão fora da
amostra, será necessária validação apropriada, mesmo sem reintroduzir um módulo
amplo de aprendizado de máquina.

### Documentar a seleção dos dendrogramas e dos itens

[dendrogramas_artigo.r](../3_ANALISE_DE_GRUPOS/Scripts/dendrogramas_artigo.r)
define duas classes de agrupamento e até 20 escolas extremas por grupo.
A figura serve a uma apresentação selecionada; não representa automaticamente
a estrutura de todas as escolas. Exportar os IDs selecionados, o critério de
seleção e os parâmetros. Se houver interpretação substantiva dos clusters,
avaliar a estabilidade de escalonamento, seleção e número de grupos.

No passo 9, os gráficos temáticos exibem apenas coeficientes com `p < 0,05`,
após filtragem por variância, ausências e VIF. Manter a tabela completa como
referência, registrar as perdas e tratar essa seleção como exploratória.
Não confundir o tamanho dos coeficientes de proporções com o do INSE
padronizado: uma variação de 0,10 em proporção representa dez pontos percentuais.

### Reduzir duplicação e fixar o ambiente

Há redefinições locais de `tema_saeb()` após carregar os helpers, por exemplo
na regressão principal e nas bases de dendrogramas. Elas impedem que uma mudança
no tema central se propague de maneira uniforme. Separar variantes de tema
explicitamente, sem redefinir o mesmo nome.

Extrair a agregação escolar e a preparação de variáveis em funções compartilhadas.
A pequena função local de detecção da raiz continua necessária antes do
`source()`; a prioridade de extração é a lógica analítica repetida.

Adotar `renv.lock` após estabilizar o ambiente: `snapshot()` registra versões e
`restore()` permite reinstalá-las. A verificação de pacotes atual só confirma
presença. Consultar a [documentação oficial do renv](https://pkgs.rstudio.com/renv/articles/renv.html).
Como o executor usa `--vanilla`, uma adoção de renv precisa ativar explicitamente
o ambiente nos subprocessos; a ativação pela `.Rprofile` não será suficiente.

O executor atual atende ao tamanho do projeto. Primeiro acrescentar contratos,
manifesto e parâmetros; uma troca de ferramenta de orquestração pode ser avaliada
se o custo de reexecução passar a justificar essa migração.

### Consolidar as fontes de verdade

`metodologia.md` e `README_METODOLOGICO.md` repetem justificativas e contêm
afirmações que precisam de revisão: síntese do INSE pelos “72 itens”, impossibilidade
de OLS só pelo número de preditores, equivalência entre rank-biserial e Cohen's d,
e identificação de convergência do bootstrap por um intervalo excluir zero.

Conferir a composição do INSE com a documentação da edição utilizada,
disponível no [INEP](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/indicadores-educacionais/nivel-socioeconomico).
O número de colunas do questionário, isoladamente, não demonstra quais itens
integram o indicador.

Usar `metodologia.md` como fonte principal e transformar o outro guia em um índice
ou complemento com escopo distinto. Atualizar também o guia operacional, que
ainda mostra o fluxo como uma sequência e saídas antigas para os módulos 4–6.
`requisitos.md` declara R >= 4.0, embora os scripts usem `|>`; alinhar os requisitos
ao ambiente efetivamente suportado.

Para organização futura, separar helpers e validações de textos é útil. Fazer
essa mudança de forma incremental, atualizando todos os `source()` e o executor.
Padronizar também `Scripts/` no módulo 1 e o uso do pipe nativo quando esses
arquivos forem refatorados.

## Plano de melhorias

P0 deve preceder a interpretação final. P1 melhora a consistência e a
reprodutibilidade; P2 simplifica manutenção e apresentação.

| Ordem | Prioridade | Entrega | Critério de aceite |
|:-----:|:----------:|---------|--------------------|
| 1 | P0 | Corrigir faixas e grupos de ausentes | Nenhum valor ausente recebe faixa válida; metadados e consumidores regenerados |
| 2 | P0 | Corrigir contrastes da mediação | Cada comparação contém somente os grupos declarados ou usa contraste categórico documentado |
| 3 | P1 | Revisar as colunas e notas do passo 2 | Ordinais, dummies e contínuas esperadas entram; notas inválidas ficam fora; sem coerções indevidas |
| 4 | P1 | Unificar domínios e relatório de ausências | Cada item segue o dicionário; códigos inválidos entram no relatório correto |
| 5 | P1 | Centralizar a base escolar e a elegibilidade | Fluxo de exclusões e denominadores por análise exportados e conferidos |
| 6 | P1 | Migrar outputs dos módulos 1 e 2 | Produtores e leitores funcionam no layout datado; nenhuma sobrescrita em execuções sucessivas |
| 7 | P1 | Acrescentar manifesto e ambiente reproduzível | Entradas exatas, hash, revisão, parâmetros e versões recuperáveis em uma nova execução |
| 8 | P1 | Ampliar validação com dados sintéticos pequenos | Detecta classificações de ausentes, referência incorreta, categorias sem variação e recorte inadequado |
| 9 | P2 | Consolidar metodologia e guias | Uma fonte para cada decisão; comandos, saídas e requisitos coerentes |
| 10 | P2 | Organizar helpers e geração de figuras | Menos duplicação; IDs e critérios de figuras selecionadas exportados |

Os testes adicionais devem cobrir os problemas analíticos identificados, sem
depender dos microdados completos. Uma integração contínua pode executar o parse
e esses casos sintéticos; uma validação dos dados reais deve ser explicitamente
separada e não anunciar sucesso completo quando os dados estiverem ausentes.

</details>
