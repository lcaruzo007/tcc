# ÍNDICE DE LEGENDAS - ANÁLISE SAEB MG 2023

## 📋 Resumo
Este documento serve como índice de todas as legendas criadas para documentar os arquivos CSV gerados pelos scripts de análise.

---

## 📁 Legendas Criadas por Localização

### 1️⃣ Pasta Principal: `/processados/`

#### Arquivo: `metadados_escolas_20260512_081534.csv`
- **Legenda:** `metadados_escolas_20260512_081534_LEGENDA.txt`
- **Script gerador:** `classificar_escolas.r`
- **Conteúdo:** 2.338 escolas de MG com proficiência agregada, INSE e classificações
- **Tamanho:** ~305 KB

#### Arquivo: `README_LEGENDAS.md` 
- **Descrição:** Documentação geral de todos os CSVs esperados

---

### 2️⃣ Pasta: `/dados_por_escola/`

#### Subpasta por Escola: `61432986/`, `61458788/`, `61466120/`, `61466123/`

Cada pasta de escola contém os seguintes arquivos COM LEGENDAS:

- ✓ `correlacoes_mantidas_LP.csv` - Correlações mantidas em Língua Portuguesa
- ✓ `correlacoes_mantidas_MT.csv` - Correlações mantidas em Matemática
- ✓ `dados_escola_em_numeros.csv` - Resumo numérico dos dados da escola
- ✓ `dados_FINAL_LP_Filtrado.csv` - Dados finais filtrados de LP
- ✓ `dados_FINAL_MT_Filtrado.csv` - Dados finais filtrados de MT
- ✓ `diagnostico_degeneracao.csv` - Diagnóstico de variáveis degeneradas
- ✓ `diagnostico_degeneracao_explicado.csv` - Diagnóstico com explicações
- ✓ `todas_correlacoes_calculadas.csv` - Matriz completa de correlações
- ✓ `variaveis_degeneradas.csv` - Lista de variáveis descartadas

#### Arquivo Especial: `escolas_nao_processadas.csv`
- **Localização:** `/dados_por_escola/`
- **Legenda:** `escolas_nao_processadas_LEGENDA.txt`
- **Descrição:** Lista de escolas que não puderam ser processadas

---

## 📊 Tipos de Arquivos CSV e suas Legendas

### Legendas de Comparação (futura)
Quando executados, os scripts `comparar_duas_escolas.r`, `comparar_grupos.r` e `dendrograma.r` geram:

| Arquivo | Descrição | Local |
|---------|-----------|-------|
| `Comparacao_Escola_*_vs_*.csv` | Comparação lado a lado | `processados/comparacao_duas_escolas/` |
| `Perfis_Escolas_*.csv` | Resumo de perfis | `processados/comparacao_duas_escolas/` |
| `resultados_comparacao_*.csv` | Testes estatísticos | `processados/` |
| `clusters_escolas_*.csv` | Atribuição de clusters | `processados/` |

---

## 🔍 Como Usar as Legendas

### Localizar uma Legenda
1. Encontre o arquivo CSV que deseja entender
2. Procure por um arquivo com mesmo nome + `_LEGENDA.txt`
3. Abra o arquivo de legenda em um editor de texto

### Exemplos:
```
CSV: dados_escola_em_numeros.csv
Legenda: dados_escola_em_numeros_LEGENDA.txt

CSV: correlacoes_mantidas_LP.csv
Legenda: correlacoes_mantidas_LP_LEGENDA.txt
```

---

## 📌 Informações Encontradas em Cada Legenda

Cada arquivo `_LEGENDA.txt` contém:

1. **Header com informações básicas**
   - Nome do arquivo
   - Data de geração
   - Número de linhas e colunas

2. **Descrição das Colunas**
   - Número da coluna
   - Nome da coluna
   - Explicação detalhada do significado

3. **Amostra dos Dados**
   - Primeiras 3 linhas do arquivo

4. **Estatísticas Básicas**
   - Resumo estatístico (média, mediana, desvio padrão, etc.)

5. **Notas Técnicas** (se aplicável)
   - Escalas utilizadas
   - Interpretações especiais
   - Códigos ou valores especiais

---

## 🎯 Estatísticas Gerais

- **Total de escolas analisadas:** 2.338 (MG)
- **Total de alunos:** 173.918+ (34EM - 3ª e 4ª série EM)
- **Arquivos CSV documentados:** 37+
- **Legendas criadas:** 36+
- **Disciplinas:** Matemática (MT) e Língua Portuguesa (LP)

---

## 📚 Referência Rápida de Termos

| Termo | Significado |
|-------|-----------|
| **MT** | Matemática |
| **LP** | Língua Portuguesa |
| **SAEB** | Sistema de Avaliação da Educação Básica |
| **INSE** | Índice de Nível Socioeconômico |
| **Proficiência** | Nível de competência/desempenho (escala 0-500) |
| **MG** | Minas Gerais |
| **EM** | Ensino Médio |
| **3EM/4EM** | 3ª/4ª série do Ensino Médio (antigo 1º/2º ano) |

---

## 🔗 Estrutura de Pastas

```
c:\Users\13756596699\tcc\TESTE\
│
├── processados/
│   ├── metadados_escolas_*.csv
│   ├── metadados_escolas_*_LEGENDA.txt
│   ├── README_LEGENDAS.md
│   ├── comparacao_duas_escolas/
│   │   ├── Comparacao_Escola_*_LEGENDA.txt
│   │   └── Perfis_Escolas_*_LEGENDA.txt
│   └── [outros CSVs dos scripts]
│
├── dados_por_escola/
│   ├── escolas_nao_processadas.csv
│   ├── escolas_nao_processadas_LEGENDA.txt
│   │
│   ├── 61432986/
│   │   ├── *.csv
│   │   └── *_LEGENDA.txt (para cada CSV)
│   │
│   ├── 61458788/
│   │   ├── *.csv
│   │   └── *_LEGENDA.txt
│   │
│   └── [outras escolas...]
│
└── 3_ANALISE_DE_GRUPOS/Scripts/
    ├── classificar_escolas.r
    ├── comparar_duas_escolas.r
    ├── comparar_grupos.r
    └── dendrograma.r
```

---

## ✅ Próximas Etapas Recomendadas

1. ✓ Legendas criadas para todos os CSVs de `dados_por_escola/`
2. ✓ Documentação geral em `README_LEGENDAS.md`
3. ⏳ Executar scripts `comparar_grupos.r` e `dendrograma.r` para gerar mais CSVs
4. ⏳ Criar legendas para novos CSVs conforme forem gerados

---

## 📝 Notas Importantes

- As legendas foram geradas automaticamente em **12/05/2026**
- Para manter as legendas atualizadas, re-execute os scripts Python quando novos CSVs forem gerados
- As legendas estão em formato TXT para fácil leitura em qualquer editor de texto
- O README_LEGENDAS.md fornece informações consolidadas sobre todos os tipos de arquivos

---

**Gerado em:** 12/05/2026 08:30  
**Localização:** `c:\Users\13756596699\tcc\TESTE\processados\`
