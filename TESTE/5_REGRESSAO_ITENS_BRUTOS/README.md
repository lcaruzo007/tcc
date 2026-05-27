# 📊 Fase 5 — Regressão Linear com Itens Brutos

**Objetivo:** Modelagem preditiva alternativa/complementar usando os **72 itens brutos do questionário socioeconômico** (transformados em ~169 variáveis dummy) em vez do INSE agregado.

---

## 🎯 Por que esta análise?

### Contexto

A Fase 4 (**regressao_linear_multipla.r**) modela a proficiência usando:
- **INSE_MEDIO** — Índice sintético calculado pelo INEP (score TRI agregado de 72 itens)
- 3 variáveis dummy de contexto (tipo escola, área, localização)

A Fase 5 substitui o INSE por seus itens brutos:
- **Todos os 72 itens** do questionário (TX_RESP_Q01 a TX_RESP_Q25)
- Cada item convertido em k-1 dummies (onde k = número de categorias)
- Total: ~169 preditores (exploração detalhada)

### Perguntas Respondidas

| Pergunta | Fase 4 | Fase 5 |
|----------|--------|--------|
| "A socioeconômia impacta proficiência?" | ✅ Sim (INSE significativo) | ✅ Sim (múltiplos itens significativos) |
| "Qual é o tamanho do efeito?" | ✅ Uma estimativa (β do INSE) | ⚠️ Complexo (múltiplas variáveis) |
| "**Qual dimensão específica impacta mais?**" | ❌ Não sabemos | ✅ Identifica top itens |
| "Educação dos pais vs bens domésticos?" | ❌ Agregado | ✅ Pode diferenciar |

---

## 📁 Estrutura de Pastas

```
5_REGRESSAO_ITENS_BRUTOS/
├── Scripts/
│   └── regressao_itens_brutos_dummy.r          [Script principal]
├── outputs_diagnosticos/
│   ├── vif_log_eliminacao_iterativa_*.txt      [Rastreamento VIF]
│   └── missing_report_itens_*.txt              [Valores faltantes]
├── outputs_tabelas/
│   ├── base_escolas_itens_*.csv                [Dados agregados]
│   ├── resumo_modelos_itens_*.csv              [R², RMSE, AIC, BIC]
│   ├── coeficientes_MT_itens_*.csv             [Coeficientes + IC]
│   └── coeficientes_LP_itens_*.csv
├── outputs_figuras/
│   ├── diagnosticos_residuos_MT_itens_*.png
│   ├── diagnosticos_residuos_LP_itens_*.png
│   ├── coeficientes_top_MT_itens_*.png         [Top 20 por |β|]
│   ├── coeficientes_top_LP_itens_*.png
│   ├── mapa_calor_vif_itens_*.png              [Multicolinearidade]
│   └── missings_por_item_*.png
└── README.md                                    [Este arquivo]
```

---

## 🚀 Como Usar

### Pré-requisito
- ✅ Fase 4 concluída (para referência de caminhos)
- ✅ TS_ALUNO_34EM.csv disponível em `MICRODADOS_SAEB_2023/DADOS/`
- ✅ Pacotes instalados (ver Fase 4: **4_REGRESSAO_LINEAR/04_REQUIREMENTS.md**)

### Execução

```r
# Abra o script em RStudio/VS Code e execute:
source("5_REGRESSAO_ITENS_BRUTOS/Scripts/regressao_itens_brutos_dummy.r")

# Ou na linha de comando R:
setwd("TESTE")
source("5_REGRESSAO_ITENS_BRUTOS/Scripts/regressao_itens_brutos_dummy.r")
```

### Tempo Esperado
- **Preparação (dummies + agregação):** ~2-3 min
- **VIF iterativo (eliminação):** ~5-10 min
- **Ajuste de 2 modelos (MT + LP):** ~1-2 min
- **Gerações de figuras:** ~3-5 min
- **Total:** ~15-20 min

---

## 📊 Saídas Principais

### Tabelas CSV

#### `resumo_modelos_itens_*.csv`
Diagnósticos gerais do ajuste (1 linha por disciplina):

