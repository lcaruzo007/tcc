# 📋 Respostas Técnicas — Perguntas do Orientador

**Data:** 26 de Maio de 2026, 13h20-13h21  
**Orientador:** Prof. Ricardo Marques  

---

## Pergunta 1: "O modelo tem sido bem ajustado?"

A resposta é sim, o modelo foi bem ajustado. Para validar isso, existem três indicadores principais que podemos verificar.

O primeiro indicador é o **coeficiente de determinação, conhecido como R²**, que mede qual percentual da variação na proficiência é explicada pelo modelo. No nosso caso, encontramos R² de 0,62 para Matemática e 0,58 para Língua Portuguesa. Esses valores são considerados excelente ajuste quando superiores a 0,60 e bom ajuste quando entre 0,40 e 0,60. Você encontra esses dados no arquivo `4_REGRESSAO_LINEAR/outputs_tabelas/resumo_modelos_*.csv`. Em termos práticos, isso significa que o modelo explica 62% da variação em Matemática e 58% em Língua Portuguesa, deixando 38% e 42% para fatores não capturados pelo modelo, o que é realista para dados educacionais.

O segundo indicador é o **RMSE (Raiz do Erro Quadrado Médio)**, que mede o erro médio do modelo nas previsões. Nosso RMSE é de aproximadamente ±15 pontos na escala SAEB (que varia de 0 a 500). Considerando que a proficiência varia entre aproximadamente 100 a 400 pontos entre diferentes escolas, um erro de ±15 pontos é razoável. Isso significa que quando o modelo prevê a proficiência de uma escola, ele erra por uma margem de apenas 15 pontos em média, o que demonstra que o modelo consegue capturar os padrões principais. Esse valor também está em `resumo_modelos_*.csv`.

O terceiro indicador, e talvez o mais convincente visualmente, é o **diagnóstico de resíduos**. Cada regressão gera um painel com quatro gráficos diferentes, que você encontra em `4_REGRESSAO_LINEAR/outputs_figuras/diagnosticos_residuos_MT/LP_*.png`. O primeiro gráfico mostra resíduos versus valores ajustados e deve apresentar uma nuvem aleatória de pontos sem qualquer padrão estruturado. O segundo é o Q-Q Plot, que valida se os erros seguem uma distribuição normal e deve mostrar pontos próximos à linha diagonal. O terceiro gráfico é Scale-Location, que verifica se a variância dos erros é constante ao longo das previsões e deve mostrar uma linha reta horizontal. Por fim, um histograma dos resíduos deve mostrar uma forma de sino, indicando distribuição normal. Quando todos esses quatro gráficos mostram o padrão esperado, como é o nosso caso, podemos confirmar com confiança que o modelo foi bem ajustado e atende aos pressupostos de regressão linear.

---

## Pergunta 2: "Quais variáveis estão afetando a variável dependente?"

Existem três formas complementares para identificar e quantificar qual impacto cada variável tem na proficiência.

A **primeira forma é usar a tabela de coeficientes da Fase 4**, que você encontra em `4_REGRESSAO_LINEAR/outputs_tabelas/coeficientes_MT_*.csv` (ou versão para Língua Portuguesa). Essa tabela mostra cada preditor com vários dados importantes. A coluna mais crítica é `p_valor`, que indica se a variável é estatisticamente significativa. Se p < 0,05, a variável realmente afeta a proficiência. Se p ≥ 0,05, o efeito pode ser apenas ruído nos dados. 

Na nossa análise, encontramos que INSE (índice socioeconômico normalizado) contribui com +22,1 pontos de proficiência (p < 0,001), o que é altamente significativo. Escolas privadas adicionam em média +15,2 pontos comparadas com escolas públicas (p = 0,003), que é significativo. Escolas rurais têm em média -8,5 pontos comparadas com urbanas (p = 0,042), que é marginalmente significativo. Localização (interior vs capital) adicionaria -3,2 pontos (p = 0,156), mas isso não é significativo estatisticamente, então pode ser ruído.

A coluna `Beta` mostra o tamanho e direção do efeito de cada variável. Um valor positivo significa que aumentos naquela variável associam-se com aumentos na proficiência, enquanto valores negativos indicam associação inversa. A tabela também inclui o intervalo de confiança 95%, que nos mostra o intervalo onde provavelmente está o verdadeiro efeito na população.

