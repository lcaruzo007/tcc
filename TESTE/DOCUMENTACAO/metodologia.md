# Metodologia — Base para o TCC

Justificativas estatísticas das decisões metodológicas.

## PASSO 1: Transformação de Variáveis

### Classificação por tipo

| Tipo | Variáveis | Transformação | Correlação |
|------|-----------|---------------|------------|
| Ordinais | Q10, Q21, Q22, Q23, Q19, Q20 | factor ordenado (A→1, B→2...) | Spearman |
| Nominais | Q01 (sexo), Q04 (raça) | dummies 0/1 | Spearman |
| Contínuas | INSE_ALUNO, NU_TIPO_NIVEL_INSE | mantidas numéricas | Pearson + Spearman |

### Limpeza de respostas inválidas
- Caracteres `.`, `*`, ` `, `F` → NA
- Justificativa: evita atribuir valores numéricos a "não sei/não quero responder"

## PASSO 2: Correlações

### Detecção de variáveis degeneradas
- `nearZeroVar` do pacote `caret`
- Critério: >95% dos valores em uma única categoria
- Justificativa: sem variância, não há poder explicativo

### Método de correlação por tipo
- **Spearman** para ordinais/nominais: não assume linearidade
- **Pearson** para contínuas: assume linearidade e normalidade

### Filtragem
- Limiar |r| >= 0.30 (Cohen 1988: efeito pequeno a moderado)
- Autoescalamento (z-score) para comparabilidade

### Paradoxo correlação x degeneração
- Variável degenerada ≠ variável com correlação baixa
- Degeneração: falta de variância (impossível calcular)
- Correlação baixa: variância existe, mas sem associação

## PASSO 3: Dashboard

- Substitui geração de PNGs estáticos
- Permite interação da banca com os dados
- Reta OLS + intervalo de confiança visual

## PASSO 4: Agregação por Escola

- Transforma dados de aluno (173k) em escola (2.3k)
- Cria classificações: tipo, localização, faixas de proficiência
- INSE médio por escola como proxy socioeconômico

## PASSO 5: Comparações entre Grupos

### Teste de Wilcoxon
- Não-paramétrico: não assume normalidade
- Robusto para dados de proficiência (podem ser assimétricos)

### Tamanho de efeito: rank-biserial r
- 0.0-0.1: negligenciável
- 0.1-0.3: pequeno
- 0.3-0.5: médio
- >0.5: grande

### Comparações realizadas
1. Pública vs Privada
2. Urbana vs Rural
3. Capital vs Interior
4. Alto INSE vs Baixo INSE

## PASSO 7: Clustering

### Método: Ward.D2
- Minimiza variância intra-cluster
- Distância euclidiana
- z-score para evitar dominância de escala

### Perspectivas
- MT + INSE (2D)
- LP + INSE (2D)
- MT + LP + INSE (3D)

### Colorização
- Azul: Pública
- Vermelho: Privada

## PASSO 8: Regressão Linear Múltipla

### Variáveis dummy
- TIPO_ESCOLA: referência = Pública
- AREA: referência = Capital
- LOCALIZACAO: referência = Urbana

### Normalização
- INSE padronizado (z-score) para comparabilidade

### Diagnósticos
- R² ajustado: proporção de variância explicada
- RMSE: erro médio de previsão
- VIF: multicolinearidade (<5 aceitável, >10 severo)
- Shapiro-Wilk: normalidade dos resíduos
- Breusch-Pagan: homocedasticidade

## PASSO 9: Regressão com Itens Brutos

### Motivação
- Fase 8 usa INSE agregado (sintético)
- Fase 9 usa itens brutos para exploração
- Permite identificar dimensões específicas

### Controle de multicolinearidade
- VIF iterativo com limiar 10
- Remove variável com maior VIF até todos < limiar

### Comparação Fase 8 vs Fase 9
| Aspecto | Fase 8 (INSE) | Fase 9 (Itens) |
|---------|---------------|----------------|
| Preditores | 4 | ~150 |
| Interpretabilidade | Alta | Complexa |
| Multicolinearidade | Nenhuma | Severa → VIF |
| Uso | Modelagem final | Exploração |

## PASSO 10: Análise Espacial (Mapas Coropléticos)

### Objetivo
Visualizar padrões geográficos de proficiência e INSE por município de MG.

### Metodologia
1. Integra `metadados_escolas` com `TS_ESCOLA.csv` via `ID_ESCOLA` para obter `ID_MUNICIPIO`
2. Agrega proficiência e INSE por município
3. Download do shapefile de MG via `geobr::read_municipality(code_muni = "MG")`
4. Gera mapas coropléticos com `tmap` (5 quantis)

### Justificativa
- Identifica padrões regionais não visíveis em análise agregada
- Revela desigualdades intraestaduais
- Complementa análise de grupos com perspectiva geográfica

## PASSO 11: Modelos Hierárquicos Lineares (HLM)

