# 4. ANÁLISE DE REGRESSÃO LINEAR MÚLTIPLA

## 📋 Visão Geral

Esta seção implementa **Regressão Linear Múltipla com Variáveis Dummy** para modelar a proficiência das escolas (MT e LP) em função de características institucionais.

### Objetivo

Construir e validar modelos preditivos que explicam:
- **MEDIA_MT** (Matemática)
- **MEDIA_LP** (Leitura e Escrita)

Com base em preditores categóricos (tipo de escola, localização, área) e contínuos (INSE - Índice Socioeconômico).

---

## 📁 Estrutura de Pastas

> **Convenção de pastas datadas** (refatoração julho/2026):
> todos os outputs vão para `outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>`
> via helper `caminho_saida()` (`TESTE/DOCUMENTACAO/utils_saeb.r`).

```
4_REGRESSAO_LINEAR/
├── Scripts/
│   ├── regressao_linear_multipla.r                 [PRINCIPAL]
│   ├── grafico_coeficientes_referencia_oposta.r   [AUXILIAR — ref oposta Privada+Rural_Interior]
│   └── testes_pressupostos.r                      [COMPLEMENTAR — verifique se existe]
└── outputs/
    └── <YYYY-MM-DD>/             (uma pasta por dia de execução)
        ├── modelos/
        │   ├── modelo_MT_<HHMMSS>.rds
        │   └── modelo_LP_<HHMMSS>.rds
        ├── tabelas/
        │   ├── resumo_modelos_<HHMMSS>.csv
        │   ├── base_escolas_agregada_<HHMMSS>.csv
        │   ├── REFERENCIAS_MODELOS_<HHMMSS>.csv
        │   ├── VIF_multicolinearidade_<HHMMSS>.csv
        │   ├── coeficientes_MT_<HHMMSS>.csv / coeficientes_LP_<HHMMSS>.csv
        │   ├── comparacao_todas_referencias_MT_<HHMMSS>.csv
        │   ├── comparacao_todas_referencias_LP_<HHMMSS>.csv
        │   └── coeficientes_referencia_oposta_{MT,LP}_<HHMMSS>.csv   (script auxiliar)
        ├── diagnosticos/
        │   ├── diagnosticos_MT_<HHMMSS>.csv
        │   └── diagnosticos_LP_<HHMMSS>.csv
        └── figuras/
            ├── diagnosticos_residuos_MT_<HHMMSS>.png
            ├── diagnosticos_residuos_LP_<HHMMSS>.png
            ├── coeficientes_MT_<HHMMSS>.png / coeficientes_LP_<HHMMSS>.png
            ├── coeficientes_TCC_color_<HHMMSS>.png
            ├── coeficientes_TCC_PB_<HHMMSS>.png
            ├── preditos_vs_observados_MT_<HHMMSS>.png / _LP_*.png
            ├── resumo_qualidade_ajuste_<HHMMSS>.png
            └── coeficientes_TCC_{color,PB}_referencia_oposta_<HHMMSS>.png  (auxiliar)
```

---

## 🚀 Como Usar

### Pré-requisitos

1. **Dados brutos**: `MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv` disponível
   na raiz do projeto (o script gera `base_escolas_agregada_<ts>.csv`
   internamente). Não depende de `classificar_escolas.r`.
2. **Dependências R**:
   ```r
   install.packages(c("tidyverse", "broom", "patchwork", "car", "lmtest"))
   ```

### Passo 1: Ajuste do Modelo (Principal)

```r
# Abrir e executar em RStudio:
source("TESTE/4_REGRESSAO_LINEAR/Scripts/regressao_linear_multipla.r")
```

**O que faz**:
- ✓ Lê `TS_ALUNO_34EM.csv` e agrega por escola (`base_escolas_agregada_<ts>.csv`)
- ✓ Cria variáveis dummy automáticas com referências explícitas:
  - `TIPO_ESCOLA_Privada` (ref: **Publica**)
  - `AREA_LOCAL_*` (ref: **Urbana_Capital**) — variável combinada de 4 categorias
    (`Urbana_Capital`, `Urbana_Interior`, `Rural_Capital`, `Rural_Interior`)
- ✓ Padroniza (z-score) o INSE
- ✓ Ajusta 2 modelos de regressão (MT e LP) + 8 modelos com todas as
  referências (comparações simétricas)
- ✓ Gera tabelas de coeficientes, VIF, documentação de referências
- ✓ Cria gráficos de diagnóstico + gráfico TCC colorido e P&B
- ✓ Salva modelos em RDS para reutilização

### Passo 1b: Gráfico de Coeficientes com Referência Oposta (Auxiliar)

```r
source("TESTE/4_REGRESSAO_LINEAR/Scripts/grafico_coeficientes_referencia_oposta.r")
```

