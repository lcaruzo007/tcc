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