### Objetivo
Considerar estrutura aninhada dos dados (alunos dentro de escolas).

### Metodologia
1. **Modelo Nulo**: Intercepto aleatório por escola → calcula ICC
2. **Modelo 1**: INSE_ALUNO como preditor fixo + intercepto aleatório
3. **Modelo 2**: INSE individual + INSE médio da escola
4. Comparação via Likelihood Ratio Test (ANOVA)
5. R² marginal (efeitos fixos) e condicional (fixos + aleatórios)

### ICC (Coeficiente de Correlação Intraclasse)
- ICC > 20%: estrutura hierárquica forte — HLM necessário
- ICC 10-20%: moderado — HLM recomendado
- ICC < 10%: estrutura hierárquica fraca

### Justificativa
- Dados educacionais são inerentemente hierárquicos
- Ignorar estrutura aninhada viola pressuposto de independência
- Permite separar variância entre e dentro de escolas

## PASSO 12: Análise de Mediação

### Objetivo
Testar se INSE media o efeito de variáveis de contexto sobre a proficiência.

### Metodologia
1. **Caminho A**: Variável independente → INSE (mediador)
2. **Caminho B + C'**: INSE + variável independente → Proficiência
3. **Efeito indireto** (A × B): bootstrap com 1000 simulações
4. **Proporção mediada**: |indireto| / |total| × 100

### Análises
- TIPO_ESCOLA → INSE → Proficiência (MT e LP)
- LOCALIZACAO → INSE → Proficiência (MT e LP)

### Justificativa
- Responde: "Escolas privadas têm melhor desempenho PORQUE têm INSE maior?"
- Separa efeito direto (tipo de escola) do efeito indireto (via INSE)
- Informa políticas públicas: focar em INSE reduz diferença?

## PASSO 13: Validação Cruzada + Curva ROC

### Objetivo
Avaliar qualidade preditiva dos modelos e capacidade de classificação.

### Metodologia

#### Validação Cruzada (Regressão)
- 10-fold CV estratificado por tipo de escola
- Métricas: RMSE, MAE, R² por fold
- Média e desvio padrão das métricas

#### Curva ROC (Classificação)
- Define "alto desempenho" como top 25% de proficiência
- Modelo logístico com preditores: INSE, TIPO_ESCOLA, LOCALIZACAO, AREA
- AUC com IC 95% (bootstrap)

### Interpretação do AUC
- AUC > 0.8: excelente discriminação
- AUC 0.7-0.8: boa discriminação
- AUC 0.6-0.7: discriminação moderada
- AUC < 0.6: discriminação fraca

### Justificativa
- Testa robustez e generalização dos modelos
- Evita overfitting
- Quantifica capacidade de prever "alto desempenho"

## PASSO 14: Análise de Resíduos Espaciais

### Objetivo
Testar autocorrelação espacial nos resíduos do modelo (Índice de Moran).

### Metodologia
1. Agrega resíduos por município (média dos resíduos das escolas)
2. Cria matriz de vizinhança (queen contiguity) via `poly2nb()`
3. Calcula Moran's I global para resíduos MT e LP
4. Calcula LISA (Local Indicators of Spatial Association)
5. Classifica municípios em quadrantes: Alto-Alto, Baixo-Baixo, Alto-Baixo, Baixo-Alto

### Interpretação
- Moran's I > 0 e p < 0.05: autocorrelação positiva (clusters espaciais)
- Moran's I ≈ 0: resíduos independentes (modelo adequado)
- Moran's I < 0: padrão alternado (raro em dados socioeconômicos)

### Justificativa
- Verifica pressuposto de independência dos resíduos
- Se autocorrelação presente: modelo precisa incluir termos espaciais
- Identifica clusters de municípios com desempenho similar

## PASSO 15: Índice Composto de Vulnerabilidade (PCA)

### Objetivo
Criar indicador próprio combinando variáveis socioeconômicas e de proficiência.

### Metodologia
1. Inverte variáveis (menor proficiência = maior vulnerabilidade)
2. Padroniza todas as variáveis (z-score)
3. Executa PCA com 5 componentes
4. Retém componentes até explicar ≥ 80% da variância
5. PC1 como índice composto (maior variância explicada)
6. Normaliza para escala 0-100
7. Classifica em 4 níveis: Muito Baixa, Baixa, Alta, Muito Alta

### Variáveis no PCA
- INV_MT: -MEDIA_MT (inverso da proficiência MT)
- INV_LP: -MEDIA_LP (inverso da proficiência LP)
- INV_INSE: -INSE_MEDIO (inverso do INSE)
- TIPO_PRIVADA: escola privada (0/1)
- LOCAL_RURAL: escola rural (0/1)

### Justificativa
- INSE é índice sintético do INEP, mas pode não capturar todas as dimensões
- Índice próprio permite combinar variáveis de forma transparente
- Útil para classificação de escolas por vulnerabilidade
- Informa políticas de intervenção direcionada