Reaproveita a `base_escolas_agregada_<ts>.csv` mais recente e reajusta os
modelos com a referência oposta (`TIPO_ESCOLA=Privada`,
`AREA_LOCAL=Rural_Interior`). Gera o mesmo gráfico TCC (colorido e P&B) sob
essa perspectiva. O ponto de quebra do eixo X é calculado dinamicamente a
partir dos ICs 95% dos coeficientes, evitando cortes visuais.

**Saídas geradas** (~20 arquivos, em `outputs/<YYYY-MM-DD>/<tipo>/`):
```
tabelas/
  ├── resumo_modelos_<HHMMSS>.csv
  ├── base_escolas_agregada_<HHMMSS>.csv
  ├── REFERENCIAS_MODELOS_<HHMMSS>.csv
  ├── VIF_multicolinearidade_<HHMMSS>.csv
  ├── coeficientes_MT_<HHMMSS>.csv / coeficientes_LP_<HHMMSS>.csv
  └── comparacao_todas_referencias_{MT,LP}_<HHMMSS>.csv
modelos/
  ├── modelo_MT_<HHMMSS>.rds
  └── modelo_LP_<HHMMSS>.rds
diagnosticos/
  ├── diagnosticos_MT_<HHMMSS>.csv
  └── diagnosticos_LP_<HHMMSS>.csv
figuras/
  ├── diagnosticos_residuos_MT_<HHMMSS>.png   [4 subplots cada]
  ├── diagnosticos_residuos_LP_<HHMMSS>.png
  ├── coeficientes_MT_<HHMMSS>.png / coeficientes_LP_<HHMMSS>.png
  ├── coeficientes_TCC_color_<HHMMSS>.png / coeficientes_TCC_PB_<HHMMSS>.png
  ├── preditos_vs_observados_MT_<HHMMSS>.png / _LP_*.png
  └── resumo_qualidade_ajuste_<HHMMSS>.png
```

### Passo 2: Validação de Pressupostos (Complementar)

```r
# Executar após o Passo 1:
source("TESTE/4_REGRESSAO_LINEAR/Scripts/testes_pressupostos.r")
```

**O que faz**:
- ✓ Teste Shapiro-Wilk (normalidade)
- ✓ Teste Breusch-Pagan (homocedasticidade)
- ✓ VIF (multicolinearidade)
- ✓ Durbin-Watson (independência)
- ✓ Cook's Distance (outliers influentes)

**Saídas geradas** (~6 arquivos):
```
outputs_diagnosticos/
  ├── resumo_testes_*.csv
  ├── vif_MT_*.csv
  └── vif_LP_*.csv

outputs_figuras/
  ├── multicolinearidade_VIF_*.png
  ├── outliers_cooks_MT_*.png
  └── outliers_cooks_LP_*.png
```

---

## 📊 Interpretação dos Resultados

### Arquivo: `coeficientes_MT_*.csv`

| Termo | Coeficiente | SE | t_value | p_valor | Sig | IC_95_inf | IC_95_sup |
|-------|-------------|-----|---------|---------|-----|-----------|-----------|
| (Intercept) | 275.34 | 2.15 | 128.07 | < 0.001 | *** | 271.12 | 279.56 |
| INSE_MEDIO_norm | 18.45 | 1.23 | 15.00 | < 0.001 | *** | 16.04 | 20.86 |
| TIPO_ESCOLA_Privada | 28.67 | 3.42 | 8.38 | < 0.001 | *** | 22.00 | 35.34 |
| AREA_Rural | -12.34 | 2.87 | -4.30 | < 0.001 | *** | -17.96 | -6.72 |
| LOCALIZACAO_Interior | -5.67 | 1.95 | -2.91 | 0.0036 | ** | -9.49 | -1.85 |

**Interpretação**:
- **Coeficiente**: Mudança esperada em MEDIA_MT para cada 1 unidade na variável preditora
  - Para `INSE_MEDIO_norm = 1` (1 desvio-padrão acima da média): aumento de 18.45 pontos
  - Para `TIPO_ESCOLA_Privada = 1`: aumento de 28.67 pontos (relativo à Pública)
- **Sig**: 
  - `***` (p < 0.001) = Altamente significativo
  - `**` (p < 0.01) = Significativo
  - `*` (p < 0.05) = Marginalmente significativo
- **IC 95%**: Intervalo de confiança do coeficiente

### Arquivo: `resumo_modelos_*.csv`

| Modelo | n_obs | n_param | R2_ajustado | RMSE | F_stat | AIC | BIC |
|--------|-------|---------|-------------|------|--------|-----|-----|
| MEDIA_MT | 1050 | 5 | 0.6234 | 15.42 | 340.67 | 6234.5 | 6262.1 |
| MEDIA_LP | 1050 | 5 | 0.5891 | 18.76 | 298.45 | 6845.2 | 6872.8 |

**Interpretação**:
- **R² ajustado**: Proporção de variância explicada (0.623 = 62.3% da variação em MT é explicada)
- **RMSE**: Erro padrão residual (em média, predições erram por ±15.42 pontos)
- **AIC/BIC**: Critérios de comparação entre modelos (menor é melhor)