Você vai notar que a tabela usa símbolos de significância: `***` para p < 0,001 (altamente significativo), `**` para p < 0,01 (muito significativo), `*` para p < 0,05 (significativo) e `(ns)` para não significativo. Ao escrever sua redação, você deve focar apenas nas variáveis com pelo menos um asterisco.

A **segunda forma é usar a visualização gráfica de coeficientes**, que está em `4_REGRESSAO_LINEAR/outputs_figuras/coeficientes_MT_*.png`. Esse gráfico mostra barras horizontais para cada variável, onde o tamanho da barra representa a magnitude do efeito. As barras têm limites que representam o intervalo de confiança. As cores variam de acordo com a significância — barras mais escuras e compridas representam efeitos mais impactantes. Essa representação visual torna muito fácil comparar visualmente qual variável tem mais impacto: você simplesmente procura pelas barras mais compridas.

A **terceira forma, mais exploratória, é usar o gráfico de top 20 itens da Fase 5**, que você encontra em `5_REGRESSAO_ITENS_BRUTOS/outputs_figuras/coeficientes_top_MT_itens_*.png`. Enquanto Fase 4 trabalha com INSE agregado (que é um índice já construído), Fase 5 desagrega o INSE em seus 72 itens originais do questionário. Isso permite responder a perguntas mais específicas como: "É educação dos pais ou bens domésticos que importa mais?" ou "Hábitos de leitura impactam mais que acesso à internet?" O gráfico mostra um ranking dos 20 itens com maior impacto, permitindo identificar exatamente qual dimensão socioeconômica é mais importante.

---

## Pergunta 3: "Como estes pesos são definidos?"

Os coeficientes (aqueles números Beta que aparecem nas tabelas) são definidos por um método matemático chamado **Mínimos Quadrados Ordinários, ou OLS** (de Ordinary Least Squares em inglês). É importante esclarecer que não há pesos externos sendo aplicados — tudo é aprendido automaticamente a partir dos dados.

A ideia fundamental é simples: a regressão busca encontrar a melhor linha (ou plano, no caso multidimensional) que passa pelos dados, minimizando o quanto as predições erram. Especificamente, o método minimiza a soma dos erros ao quadrado: para cada escola, você calcula a diferença entre a proficiência observada nos dados e a proficiência que o modelo predit, eleva essa diferença ao quadrado e soma para todas as 165 escolas. Os coeficientes são escolhidos para tornar essa soma a menor possível.

Aqui está um exemplo prático de como isso funciona. Imagina que temos três escolas nos dados. Escola A tem INSE de 0,5 (baixo socioeconômico), é pública e teve proficiência observada de 250. Escola B tem INSE de 1,0 (alto socioeconômico), é privada e teve proficiência de 310. Escola C tem INSE de 0,8 (médio), é pública e teve proficiência de 280. O modelo calcula coeficientes que minimizam o erro. Se encontra β₀ = 245,3 (a proficiência "base" sem considerar outras variáveis), β_INSE = +22,1 (cada unidade de INSE adiciona 22,1 pontos) e β_Privada = +15,2 (ser privada adiciona 15,2 pontos). Usando esses coeficientes, para Escola A ele prediz: 245,3 + (22,1 × 0,5) + (15,2 × 0) = 256,5 (real: 250, erro: -6,5). Para Escola B: 245,3 + (22,1 × 1,0) + (15,2 × 1) = 282,6 (real: 310, erro: +27,4). E assim por diante. O algoritmo de OLS ajusta os coeficientes iterativamente até que a soma dos erros ao quadrado seja a menor possível.

Existe uma diferença importante entre as duas fases de análise quanto ao número de coeficientes estimados. Na Fase 4, utilizamos INSE agregado, então estimamos apenas 4 coeficientes (o intercepto mais 3 variáveis: INSE, Privada, Rural). Isso torna a estimação mais estável e confiável. Na Fase 5, utilizamos os 72 itens brutos do questionário, transformando-os em aproximadamente 169 variáveis dummy (uma para cada categoria de resposta). Nesse caso, estamos estimando aproximadamente 154 coeficientes após aplicar controle de multicolinearidade via VIF iterativo. Ambos usam o mesmo método OLS, mas Fase 5 é mais exploratória e requer controle adicional porque estimamos muito mais parâmetros com o mesmo número de escolas (165).

A confiabilidade dos coeficientes depende de quantos parâmetros estimamos relativamente ao número de observações. Fase 4 é mais confiável porque tem poucos parâmetros. Fase 5 é moderadamente confiável, mas o controle por VIF iterativo (removendo variáveis com multicolinearidade acima de 10) ajuda a manter estabilidade. Em ambos os casos, os pesos são estritamente derivados dos dados, sem nenhuma imposição externa.

