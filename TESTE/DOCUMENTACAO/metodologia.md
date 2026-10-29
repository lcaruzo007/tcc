# Metodologia · SAEB 2023 em Minas Gerais

Este é o documento principal das decisões metodológicas implementadas.
A [análise do projeto](analise_projeto.md) registra a revisão e suas correções.

## Dados, unidade e validade

O arquivo local `TS_ALUNO_34EM.csv` contém 173.918 registros de 2023, UF 31,
com `ID_SERIE` 12 e 13 (3ª/4ª séries, ensino tradicional e integrado).
Os modelos agregados têm a **escola como unidade de análise**; correlações
dentro de cada escola usam os registros individuais.

`ler_microdados_saeb()` exige o recorte explícito, preserva os estudantes e
substitui por `NA` notas sem indicador de validade igual a 1, não finitas ou
fora de 150–800. Essa faixa é um filtro operacional do projeto e deve ser
justificada no TCC; não é apresentada como limite universal da escala do SAEB.
O INSE requer `IN_INSE = 1` e valor finito. Conjuntos sem valores válidos
produzem `NA_real_`, nunca uma média artificial ou uma classificação alta.

O projeto usa médias aritméticas escolares. A sensibilidade com WLS por número
de estudantes não reproduz o desenho amostral oficial: os pesos `PESO_ALUNO_*`
do CSV não são utilizados como pesos amostrais. A inferência se refere às
associações na amostra escolar analisada.

## Limpeza das respostas e correlações · passos 1–3

Os domínios de cada item vêm de `DICT_ROTULOS_SAEB`, transcrito do importador
do INEP. Branco, `"."`, `"*"` e códigos fora do domínio viram `NA`.
Letras como `F` são preservadas quando válidas para a pergunta; respostas
“não sei” e “não quero declarar” são categorias identificadas separadamente
no relatório, sem serem confundidas com ausência ou código inválido.

| Variáveis analíticas | Representação | Correlação |
|----------------------|---------------|------------|
| Q10, Q19–Q23 e respectivos subitens configurados | Escore ordinal com ordem explícita; Q22/Q23 invertidas | Spearman |
| Q01 e Q04 | Indicadores 0/1, incluindo categorias de não declaração | Spearman |
| `INSE_ALUNO` | Escore numérico válido | Pearson |
| `NU_TIPO_NIVEL_INSE` | Nível ordinal numérico válido | Spearman |

A seleção usa somente nomes analíticos esperados e numéricos, incluindo as
dummies e as duas variáveis do INSE. Respostas brutas em letras não entram no
cálculo. O padrão remove apenas ausência total ou variância zero; a opção
near-zero, quando habilitada no script, usa os parâmetros documentados de
`caret::nearZeroVar()`, que não se resumem a uma frequência de 95%.

Cada correlação usa os pares finitos de sua disciplina, no mínimo três,
verificando a variância nesse mesmo subconjunto. Status e número de pares são
exportados separadamente para MT e LP. Uma disciplina sem pares não invalida
a correlação válida da outra. O filtro exploratório é `|r| >= 0,30`; os CSVs
completos preservam as demais correlações. O dashboard usa z-scores e os
rótulos do dicionário central.

## Agregação e amostras · passos 4, 6, 8–10

`agregar_escolas_saeb()` centraliza validade, contexto e denominadores.
Valores conflitantes de contexto dentro de uma escola provocam erro.
`AREA_LOCAL` combina área e localização; referências principais:
`TIPO_ESCOLA = Publica` e `AREA_LOCAL = Urbana_Capital`.
Categorias não observadas não geram coeficientes.

| Análise | Denominador das médias | Elegibilidade |
|---------|------------------------|---------------|
| Metadados e descrição, passo 4 | Notas válidas separadamente em MT/LP | Todas as escolas; ausentes permanecem ausentes |
| Comparação de duas escolas, passo 6 | Notas válidas por disciplina | IDs configurados; mesmos indicadores de validade, inclusive em XLSX |
| Regressão principal, passo 8 | Alunos com ambas as notas válidas | No mínimo 5 pares, 3 INSE válidos e contexto completo |
| Itens brutos, passo 9 | Alunos com ambas as notas válidas | No mínimo 5 pares; posteriormente casos completos das preditoras |
| Mediação, passo 10 | Médias descritivas por disciplina do passo 4 | No mínimo 5 notas válidas em cada disciplina, 3 INSE válidos e contexto completo |

Essas perguntas conservam denominadores diferentes de forma deliberada.
`N_ALUNOS_MT_VALIDOS`, `N_ALUNOS_LP_VALIDOS`, `N_ALUNOS_PAREADOS`,
`N_ALUNOS_INSE` e `MEDIAS_PAREADAS` permitem verificá-los. Nos passos 8 e 9,
`N_ALUNOS_MT` é a contagem de pares usada no ajuste, também para LP.

Quartis de proficiência e cortes 0,33/0,67 de INSE usam apenas valores finitos.
Escolas sem a medida não recebem `FAIXA_MT/LP` ou `GRUPO_INSE`.
Os modelos exportam fluxos de elegibilidade; o passo 9 registra ainda as
exclusões por ausência nos preditores selecionados.

## Comparações e agrupamentos · passos 5 e 7

As comparações usam Wilcoxon, tamanho de efeito rank-biserial com sinal,
p-valores numéricos e ajuste de Benjamini–Hochberg. Rank-biserial e Cohen's d
medem aspectos distintos e não são intercambiáveis. A interpretação como
diferença de localização depende das distribuições comparadas.