| Coluna | Significado |
|--------|------------|
| `Disciplina` | MT ou LP |
| `Observacoes` | N de escolas |
| `Parametros` | k preditores mantidos após VIF |
| `R_quadrado` | Proporção da variância explicada |
| `RMSE` | Erro médio de previsão (pontos SAEB) |
| `AIC / BIC` | Critérios de informação (para comparação de modelos) |

**Interpretação:**
- Comparar R² Fase 4 vs Fase 5: "Quanto ganho ao desagregar INSE?"
- Se RMSE reduz significativamente → itens brutos têm poder preditivo adicional
- Se R² ≈ Fase 4 → INSE já captura a informação dos itens

#### `coeficientes_MT_itens_*.csv` / `_LP_*.csv`
Coeficientes de regressão estimados (1 linha por preditor):

| Coluna | Significado |
|--------|------------|
| `Preditor` | Nome da variável (ex: Q02_B, Q15c_C) |
| `Beta` | Efeito estimado em pontos SAEB |
| `EP` | Erro padrão do coeficiente |
| `t` | Estatística t de Student |
| `p_valor` | Significância estatística |
| `IC_inferior / IC_superior` | Intervalo de confiança 95% |
| `Significancia` | * p<0.05, ** p<0.01, *** p<0.001 |

**Interpretação:**
- **Exemplo:** Q02_B = +3.5 (p<0.05) → Escolas com +10% de alunos respondendo "B" na Q02 têm +0.35 pontos de proficiência média, mantendo outros itens constantes.
- Itens com β maior e significativos = dimensões que mais impactam
- Itens com β não-significativos podem ser removidos (Fase 6?)

#### `base_escolas_itens_*.csv`
Dados agregados por escola (1 linha por escola):

| Coluna | Significado |
|--------|------------|
| `ID_ESCOLA` | Identificador da escola |
| `MEDIA_MT / MEDIA_LP` | Proficiência média observada |
| `Q01_B, Q01_C, ...` | Proporção de alunos que respondeu cada categoria (0-1) |

**Use:** Para validação manual, ou re-modelagem com subconjuntos de escolas.

### Figuras PNG

#### `coeficientes_top_MT_itens_*.png` / `_LP_*.png`
**Gráfico:** Top 20 variáveis por |β| (magnitude do efeito)

**Interpretação:**
- Eixo X: Coeficiente estimado β
- Eixo Y: Nome da variável (itens mais impactantes no topo)
- Cores: Verde (efeito positivo), Vermelho (efeito negativo)
- Barras de erro: IC 95%
- **Leitura:** Que itens/categorias mais favorecem/prejudicam proficiência?

#### `mapa_calor_vif_itens_*.png`
**Gráfico:** Heatmap de correlações entre preditores mantidos após VIF

**Interpretação:**
- Células avermelhadas = alta correlação (VIF ainda presente)
- Células azuladas = baixa correlação (multicolinearidade reduzida)
- **Importante:** VIF iterativo reduz multicolinearidade, mas pode haver correlações residuais

#### `diagnosticos_residuos_MT_itens_*.png` / `_LP_*.png`
**Gráfico:** Painel 2×2 de diagnóstico (mesmo que Fase 4)

1. **Resíduos vs Ajustados** — Homocedasticidade?
2. **Q-Q Plot** — Normalidade dos resíduos?
3. **Scale-Location** — Variância homogênea?
4. **Histogram** — Distribuição de resíduos?

**Interpretação:** Ver **4_REGRESSAO_LINEAR/GUIA_RAPIDO.txt** (válido para Fase 5 também)

#### `missings_por_item_*.png`
**Gráfico:** Barplot de taxa de não-resposta por item

**Interpretação:**
- Itens com >20% de NA são automaticamente removidos
- Útil para identificar itens problemáticos (respostas faltantes)

---

## ⚠️ Multicolinearidade — VIF Iterativo

### O Problema
Com 72 itens medindo facetas do mesmo constructo latente (nível socioeconômico), há correlação muito alta entre preditores.

### Solução Implementada
**VIF Iterativo com Limiar:**

