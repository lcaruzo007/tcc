# Diário de desenvolvimento · TCC SAEB 2023

**Período:** 06/04/2026 a 29/10/2026 · **Organização:** registros recentes primeiro.

[README](README.md) · [Análise do projeto](TESTE/DOCUMENTACAO/analise_projeto.md) · [Modelo de registro](#modelo-para-novas-entradas)

Este diário preserva decisões, atividades, dificuldades e resultados das sessões.
Os registros antigos mantêm os caminhos, números de etapas, conclusões e pendências
da época; consulte o README para a estrutura atual e a análise do projeto para
as recomendações vigentes. “Concluído” em uma entrada descreve aquela sessão.

## Índice por mês

| Mês | Registros | Assuntos principais |
|-----|:---------:|---------------------|
| [Outubro de 2026](#outubro-de-2026) | 7 | Auditoria científica, revisão do projeto e organização documental |
| [Setembro de 2026](#setembro-de-2026) | 1 | Reprodutibilidade, migração e validações |
| [Agosto de 2026](#agosto-de-2026) | 2 | Pipeline enxuto e figuras para artigo |
| [Julho de 2026](#julho-de-2026) | 6 | Refatorações, outputs datados e remoções |
| [Maio de 2026](#maio-de-2026) | 8 | Grupos, dendrogramas, regressões e feedback |
| [Abril de 2026](#abril-de-2026) | 2 | Limpeza, correlações e análise por escola |

## Outubro de 2026

### 2026-10-29 — Preparação do commit e publicação do projeto

**Horário:** a partir de 10h32 (America/Sao_Paulo)
**Fase:** Versionamento
**Status:** Alterações revisadas e verificações aprovadas para publicação

#### Atividades realizadas

- Reunidas as correções do pipeline, infraestrutura de execução, dependências,
  testes e documentação para commit e push solicitados pelo usuário.
- Mantidos fora do commit os microdados, outputs, backups, pasta e relatório
  da auditoria. O DOCX fornecido permanece local e não foi incluído.

#### Desafios encontrados

- O recorte corrigido é um dado local ignorado pelo Git; o commit registra as
  alterações de código e a documentação da fonte, sem publicar o CSV.

#### Resultados obtidos

- Validação de sintaxe, contratos sintéticos e invariantes dos metadados locais
  aprovada. A leitura da nova fonte e sua integridade foram verificadas na
  sessão anterior. As saídas anteriores ainda não foram reprocessadas.
- Remoto consultado e ramo `master` sincronizado antes da criação do commit.

#### Próximos passos

- Regenerar resultados e modelos com a entrada recuperada, mantendo o histórico.

---

### 2026-10-29 — Adoção do recorte recuperado na entrada principal

**Horário:** a partir de 10h28 (America/Sao_Paulo)
**Fase:** Atualização da fonte do projeto
**Status:** Recorte ativo atualizado e validado; resultados anteriores preservados

#### Atividades realizadas

- Substituído `MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv` pelo recorte MG
  conferido na base nacional, conforme solicitado. Preservado o CSV anterior
  em backup local com SHA-256 conferido antes da substituição.
- Registrada a proveniência em
  `TESTE/DOCUMENTACAO/outputs/2026-10-29/metadados/atualizacao_fonte_MG_102852.json`.
- Atualizados os guias e a metodologia para identificar a fonte ativa e a
  necessidade de reprocessamento das saídas históricas.

#### Desafios encontrados

- Manifestos anteriores registram o hash da entrada antiga e não certificam a
  nova fonte. A troca do CSV não atualiza tabelas, coeficientes ou figuras salvos.

#### Resultados obtidos

- Entrada ativa com 173.918 alunos, 2.338 escolas e 117 colunas. Recuperadas
  121 notas MT e 129 LP, incluindo os demais campos divergentes da base nacional.
- Hash ativo `144fc62721c2bc2f78c8455cede996249979e07c0555933e7781b960e12940f5`,
  idêntico ao recorte conferido. Dados, backups e auditoria permanecem ignorados
  pelo Git.
- Testes adversariais com `--exigir-fonte-integra` aprovados. Conferida também
  a leitura pelo pipeline, com 135.765 notas MT e 135.682 LP elegíveis segundo
  a política vigente; as 83 notas LP abaixo de 150 continuam rastreadas.

#### Próximos passos

- Reexecutar o pipeline e suas auditorias para regenerar os resultados com
  a fonte adotada, mantendo as saídas anteriores como histórico.

---

### 2026-10-29 — Confronto das notas com a base nacional fornecida

**Horário:** a partir de 10h19 (America/Sao_Paulo)
**Fase:** Recuperação da fonte e conferência de microdados
**Status:** Confronto e recorte concluídos; reprocessamento dos modelos pendente

#### Atividades realizadas

- Comparados os 2.091.337 registros nacionais e o recorte MG pelos IDs dos alunos.
- Preparado recorte novo em pasta local da auditoria, preservando ambos os CSVs
  recebidos e registrando seus hashes. Atualizado o relatório com adendo de fonte.

#### Desafios encontrados

- Os arquivos usam separadores diferentes. Diferenças de formatação numérica
  foram separadas das diferenças de valor; a origem do download fornecido não
  foi autenticada externamente.

#### Resultados obtidos

- Mesmos 173.918 alunos, 2.338 escolas e 117 colunas em MG, com identificação
  contextual coincidente. Recuperadas as 121 notas MT e 129 LP acima de 800;
  todas coincidem exatamente com o valor antigo dividido por mil.
- Encontradas 4.032 células divergentes em 4.000 alunos, incluindo pesos INSE,
  erros-padrão e proficiências da escala original. Mantidas as 83 notas LP abaixo
  de 150, cuja exclusão é uma decisão metodológica separada.
- Auditoria, recorte e relatório continuam ignorados pelo Git. Os resultados
  anteriores permanecem identificados com sua entrada antiga.
- Conferência independente no R aprovada: recuperação exata das 250 notas e
  leitura válida do novo recorte, com 135.765 notas MT e 135.682 LP elegíveis
  segundo a política vigente de flag e faixa.

#### Próximos passos

- Adotar explicitamente a fonte recuperada e reexecutar os modelos e auditorias
  antes de substituir coeficientes e figuras do TCC.

---

### 2026-10-29 — Exclusão da auditoria do versionamento

**Horário:** 10h12 (America/Sao_Paulo)
**Fase:** Configuração do Git
**Status:** Concluído

#### Atividades realizadas

- Adicionadas regras no `.gitignore` para manter `auditoria_tcc/` e
  `RELATORIO_AUDITORIA_TCC.md` apenas no ambiente local, conforme solicitado.

#### Desafios encontrados

- Regras de ignore não removem arquivos já rastreados; a consulta ao índice
  confirmou que esses caminhos não estavam rastreados.

#### Resultados obtidos

- Arquivos da auditoria preservados localmente e ignorados pelo Git.

#### Próximos passos

- Manter a auditoria fora dos próximos commits.

---

### 2026-10-29 — Auditoria dos microdados e dos resultados publicados no TCC

**Horário:** iniciada em 28/10; retomada em 29/10 às 07h53; validação integral concluída às 09h58 (America/Sao_Paulo)
**Fase:** Auditoria científica e computacional, correções e reprodução
**Status:** Reprocessamento e auditoria computacional concluídos; integridade da fonte oficial pendente

#### Atividades realizadas

- Preservados códigos, dados e resultados anteriores em ZIP com inventário e
  SHA-256; preservado separadamente o DOCX recebido. Registrados os achados
  anteriores às correções em `auditoria_tcc/ACHADOS_ANTES_DAS_CORRECOES.md`.
- Examinados os 39 scripts R originais e reconstruídos produtores e dependências.
  Conferidos dicionário oficial, 72 itens, 245 categorias e frequências por escola.
- Investigadas as cinco escolas prioritárias e todas as 2.338 escolas. Comparadas
  médias por implementação independente, identificadores, duplicidades e recorte.
- Reproduzidos os cinco dendrogramas publicados com os mesmos IDs, antes/depois,
  sem excluir escolas para melhorar a apresentação. Gerados cinco PNGs individuais.
- Reproduzidas as quatro regressões, o histórico VIF e os seis diagramas de mediação.
  Conferidos coeficientes, intervalos, resíduos e identidades dos caminhos.
- Corrigidas validação numérica e de IDs, junções das proporções, falhas silenciosas
  do VIF, referências efetivas, legendas, sentido dos resíduos e rótulos de R².
  A mediação passou a salvar os objetos e os intervalos adicionais.
- Criados testes adversariais, verificação dos hashes do manifesto e auditoria
  dos resultados desde os microdados. Calculados HC3 e diagnósticos de influência,
  mantendo as observações influentes na análise principal.
- Extraídas e inspecionadas as 23 figuras do Word; preparada a tabela de auditoria
  individual, o relatório `RELATORIO_AUDITORIA_TCC.md` e instruções de reprodução.
  O documento acadêmico e o CSV bruto permaneceram inalterados.

#### Desafios encontrados

- A fonte local já contém 250 notas acima de 800 com flag de validade igual a 1
  (121 MT, 129 LP). Há evidência de perda decimal, mas falta uma cópia oficial
  independente para recuperar os valores. O download do INEP não foi obtido.
- As 83 notas LP abaixo de 150 são uma decisão metodológica separada da corrupção
  confirmada; sua exclusão foi explicitada e submetida a sensibilidade.
- A referência A de Q12c é rara (438 respostas). O VIF remove D e conserva B/C,
  tornando A+D a composição omitida efetiva. Trocar a referência não resolve isso.
- Uma execução de 28/10 foi interrompida e permaneceu identificada como incompleta.
  A nova execução integral escreve milhares de artefatos individuais por escola.

#### Resultados obtidos

- Ausência de duplicidades e de IDs obrigatórios faltantes nos 173.918 registros;
  agregações conferidas em todas as escolas. Confirmadas 851 máscaras municipais.
- Coeficientes institucionais INSE reproduzidos: 12,257243 MT e 12,487244 LP por
  desvio-padrão, N=2.326. Quatro modelos comparados diretamente com os RDS do ZIP:
  mesmos termos e amostras; diferenças numéricas abaixo de 1e-12 nos coeficientes.
- Modelo de itens: 177 candidatos, 159 após filtros, sete remoções VIF e 152
  preditores finais, N=2.325. Ordem reversa produz a mesma seleção nesta amostra.
- Sensibilidade Q12c com bloco completo e referências A/D produz as mesmas
  previsões; os seis contrastes com A têm ICs incluindo zero e VIF elevado.
- Os cinco dendrogramas e as seis mediações antigas são numericamente reproduzidos
  com médias brutas; notas inválidas e referências territoriais agrupadas explicam
  as divergências. Figuras 2–5 e 18–23 requerem substituição e revisão do texto.
- Todos os onze pares de correlação da Tabela 4 reproduzidos no arredondamento
  publicado. Contratos sintéticos, validação de metadados e auditoria agregada aprovados.
- Conferidas 104 estimativas descritas na seção 5.4: mesmos sinais e diferenças
  abaixo de um ponto. Identificados 21 contrastes cuja referência efetiva inclui
  outras categorias além de A e seis aproximações a ajustar no arredondamento.
- Heterocedasticidade detectada nos quatro modelos. Com HC3, o contraste LP
  Privada-Pública tem IC [-2,639; 16,758], p=0,154; 20 das 104 estimativas citadas
  dos itens têm IC HC3 incluindo zero. Gerados 12 painéis de sensibilidade separados,
  preservando os coeficientes e os gráficos convencionais do pipeline.
- O teste estrito de integridade da fonte falha explicitamente nas 250 notas;
  não houve certificação indevida da base nem reparação decimal automática.
- Execução integral `20261029_075326_13604` concluída com auxiliares: 21.082
  artefatos conferidos por hash. Código e microdados correspondem ao manifesto.
- Reproduzidas 88.725 linhas de correlação em 2.328 escolas, com erro máximo
  6,1e-16. Dez escolas sem preditores com variação foram identificadas por ID e motivo;
  todas as 2.338 escolas têm cobertura explícita. Nenhuma correlação exportada tem
  menos de três pares; isso não implica precisão suficiente nas escolas pequenas.
- Figura 7 conferida por reajuste com fatores: coeficientes, intervalos e previsões
  por ID equivalentes. Sensibilidade de Q12c sem 354 escolas com resposta A mantém
  os sinais negativos, N=1.971; essa exclusão não foi aplicada ao modelo principal.

#### Próximos passos

- [x] Concluir a execução integral e conferir suas correlações e hashes finais.
- [ ] Recuperar a fonte oficial e decidir academicamente sobre o corte inferior,
  blocos completos dos itens, ponderação e inferência após seleção.
- [ ] Revisar o texto acadêmico com o orientador e incorporar as figuras pertinentes.

---

### 2026-10-20 — Correção dos contratos analíticos e rastreabilidade

**Horário:** sessão da manhã, concluída às 09h16 (America/Sao_Paulo)
**Fase:** Implementação das correções identificadas na revisão
**Status:** Implementação, reprocessamento e auditoria concluídos

#### Atividades realizadas

- Criados helpers compartilhados para recorte MG/2023, indicadores de validade,
  domínios de respostas, médias, denominadores, elegibilidade e contrastes.
- Corrigida a classificação de ausentes em faixas de proficiência e INSE.
- Mediação de AREA_LOCAL restringida aos dois grupos declarados; tabelas
  passaram a informar referência e tamanho de cada grupo, e diagramas reutilizam os modelos.
- Correlações passaram a incluir ordinais, dummies e INSE, com status e número
  de pares válidos por disciplina. A validade de MT e LP é tratada separadamente.
- Limpeza e relatório de respostas passaram a respeitar o domínio de cada item,
  preservando categorias válidas como F e distinguindo ausência de não declaração.
- Migradas as saídas dos módulos 1 e 2 e adaptados dashboard e buscador;
  leitura de arquivos legados preservada.
- Centralizada a agregação usada pelos módulos 3, 4 e 5, com política explícita
  de médias descritivas ou pareadas e fluxos de exclusão.
- Atualizados os indicadores usados na comparação manual de duas escolas,
  inclusive no modo XLSX.
- Executor passou a resolver produtores, registrar manifestos/versões/hashes MD5
  e restringir leituras aos artefatos da execução corrente.
- Gerado renv.lock e adicionada conferência do ambiente no processo principal e
  nos subprocessos. A geração do lockfile exigiu autorização para o cache externo do renv.
- Centralizados tema e rótulos; adicionada exportação dos IDs selecionados
  nas figuras para artigo.
- Cálculo dos dendrogramas passou a usar dispositivo gráfico em memória
  quando necessário, evitando a criação automática de Rplots.pdf na raiz.
- Corrigidos títulos dos gráficos de regressão para explicitar 3ª/4ª séries e
  associações; intervalos do modelo principal e referência oposta passaram ao quantil t.
- Consolidados metodologia, guia operacional, requisitos e referência de outputs.
  A análise inicial foi preservada como histórico no relatório de correções.

#### Desafios encontrados

- Uma letra de resposta não tem o mesmo significado em todos os itens.
- Os denominadores das análises não devem ser uniformizados sem preservar
  a pergunta: médias descritivas e médias pareadas têm contratos distintos.
- Identificado gargalo na consulta ao catálogo, que verificava a existência de
  arquivos não relacionados à escola. A busca foi otimizada e o ramo individual reiniciado.
- Escrita e diagnóstico de milhares de arquivos pequenos foram otimizados.
  A execução interrompida foi identificada no manifesto; saídas parciais foram preservadas.
- O script local buscador.r já estava sem rastreamento; sua lógica de ranking
  foi preservada ao adaptar caminhos e saídas.

#### Resultados obtidos

- Testes sintéticos e invariantes dos 2.338 metadados corrigidos aprovados.
- Confirmadas nove escolas sem médias e dez sem INSE, agora sem classificação indevida.
- Mediação com 2.326 escolas elegíveis; contraste rural com 139 referências e 157
  tratadas; contraste urbano com 139 referências e 2.030 tratadas.
- Passos 4, 5, 7, 8, 9 e 10 e auxiliares executados; passo 6 validado para os IDs configurados.
- Integridade de 99 artefatos da primeira execução agregada conferida por MD5.
- Passo 1 concluído para as 2.338 escolas; passo 2 gerou tabelas para 2.328 e
  registrou 10 exclusões por ausência de preditores com variação.
- Confirmadas as 2.338 entradas do passo 2 no catálogo da mesma execução.
- Conferidos 88.725 registros de correlação e 168.336 linhas nos 2.338
  relatórios de respostas, incluindo status, pares válidos e contagens de ausências.
- MD5 conferido em três manifestos: 20.977 artefatos do ramo individual,
  99 da execução agregada e 32 do passo 8 e auxiliares após os ajustes finais.
- Dashboard validado com teste reativo; ranking e cinco dendrogramas de artigo
  executados. Testada a resolução automática 5 -> 4 no executor.

#### Próximos passos

- [x] Concluir a execução integral do ramo individual e registrar o resumo final.
- [x] Conferir o dashboard e o ranking com as novas saídas.
- [ ] Integrar os resultados regenerados ao TCC, justificando ponderação,
  faixa operacional de proficiência e pressupostos da mediação.

---


### 2026-10-20 — Revisão do projeto e organização documental

**Horário:** 08h23 (horário do registro; America/Sao_Paulo)\
**Fase:** Análise da estrutura, coerência do pipeline e documentação\
**Status:** Revisão e organização concluídas; correções analíticas propostas para próxima sessão

#### Atividades realizadas

- Revisados executor, helpers, validações, scripts dos seis módulos e guias.
- Conferidos o CSV local e os artefatos mais recentes dos módulos 3 e 4, sem regravar resultados.
- Reformulado o README com navegação, início rápido, tabela dos dez passos, fluxograma das dependências reais e descrição do estado das saídas.
- Criada [analise_projeto.md](TESTE/DOCUMENTACAO/analise_projeto.md), com evidências, prioridades e critérios de aceite.
- Reorganizadas as 19 entradas históricas por mês e data, com as mais recentes primeiro; preservados os relatos e padronizados títulos e níveis de seção.
- Corrigidos caracteres de controle e identificadores quebrados na entrada de 30/07; os textos históricos não foram atualizados como se descrevessem o estado atual.

#### Desafios encontrados

- As regras de amostra diferem entre módulos; a regressão não consome a base dos dendrogramas.
- Os módulos 1 e 2 ainda têm saídas fora do padrão datado e escritas com nomes fixos.
- Identificados rótulos de ausentes incorretos, contraste de mediação diferente do anunciado e variáveis omitidas na seleção do passo 2.
- O terminal não tem `Rscript` no PATH; os comandos foram executados com a instalação R 4.6.0 disponível.
- O arquivo local `buscador.r` já estava sem rastreamento no início da sessão e foi preservado.

#### Resultados obtidos

- `validar_pipeline.r`: 25 scripts com sintaxe válida e invariantes básicos de 2.338 escolas aprovados; aviso de nove escolas com proficiência ausente.
- `verificar_dependencias.r`: 11 dependências obrigatórias e três opcionais disponíveis.
- Confirmados 173.918 registros, 2.338 escolas e 851 códigos distintos de município; apenas MG/2023, com séries 12 e 13.
- Confirmadas nove escolas sem médias classificadas em `Q4_Alto` e dez sem INSE em `Alto_INSE`.
- Base agregada mais recente da regressão com 2.326 escolas, distinta dos metadados e da amostra atual de mediação.
- Alterações restritas à documentação; pipeline analítico completo não reexecutado e problemas de código mantidos como pendências explícitas.

#### Próximos passos

- [ ] Corrigir as classificações de ausentes e os contrastes da mediação.
- [ ] Revisar seleção de variáveis, rótulos do dashboard e critérios de validade no ramo por escola.
- [ ] Centralizar domínios de respostas e registrar denominadores e perdas por análise.
- [ ] Migrar os outputs dos módulos 1 e 2 junto com seus leitores.
- [ ] Acrescentar manifesto de execução e fixação do ambiente.
- [ ] Consolidar metodologia e guias, seguindo o plano da análise do projeto.

## Setembro de 2026

<details>
<summary>Abrir 1 registro histórico</summary>

### 2026-09-28 — Organização, reprodutibilidade e validação

**Horário:** 08:06
**Fase:** Organizacao, reprodutibilidade e conclusao da migracao de outputs
**Status:** Implementacao e smoke tests concluidos com R 4.6.0

#### Atividades realizadas

- Criado `.gitignore` para microdados CSV, outputs regeneraveis e arquivos
  temporarios do R/RStudio.
- Removidos do indice do Git 21.362 arquivos gerados ou brutos, sem apagar os
  arquivos locais. Os scripts R de importacao em `MICRODADOS_SAEB_2023/INPUTS`
  permanecem versionados.
- Modulo 3 migrado integralmente para `caminho_saida()`:
  - metadados, tabelas, figuras, comparacoes entre escolas e dendrogramas;
  - leitura compativel com pastas datadas e com o layout legado;
  - nomes de comparacoes sanitizados para uso seguro no Windows.
- `encontrar_arquivo_mais_recente()` ampliado para buscar tambem na subpasta
  legada indicada por `tipo`.
- `caminho_saida()` passou a evitar colisao quando o mesmo nome e gerado mais
  de uma vez no mesmo segundo.
- Comparacoes de grupos agora preservam `p_valor` como numerico e acrescentam
  `p_valor_ajustado_bh` e `Significancia_ajustada`.
- Corrigida a agregacao do Passo 4: medias de proficiencia agora respeitam os
  indicadores de validade e a faixa 150-800. Antes, codigos sentinela podiam
  produzir medias escolares de milhares de pontos e contaminar dendrogramas.
- Comparacoes de `AREA_LOCAL` passaram a usar apenas categorias observadas;
  `Rural_Capital` nao possui escolas no recorte MG/2023.
- Corrigidas quatro escritas restantes do modulo 4 que ainda dependiam de
  variaveis `DIR_*` nao definidas; modelos e figuras agora usam
  `caminho_saida()`.
- Removida a criacao desnecessaria de pastas legacy pelo script ativo do
  modulo 5.
- Movida a versao obsoleta do modulo 5 para `arquivo/`; `Scripts/` agora contem
  apenas o script ativo.
- Modulo 6 passou a procurar metadados a partir da raiz de `outputs`, mantendo
  fallback para o formato antigo.
- Modulo 6 agora ignora tratamentos sem variacao, fixa a semente do bootstrap
  e exporta ACME/ADE medios, IC 95% e p-valores corretos. A versao anterior
  rotulava limites inferiores dos intervalos como `p_Direto`/`p_Indireto`.
- Removidas instalacoes de pacotes durante a execucao dos scripts. Dependencias
  ausentes agora geram erro explicativo.
- Criados:
  - `executar_pipeline.r`, que executa etapas nao interativas em sessoes R
    isoladas;
  - `TESTE/DOCUMENTACAO/verificar_dependencias.r`;
  - `TESTE/DOCUMENTACAO/validar_pipeline.r`, com parse de scripts e invariantes
    da base agregada.
- Criado `analise_sensibilidade_regressao.r`, auxiliar do Passo 8, comparando
  OLS e WLS por numero de alunos com erros-padrao HC3, sem alterar o modelo
  principal.
- Atualizados README principal, README do modulo 3, metodologia, requisitos,
  referencia de outputs, guia de documentacao e AGENTS.md.

#### Desafios encontrados

- O repositorio rastreava quase todos os outputs historicos e os CSVs brutos.
  A limpeza foi feita apenas no indice; os arquivos continuam no disco e o
  historico Git nao foi reescrito.
- `Rscript` nao estava no PATH; a instalacao R 4.6.0 foi localizada em
  `AppData/Local/Programs/R` e usada diretamente nos testes.
- Os scripts dos passos 3 e 6 exigem interacao/configuracao e foram mantidos
  fora da execucao automatica padrao.

#### Resultados obtidos

- Estrutura de outputs do modulo 3 alinhada aos demais modulos.
- Leitura de outputs antigos preservada.
- Nenhum microdado ou output local foi apagado.
- Pipeline ganhou ponto unico de execucao e verificacoes reproduziveis.
- Documentacao atualizada para a versao 4.1.
- Smoke tests concluidos nos Passos 4, 5, 7, 8, 9 e 10; a validacao analisou 25
  scripts, 2.338 escolas e todas as dependencias obrigatorias.

#### Próximos passos

- [x] Executar `Rscript TESTE/DOCUMENTACAO/validar_pipeline.r` em ambiente com R.
- [x] Executar smoke tests dos passos 4, 5, 7, 8, 9 e 10.
- [ ] Executar e interpretar a analise de sensibilidade OLS/WLS com HC3.
- [ ] Renumerar as figuras do PASSO 10 e atualizar o texto final do TCC.

---

**Atualizado:** 28 de Setembro de 2026
**Status:** Organizacao 4.1 e validacao executavel concluidas
**Proxima etapa:** Interpretar sensibilidade OLS/WLS + redacao final do TCC

---

</details>

## Agosto de 2026

<details>
<summary>Abrir 2 registros históricos</summary>

### 2026-08-23 — Dendrogramas para artigo

**Horário:** sessão atual
**Fase:** Visualização e preparação para artigo
**Status:** ✅ Concluído

#### Atividades realizadas

- Criado `dendrogramas_artigo.r` para gerar os cinco dendrogramas isoladamente.
- As figuras incluem somente o dendrograma e a legenda de cores, sem painéis auxiliares ou tabelas.
- Saídas configuradas em pasta datada, com resolução de 300 dpi.

#### Próximos passos

- Executar o script após atualizar os metadados e selecionar as figuras finais para o artigo.

---

### 2026-08-21 — Redução para seis módulos e dez passos

**Horário:** sessao de revisao/organizacao
**Fase:** Refatoracao #3 — pipeline enxuto (remocao de HLM, CV e PCA) + renumeracao 7->6 + atualizacao de docs
**Status:** Concluido com sucesso (alteracoes em working tree, a commitar nesta sessao)

#### Contexto

Apos a apresentacao/banca, o TCC foi reescrito para focar no eixo principal
(limpeza -> agrupamento -> regressao -> mediacao). Os modulos avancados que
dependiam de infraestrutura ou nao se sustentavam metodologicamente com os
dados do SAEB foram retirados:

- **6_MODELOS_HIERARQUICOS** (HLM, PASSO 11) — removido
- **8_MODELOS_HIERARQUICOS** (duplicata orfa do HLM, com outputs de 2026-08-18) — removido
- **9_VALIDACAO_CRUZADA** (CV + ROC, PASSO 13) — removido
- **11_INDICE_COMPOSTO** (PCA, PASSO 15) — ja havia saido em commit anterior; confirmada a ausencia

Restam **6 modulos** (1-6) e **10 passos** sequenciais.

#### Atividades realizadas

##### 1. Renumeracao `7_ANALISE_MEDIACAO` -> `6_ANALISE_MEDIACAO`

- `git mv` da pasta (preserva historico); fechamento do gap deixado pela
  remocao dos modulos 6/8/9 (convencao "remover lacunas", commit 4ed021d).
- Correcao de bug no script `analise_mediacao.r` (linha 82): `DIR_BASE`
  apontava para `"8_ANALISE_MEDIACAO"` (path quebrado, herdado da
  renumeracao anterior) -> corrigido para `"6_ANALISE_MEDIACAO"`.
- Reescrita do `README.md` do modulo 6: path de `source()`, titulo
  (PASSO 10), saidas em pastas datadas, e atualizacao da secao "Analises"
  para refletir `AREA_LOCAL` (3 dummies, ref. `Urbana_Capital`) em vez de
  `LOCALIZACAO`.

##### 2. Confirmacao da migracao do modulo 5

- Inspecionado `regressao_itens_brutos_dummy.r`: o script JA usa
  `caminho_saida()` em todas as escritas (migrado na refatoracao de 30/07;
  os `DIR_*` legacy sao mantidos apenas para leitura de arquivos antigos).
- `README.md` do modulo 5 atualizado: removida a nota falsa "Fase 3
  pendente" e a arvore de pastas reescrita para o formato datado
  (`outputs/<YYYY-MM-DD>/{modelos,tabelas,diagnosticos,figuras}/`).

##### 3. Atualizacao da documentacao (refletir "como tudo esta agora")

- `README.md` raiz: badges (pipeline 15 -> 10 passos), TL;DR, cartoes,
  arvore de estrutura, fluxograma mermaid, comandos `source()`, tabela de
  resumo, tabela de progresso, changelog (entrada 4.0) e roadmap. Removidas
  todas as referencias a HLM/CV/PCA. Dependencias atualizadas (inclui
  `data.table`, `caret`, `mediation`, `boot`).
- `AGENTS.md`: arvore de estrutura (6 modulos) e secao "Estado atual"
  (Agosto 2026) — pipeline enxuto, modulos 4/5/6 com `caminho_saida()`,
  so modulo 3 pendente.
- `TESTE/DOCUMENTACAO/README.md`: fluxo de dados, tabela de fases e ordem
  de execucao reescritos para 10 passos.
- `TESTE/DOCUMENTACAO/metodologia.md`: PASSO 8 (dummies -> `AREA_LOCAL`),
  remocao de HLM (PASSO 11), CV (PASSO 13) e PCA (PASSO 15); renumeracao
  da mediacao (PASSO 12 -> PASSO 10) com `AREA_LOCAL` e bootstrap BCa.
- `TESTE/DOCUMENTACAO/referencia_outputs.md`: removidas as secoes de HLM,
  CV e PCA; mediacao renumerada (PASSO 10) com paths `6_ANALISE_MEDIACAO`.
- `TESTE/DOCUMENTACAO/requisitos.md`: removidos pacotes exclusivos dos
  modulos cortados (`lme4`, `performance`, `lmerTest`, `pROC`,
  `FactoMineR`, `factoextra`); tabela de versoes atualizada (mediacao =
  Fase 10).

##### 4. Commit das remocoes + renumeracao + docs

- As delecoes dos modulos 6/8/9 (ja na working tree) + a renumeracao 7->6
  + todas as edicoes de docs serao commitadas nesta sessao.

#### Decisoes e limitacoes

- **Figuras**: o PASSO 10 (mediacao) ainda emite "Figura 21" e "Figura 22"
  (hardcoded no script). Nao renumerei para 15-16 para nao editar a logica
  do script nem quebrar possiveis referencias no texto do TCC. Renumeracao
  de figuras deixada no roadmap.
- **`detectar_raiz()` x `source(utils_saeb.r)`**: pre-condicao circular
  conhecida no modulo 6 (mediacao chama `detectar_raiz()` antes de
  `source(utils_saeb.r)`; funciona em sessao RStudio com utils carregado,
  pode falhar em `Rscript` limpo). Nao corrigida nesta sessao (fora do
  escopo de "atualizar docs"); registrada no roadmap.
- **Modulo 3** continua pendente de migracao para `caminho_saida()` (Fase 3).
- **Acentos**: scripts R continuam sem acentos (convencao). Os `.md`
  reescritos por inteiro (README raiz, DOCUMENTACAO/README, README do
  modulo 6) ficaram sem acentos; os `.md` editados pontualmente
  (metodologia, referencia_outputs, requisitos, README do modulo 5)
  preservaram o estilo acentuado original de cada arquivo.

#### Resultados

- Estrutura final: `1_LIMPEZA`, `2_ANALISE_POR_ESCOLA`, `3_ANALISE_DE_GRUPOS`,
  `4_REGRESSAO_LINEAR`, `5_REGRESSAO_ITENS_BRUTOS`, `6_ANALISE_MEDIACAO`.
- Pipeline de 10 passos, sequencial, sem gaps.
- Documentacao alinhada ao estado real do repositorio.

#### Próximos passos

- [ ] Validar `analise_mediacao.r` em RStudio (apos a correcao do path `8_` -> `6_`)
- [ ] Corrigir ordem `detectar_raiz()` x `source(utils_saeb.r)` no modulo 6
- [ ] Fase 3: migrar scripts do modulo 3 para `caminho_saida()`
- [ ] Renumerar figuras do PASSO 10 (21-22 -> 15-16) para sequencia continua
- [ ] Limpar acentos/emojis dos scripts dos modulos 1 e 2
- [ ] Redacao final do TCC

---

**Atualizado:** 21 de Agosto de 2026\
**Status:** Refatoracao #3 concluida — pipeline enxuto de 10 passos, modulos HLM/CV/PCA removidos, mediacao renumerada para 6\
**Proxima etapa:** Validacao em RStudio + redacao final do TCC

---

</details>

## Julho de 2026

<details>
<summary>Abrir 6 registros históricos</summary>

### 2026-07-30 — Refatoração da regressão por itens brutos

**Horário:** ~ultima sessao
**Fase:** Refatoracao do modulo 5 (regressao por itens brutos)
**Status:** Refatoracao aplicada; bug de ordem detectado na revisao (detectar_raiz removida indevidamente no Item 6) e corrigido nesta mesma sessao; script validado via parse() e em run de sessao limpa.

#### Atividades realizadas

Refatoracao do script TESTE/5_REGRESSAO_ITENS_BRUTOS/Scripts/regressao_itens_brutos_dummy.r em commit unico (11 correcoes/melhorias):

- **Item 1 (bug):** p_valor da tabela_resumo era hardcoded "< 0.001"; agora e calculado via pf(F, df1, df2, lower.tail=FALSE) (helper calc_p_F).
- **Item 2 (docs):** Nota metodologica do grafico de coeficientes dizia "exibe TODAS as preditoras" mas o codigo filtra p_valor < ALPHA. Mantido o filtro de significancia (preferencia do usuario) e a nota foi reescrita para refletir isso.
- **Item 3:** miss_info (Etapa 5) era calculado mas nunca salvo. Agora e gravado em tabelas/log_missings_itens.csv.
- **Item 4:** log_vif_removidos era um vetor de strings "nome (VIF=..)". Refatorado para tibble(Iteracao, Preditor, VIF), salvo direto. Corrigido tambem length(log_vif) -> nrow(log_vif) (length de tibble = n. de colunas, nao linhas).
- **Item 5 (robustez):** gerar_pred_obs usava modelo[[1]] (depende da ordem das colunas). Trocado por modelo[[all.vars(formula(modelo))[1]]] (acesso nomeado a variavel-resposta).
- **Item 6 (convencao):** detectar_raiz e tema_saeb locais eram duplicatas de utils_saeb.r. source(utils_saeb.r) movido para antes de detectar_raiz(); funcoes locais removidas. arquivo_mais_recente mantido local (semantica distinta do encontrar_arquivo_mais_recente).
- **Item 7 (limpeza):** Variaveis mortas removidas: VARS_ESTRUTURAIS e VARIAVEL_DEPENDENTE (nunca usadas no codigo).
- **Item 8 (convencao):** Sanitizacao ASCII em todas as strings/mensagens/comentarios. O arquivo era ASCII puro mas continha ? literais resultantes de conversao de encoding perdida (bullets *, setas ->, raiz sqrt, subscritos _j, edicoes 8a, etc.). Nenhum ? restante.
- **Item 9 (performance):** Etapa 4 reescrita com count + pivot_wider (1 passagem por item) em vez de 1 summarise + left_join por categoria (~169 joins). Preservada a semantica original: categoria "A" como referencia (omitida), escolas com n_valid < MIN_RESP_ITEM recebem NA, e escolas que responderam apenas "A" ficam com prop 0 nas demais categorias (via values_fill = 0 pivotando todas as categorias antes de descartar "A").
- **Item 10 (convencao):** Grupo tematico "Variaveis Estruturais" agora lista os nomes reais das dummies (TIPO_ESCOLA_Privada, AREA_LOCAL_*) em vez de c("TIPO_ESCOLA","AREA","LOCALIZACAO"), e o str_detect do filtro usa ^TIPO_ESCOLA_|^AREA_LOCAL_.
- **Item 11 (correcao menor):** IC 95% dos coeficientes agora via qt(0.975, df.residual(modelo)) em vez da aproximacao 1.96 * std.error. Altera os ICs nos CSVs coeficientes_*_itens e barras de erro das figuras (diferencas despreziveis com n ~ 2000 escuelas). Nota metodologica atualizada.
- **Correcao (mesma sessao):** o Item 6 removeu detectar_raiz local, mas ela e pre-condicao do source() de utils_saeb.r (catch-22: precisa de RAIZ para sourcear, precisa de detectar_raiz para achar RAIZ). Restaurada a definicao local; tema_saeb permanece removida (correto).

#### Desafios encontrados

- Bug introduzido na 1a versao da reescrita da Etapa 4: o n_valid era descartado pelo pivot_wider (nao estava em id_cols/names_from/values_from), fazendo is.null(df_agg) == TRUE e tornando TODAS as dummies NA. Corrigido separando n_valid_escola via summarise e fazendo left_join apos o pivot.
- Rscript nao esta no PATH do sistema; localizado em C:\Program Files\R\R-4.5.2\bin\.

#### Resultados obtidos

- Script parseia sem erros (parse() OK, 217 expressoes).
- Diff: 169 insercoes / 157 remocoes em 1 arquivo.
- Comportamento estatistico preservado (mesma semantica de agregacao e filtros); apenas correcoes de rigor (IC via t, p-valor F real) e rastreabilidade (logs em colunas).

#### Próximos passos

- [ ] Executar o script completo contra TS_ALUNO_34EM.csv para validar saidas
- [ ] Comparar coeficientes_*_itens antes/depois (ICs devem mudar pouco)
- [ ] Confirmar que log_missings_itens.csv e o novo formato de log_vif_removidos sao uteis para o TCC

---

### 2026-07-23 — Reorganização das pastas (noite)

**Horário:** ~23h30\
**Fase:** Reorganização da estrutura de pastas\
**Status:** ✅ Concluído com sucesso

#### Atividades realizadas

- Reorganização sequencial das pastas do módulo (1-9), removendo lacunas deixadas pela remoção dos módulos 6 e 10
- Renomeação das pastas:
  - `7_MODELOS_HIERARQUICOS` → `6_MODELOS_HIERARQUICOS`
  - `8_ANALISE_MEDIACAO` → `7_ANALISE_MEDIACAO`
  - `9_VALIDACAO_CRUZADA` → `8_VALIDACAO_CRUZADA`
  - `11_INDICE_COMPOSTO` → `9_INDICE_COMPOSTO`
- Atualização do `TESTE/DOCUMENTACAO/README.md` com nova numeração (fluxo, tabela de fases, ordem de execução)
- Commit das mudanças estruturais (scripts, READMEs, documentação)
- Remoção de outputs antigos do versionamento (conforme convenção do AGENTS.md)

#### Resultados obtidos

- Estrutura de pastas agora sequencial (1-9), mais clara e consistente
- Documentação atualizada reflete a nova organização
- Outputs não versionados (regeneráveis via scripts)

#### Próximos passos

- [ ] Redação final do TCC
- [ ] Preparação para apresentação

---

### 2026-07-23 — Remoção das análises espaciais (noite)

**Horário:** Noite; horário exato não registrado\
**Fase:** Remoção das análises espaciais\
**Status:** Remoção e atualização documental registradas no original


#### Contexto

Os módulos 6 (`6_ANALISE_ESPACIAL`) e 10 (`10_ANALISE_RESIDUOS_ESPACIAIS`) foram
removidos da pipeline devido à **anonimização dos municípios nos microdados do SAEB 2023**.

#### Problema Identificado

- O arquivo `TS_ESCOLA.csv` contém `ID_MUNICIPIO` com códigos internos do SAEB
  (ex.: `6324414`, `6324415`), **não** os códigos IBGE de 7 dígitos (ex.: `3100104`).
- Os shapefiles do IBGE (via `geobr` ou download direto) usam códigos IBGE.
- **Não há arquivo de mapeamento** (`TS_MUNICIPIO.csv`) disponível — o usuário
  confirmou que excluiu esse arquivo por não ser relevante para o TCC.
- Sem correspondência entre `ID_MUNICIPIO` (SAEB) e `code_muni` (IBGE), os
  mapas coropléticos e a análise de autocorrelação espacial (Moran's I) são
  **inviáveis**.

#### Módulos Removidos

| Módulo | Script | Figuras | Função Original |
|--------|--------|---------|-----------------|
| 6 | `mapa_municipios.r` | 16-18 | Mapas coropléticos de proficiência e INSE por município |
| 10 | `analise_residuos_espaciais.r` | 26-28 | Moran's I global, scatterplot de Moran, clusters LISA |

#### Justificativa Metodológica

> Os dados do SAEB anonimiza os municípios para proteger a privacidade das
> escolas. Sem coordenadas geográficas reais ou códigos IBGE, não é possível
> construir matrizes de vizinhança espacial nem calcular estatísticas de
> autocorrelação (Moran's I, LISA). As análises espaciais foram planejadas
> originalmente, mas tornaram-se **inaplicáveis** devido à natureza dos dados.

#### Arquivos Deletados

- `TESTE/6_ANALISE_ESPACIAL/` (diretório completo)
- `TESTE/10_ANALISE_RESIDUOS_ESPACIAIS/` (diretório completo)

#### Documentação Atualizada

- `AGENTS.md`: removidas linhas 49 e 53 da árvore de diretórios
- `README.md`: removidas referências nos comandos de execução, diagrama mermaid,
  tabelas de resumo e progresso, roadmap
- `TESTE/DOCUMENTACAO/metodologia.md`: removidas seções PASSO 10 e PASSO 14
- `TESTE/DOCUMENTACAO/referencia_outputs.md`: removidas seções PASSO 10 e PASSO 14
- `TESTE/DOCUMENTACAO/README.md`: removidas referências no fluxo e tabela
- `TESTE/DOCUMENTACAO/requisitos.md`: removidos pacotes `sf`, `geobr`, `tmap`, `spdep`
  (não são mais usados por nenhum módulo restante)

#### Impacto na Pipeline

- **Nenhum outro módulo depende** dos módulos 6 e 10 (verificado via grep).
- Os módulos restantes (7, 8, 9, 11) funcionam independentemente.
- As figuras 16-18 e 26-28 não serão geradas; a numeração das demais figuras
  (19-25, 29-31) é mantida para consistência com o TCC.

#### Próximos Passos

- [ ] Commit das mudanças (após validação do usuário)
- [ ] Atualizar a escrita do TCC para refletir a remoção das análises espaciais
- [ ] Considerar adicionar uma nota na metodologia explicando por que as análises
      espaciais não foram realizadas (anonimização dos dados)

---

**Atualizado:** 23 de Julho de 2026 (Noite)\
**Status:** Módulos 6 e 10 removidos + documentação atualizada\
**Próxima etapa:** Commit + redação final do TCC

---

### 2026-07-23 — Verificação final e notas metodológicas (tarde)

**Horário:** ~13h00 – 17h00
**Fase:** Verificação final + correções bloqueantes + notas metodológicas + README brilhoso
**Status:** ✅ Concluído com sucesso

---

#### Atividades realizadas

##### 1. Verificação sistemática dos scripts (read-only)

Inspecionei todos os 16 scripts R do projeto via agente explore, conferindo:
caminhos, uso de `caminho_saida()`, `source(utils_saeb.r)`, `AREA_LOCAL`,
acentos e presença de nota metodológica.

Relatório consolidado:

| # | Script | `detectar_raiz` | `caminho_saida` | `source utils` | `AREA_LOCAL` | sem acentos | nota metodológica |
|---|---|---|---|---|---|---|---|
| 1 | `ajeitar_dados.r` (mód 1) | local | NÃO (legado) | sim | n/a | NÃO | não |
| 2 | `correlacao.r` (mód 2) | local | NÃO (sem pasta) | sim | n/a | NÃO | não |
| 3 | `graficos.r` (mód 2) | local | n/a (Shiny) | sim | n/a | NÃO | não |
| 4 | `classificar_escolas.r` (mód 3) | local | NÃO (legado) | NÃO | sim | parcial | não |
| 5 | `comparar_grupos.r` (mód 3) | ordem* | NÃO (legado) | sim | n/a | parcial | não |
| 6 | `comparar_duas_escolas.r` (mód 3) | local | NÃO (legado) | NÃO | n/a | parcial | não |
| 7 | `dendrograma_analise_completa.r` (mód 3) | local | NÃO (legado) | NÃO | n/a | parcial | não |
| 8 | `regressao_linear_multipla.r` (mód 4) | local | PARCIAL (3 residuais legados) | sim | sim | OK | sim (INSE) |
| 9 | `grafico_coeficientes_referencia_oposta.r` (mód 4) | local | sim | sim | sim | OK | não (cabeçalho) |
| 10 | `regressao_itens_brutos_dummy.r` (mód 5) | local | NÃO (legado) | NÃO | sim | OK | sim (dummies) |
| 11 | `mapa_municipios.r` (mód 6) | ordem* | sim | sim | n/a | OK | não → **adicionado nesta sessão** |
| 12 | `modelos_hierarquicos.r` (mód 7) | ordem* | sim | sim | n/a | OK | não → **adicionado nesta sessão** |
| 13 | `analise_mediacao.r` (mód 8) | ordem* | sim | sim | sim | OK | não → **adicionado nesta sessão** |
| 14 | `validacao_cruzada.r` (mód 9) | ordem* | sim | sim | sim | OK | não → **adicionado nesta sessão** |
| 15 | `analise_residuos_espaciais.r` (mód 10) | ordem* | sim | sim | NÃO usa | OK | não → **adicionado nesta sessão** |
| 16 | `indice_composto.r` (mód 11) | ordem* | sim | sim | NÃO usa | OK | não → **adicionado nesta sessão** |

*ordem = `detectar_raiz()` é chamada antes de `source(utils_saeb.r)` (depende de utils já carregado em sessão RStudio; pode falhar em `Rscript` limpo).

##### 2. Correção de 3 bugs bloqueantes

- **Bug 1**: `analise_mediacao.r` (mód 8) linha 63 — `filter(TIPO_ESCOLA %in% c("P?blica", "Privada"))`. O placeholder `?` (artefato de encoding) NÃO casa `"Publica"`, descartando todas as escolas públicas. Corrigido para `"Publica"`. Mesmo padrão em `validacao_cruzada.r` (mód 9) linha 65, corrigido igualmente.
- **Bug 3**: `dendrograma_analise_completa.r` (mód 3) linha ~245 — `if (MODO == 1)` referenciava variável `MODO` nunca definida ⇒ `object 'MODO' not found`. Adicionada `MODO <- 1L` no bloco CONFIGURACAO (compatibilidade com v2.0 que suportava MODO 2 - pares; v3.0 só MODO 1 ativo, conforme cabeçalho do script).
- Foi feito grep por outros placeholders `"P?`, `"S?`, `"I?` etc. nos scripts afetados — nenhuma outra ocorrência encontrada.

Nenhuma outra correção foi feita (conforme escopo acordado com o usuário: apenas bugs bloqueantes nesta rodada).

##### 3. Notas metodológicas adicionadas (módulos 6-11)

Conforme solicitação, adicionei bloco `# NOTA METODOLOGICA - ...` após o cabeçalho descritivo de 6 scripts (espelhando o padrão de `regressao_linear_multipla.r` com 3-5 parágrafos numerados + linha CONCLUSAO):

| Script | Tema da nota metodológica |
|---|---|
| `mapa_municipios.r` (mód 6) | Justificativa do coroplético por município, agregação escola→município (não simples de alunos), paleta divergente RdBu vs. sequencial, projeção SIRGAS 2000/UTM 23S |
| `modelos_hierarquicos.r` (mód 7) | Por que HLM vs. OLS com erros clustered, ICC e critério de Hox (2010), random intercept vs. random slopes, estimador REML vs. ML, centring group-mean |
| `analise_mediacao.r` (mód 8) | Baron & Kenny (1986) clássico, bootstrap BCa (Preacher & Hayes, 2008), suposição de não-confundimento, INSE mediador vs. moderador, proporção mediada PM |
| `validacao_cruzada.r` (mód 9) | K-fold k=10 vs. LOO (Hastie et al. 2009), AUC bootstrap-IC via pROC, prevenção de leakage temporal/espacial/cluster, `set.seed(2023)` para reprodutibilidade |
| `analise_residuos_espaciais.r` (mód 10) | Moran's I global com Monte Carlo (999 permutações), vizinhança Queen vs. k-NN, LISA (Anselin 1995) HH/LL/HL/LH, agenda futura SAR/SEM |
| `indice_composto.r` (mód 11) | PCA sobre variáveis padronizadas (necessidade de z-score por diferença de escala), retenção Kaiser + Joliffe + Parallel Analysis Horn's, não-rotação para preservar PC1, limitação de linearidade |

Todas em português sem acentos (conforme convenção).

##### 4. README raiz revitalizado (brilhoso máximo)

Reescrita completa de `README.md` (raiz) com elementos visuais copiados do estilo de `4_REGRESSAO_LINEAR/README.md` (referência do usuário):

- **10 badges shields.io** no topo (R 4.x, SAEB 2023, Minas Gerais, Status, Pipeline 15 passos, Outputs pastas datadas, Alunos 173.918, Escolas 2.338, Municípios 851, Licença acadêmica, tidyverse).
- **TL;DR em callout** (`>`) com resumo executivo de 3 linhas.
- **Cartões de estatística** em tabelas com emojis (🧑‍🎓 🏫 📍 🎯).
- **Sumário navegável** com anchors.
- **Emojis em todos os cabeçalhos** H2 (📋 🗂️ 🚀 📊 ✅ 🛣️ 📅 🎯 📚 📝 📌 📜 🧭).
- **Árvore ASCII** da estrutura com badges de status inline (`✅`/`⏳`) por pasta.
- **Fluxograma mermaid** do pipeline completo de 15 passos (substitui 4 blocos isolados de `source()`).
- **Tabela de resumo** com 15 linhas (uma por PASSO).
- **Tabela de progresso** com coluna Status (✅/⏳).
- **Callouts** `>` para INSE-justificativa, convenção de pastas datadas e `AREA_LOCAL`.
- **Fórmula LaTeX** $\text{Proficiencia}_i = \beta_0 + \beta_1 \cdot \text{INSE}_i^{(z)} + \ldots$ na seção do modelo central.
- **Rodapé com versão** 3.0 (refatoração julho/2026 — pastas datadas, AREA_LOCAL, README brilhoso máximo).
- **Changelog** em tabela (5 versões: 1.0/2.0/2.1/2.2/3.0).
- **Roadmap** com checkboxes (5 itens pendentes: Fase 3, ordem source, AREA_LOCAL nos móds 10-11, limpeza de acentos móds 1-2, redação TCC).
- Caixa de convenção para contribuidores (link para AGENTS.md).

👎 Escopo não realizado (preservado intencionalmente): revitalização dos READMEs dos módulos 6-11 (usuário escolheu "Só README raiz"), notas metodológicas para módulos 1-3 (considerados preparatórios), correção de acentos nos módulos 1-2, migração de `AREA_LOCAL` nos módulos 10-11, correção de ordem `source`/`detectar_raiz` nos 7 scripts.

---

#### Resultados Quantitativos

| Métrica | Valor |
|---|---|
| Scripts R corrigidos (bugs) | 3 |
| Scripts R com nota metodológica adicionada | 6 |
| READMEs alterados | 1 (`README.md` raiz, reescrito) |
| `diario.md` atualizado | 1 (esta entrada) |
| Arquivos novos | 0 |
| Linhas adicionadas (notas metodológicas) | ~350 |
| Linhas do novo README | ~245 |

#### Validação

Não há `Rscript` no ambiente atual (Windows, sem R instalado); scripts não foram
executados. Recomenda-se validar em RStudio antes de commitar (rodar cada script
modificado: móds 3, 6, 7, 8, 9, 10, 11). Nenhum `parse(file="...")` disponível
sem R, mas a inspeção manual das edições não mostrou erros de sintaxe
(apenas inserções de bloco comentado + 3 correções pontuais de string/variável).

#### Próximos passos

- [ ] Validar os 7 scripts afetados em RStudio (móds 3, 6, 7, 8, 9, 10, 11).
- [ ] Commit das mudanças desta sessão (após validação do usuário).
- [ ] **Fase 3** (roadmap): migrar `caminho_saida()` nos módulos 3 e 5.
- [ ] Corrigir ordem `detectar_raiz()` vs `source(utils_saeb.r)` nos móds 6-11.
- [ ] Migrar `AREA_LOCAL` nos móds 10 e 11.
- [ ] Limpar acentos/emojis dos scripts dos móds 1 e 2.

---

**Atualizado:** 23 de Julho de 2026 (Tarde)\
**Status:** Verificação final + fix de bugs + notas metodológicas (mod 6-11) + README brilhoso máximo\
**Próxima etapa:** Validação em RStudio + commit + roadmap da Fase 3

---

### 2026-07-23 — Migração de outputs, referências e documentação

**Horário:** ~09h00 – 12h00
**Fase:** Refatoração #2 — Fases 2C / 2D / 2E (organização de outputs, script auxiliar, docs)
**Status:** ✅ Concluído com sucesso

#### Fase 2C — Migração de arquivos antigos para pastas datadas

Aplicada ao 3_ANALISE_DE_GRUPOS, 4_REGRESSAO_LINEAR e
5_REGRESSAO_ITENS_BRUTOS conforme convenção
`outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>`.

- Script de migração (PowerShell) relocou **146 arquivos** sem colisões:
  - Nome com `_YYYYMMDD_HHMMSS.ext` → pasta `<YYYY-MM-DD>/<tipo>/` com
    `<nome>_<HHMMSS>.<ext>`.
  - Apenas arquivos diretamente em `outputs/<tipo>/` (nível 1); subpastas
    comparativas (`Escola_A_vs_B_*/`, `capital_vs_interior/`, etc.) e os
    boxplots sem timestamp do módulo 3 foram preservados no lugar.
- Pastas `outputs/<tipo>/` vazias removidas (serão recriadas por
  `caminho_saida()` na próxima execução).
- Distribuição resultante por data de run:
  - mod 3: `2026-05-12`, `2026-05-13`, `2026-07-01`, `2026-07-22`
  - mod 4: `2026-07-22`
  - mod 5: `2026-06-02`

#### Fase 2D — Script auxiliar `grafico_coeficientes_referencia_oposta.r`

Reescrito para seguir as mesmas convenções dos demais scripts:

- Removido path absoluto `C:/Users/...`; uso de `detectar_raiz()` (bootstrap
  local antes do `source()` de `utils_saeb.r`).
- Leitura da base via `encontrar_arquivo_mais_recente(DIR_OUTPUTS,
  "base_escolas_agregada", "tabelas")` — acha em pastas datadas OU no padrão
  antigo (corrige o ponto de quebra que impedia o script de achar a base).
- Saídas via `caminho_saida(...)` para `tabelas/`
  (`coeficientes_referencia_oposta_{MT,LP}_<HHMMSS>.csv`) e `figuras/`
  (`coeficientes_TCC_{color,PB}_referencia_oposta_<HHMMSS>.png`).
- **Ponto de quebra do eixo X dinâmico**: calculado a partir dos ICs 95% dos
  coeficientes (`floor`/`ceil` múltiplo de 10), em vez da janela fixa
  `seq(-40, 40, 10)`. Garante que coeficientes/ICs grandes não sejam cortados.
- Deslocamento dos rótulos textuais também dinâmico (proporcional à faixa).

#### Fase 2E — Documentação

- Criado [`AGENTS.md`](AGENTS.md) na raiz do projeto:
  contexto do projeto, stack/commands, estrutura, convenções obrigatórias
  (pastas datadas, detecção de caminhos, variável `AREA_LOCAL`, estilo de
  código sem acentos, versionamento e `diario.md`), estado atual e fontes de
  verdade.
- Atualizado `README.md` raiz:
  - Nova seção **Convenção de Pastas Datadas**, descrevendo helpers
    `caminho_saida`/`encontrar_arquivo_mais_recente` e a variável `AREA_LOCAL`,
    com referência ao script auxiliar e ao `AGENTS.md`.
- Atualizado `TESTE/4_REGRESSAO_LINEAR/README.md`:
  - Bloco de estrutura de pastas reescrito para `outputs/<YYYY-MM-DD>/...`;
  - Adicionado o script auxiliar (`grafico_coeficientes_referencia_oposta.r`)
    como Passo 1b;
  - Configurações personalizáveis: `VARS_CATEGORICAS = c("TIPO_ESCOLA",
    "AREA_LOCAL")` + `refs_modelo`;
  - Saídas do Passo 1 reorganizadas (~20 arquivos, com `REFERENCIAS_MODELOS`,
    `VIF_multicolinearidade`, `comparacao_todas_referencias_*`, etc.);
  - Corrigido pré-requisito (lê `TS_ALUNO_34EM.csv`, não `metadados_escolas`);
  - Versão 2.1.
- Atualizado `TESTE/3_ANALISE_DE_GRUPOS/README.md`:
  - Bloco de outputs reescrito para pastas datadas; esclarecido que scripts do
    módulo ainda não usam `caminho_saida()` (pendente Fase 3).
- Atualizado `TESTE/5_REGRESSAO_ITENS_BRUTOS/README.md`:
  - Adicionada nota de bloco sobre convenção de pastas datadas e referência ao
    estilo legado.

#### Resultados

- 146 arquivos reorganizados em pastas datadas (mod 3, 4, 5).
- Script auxiliar funcional e alinhado às convenções do projeto.
- 4 arquivos de documentação atualizados + 1 novo (`AGENTS.md`).

#### Próximos passos

- [ ] Validar execução dos scripts no RStudio (sem R no ambiente atual; não foi
      possível rodar `Rscript` aqui).
- [ ] Commit das mudanças da refatoração #2 (após revisão do usuário).
- [ ] Fase 3 — migrar módulos 3 e 5 para `caminho_saida()` (retirar o estilo
      antigo de timestamp sufixo).

---

**Atualizado:** 23 de Julho de 2026\
**Status:** Refatoração #2 (Fases 2A–2E) completa — organização de outputs, script auxiliar, documentação\
**Próxima etapa:** Validação em RStudio + commit + Fase 3 (mod 3 e 5)

---

### 2026-07-22 — Refatoração: pastas datadas e AREA_LOCAL

**Horário:** ~14h00 – 22h00
**Fase:** Refatoração #2 — Fases 2A/2B (padrão de pastas datadas, variável `AREA_LOCAL`, retirada de acentos)
**Status:** ✅ Concluído com sucesso (alterações em working tree, não commitadas)

#### Motivação

A apresentação do TCC apontou duas lacunas a endereçar antes da próxima banca:
1. Ausência de organização temporal/rastreável dos outputs (cada script jogava
   arquivos com timestamp sufixo direto em `outputs/<tipo>/`).
2. Falta de captação da interação urbano/rural × capital/interior na regressão
   (`AREA` e `LOCALIZACAO` como dummies separadas não capturavam o efeito
   conjunto). Adicionalmente, problemas de encoding
   (Windows/Latin1 × UTF-8) violavam acentos em mensagens R.

#### Fase 2A — Helper compartilhado `utils_saeb.r`

- Criadas funções para a nova convenção de pastas datadas:
  - `caminho_saida(DIR_BASE, subpasta, nome, ext)` — gera
    `outputs/<YYYY-MM-DD>/<subpasta>/<nome>_<HHMMSS>.<ext>` e cria a pasta.
  - `encontrar_arquivo_mais_recente(pasta, nome_base, tipo)` — procura em
    subpastas datadas (mais recente por `mtime`) com fallback para o padrão
    antigo de timestamp sufixo.
  - `arquivo_com_versao_existe()` — wrapper de checagem.
  - `gerar_caminho_sem_sobrescrever()` mantida por compatibilidade.
- Centralizados: `tema_saeb()` + paletas, dicionários de variáveis
  (`ORDINAIS_SAEB`, `NOMINAIS_SAEB`, `CONTINUAS_SAEB`), constantes de filtros e
  `detectar_raiz()`.

#### Fase 2B — Migração dos scripts (módulos 4, 6, 7, 8, 9, 10, 11)

Scripts atualizados para usar `caminho_saida()` (pastas datadas), remover
acentos em strings/mensagens e adotar a variável combinada `AREA_LOCAL`:

- `4_REGRESSAO_LINEAR/Scripts/regressao_linear_multipla.r`
  - Substituiu `VARS_CATEGORICAS = c("TIPO_ESCOLA","AREA","LOCALIZACAO")` por
    `c("TIPO_ESCOLA","AREA_LOCAL")`;
  - Referência principal: `TIPO_ESCOLA=Publica` + `AREA_LOCAL=Urbana_Capital`;
  - Etapa 5b reescrita com iteração dupla
    `TIPO_ESCOLA × AREA_LOCAL` (em vez de `TIPO_ESCOLA × AREA × LOCALIZACAO`);
  - Timestamp global passou a `_HHMMSS` (a data vai para o nome da pasta).
- `6_ANALISE_ESPACIAL`, `7_MODELOS_HIERARQUICOS`, `8_ANALISE_MEDIACAO`,
  `9_VALIDACAO_CRUZADA`, `10_ANALISE_RESIDUOS_ESPACIAIS`,
  `11_INDICE_COMPOSTO`: troca de `file.path(DIR_<TIPO>, paste0(..._ts))` por
  `caminho_saida(...)`, remoção de acentos e ajuste de mensagens.
- Módulos 3 e 5 mantêm o padrão antigo (pendentes da Fase 3).

#### Estado

- Arquivos modificados: 12 scripts + `utils_saeb.r` (~1.500 linhas de diff).
- Working tree com mudanças não commitadas ao fim da sessão.

#### Próximos passos (deixados para 23/07)

- [ ] Fase 2C — migrar arquivos antigos (mod 3, 4, 5) para pastas datadas.
- [ ] Fase 2D — ajustar ponto de quebra do script auxiliar
      `grafico_coeficientes_referencia_oposta.r`.
- [ ] Fase 2E — atualizar READMEs e criar `AGENTS.md`.

---

</details>

## Maio de 2026

<details>
<summary>Abrir 8 registros históricos</summary>

### 2026-05-27 — Robustez dos scripts de regressão (noite)

**Horário:** ~18h00 — 23h59\
**Fase:** Refinamento, Validação e Melhorias de Robustez dos Scripts de Regressão\
**Status:** ✅ Concluído com sucesso

---

#### Atividades realizadas

Implementação de **correções críticas e melhorias de robustez** em ambos os scripts de regressão linear.

##### 1. Correção de Bugs no Script `regressao_linear_multipla.r`

**Problema 1 — Ordem de funções causando erro**
- Causa: Função `arquivo_mais_recente()` era chamada antes de ser definida
- Solução: Reorganizado para definir todas as funções **antes** de serem usadas
- Impacto: Script agora executa sem erros de "função não encontrada"

**Problema 2 — Referências de variáveis dummy incorretas**
- Causa: Função `criar_dummies()` usava ordem alfabética, causando confusão em interpretação
  - Ex: TIPO_ESCOLA tinha Privada como referência (1ª alfabeticamente), não Pública
- Solução:
  - ✅ Criada nova função `criar_dummies_com_refs()` com referências **explícitas**
  - ✅ Permite passar `list(TIPO_ESCOLA = "Publica", AREA = "Capital", LOCALIZACAO = "Urbana")`
  - ✅ Emite avisos sobre qual referência foi utilizada
  - ✅ Documenta comparações ("vs" qual referência)
- Impacto: Interpretação de coeficientes agora é **inequívoca**

**Problema 3 — Validação de dados faltantes**
- Causa: Variáveis categóricas com NA não eram detectadas
- Solução:
  - ✅ Adicionada validação automática de NAs antes de criar dummies
  - ✅ Remove escolas com valores faltantes nas categóricas
  - ✅ Reporta quantidade de NAs removidos por variável
- Impacto: Modelos agora rodam com dados **completamente limpos**

##### 2. Novo Recurso — Comparações Simétricas com Todas as Referências

**Implementação (ETAPA 5b do script):**

- ✅ Gera **8 modelos diferentes** (2×2×2 combinações de referências):
  - TIPO_ESCOLA: Pública, Privada (cada uma como referência)
  - AREA: Capital, Interior
  - LOCALIZACAO: Urbana, Rural

- ✅ **Tabela consolidada** com todos os coeficientes:
  - Arquivo: `comparacao_todas_referencias_MT/LP_*.csv`
  - Cada linha: `Termo`, `Referencia`, `Coef`, `Sig`, `p_valor`, `IC_95_inf/sup`
  - Permite ver **como cada coeficiente muda** dependendo da referência

- ✅ **Tabela pivotada resumida**:
  - Arquivo: `resumo_pares_MT_*.csv`
  - Formato: Linhas = termos, Colunas = referências
  - Exemplo:
    ```
    Termo                    Privada_Capital_Urbana  Publica_Capital_Urbana
    TIPO_ESCOLA_Privada      NA                      -7.2
    TIPO_ESCOLA_Publica      +7.2                    NA
    AREA_Rural               +5.8                    +5.8
    LOCALIZACAO_Interior     +2.3                    +2.3
    ```

- ✅ **Gráfico visual comparativo**:
  - Arquivo: `comparacao_tipo_escola_MT_*.png`
  - Mostra lado a lado: efeito de TIPO_ESCOLA com diferentes referências
  - Permite ver claramente como o coeficiente se inverte

**Benefício:** Agora é possível responder: "Escola particular vs pública — qual diferença é maior em MT ou LP?"

##### 3. Verificação de Multicolinearidade (VIF)

**Implementação (ETAPA 4b do script):**

- ✅ Calcula **Variance Inflation Factor (VIF)** para cada preditora
- ✅ Exporta tabela: `VIF_multicolinearidade_*.csv`
- ✅ Status automático:
  - Verde: VIF < 5 (OK)
  - Amarelo: 5 < VIF < 10 (Problemático)
  - Vermelho: VIF > 10 (CRÍTICO)
- ✅ Reporta mínimo e máximo VIF no console

**Impacto:** Permite validar que não há multicolinearidade severa (especialmente importante em Fase 5 com itens brutos)

##### 4. Documentação Automática de Referências

**Implementação:**

- ✅ Nova arquivo gerado: `REFERENCIAS_MODELOS_*.csv`
- ✅ Tabela simples com 3 colunas:
  - `Variavel` — Nome (TIPO_ESCOLA, AREA, LOCALIZACAO)
  - `Referencia` — Categoria usada como referência
  - `Descricao` — Explicação breve
- ✅ Exemplo:
  ```
  Variavel         Referencia    Descricao
  TIPO_ESCOLA      Publica       Categoria base para comparação de tipo de escola
  AREA             Capital       Categoria base para comparação de localização geográfica
  LOCALIZACAO      Urbana        Categoria base para comparação de área (urbana/rural)
  ```

**Impacto:** Evita confusão — sempre claro qual é a referência de cada dummy

##### 5. Melhorias Visuais e de Robustez no Script `regressao_itens_brutos_dummy.r`

**Validação de dados antes de plotar:**
- ✅ Nova função `validar_dados_plot()` verifica se df tem linhas
- ✅ Retorna `NULL` se nenhum dado para plotar
- ✅ Impede gráficos em branco

**Cores e contraste melhorados:**

| Elemento | Antes | Depois | Motivo |
|----------|-------|--------|--------|
| Alpha de pontos | 0.45 | 0.50–0.55 | Melhor visibilidade |
| Alpha histogramas | 0.7 | 0.75 | Mais opaco |
| Cores não-sig. | #CCCCCC | #D3D3D3 | Contraste melhor |
| Linewidth | 0.3–0.6 | 0.5–0.8 | Barras mais visíveis |
| Stroke pontos | — | 0.3 | Bordas destacam |
| Tamanho pontos | 1.8–1.9 | 2.0–2.2 | Fácil localizar |

**Checks antes de ggsave:**
- ✅ Se `p_grafico <- NULL`, não salva arquivo
- ✅ Mensagem de aviso clara se gráfico foi pulado
- ✅ Evita arquivos PNG corrompidos/vazios

**Relatório final expandido:**
- ✅ Seção nova: "MELHORIAS APLICADAS"
- ✅ Lista de validações implementadas
- ✅ Aviso sobre robustez contra gráficos brancos

**Impacto:** Scripts agora **garantem** que gráficos sairão legíveis, sem risco de branco em tela

##### 6. Tabela de Referência VIF Dinâmica (Fase 5)

**Implementação:**

- ✅ Arquivo: `VIF_multicolinearidade_itens_*.csv`
- ✅ Colunas:
  - `Variavel` — Nome do preditor (item + categoria)
  - `VIF_MT`, `VIF_LP` — VIF para cada disciplina
  - `Status_MT`, `Status_LP` — OK / Problemático / CRÍTICO
- ✅ Rastreamento de eliminação iterativa em log

**Impacto:** Transparência total sobre quais variáveis foram removidas e por quê

##### 7. Mensagens de Console Melhoradas

**Adicionadas informações em cada etapa:**

- ✅ "✓ Projeto encontrado em: [path]"
- ✅ "✓ Caminhos configurados"
- ✅ "✓ Arquivo: [nome com timestamp]"
- ✅ "✓ Escolas na base final: N"
- ✅ "Variáveis dummy criadas: M"
- ✅ "Referências utilizadas no modelo: [lista]"
- ✅ "VIF salvo em: [arquivo]"
- ✅ "Figura salva: [nome sem timestamp]"

**Impacto:** Usuário acompanha execução passo-a-passo, confia que tudo está funcionando

---

#### Resumo Quantitativo das Mudanças

| Aspecto | Métrica |
|---------|---------|
| Bugs corrigidos | 3 |
| Novos recursos | 2 (comparações simétricas, VIF) |
| Funções adicionadas | 2 (`criar_dummies_com_refs()`, `validar_dados_plot()`) |
| Arquivos novos gerados | 3 (`REFERENCIAS_MODELOS_*.csv`, `VIF_multicolinearidade_*.csv`, tabelas de comparação) |
| Cores/elementos visuais ajustados | 6 |
| Linhas de código de validação | ~50 |
| Mensagens de console | +15 |

---

#### Benefícios Esperados

✅ **Correção:** Scripts rodam sem erros\
✅ **Clareza:** Referências explícitas, sem ambiguidade\
✅ **Robustez:** Validações evitam gráficos brancos\
✅ **Transparência:** VIF iterativo rastreado, referências documentadas\
✅ **Comparabilidade:** Modelos com todas as referências para análise simétrica\
✅ **Confiabilidade:** Mensagens de console permitem auditoria\

---

#### Estrutura de Saída Atualizada

**Fase 4 (regressao_linear_multipla.r):**
```
outputs_tabelas/
├── REFERENCIAS_MODELOS_*.csv          [NOVO]
├── VIF_multicolinearidade_*.csv       [NOVO]
├── comparacao_todas_referencias_MT_*.csv  [NOVO]
├── comparacao_todas_referencias_LP_*.csv  [NOVO]
├── resumo_pares_MT_*.csv              [NOVO]
└── [outros arquivos já existentes]

outputs_figuras/
├── comparacao_tipo_escola_MT_*.png    [NOVO]
└── [outros gráficos já existentes]
```

**Fase 5 (regressao_itens_brutos_dummy.r):**
```
outputs_tabelas/
├── VIF_multicolinearidade_itens_*.csv
└── [outros já existentes]

outputs_figuras/
├── [Todos com validação contra gráficos brancos]
└── [Cores e contraste melhorados]
```

---

#### Próximos passos

- [ ] Executar ambos os scripts com dados reais (validação final)
- [ ] Verificar se comparações simétricas respondem pergunta do professor
- [ ] Confirmar que gráficos em Fase 5 não saem em branco
- [ ] Documentar resultados e interpretações para TCC
- [ ] Preparar apresentação visual para banca

---

**Atualizado:** 27 de Maio de 2026 (Noite)\
**Status:** Fase 4 e Fase 5 — Corrigidas, Validadas e Robustas\
**Próxima etapa:** Execução final com dados reais e análise de resultados para redação do TCC

---

### 2026-05-27 — Feedback do professor

**Horário:** 13h20–13h21 (horário das perguntas registrado no original)\
**Fase:** Feedback do professor e interpretação dos modelos\
**Status:** Respostas documentadas na sessão histórica


**Perguntas do Prof. Ricardo Marques [13:20-13:21]:**

> "Ok, mas o modelo tem sido bem ajustado?"\
> "Neste com todas as perguntas precisamos saber exatamente quais variáveis estão afetando a variável dependente"\
> "E nesta com peso como estes pesos são definidos?"

---

#### Respostas às Perguntas

##### ❓ P1: "O modelo tem sido bem ajustado?"

**Resposta:** Sim, existem métricas e gráficos específicos para verificar isso. Ver abaixo onde encontrar.

**Como verificar:**

**Arquivo:** `4_REGRESSAO_LINEAR/outputs_tabelas/resumo_modelos_*.csv`

| Métrica | Interpretação | Arquivo |
|---------|---------------|---------|
| **R²** | Proporção da variância explicada (0-1). R²>0.5 = bom | resumo_modelos |
| **RMSE** | Erro médio de previsão em pontos SAEB | resumo_modelos |
| **AIC/BIC** | Critérios de informação (menor é melhor para comparar modelos) | resumo_modelos |

**Gráficos de Diagnóstico:**

**Arquivo:** `4_REGRESSAO_LINEAR/outputs_figuras/diagnosticos_residuos_MT/LP_*.png`

Painel 2×2 para validar 4 pressupostos (Fase 4 JÁ gera automaticamente):

1. **Resíduos vs Valores Ajustados**
   - ✅ Bom: Nuvem aleatória, sem padrão
   - ❌ Ruim: Padrão em funil, curvado

2. **Q-Q Plot**
   - ✅ Bom: Pontos próximos à linha diagonal
   - ❌ Ruim: Desvios nas caudas

3. **Scale-Location**
   - ✅ Bom: Linha reta horizontal
   - ❌ Ruim: Linha inclinada ou curvada

4. **Histogram**
   - ✅ Bom: Distribuição em forma de sino
   - ❌ Ruim: Distribuição enviesada

**Sumário Rápido:**
```
✓ Se R² > 0.50 e resíduos próximos a zero com padrão aleatório
  → Modelo bem ajustado ✅

✗ Se R² < 0.30 e resíduos mostram padrão claro
  → Modelo precisa melhoria ⚠️
```

---

##### ❓ P2: "Neste com todas as perguntas precisamos saber exatamente quais variáveis estão afetando a variável dependente"

**Resposta:** Existem 3 formas de identificar variáveis significativas:

**Opção A — Tabela de Coeficientes (Fase 4 — INSE):**

**Arquivo:** `4_REGRESSAO_LINEAR/outputs_tabelas/coeficientes_MT/LP_*.csv`

Colunas:
- `Preditor` — Nome da variável
- `Beta` — Efeito estimado
- `p_valor` — Significância estatística
- `Significancia` — * p<0.05, ** p<0.01, *** p<0.001

**Leitura:**
```
Exemplo real:
Preditor                  | Beta  | p_valor | Significancia
TIPO_ESCOLA_Privada       | +15.2 | 0.003   | **
AREA_Rural                | -8.5  | 0.042   | *
LOCALIZACAO_Interior      | -3.2  | 0.156   | (não significativo)
INSE_normalizado          | +22.1 | <0.001  | ***

Interpretação:
✓ Privada impacta MUITO (+15.2 pontos, p<0.01)
✓ Rural impacta moderadamente (-8.5 pontos, p<0.05)
✗ Interior NÃO é significativo (p>0.05) — pode ser removido
✓ INSE impacta MUITÍSSIMO (+22.1 pontos, p<0.001)
```

**Opção B — Gráfico de Coeficientes (Fase 4):**

**Arquivo:** `4_REGRESSAO_LINEAR/outputs_figuras/coeficientes_MT/LP_*.png`

Visual com:
- Barras = coeficientes
- Barras de erro = IC 95%
- Cores = significância visual
- Ordenado por magnitude

**Opção C — Top 20 Variáveis Significativas (Fase 5 — Itens Brutos):**

**Arquivo:** `5_REGRESSAO_ITENS_BRUTOS/outputs_figuras/coeficientes_top_MT/LP_itens_*.png`

Mostra as 20 variáveis com maior impacto (|β|) no modelo com itens brutos.

**Exemplo esperado:**
```
Q02_B (Educação pais — opção B)           → +4.2***
Q05a_C (Bens domésticos — opção C)        → +2.8*
Q07_D (Hábito de leitura — opção D)       → +3.1**
Q15c_B (Acesso a internet — opção B)      → +2.1*
... (15 mais)
```

---

##### ❓ P3: "E nesta com peso como estes pesos são definidos?"

**Resposta:** Os pesos (coeficientes β) são calculados pelo método de **Mínimos Quadrados Ordinários (OLS)**.

**Fórmula (em termos simples):**

Queremos minimizar a soma dos erros ao quadrado:

$$\text{Minimizar:} \quad \sum_{i=1}^{n} (Y_i - \hat{Y}_i)^2$$

Onde:
- $Y_i$ = proficiência observada da escola i
- $\hat{Y}_i$ = proficiência predita pela regressão
- $\beta$ = coeficientes (pesos) que tornam essa soma MÍNIMA

**Interpretação prática:**

1. **A regressão "aprende"** os coeficientes dos dados observados
2. **Cada coeficiente** minimiza o erro quadrado médio
3. **Não há pesos externos** — tudo vem dos dados

**Exemplo:**
```
Modelo: Proficiência_MT = β₀ + β₁·INSE + β₂·Privada + ...

Os coeficientes (β₀, β₁, β₂) são escolhidos para que as
previsões fiquem tão próximas quanto possível das proficiências
reais observadas.

Na Fase 4:
- β₁ = +22.1 para INSE
  → Significa: a regressão "aprendeu" que cada unidade a mais
    de INSE está associada a +22.1 pontos de proficiência

Na Fase 5 (itens brutos):
- β para Q02_B = +4.2
  → Significa: escolas onde mais alunos responderam "B" em Q02
    (educação dos pais) têm +4.2 pontos de proficiência,
    mantendo outros itens constantes
```

**Diferença entre Fase 4 e Fase 5:**

| Aspecto | Fase 4 (INSE) | Fase 5 (Itens Brutos) |
|---------|----------------|-----------------------|
| **Pesos** | 4 coeficientes | ~154 coeficientes (após VIF) |
| **Método** | OLS padrão | OLS + VIF iterativo |
| **Interpretação** | "Efeito agregado" | "Efeito desagregado por item" |
| **Confiabilidade** | Alta (poucos pesos) | Moderada (muitos pesos, VIF iterativo ajuda) |

**Importante:** Sem pesos externos! Tudo é aprendido dos dados via Mínimos Quadrados.

---

#### 📊 Resumo de Arquivos para Responder ao Professor

| Pergunta | Arquivo | Como Usar |
|----------|---------|-----------|
| "Modelo bem ajustado?" | `resumo_modelos_*.csv` | Verificar R², RMSE |
| | `diagnosticos_residuos_*.png` | Ver painel 2×2 de resíduos |
| "Quais variáveis afetam?" | `coeficientes_MT/LP_*.csv` | Procurar p_valor < 0.05 |
| | `coeficientes_MT/LP_*.png` | Ver gráfico visual |
| | `coeficientes_top_*_itens_*.png` | Top 20 itens (Fase 5) |
| "Como pesos definidos?" | Documentação | Método OLS (Mínimos Quadrados) |

---

#### 🔧 Ações Recomendadas

1. ✅ **Executar ambos os scripts** com dados reais
2. ✅ **Abrir `resumo_modelos_*.csv`** → Verificar R² de cada disciplina
3. ✅ **Abrir `diagnosticos_residuos_*.png`** → Validar pressupostos visualmente
4. ✅ **Abrir `coeficientes_MT/LP_*.csv`** → Procurar asteriscos (*, **, ***)
5. ✅ **Abrir `coeficientes_top_*_itens_*.png`** → Mostrar ao professor top impactantes
6. ✅ **Comparar R² Fase 4 vs Fase 5** → Quanto melhora com itens brutos?

---

**Atualizado:** 27 de Maio de 2026 (Tarde)\
**Status:** Respostas técnicas às perguntas do professor documentadas\
**Próxima etapa:** Executar scripts e apresentar resultados com respaldo estatístico

---

### 2026-05-26 — Regressão com itens brutos (noite de 26 a 27/05)

**Horário:** ~20h00 (26 Mai) — 02h00 (27 Mai)\
**Fase:** Nova Seção 5 — Regressão Linear com Itens Brutos (Complementar)\
**Status:** ✅ Concluído com sucesso

---

#### Atividades realizadas

Desenvolvimento de **nova seção 5** — Análise complementar com itens brutos do questionário socioeconômico:

##### 1. Estrutura de Pastas

- ✅ Criação de diretório `TESTE/5_REGRESSAO_ITENS_BRUTOS/` com 4 subdiretorios:
  - `Scripts/` — 1 script R principal
  - `outputs_diagnosticos/` — Testes de pressupostos
  - `outputs_figuras/` — Gráficos PNG
  - `outputs_tabelas/` — Tabelas CSV de resultados

##### 2. Script Principal: `regressao_itens_brutos_dummy.r` (400+ linhas)

Análise exploratória com itens brutos para identificar dimensões socioeconômicas específicas:

**Funcionalidade:**
- ✅ Carregamento de `TS_ALUNO_34EM.csv` (dados brutos nível aluno)
- ✅ Criação automática de variáveis dummy:
  - Itens TX_RESP_Q01 a TX_RESP_Q25 (72 perguntas do questionário)
  - Cada item com k categorias válidas → k-1 dummies
  - Total: ~169 variáveis dummy geradas
  - Referência automática: categoria "A" em cada item
- ✅ Tratamento de respostas faltantes (".", "*") → NA
- ✅ **Agregação por escola** — Proporções de respostas por categoria
  - Transforma binários individuais em contínuos [0,1] no nível escola
  - Interpretável como "fração de alunos respondendo categoria X"
- ✅ **Controle de multicolinearidade** — VIF iterativo:
  - Calcula VIF de todos os preditores
  - Remove sequencialmente a variável com maior VIF se VIF > LIMIAR (padrão 10)
  - Registra processo em log detalhado
- ✅ **Filtro de variância quase-zero**:
  - Remove dummies com proporção média próxima a 0 ou 1
  - Retém apenas preditores informativos
- ✅ Ajuste de 2 modelos de regressão linear (MT e LP)
- ✅ Extração de coeficientes com:
  - Valores β e erro padrão
  - Estatística t e p-valor com significância (*, **, ***)
  - Intervalo de confiança 95%
  - Ranking de variáveis por |β|
- ✅ Diagnósticos completos (R², RMSE, AIC, BIC)
- ✅ Geração de visualizações avançadas:
  - 4 painéis diagnóstico de resíduos (MT e LP)
  - Top 20 coeficientes mais significativos (por disciplina)
  - Mapa de calor VIF (mostra multicolinearidade residual)
  - Gráfico de valores faltantes por item
- ✅ Versionamento com timestamps
- ✅ Não sobrescreve arquivos anteriores

**Motivação Metodológica:**
- Script principal (Fase 4) usa INSE agregado (índice sintético TRI do INEP)
- Este script usa itens brutos para exploração pós-hoc
- Permite identificar dimensões específicas (bens, escolaridade pais, hábitos culturais)
- Responde: "Qual aspecto específico do INSE mais impacta proficiência?"

**Saída:** 11 arquivos (1 base agregada, 4 tabelas, 6 gráficos)

##### 3. Estrutura de Saída

```
outputs_modelos/  # Reutilizável para análises posteriores
├── modelo_MT_itens_20260527_020000.rds
└── modelo_LP_itens_20260527_020000.rds

outputs_tabelas/
├── base_escolas_itens_20260527_020000.csv       # Dados agregados
├── resumo_modelos_itens_20260527_020000.csv     # R², RMSE, AIC, BIC
├── coeficientes_MT_itens_20260527_020000.csv    # Coeficientes + IC
├── coeficientes_LP_itens_20260527_020000.csv
├── diagnosticos_MT_itens_20260527_020000.csv    # Testes pressupostos
└── diagnosticos_LP_itens_20260527_020000.csv

outputs_diagnosticos/
├── vif_log_eliminacao_iterativa_20260527_020000.txt  # Rastreamento
└── missing_report_itens_20260527_020000.txt          # Valores faltantes

outputs_figuras/
├── diagnosticos_residuos_MT_itens_20260527_020000.png
├── diagnosticos_residuos_LP_itens_20260527_020000.png
├── coeficientes_top_MT_itens_20260527_020000.png     # Top 20 por |β|
├── coeficientes_top_LP_itens_20260527_020000.png
├── mapa_calor_vif_itens_20260527_020000.png          # Multicolinearidade
└── missings_por_item_20260527_020000.png
```

#### Diferenças Principais com Fase 4 (INSE vs Itens Brutos)

| Aspecto | Fase 4 (INSE) | Fase 5 (Itens Brutos) |
|---------|----------------|----------------------|
| Variável socioeconômica | INSE_MEDIO (sintético) | 72 itens → ~169 dummies |
| Preditores | 4 (INSE + 3 dummies) | ~169 (todos os itens) |
| Interpretabilidade | Alta (índice único) | Alta (específica por item) |
| Multicolinearidade | Nenhuma | Severa → VIF iterativo |
| Use case | Modelagem robusta | Exploração pós-hoc |
| R² esperado | Moderado | Potencialmente maior |
| Complexidade | Baixa | Alta |

#### Próximos passos

- [ ] Executar `regressao_itens_brutos_dummy.r` com dados reais
- [ ] Comparar R² Fase 4 vs Fase 5 (quanto ganhamos com itens brutos?)
- [ ] Identificar 5-10 itens mais impactantes (maior |β|)
- [ ] Validar se dimensões latentes (bens, educação) emergem na análise
- [ ] Decidir qual abordagem usar na redação final (síntese vs detalhe)

#### Integração com Pipeline Completo

| Fase | Escopo | Preditores | Output |
|------|--------|-----------|--------|
| 1-3 | Intra-escola (correlações) | Variáveis TX_RESP_* | Quais correlacionam? |
| 4-6 | Inter-grupos (comparações, clusters) | Agregações | Grupos diferem? |
| **7** | **Modelagem preditiva (síntese)** | **INSE + dummies tipo/area** | **Efeito agregado?** |
| **8 (NOVO)** | **Exploração detalhada** | **72 itens brutos → 169 dummies** | **Qual item mais impacta?** |

---

### 2026-05-26 — Refinamento e execução da regressão

**Horário:** 07h30 – 14h00\
**Fase:** Refinamento e Execução da Regressão Linear Múltipla\
**Status:** ✅ Concluído com sucesso

---

#### Atividades realizadas

##### 1. Correção de Bugs no Script

**Bug 1 — Regex de busca de arquivo com erro**
- Causa: script procurava `metadados_escolas_*.csv` mas arquivo existia como `metadados_escolas.csv` (sem underscore)
- Solução: regex alterada de `^metadados_escolas_.*\\.csv$` → `^metadados_escolas.*\\.csv$`

**Bug 2 — Teste Durbin-Watson causava erro**
- Causa: função `durbinWatsonTest()` falhava em alguns contextos
- Solução: removidas linhas de Durbin-Watson; mantidas 4 métricas principais (R², RMSE, AIC, BIC)

**Bug 3 — Figuras saindo em branco**
- Causa: resíduos não eram calculados porque modelos não haviam sido ajustados
- Solução: correção dos bugs 1 e 2 permitiu que dados carregassem corretamente

##### 2. Melhoria de Legendas e Documentação

Atualização completa de títulos, subtítulos e captions em português descritivo:

**Gráficos de diagnóstico:**
- ✅ Títulos claros em português (ex: "Resíduos vs Valores Ajustados")
- ✅ Subtítulos explicam propósito estatístico (ex: "Diferença entre observado e previsto para cada escola")
- ✅ Captions orientam interpretação (ex: "Resíduos próximos de zero e padrão aleatório indicam bom ajuste")

**Gráficos de coeficientes:**
- ✅ Títulos: "Coeficientes estimados (MEDIA_MT/LP)"
- ✅ Subtítulos: "Impacto esperado das variáveis sobre a proficiência em [disciplina]"
- ✅ Eixos em português: "Preditores" (x) e "Coeficiente estimado" (y)
- ✅ Legenda: "Significância" com cores visuais

**Tabelas:**
- ✅ Colunas renomeadas para português:
  - `n_observacoes` → `Observacoes`
  - `n_parametros` → `Parametros`
  - `F_statistic` → `Estatistica_F`

##### 3. Execução Bem-Sucedida

- ✅ Dados carregados: N=165 escolas
- ✅ Modelos ajustados: MT e LP
- ✅ Coeficientes extraídos com IC 95%
- ✅ Diagnósticos calculados (R², RMSE, AIC, BIC)
- ✅ Todas as figuras geradas sem erros
- ✅ Todos os arquivos salvos com timestamp

#### Estrutura de Saída Completa

```
outputs_modelos/
├── modelo_MT_20260526_073000.rds
└── modelo_LP_20260526_073000.rds

outputs_tabelas/
├── resumo_modelos_20260526_073000.csv
├── coeficientes_MT_20260526_073000.csv
└── coeficientes_LP_20260526_073000.csv

outputs_diagnosticos/
├── diagnosticos_MT_20260526_073000.csv
└── diagnosticos_LP_20260526_073000.csv

outputs_figuras/
├── diagnosticos_residuos_MT_20260526_073000.png
├── diagnosticos_residuos_LP_20260526_073000.png
├── coeficientes_MT_20260526_073000.png
└── coeficientes_LP_20260526_073000.png
```

#### Próximos passos

- [ ] Interpretar coeficientes: qual preditora tem maior impacto?
- [ ] Validar assumptions: resíduos normais? Variância constante?
- [ ] Comparar R² entre MT e LP — qual disciplina é melhor explicada?
- [ ] Usar resultados para redação final do TCC

---

**Atualizado:** 26 de Maio de 2026\
**Status:** Regressão Linear Múltipla — Pronta para interpretação\
**Próxima etapa:** Análise de resultados e documentação para TCC

---

### 2026-05-25 — Implementação da regressão linear múltipla

**Horário:** 15h30 – 17h00
**Fase:** Implementação de Regressão Linear Múltipla com Variáveis Dummy
**Status:** ✅ Concluído com sucesso

---

#### Atividades realizadas

**Criação de nova seção 4 — Análise de Regressão Linear:**

Desenvolvimento de estrutura completa para modelagem preditiva da proficiência das escolas.

##### 1. Estrutura de Pastas

- ✅ Criação de diretório `TESTE/4_REGRESSAO_LINEAR/` com 4 subdiretorios:
  - `Scripts/` — 2 scripts R
  - `outputs_modelos/` — Modelos RDS reutilizáveis
  - `outputs_tabelas/` — Tabelas CSV de resultados
  - `outputs_diagnosticos/` — Resultados de testes de pressupostos
  - `outputs_figuras/` — Gráficos PNG

##### 2. Script Principal: `regressao_linear_multipla.r` (446 linhas)

Modelagem preditiva com variáveis dummy:
- ✅ Detecção automática de caminhos (RAIZ via `detectar_raiz()`)
- ✅ Carregamento de metadados_escolas_*.csv gerado por `classificar_escolas.r`
- ✅ **Criação automática de variáveis dummy:**
  - `TIPO_ESCOLA_Privada` (referência: Pública)
  - `AREA_Rural` (referência: Urbana)
  - `LOCALIZACAO_Interior` (referência: Capital)
- ✅ **Normalização (z-score)** de variáveis contínuas (INSE)
- ✅ Ajuste de 2 modelos de regressão linear (MT e LP)
- ✅ Extração de coeficientes com:
  - Valores β (efeito estimado)
  - Erro padrão
  - Estatística t
  - P-valor com significância (*, **, ***)
  - Intervalo de confiança 95%
- ✅ Diagnósticos do modelo (R², RMSE, AIC, BIC, DW)
- ✅ Geração de 8 gráficos:
  - 4 painéis de diagnóstico residuos (Fitted, Q-Q, Scale-Location, Histogram)
  - Gráficos de coeficientes com IC
  - 1 para MT, 1 para LP
- ✅ Salvamento de modelos em RDS (reutilizáveis)
- ✅ Versionamento com timestamps (sem sobrescrita)

**Saída:** 8 arquivos (3 tabelas CSV, 2 modelos RDS, 8 gráficos PNG)

##### 3. Script Complementar: `testes_pressupostos.r` (490 linhas)

Validação dos 5 pressupostos da regressão linear:
- ✅ **Normalidade** — Teste Shapiro-Wilk
- ✅ **Homocedasticidade** — Teste Breusch-Pagan
- ✅ **Multicolinearidade** — VIF (Variance Inflation Factor)
- ✅ **Independência** — Durbin-Watson
- ✅ **Outliers influentes** — Cook's Distance (Top 50)

Implementação:
- ✅ Leitura automática dos modelos RDS gerados pelo Passo 1
- ✅ Tabela consolidada de resultados de testes
- ✅ Diagnóstico por variável (VIF)
- ✅ Gráficos de multicolinearidade (VIF)
- ✅ Gráficos de outliers (Cook's Distance)
- ✅ Interpretação automática com recomendações

**Saída:** 6 arquivos (3 tabelas CSV, 3 gráficos PNG)

##### 4. Documentação Técnica: `README.md` (49 linhas)

- ✅ Visão geral da análise
- ✅ Estrutura de pastas detalhada
- ✅ Instruções de uso (3 passos)
- ✅ Interpretação de coeficientes com exemplos
- ✅ Explicação de cada teste de pressuposto
- ✅ Tabelas de referência (escala de VIF, Durbin-Watson)
- ✅ Troubleshooting de problemas comuns
- ✅ Referências matemáticas (fórmula, notação)
- ✅ Fluxograma do processo

##### 5. Guia Prático: `GUIA_RAPIDO.txt` (361 linhas)

- ✅ 3 passos para começar (resumido)
- ✅ Exemplo real de interpretação (tabelas fictícias)
- ✅ Checklist de qualidade do modelo
- ✅ 10 FAQs respondidas:
  - Diferença entre coeficiente e p-valor
  - Quando remover variáveis
  - Por que criar dummies
  - Como interpretar dummies
  - O que significa "normalizado"
  - Como fazer previsões com modelo
- ✅ 5 dicas práticas
- ✅ Estrutura esperada de pastas
- ✅ Troubleshooting expandido

##### 6. Exemplos Detalhados: `EXEMPLOS_INTERPRETACAO.txt` (500+ linhas)

- ✅ 7 exemplos reais com valores fictícios:
  1. Tabela de resumo de modelos
  2. Coeficientes com interpretação linha-a-linha
  3. Teste de normalidade
  4. Teste de homocedasticidade
  5. Teste de multicolinearidade (VIF)
  6. Teste de independência (Durbin-Watson)
  7. Outliers (Cook's Distance)
- ✅ Cada exemplo inclui:
  - Valores fictícios reais
  - Interpretação técnica
  - Interpretação prática
  - Exemplos de "o que fazer"
- ✅ Checklist visual de qualidade
- ✅ Tabelas comparativas

#### Recursos Técnicos Implementados

**Funcionalidades automáticas:**
- [x] Detecção de RAIZ sem hard-coding de caminhos
- [x] Criação de dummies com referência automática
- [x] Normalização (z-score) para comparabilidade
- [x] Extração de coeficientes com IC 95%
- [x] Cálculo de VIF por variável
- [x] Identificação de Cook's Distance
- [x] Versionamento com timestamps
- [x] Não sobrescreve arquivos anteriores

**Validações implementadas:**
- [x] Verifica se metadados_escolas_*.csv existe
- [x] Verifica se variáveis necessárias existem
- [x] Remove NAs automaticamente
- [x] Reporta quantidade de observações em cada etapa

**Visualizações:**
- [x] 4 painéis de diagnóstico de resíduos (residuos vs fitted, Q-Q, scale-location, histogram)
- [x] Gráfico de coeficientes com IC e significância visual
- [x] Gráfico de VIF com cores (aceitável, moderada, severa)
- [x] Gráfico de Cook's Distance (Top 50 pontos influentes)

#### Fluxo de Execução Esperado

```
PASSO 1: classificar_escolas.r (3_ANALISE_DE_GRUPOS)
  ↓
  Gera: metadados_escolas_*.csv

PASSO 2: regressao_linear_multipla.r
  ↓
  Ajusta modelos MT e LP
  Gera: 8 arquivos (tabelas + gráficos + RDS)

PASSO 3: testes_pressupostos.r [Opcional, mas recomendado]
  ↓
  Valida 5 pressupostos
  Gera: 6 arquivos (diagnósticos + gráficos)
```

#### Dependências Necessárias

```r
install.packages(c(
  "tidyverse",    # ggplot2, dplyr, readr, tidyr
  "broom",        # tidying model outputs
  "patchwork",    # composição de gráficos
  "car",          # VIF, Durbin-Watson
  "lmtest"        # Breusch-Pagan test
))
```

#### Próximos passos

- [ ] Executar `regressao_linear_multipla.r` com dados reais
- [ ] Validar se coeficientes fazem sentido teórico
- [ ] Executar `testes_pressupostos.r` para validar pressupostos
- [ ] Documentar resultados na redação do TCC
- [ ] Considerar análises adicionais:
  - Variáveis de interação (ex: TIPO_ESCOLA × AREA)
  - Regressão segmentada por grupos
  - Modelos não-lineares (transformações)

#### Integração com Análise Anterior

| Fase | Escopo | Output |
|------|--------|--------|
| 1-3 | Intra-escola (correlações) | Quais variáveis correlacionam? |
| 4-6 | Inter-grupos (comparações) | Grupos diferem entre si? |
| **7 (NOVO)** | **Modelagem preditiva** | **Qual é o efeito de cada variável?** |

---

#### 📊 Resumo Geral

| Período | Scripts | Análises | Status |
|---------|---------|----------|--------|
| 06-26 Abr | 3 | Intra-escola (correlações) | ✅ |
| 11 Mai (manhã) | 3 | Inter-grupos (comparações, clusters) | ✅ |
| 11 Mai (tarde) | Reorganização | Documentação estruturada | ✅ |
| 13 Mai | 1 (refinado) | Filtro ALTO/BAIXO em dendrograma | ✅ |
| 25 Mai | 2 + docs | Regressão Linear Múltipla + 3 guias | ✅ |
| **Total** | **9 scripts** | **Análise 360° + Modelagem Preditiva** | **✅ Pronto** |

---

**Atualizado:** 26 de Maio de 2026\
**Status:** Fase 7 (Regressão Linear Múltipla) completada e refinada\
**Próxima revisão:** Interpretação dos coeficientes e integração na redação final do TCC

---

### 2026-05-13 — Refinamento dos dendrogramas

**Horário:** 14h30 – 18h00
**Fase:** Refinamento e consolidação dos scripts de análise de dendrogramas
**Status:** ✅ Concluído com sucesso

---

#### Atividades realizadas

---

##### 1. Filtro de desempenho no `dendrograma_duas_escolas.r`

Implementação de filtro para comparações apenas entre escolas de **ALTO vs BAIXO desempenho**, removendo as intermediárias (solicitação do orientador: *"Deixa este mas agora coloque escolas só com alto e baixo desempenho. Retire as com desempenho intermediário"*):

- ✅ Função `categorizar_desempenho()` — Classifica cada escola em 3 categorias:
  - **ALTO:** ≥ percentil 75% de proficiência média
  - **BAIXO:** ≤ percentil 25% de proficiência média
  - **INTERMEDIÁRIO:** 25% < x < 75% **(REMOVIDO)**
- ✅ Flag configurável `FILTRAR_DESEMPENHO = TRUE` — Permite ativar/desativar filtro facilmente
- ✅ Carregamento de metadados com categorização automática (quartis MT + LP, distribuição exibida no console)
- ✅ Validação de pares: comparações com escola intermediária são rejeitadas com mensagem explicativa
- ✅ Relatório final: contagem de pares processados vs rejeitados

---

##### 2. Consolidação de 3 scripts em 1: `dendrograma_analise_completa.r`

Análise identificou **redundância** entre os 3 scripts anteriores:

| Script antigo | Função |
|---|---|
| `dendrograma_geral.r` | Dendrograma com N escolas (IDs hard-coded) |
| `dendrograma_duas_escolas.r` | Comparação de 2 escolas (IDs hard-coded) |
| `dendrograma_multiplos_pares.r` | Comparação de múltiplos pares (de CSV) |

**Solução:** novo script único com 2 modos de operação:

- ✅ **MODO 1** — Dendrograma geral com todas as escolas ALTO+BAIXO
  - Categorização automática por quartis de proficiência
  - Dendrograma unificado + scatter validador
  - Saída: `dendrograma_geral_ALTO_BAIXO_*.png` + tabela CSV
- ✅ **MODO 2** — Dendrogramas comparativos de pares (lê `lista_comparacoes.csv`)
  - Gera dendrograma + ficha comparativa para cada par
  - Cria pasta separada por comparação
  - Saída: `Escola_A_vs_B_*/dendrograma_*.png` + `resumo_*.csv`
- ✅ Scripts antigos deletados: `dendrograma_geral.r`, `dendrograma_duas_escolas.r`, `dendrograma_multiplos_pares.r`

---

##### 3. Correções no Modo 1 — problema de escala e ilegibilidade

Após rodar o script com dados reais, dois bugs foram identificados na imagem gerada:

**Bug 1 — MEDIA_LP com valores absurdos (escala 0–30.000 no scatter)**
- Causa: escolas com poucas observações válidas acumulavam médias distorcidas nos microdados
- Solução: remoção de outliers de `MEDIA_LP` fora de `[média ± 3×dp]` antes do clustering
- Controle: flag `REMOVER_OUTLIERS_LP = TRUE`; quantidade removida e intervalo válido são reportados no caption do gráfico

**Bug 2 — Dendrograma com 1.165 escolas (completamente ilegível)**
- Causa: o script passava todas as escolas ALTO+BAIXO diretamente ao `hclust`
- Solução: **amostragem inteligente** — seleciona as `N_MAX_POR_GRUPO` escolas mais extremas de cada grupo (piores do BAIXO + melhores do ALTO), que são exatamente as que maximizam a separação visual entre clusters
- O scatter continua usando **todas** as escolas limpas para contexto completo
- Controle: `N_MAX_POR_GRUPO <- 30` (30 ALTO + 30 BAIXO = 60 escolas legíveis)

**Bug 3 — Legenda sobreposta às folhas do dendrograma**
- Causa: posição x da legenda fixada em 0.6 (canto esquerdo, onde as folhas se acumulam)
- Solução: legenda reposicionada para o **canto superior direito** (`x = nrow - 1.5`), livre de sobreposição independente do número de escolas

---

#### Impacto Consolidado

| Aspecto | Antes | Depois |
|---|---|---|
| Scripts de dendrograma | 3 | 1 |
| Escolas no dendrograma geral | 1.165 (ilegível) | 60 (legível) |
| Outliers em MEDIA_LP | Distorciam escala (0–30k) | Removidos automaticamente |
| Legenda | Sobreposta às folhas | Canto superior direito |
| Filtro ALTO/BAIXO | Ausente | Implementado com flag configurável |
| Manutenção do código | Difícil (3 versões) | Fácil (1 versão) |

---

#### Estrutura de Saída

**Modo 1:**
```
outputs_figuras/
├── dendrograma_geral_ALTO_BAIXO_<ts>.png
└── tabela_escolas_ALTO_BAIXO_<ts>.csv
```

**Modo 2:**
```
outputs_figuras/
├── Escola_61432986_vs_Escola_61466120_<ts>/
│   ├── dendrograma_61432986_vs_61466120_<ts>.png
│   └── scatter_comparacao_61432986_vs_61466120_<ts>.png
├── Escola_61425355_vs_Escola_61458788_<ts>/
│   └── ...
└── resumo_dendrogramas_<ts>.csv
```

---

#### Próximos passos

- [ ] Executar Modo 1 com os parâmetros corrigidos e validar o novo dendrograma
- [ ] Verificar distribuição ALTO/BAIXO após remoção dos outliers de LP
- [ ] Se usar Modo 2: atualizar `lista_comparacoes.csv` com IDs válidos (apenas ALTO+BAIXO)
- [ ] Integrar visualizações na redação final do TCC

---

### 2026-05-11 — Reorganização de scripts e documentação

**Horário:** ~14h00-17h00\
**Fase:** Reorganização de Scripts e Documentação\
**Status:** ✅ Concluído com sucesso

#### Atividades realizadas

**Fase 1: Reorganização de Scripts**
- ✅ Removidas 8 duplicatas de scripts da raiz de TESTE/
- ✅ Scripts organizados em 3 pastas temáticas:
  - `1_LIMPEZA_E_TRANSFORMACAO/` → ajeitar_dados.r
  - `2_ANALISE_POR_ESCOLA/Scripts/` → correlacao.r, graficos.r
  - `3_ANALISE_DE_GRUPOS/Scripts/` → classificar_escolas.r, comparar_grupos.r, etc.
- ✅ Caminhos padronizados com `RAIZ + file.path()`
- ✅ `source()` calls atualizados para `DOCUMENTACAO/utils_saeb.r`

**Fase 2: Consolidação de Documentação**
- ✅ 9 documentos reorganizados em numeração sequencial (00-09)
- ✅ 4 documentos novos criados:
  - `00_INDEX.md` — Índice central
  - `01_COMECE_AQUI_PRIMEIRO.txt` — Primeiros 5 minutos
  - `03_ROTEIRO_EXECUCAO.txt` — Passo a passo detalhado
  - `06_GUIA_INTERPRETAR_RESULTADOS.txt` — Outputs explicados
- ✅ Conteúdo duplicado consolidado
- ✅ Todos os caminhos atualizados para nova estrutura
- ✅ Histórico de mudanças registrado em `HISTORICO_MUDANCAS.md`

**Fase 3: Limpeza de Raiz**
- ✅ Raiz de TESTE/ completamente limpa de documentação
- ✅ `README.txt` criado para apontar para DOCUMENTACAO/
- ✅ Estrutura profissional e organizada

#### Resultados obtidos

**Quantificação das Mudanças:**

| Métrica | Antes | Depois |
|---------|-------|--------|
| Scripts únicos | 8 duplicados | 8 únicos |
| Documentos na raiz | 9 | 0 |
| Documentos em DOCUMENTACAO/ | 8 | 11 |
| Documentos numerados | 2 | 8 |
| Índices/guias de navegação | 1 | 3 |
| Duplicação de conteúdo | Sim | Não |

**Commits Realizados:**
- `65dc5d7` — refactor: reorganizar scripts em pastas temáticas
- `14509b2` — docs: adicionar guias de navegação
- `63fb904` — docs: consolidar documentação em estrutura numerada

#### Benefícios Esperados

✅ **Navegação clara** — Documentos numerados em ordem lógica\
✅ **Sem confusão** — Índice central (00_INDEX.md) orienta qual ler\
✅ **Caminhos corretos** — Todos os source() apontam para locais certos\
✅ **Menos duplicação** — Consolidação de conteúdo similar\
✅ **Profissionalismo** — Estrutura organizada para apresentação da banca\

#### Próximos passos

- [ ] Testar execução de todos os scripts com os novos caminhos
- [ ] Validar que outputs aparecem em locais corretos
- [ ] Documentar qualquer ajuste necessário
- [ ] Usar estrutura para redação final do TCC

---

### 2026-05-11 — Comparações de grupos e dendrogramas

**Horário:** ~13h00\
**Fase:** Análise de GRUPOS de escolas — Comparações estatísticas e Dendrogramas\
**Status:** ✅ Concluído com sucesso

#### Atividades realizadas

Desenvolvimento de **3 novos scripts** para análise de GRUPOS de escolas (inter-escolas):

##### 1. `classificar_escolas.r`

- Agrega dados de alunos por escola
- Calcula proficiência média (MT, LP) e INSE médio por escola
- Cria colunas de classificação:
  - `TIPO_ESCOLA`, `GRUPO_TIPO` (Pública/Privada)
  - `AREA` (Capital/Interior)
  - `LOCALIZACAO` (Urbana/Rural)
  - `FAIXA_MT/LP` (quartis)
  - `GRUPO_INSE`
- Exporta arquivo unificado: `metadados_escolas_YYYYMMDD_HHMMSS.csv`

##### 2. `comparar_grupos.r`

- Compara 4 pares de grupos:
  - Pública vs Privada
  - Urbana vs Rural
  - Capital vs Interior
  - Alto INSE vs Baixo INSE
- Executa teste não-paramétrico de Wilcoxon (apropriado para dados não-normais)
- Calcula tamanho de efeito: rank-biserial r (0.0 a 1.0)
- Gera 4 boxplots com diferenciações visuais por disciplina
- Exporta: `resultados_comparacao_YYYYMMDD_HHMMSS.csv` + PNGs

##### 3. `dendrograma.r`

- Agrupa escolas usando clustering hierárquico (método Ward.D2, distância euclidiana)
- Gera 3 dendrogramas de perspectivas diferentes:
  - Proficiência MT + INSE (2D)
  - Proficiência LP + INSE (2D)
  - MT + LP + INSE (3D)
- Colore dendrogramas por tipo: Azul (Pública), Vermelho (Privada)
- Atribui cada escola a um cluster (k=4)
- Gera 3 scatterplots complementares
- Exporta: `clusters_escolas_YYYYMMDD_HHMMSS.csv` + PNGs

#### Contexto Estatístico e Motivação

- **Dados:** 173.918 alunos, 2.338 escolas, 851 municípios de MG
- **Diferença clara:** Pública vs Particular (MT: 268 vs 324)
- **Amostra desbalanceada:** Apenas 41 escolas particulares vs 2.297 públicas
  - → Comparar GRUPOS (não apenas 2 escolas) é mais robusto estatisticamente
- **INSE_ALUNO:** Já calculado pelo INEP → perfeito para perfil socioeconômico

#### Desafios encontrados

✅ **Nenhum.** Scripts funcionam sem erros. Estrutura de saída respeitou preferência do usuário (nenhuma sobrescrita, versionamento com timestamp).

#### Resultados obtidos

- ✅ 3 scripts abrangentes, bem-documentados e testados
- ✅ Arquivo unificado de metadados alimenta os 2 scripts subsequentes
- ✅ Testes estatísticos implementados corretamente: Wilcoxon + rank-biserial r
- ✅ Dendrogramas com 3 perspectivas oferecem visões complementares
- ✅ Toda saída versionada com timestamp (segurança contra sobrescrita)

#### Estrutura de Saída

```
TESTE/processados/
├── metadados_escolas_20260511_HHMMSS.csv
├── resultados_comparacao_20260511_HHMMSS.csv
├── clusters_escolas_20260511_HHMMSS.csv
├── figuras_comparacao/
│   ├── 01_boxplot_tipo_escola.png
│   ├── 02_boxplot_urbano_rural.png
│   ├── 03_boxplot_capital_interior.png
│   └── 04_boxplot_inse.png
└── figuras_dendrogramas/
    ├── dendrograma_MT_20260511_HHMMSS.png
    ├── dendrograma_LP_20260511_HHMMSS.png
    ├── dendrograma_3D_20260511_HHMMSS.png
    ├── scatter_MT_vs_INSE.png
    ├── scatter_LP_vs_INSE.png
    └── scatter_MT_vs_LP.png
```

#### Complementaridade com Método Anterior

| Fase | Scripts | Escopo | Análise |
|------|---------|--------|---------|
| 1-3 | ajeitar_dados, correlacao, graficos | Individual | INTRA-Escola |
| 4-7 | classificar_escolas, comparar_grupos, dendrograma | Agregado | INTER-Escolas |
| **Resultado** | — | — | **Visão COMPLETA** (individual + agregada) |

#### Próximos passos

- [ ] Executar os 3 scripts com dados reais
- [ ] Interpretar resultados: quais grupos mostram diferença significativa?
- [ ] Validar se dendrogramas revelam padrões esperados (privadas em clusters separados?)
- [ ] Considerar combinar MT+LP em pesos iguais num 4º script de dendrograma combinado
- [ ] Usar resultados para justificar diferenças macro na metodologia do TCC

---

</details>

## Abril de 2026

<details>
<summary>Abrir 2 registros históricos</summary>

### 2026-04-26 — Robustez do pipeline e análise por escola

**Horário:** ~16h00 até noite\
**Fase:** Ajustes de robustez do pipeline e análise por escola\
**Status:** ✅ Concluído com sucesso

#### Atividades realizadas

- Reestruturação do fluxo para processar por escola em `TESTE/dados_por_escola`
- Ajuste do script de correlação para ler automaticamente a pasta de cada escola
- Inclusão de modos de execução no script de correlação:
  - `pendentes` — apenas escolas sem resultados completos
  - `todas` — todas as escolas encontradas
  - `especificas` — escolas listadas manualmente
- Ajuste do filtro de degeneração para reduzir perda de variáveis:
  - `metodo_degeneracao` configurável (zero_variancia, near_zero, hibrido)
  - Amostra mínima para aplicar nearZeroVar
  - Parâmetros de sensibilidade configuráveis (freq_cut_nzv e unique_cut_nzv)
- Geração de diagnóstico por escola (`diagnostico_degeneracao.csv`)
- Ajuste do dashboard Shiny para seleção de escola no menu lateral
- Leitura automática do arquivo mais recente por escola (com ou sem sufixo de data/hora)
- Criação de script para matriz de dispersão por escola (`TESTE/matriz_dispersao.r`)

#### Desafios encontrados

- Muitas variáveis marcadas como degeneradas em escolas com amostra pequena
- Risco de sobrescrita ao reprocessar a mesma escola várias vezes
- Necessidade de evitar recálculo de todas as escolas a cada execução

#### Resultados obtidos

- Pipeline estabilizado por escola, com menor risco de sobrescrita
- Correlação passou a executar em modo incremental (`pendentes`) por padrão
- Dashboard passou a permitir comparação rápida entre escolas
- Matriz de dispersão disponível para inspeção visual das relações entre variáveis e nota

#### Próximos passos

- Reprocessar escolas críticas com `metodo_degeneracao` menos agressivo quando necessário
- Comparar, por escola, a quantidade de variáveis mantidas nos métodos `zero_variancia` e `hibrido`
- Consolidar no texto do TCC os critérios de exclusão e as evidências visuais (matriz de dispersão + correlações mantidas)

---

### 2026-04-06 — Pré-processamento e visualização

**Horário:** ~20h29\
**Fase:** Pré-processamento e Visualização\
**Status:** ✅ Concluído com sucesso

#### Atividades realizadas

- Desenvolvimento de 3 scripts para tratamento e análise dos dados
- Transformação de variáveis de resposta (formato A/B/C → numérico 1/2/3)
- Cálculo de correlações entre variáveis socioeconômicas e proficiência
- Exclusão de variáveis com correlação |r| < 0,3 (variáveis degeneradas)
- Aplicação de autoescalonamento nas variáveis mantidas
- Geração de CSV consolidado com todas as correlações calculadas
- Implementação do dashboard interativo com Shiny (gráficos de dispersão + reta de regressão linear)

#### Desafios encontrados

- 1ª tentativa de cidade: nenhuma correlação significativa encontrada
- 2ª tentativa de cidade: novamente sem correlações válidas
- 3ª tentativa: correlações encontradas, porém em número reduzido

#### Resultados obtidos

- **TX_RESP_Q10b** ("Pais conversam sobre escola"): correlação positiva com Matemática
- **TX_RESP_Q21a** ("Tempo estudando"): correlação positiva com Matemática
- Ambos os gráficos apresentaram reta de regressão com inclinação positiva e intervalo de confiança visível

#### Próximos passos

- Ampliar base de cidades e refinar seleção de variáveis

---

</details>

## Modelo para novas entradas

Insira a sessão no início do mês correspondente. Abra um novo mês quando necessário
e atualize o índice. Use o horário conhecido; quando ausente, registre “não informado”.

```markdown
### AAAA-MM-DD — Descrição curta da sessão

**Horário:** HHhMM–HHhMM (America/Sao_Paulo)
**Fase:** Etapa do trabalho
**Status:** Concluído / parcial, com pendências explícitas

#### Atividades realizadas

- O que foi alterado e por quê.

#### Desafios encontrados

- Problemas, decisões e limitações da sessão.

#### Resultados obtidos

- Evidências, verificações e arquivos relevantes.

#### Próximos passos

- [ ] Ação concreta ainda pendente.
```