Os dendrogramas usam distância euclidiana sobre variáveis padronizadas e
`Ward.D2`. As figuras para artigo selecionam escolas extremas; são ilustrações
desse subconjunto. Não se deve interpretar a seleção como representação
automática da estrutura de todas as escolas.

## Regressão e exploração de itens · passos 8 e 9

O modelo principal relaciona a média da disciplina ao INSE escolar padronizado,
tipo de escola e `AREA_LOCAL`. Os coeficientes descrevem associações condicionais,
sem identificação causal pelo desenho observacional agregado.

O INSE é usado como indicador oficial e parcimonioso; isso não implica que
todos os itens do questionário componham sua calibração. A composição deve ser
citada a partir da documentação oficial da edição. A quantidade de itens,
sozinha, também não torna uma regressão impossível.

O passo 9 usa proporções de categorias por escola, omissão inicial de A, mínimo de três
respostas válidas por item, filtros de variância/ausência e remoção iterativa por
VIF acima de 10. O conjunto escolhido no modelo MT é reutilizado em LP.
A seleção é exploratória: tabelas completas acompanham gráficos que mostram
apenas coeficientes com `p < 0,05`. Um incremento de 0,10 na proporção corresponde
a dez pontos percentuais; não é comparável diretamente a uma unidade de INSE
padronizado.

A seleção pode remover outras categorias do mesmo item. Nesse caso, A deixa
de ser a única categoria omitida e o coeficiente não representa um contraste
isolado com A sem as restrições adicionais impostas pela seleção. O arquivo
`referencias_efetivas_itens` documenta as categorias mantidas e omitidas de cada
item. Em Q12c, a auditoria reproduziu modelos com o bloco completo e referências
A/D para distinguir uma reparametrização equivalente de uma mudança de modelo.

R², R² ajustado e RMSE descrevem ajuste nos próprios dados. Os gráficos de
resíduos, VIF e testes de heterocedasticidade/normalidade auxiliam o diagnóstico.
A sensibilidade compara OLS e WLS por número de pares, ambos com erros-padrão HC3.
Essas métricas não medem desempenho preditivo fora da amostra.

## Mediação exploratória · passo 10

Para cada disciplina, são ajustados um modelo para INSE e outro para proficiência
condicionada ao INSE e ao tratamento. O bootstrap percentil usa 1.000 simulações,
com semente 2023. Excluir zero do intervalo não demonstra convergência do bootstrap.

- Tipo de escola: privada versus pública na amostra elegível.
- Localização: cada categoria observada é comparada **somente** com
  `Urbana_Capital`, após filtrar a base para esses dois grupos.
- As fórmulas não incluem covariáveis adicionais. Essa escolha exploratória é
  explicitada nas saídas, sem confundir o ajuste com a regressão principal.
- Tabelas registram número de escolas em cada grupo, referência e efeitos
  direto, indireto, total, intervalos, p-valores e proporção mediada.
- Diagramas reutilizam os modelos efetivamente estimados para cada contraste.

A interpretação causal requer pressupostos de identificação e avaliação de
confundimento que o bootstrap não estabelece. A análise é uma decomposição
exploratória de associações; uma proporção mediada pode ser instável quando
o efeito total é próximo de zero. Ver o
[artigo do pacote mediation](https://www.jstatsoft.org/article/view/v059i05).

## Reprodutibilidade

O executor confere `renv.lock`, resolve dependências e vincula leituras ao
catálogo da execução. Manifests preservam versões, parâmetros, revisão do código,
hashes MD5 dos arquivos e status. Consulte o [guia operacional](README.md) e o
[dicionário de outputs](referencia_outputs.md).

## Auditoria de 28–29/10/2026

A [auditoria técnica](../../RELATORIO_AUDITORIA_TCC.md) identificou 250 notas
armazenadas acima de 800 no CSV local anterior, mesmo com flag de validade igual a 1.
As 83 notas LP abaixo de 150 constituem outra questão: sua exclusão é uma
decisão operacional do projeto e foi submetida a sensibilidade. Não se deve
descrever ambos os conjuntos como erros confirmados. As exclusões passam a
ser exportadas por aluno, escola, disciplina e motivo, preservando a fonte.

Em 29/10, o confronto com a base nacional fornecida recuperou essas 250 notas
pelos IDs dos alunos: 121 em MT e 129 em LP. Todos os valores correspondem
exatamente ao valor corrompido dividido por mil. O recorte MG extraído dessa
base foi adotado em `MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv`, preservando
o arquivo anterior em backup. Foram mantidos os mesmos alunos e escolas e
incorporados também os demais campos da fonte nacional, incluindo pesos e
erros-padrão divergentes. As 83 notas LP abaixo de 150 permanecem na fonte;
a política de limpeza descrita acima continua em vigor. Modelos e figuras
anteriores à substituição precisam ser reprocessados antes de representar
a nova entrada. O arquivo nacional foi fornecido pelo usuário; a procedência
do download não foi autenticada externamente.

Os dendrogramas publicados foram reproduzidos com os mesmos IDs e comparados
após a limpeza. As mediações antigas foram reproduzidas com as notas brutas e
o contraste antigo, que incluía outras categorias no grupo de referência.
O relatório detalha as revisões necessárias na seção de resultados do TCC.