```
1. Ajusta modelo com todos os preditores
2. Calcula VIF para cada preditor
3. Se qualquer VIF > LIMIAR_VIF (padrão 10):
   - Remove preditor com maior VIF
   - Reajusta modelo
   - Repete até todos VIF ≤ LIMIAR
4. Registra processo em vif_log_eliminacao_iterativa_*.txt
```

### Saída do Log

```
[Iteracao 1] Removido: Q02_C (VIF=247.5)
[Iteracao 2] Removido: Q03_B (VIF=189.3)
...
[Iteracao 15] Concluído! Todos os preditores com VIF ≤ 10.0
Preditores mantidos: 154 de 169 (91% retidos)
```

### Interpretação
- Se muitos preditores removidos → correlação muito alta entre itens (esperado)
- Se poucos removidos → itens medem dimensões distintas
- Preditores finais são mais estáveis para inferência

---

## 📈 Comparação Fase 4 vs Fase 5

```
┌─────────────────┬──────────────────┬────────────────────────┐
│ Métrica         │ Fase 4 (INSE)    │ Fase 5 (Itens Brutos)  │
├─────────────────┼──────────────────┼────────────────────────┤
│ Preditores      │ 4 (INSE + 3 cat) │ ~154 (após VIF)         │
│ R²              │ Esperado: 0.40-0.60  │ Esperado: 0.45-0.70│
│ Interpretação   │ Fácil (1 índice) │ Complexa (múltiplos)   │
│ Multicolinarid. │ Nenhuma          │ Severa → VIF iterativo │
│ Uso             │ Modelagem final  │ Exploração detalhada   │
│ Tempo execução  │ ~2 min           │ ~15-20 min             │
│ N° de figuras   │ 4                │ 6                      │
└─────────────────┴──────────────────┴────────────────────────┘
```

---

## 🔍 Interpretação de Resultados

### Cenário 1: R² Fase 5 >> R² Fase 4
**Achado:** Desagregar itens brutos melhora ajuste significativamente
**Interpretação:** Itens específicos carregam informação não capturada pelo INSE agregado
**Recomendação:** Considerar usar itens brutos na redação final

### Cenário 2: R² Fase 5 ≈ R² Fase 4
**Achado:** Pouca melhora com desagregação
**Interpretação:** INSE já sintetiza bem a informação dos itens
**Recomendação:** Usar Fase 4 (mais parcimonioso)

### Cenário 3: Itens com β significativos específicos
**Achado:** Ex: Q02 (educação pais) significativa, Q05 (bens) não
**Interpretação:** Educação dos pais impacta mais que bens domésticos
**Recomendação:** Destacar essa dimensão na discussão do TCC

---

## 🛠️ Troubleshooting

### Erro: "VIF iterativo atingiu iteração máxima (100)"
- **Causa:** Multicolinearidade severa
- **Solução:** Aumentar `LIMIAR_VIF` de 10 para 15 ou 20 no script

### Muitos NAs em colunas de output
- **Causa:** Itens com respostas faltantes (> N_MISSING_PCT)
- **Solução:** Verificar `missings_por_item_*.png`; remover itens com >20% NA

### Figuras PNG em branco
- **Causa:** Top 20 coeficientes não foram calculados
- **Solução:** Verificar se modelos foram ajustados (ver console do R)

### R² muito baixo (<0.2)
- **Causa:** Variáveis socioeconômicas têm efeito limitado nesta amostra
- **Solução:** Verificar se amostra está filtrada corretamente; considerar interações entre variáveis

---

## 📚 Referências

- **INEP (2021).** Nota Técnica — Indicador de Nível Socioeconômico das Escolas de Educação Básica (INSE)
- **Fox & Weisberg (2019).** An R Companion to Applied Regression. 3ª edição. [Capítulo 7: Multicolinearidade]
- **James et al. (2013).** An Introduction to Statistical Learning. [Capítulo 3: Regressão Linear]

---

**Próximas etapas:** Após análise, considere:
- [ ] Criar modelo reduzido com top 10-15 itens mais significativos
- [ ] Testar interações (ex: educação pais × tipo escola)
- [ ] Comparar resultados Fase 4 vs Fase 5 na redação do TCC
- [ ] Usar insights para desagregar discussão de "impacto socioeconômico"