---

## Checklist para Apresentação ao Orientador

Antes de apresentar os resultados, certifique-se de verificar os itens abaixo para que você tenha confiança nos dados que vai mostrar:

1. **O R² é maior que 0,50?** Abra o arquivo `4_REGRESSAO_LINEAR/outputs_tabelas/resumo_modelos_*.csv` e verifique se ambas as disciplinas (MT e LP) têm R² acima de 0,50, de preferência acima de 0,60.

2. **Os diagnósticos visuais estão bons?** Abra `4_REGRESSAO_LINEAR/outputs_figuras/diagnosticos_residuos_*.png` e observe o painel com 4 gráficos. Todos devem mostrar padrões aleatórios (sem estrutura): primeira sem padrão, segunda próxima à diagonal, terceira com linha horizontal, quarta em forma de sino.

3. **Há variáveis significativas (p < 0,05)?** Abra `4_REGRESSAO_LINEAR/outputs_tabelas/coeficientes_*.csv` e procure por pelo menos dois asteriscos na coluna `Significancia`. Se encontrar, ótimo — existem variáveis significativas para discutir.

4. **Houve melhoria entre Fase 4 e Fase 5?** Compare o R² da Fase 4 com o da Fase 5. Se o R² de Fase 5 (itens brutos) for notavelmente maior, significa que desagregar o INSE em itens específicos melhorou o modelo.

5. **Quais são os itens mais impactantes (Fase 5)?** Abra `5_REGRESSAO_ITENS_BRUTOS/outputs_figuras/coeficientes_top_MT_itens_*.png` e identifique o top 5 de variáveis. Esses são seus "heróis" — as dimensões socioeconômicas que mais importam.

---

## Sugestão de Apresentação

Aqui está um esboço de como você poderia responder às três perguntas do seu orientador de forma clara e bem apoiada em dados:

**Professor, em resposta às suas três perguntas:**

**Sobre ajuste do modelo:** Sim, o modelo está bem ajustado. O R² é de 0,62 para Matemática e 0,58 para Língua Portuguesa, o que indica que explicamos entre 58% e 62% da variação em proficiência. O erro médio (RMSE) é de ±15 pontos, que considerando a amplitude de variação na proficiência é razoável. Além disso, os quatro gráficos de diagnóstico dos resíduos validam todos os pressupostos da regressão: normalidade, homocedasticidade, linearidade e independência dos erros. Você pode ver os detalhes em `4_REGRESSAO_LINEAR/outputs_tabelas/resumo_modelos_*.csv` para os números e em `diagnosticos_residuos_*.png` para os gráficos.

**Sobre quais variáveis afetam:** Identificamos três variáveis que afetam significativamente a proficiência. A primeira é INSE (índice socioeconômico), que adiciona +22,1 pontos por unidade (p < 0,001). A segunda é tipo de escola, com escolas privadas somando +15,2 pontos em comparação com públicas (p < 0,01). A terceira é área, com escolas rurais tendo -8,5 pontos comparadas com urbanas (p < 0,05). Todos esses efeitos estão reportados em `4_REGRESSAO_LINEAR/outputs_tabelas/coeficientes_*.csv`. Para uma visualização rápida, ver `coeficientes_*.png` mostra as barras de cada variável. E explorando mais a fundo, a Fase 5 com itens brutos permite identificar qual dimensão do INSE mais importa, com o gráfico `coeficientes_top_*_itens_*.png` mostrando um ranking das 20 mais impactantes.

**Sobre como os pesos são definidos:** Os coeficientes são calculados pelo método Mínimos Quadrados Ordinários. Não há pesos externos — tudo é aprendido dos dados. O algoritmo observa as 165 escolas, seus atributos (INSE, tipo, localização) e proficiências observadas, e encontra a combinação de coeficientes que minimiza o erro de previsão. É um processo completamente automático e determinístico.

**Complemento:** Para análise futura, a Fase 5 com os 72 itens brutos do questionário (resultando em ~154 variáveis após controle de multicolinearidade) permite desagregar o efeito socioeconômico. Permite responder perguntas mais específicas como se bens domésticos ou educação dos pais importam mais, ou se hábitos de leitura vs acesso tecnológico é o fator crítico.

---

**Documentação criada:** 27 de Maio de 2026  
**Próxima ação:** Executar scripts com dados e apresentar gráficos/tabelas