### Gráficos: `diagnosticos_residuos_MT_*.png`

**Painel 1: Resíduos vs Fitted**
- Verifica se há padrões não-lineares ou heterocedasticidade
- Ideal: nuvem aleatória em torno da linha 0

**Painel 2: Q-Q Plot**
- Verifica normalidade dos resíduos
- Ideal: pontos sobre a linha diagonal

**Painel 3: Scale-Location**
- Verifica homocedasticidade (variância constante)
- Ideal: linha reta horizontal

**Painel 4: Histograma**
- Distribuição dos resíduos
- Ideal: forma aproximadamente normal

---

## 🔍 Testes de Pressupostos

### Normalidade (Shapiro-Wilk)

```
H₀: Os resíduos seguem distribuição normal
H₁: Os resíduos não seguem distribuição normal

Se p > 0.05: Não rejeita H₀ (bom!)
Se p < 0.05: Rejeita H₀ (violar normalidade)
```

### Homocedasticidade (Breusch-Pagan)

```
H₀: Variância dos resíduos é constante
H₁: Variância varia com os preditores

Se p > 0.05: Variância homogênea (bom!)
Se p < 0.05: Heterocedasticidade (usar robust SE)
```

### Multicolinearidade (VIF)

```
VIF = 1           → Sem correlação
1 < VIF < 5       → Aceitável
5 < VIF < 10      → Moderada (investigar)
VIF > 10          → Severa (remover preditores)
```

### Independência (Durbin-Watson)

```
DW ≈ 2            → Independência (ideal)
DW < 2            → Autocorrelação positiva
DW > 2            → Autocorrelação negativa

Intervalo aceitável: [1.5, 2.5]
```

---

## 📌 Configurações Personalizáveis

No arquivo `regressao_linear_multipla.r`, ajustar:

```r
# Variáveis categóricas a converter em dummy (refatoração julho/2026:
# AREA + LOCALIZACAO foram combinadas em AREA_LOCAL — 4 categorias)
VARS_CATEGORICAS <- c("TIPO_ESCOLA", "AREA_LOCAL")

# Variáveis contínuas (preditoras)
VARS_CONTINUAS <- c("INSE_MEDIO")

# Referências do modelo principal (passadas via criar_dummies_com_refs())
refs_modelo <- list(TIPO_ESCOLA = "Publica", AREA_LOCAL = "Urbana_Capital")

# Significância para estrelas
ALPHA <- 0.05
```

---

## ⚠️ Possíveis Problemas

| Problema | Causa | Solução |
|----------|-------|---------|
| "TS_ALUNO_34EM.csv não encontrado" | `MICRODADOS_SAEB_2023/DADOS/` fora da raiz | Verifique a detecção automática de `RAIZ` (`detectar_raiz()`) |
| VIF > 10 para várias variáveis | Multicolinearidade severa | Remover variáveis correlacionadas, usar PCA |
| p < 0.05 em Shapiro-Wilk | Resíduos não normais | Usar transformação (log, raiz) ou robust regression |
| p < 0.05 em Breusch-Pagan | Heterocedasticidade | Usar erros padrão robustos (sandwich) |
| Autocorrelação em Durbin-Watson | Dados ordenados no tempo | Usar modelos com estrutura de série temporal |

---

## 📚 Referências Técnicas

### Regressão Linear Múltipla

$$Y = \beta_0 + \beta_1 X_1 + \beta_2 X_2 + \cdots + \beta_p X_p + \epsilon$$

### Variáveis Dummy

Para variável categórica com $k$ categorias, criar $k-1$ dummies:
- Categoria 1 (referência): todas as dummies = 0
- Categoria 2: dummy 2 = 1, resto = 0
- etc.

---

## 🔄 Fluxo Completo

```mermaid
graph TD
    A["1. classificar_escolas.r"] -->|gera| B["metadados_escolas_*.csv"]
    B --> C["regressao_linear_multipla.r"]
    C -->|ajusta| D["Modelo MT"]
    C -->|ajusta| E["Modelo LP"]
    D --> F["Tabelas de Coeficientes"]
    E --> F
    F --> G["testes_pressupostos.r"]
    G -->|valida| H["Normalidade?"]
    G -->|valida| I["Homocedasticidade?"]
    G -->|valida| J["Multicolinearidade?"]
    H --> K["Resumo dos Pressupostos"]
    I --> K
    J --> K
```

---

## 📞 Suporte

Para erros ou dúvidas:
1. Verificar logs de execução no console
2. Conferir estrutura de pastas (`4_REGRESSAO_LINEAR/` deve estar em `TESTE/`)
3. Garantir que `TS_ALUNO_34EM.csv` está em `MICRODADOS_SAEB_2023/DADOS/`
4. Revisar pressupostos com `testes_pressupostos.r`

---

**Versão**: 2.1 (refatoração julho/2026 — pastas datadas, variável `AREA_LOCAL`, script auxiliar de referência oposta)
