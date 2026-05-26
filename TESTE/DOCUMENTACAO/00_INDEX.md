# 📚 Índice de Documentação — Análise SAEB 2023

**Última atualização:** 25 de Maio de 2026  
**Status:** ✅ Estrutura Completa com Regressão Linear Múltipla

---

## 🎯 Comece por aqui

### Para Iniciantes
1. **[01_COMECE_AQUI_PRIMEIRO.txt](01_COMECE_AQUI_PRIMEIRO.txt)** — Guia visual da estrutura  
   *Leia primeiro se está perdido. 5 minutos.*

2. **[02_GUIA_RAPIDO.txt](02_GUIA_RAPIDO.txt)** — Passo a passo executar análises  
   *Copie e cole os comandos. Pronto para rodar.*

### Para Executar os Scripts
3. **[03_ROTEIRO_EXECUCAO.txt](03_ROTEIRO_EXECUCAO.txt)** — Ordem e caminhos exactos  
   *Segue este arquivo. Inclui tempo estimado e saídas esperadas.*

4. **[04_REQUIREMENTS.md](04_REQUIREMENTS.md)** — Dependências e instalação  
   *Verifique suas dependências R antes de começar.*

### Para Entender a Metodologia
5. **[05_DOCUMENTACAO_PASSOS_TCC.txt](05_DOCUMENTACAO_PASSOS_TCC.txt)** — Detalhes técnicos  
   *Use para escrever a Metodologia do TCC.*

6. **[06_GUIA_INTERPRETAR_RESULTADOS.txt](06_GUIA_INTERPRETAR_RESULTADOS.txt)** — O que significam os outputs  
   *Explica cada coluna, cada gráfico, cada arquivo.*

10. **[10_RESUMO_ANALISE_GRUPOS.md](10_RESUMO_ANALISE_GRUPOS.md)** — O que cada script faz  
   *Explicação completa de `classificar_escolas.r`, `comparar_grupos.r`, `dendrograma_analise_completa.r`.*

### Para Análise de Regressão Linear (NOVO)
11. **[11_GUIA_REGRESSAO_LINEAR.md](../4_REGRESSAO_LINEAR/README.md)** — Regressão Linear Múltipla  
   *Modelagem preditiva com variáveis dummy. Includes pressupostos e diagnósticos.*

12. **[GUIA_RAPIDO_REGRESSAO.txt](../4_REGRESSAO_LINEAR/GUIA_RAPIDO.txt)** — Início rápido em regressão  
   *3 passos, exemplos, FAQs, checklist de qualidade do modelo.*

13. **[EXEMPLOS_INTERPRETACAO.txt](../4_REGRESSAO_LINEAR/EXEMPLOS_INTERPRETACAO.txt)** — Exemplos com interpretação  
   *7 exemplos reais com tabelas fictícias. Como ler cada resultado.*

### Referência Técnica
7. **[07_MAPA_ESTRUTURA_PASTAS.txt](07_MAPA_ESTRUTURA_PASTAS.txt)** — Estrutura visual completa  
   *Visual de todas as pastas e seu conteúdo.*

8. **[HISTORICO_MUDANCAS.md](HISTORICO_MUDANCAS.md)** — O que mudou e quando  
   *Rastreamento de alterações feitas na reorganização.*

9. **[09_DIARIO_DE_TCC.md](09_DIARIO_DE_TCC.md)** — Seu diário de desenvolvimento  
   *Registro de todas as sessões, atividades, desafios e resultados do TCC.*

---

## 📁 Estrutura de Uso Recomendado

```
Seu Primeira Vez?
│
├─→ 01_COMECE_AQUI_PRIMEIRO.txt
├─→ 02_GUIA_RAPIDO.txt
└─→ 04_REQUIREMENTS.md (instalar pacotes)

Quer Executar Agora?
│
├─→ 02_GUIA_RAPIDO.txt (copiar comandos)
└─→ 03_ROTEIRO_EXECUCAO.txt (detalhes)

Quer Entender Melhor?
│
├─→ 05_DOCUMENTACAO_PASSOS_TCC.txt
├─→ 06_GUIA_INTERPRETAR_RESULTADOS.txt
└─→ 07_MAPA_ESTRUTURA_PASTAS.txt

Algo Quebrou?
│
└─→ Procure em 06_GUIA_INTERPRETAR_RESULTADOS.txt
    seção "TROUBLESHOOTING"
```

---

## ⚡ Atalhos Frequentes

### "Como executo script X?"
→ Vá para **03_ROTEIRO_EXECUCAO.txt**

### "Quais pacotes preciso instalar?"
→ Vá para **04_REQUIREMENTS.md**

### "O que significa coluna Y no CSV?"
→ Vá para **06_GUIA_INTERPRETAR_RESULTADOS.txt**

### "Qual é a ordem correta?"
→ Vá para **02_GUIA_RAPIDO.txt** ou **03_ROTEIRO_EXECUCAO.txt**

### "Onde os dados saem?"
→ Vá para **07_MAPA_ESTRUTURA_PASTAS.txt**

---

## 📝 Legenda de Documentos

| Documento | Tipo | Para Quem? | Tempo |
|-----------|------|-----------|-------|
| 01_COMECE_AQUI | Guia | Primeiro acesso | 5 min |
| 02_GUIA_RAPIDO | Tutorial | Executar rápido | 2 min |
| 03_ROTEIRO_EXECUCAO | Referência | Detalhes de execução | 10 min |
| 04_REQUIREMENTS | Técnico | Setup de dependências | 5 min |
| 05_DOCUMENTACAO_PASSOS | Acadêmico | Escrever TCC | 30 min |
| 06_GUIA_INTERPRETAR | Referência | Entender outputs | 20 min |
| 07_MAPA_ESTRUTURA | Técnico | Estrutura de pastas | 5 min |
| 09_DIARIO_DE_TCC | Registro | Rastrear progresso | 10 min |
| 10_RESUMO_ANALISE_GRUPOS | Explicativo | Entender cada script | 15 min |
| HISTORICO_MUDANCAS | Referência | Saber o que mudou | 10 min |
| **4_REGRESSAO_LINEAR/README** | **Técnico** | **Metodologia de regressão** | **20 min** |
| **GUIA_RAPIDO_REGRESSAO** | **Tutorial** | **Executar regressão rápido** | **10 min** |
| **EXEMPLOS_INTERPRETACAO** | **Prático** | **Entender resultados** | **30 min** |

---

## 🎓 Estrutura de Pastas da Análise

```
TESTE/
├─ 1_LIMPEZA_E_TRANSFORMACAO/
│  └─ ajeitar_dados.r              ← PASSO 1
│
├─ 2_ANALISE_POR_ESCOLA/
│  └─ Scripts/
│     ├─ correlacao.r              ← PASSO 2
│     └─ graficos.r                ← PASSO 3 (opcional)
│
├─ 3_ANALISE_DE_GRUPOS/
│  └─ Scripts/
│     ├─ classificar_escolas.r      ← PASSO 4
│     ├─ comparar_grupos.r          ← PASSO 5
│     ├─ comparar_duas_escolas.r    ← PASSO 6 (opcional)
│     └─ dendrograma_analise_completa.r  ← PASSO 7
│
├─ 4_REGRESSAO_LINEAR/             ← NOVO
│  ├─ Scripts/
│  │  ├─ regressao_linear_multipla.r  ← PASSO 8
│  │  └─ testes_pressupostos.r        ← PASSO 9 (complementar)
│  ├─ outputs_modelos/              ← Modelos RDS
│  ├─ outputs_tabelas/              ← Resultados CSV
│  ├─ outputs_diagnosticos/         ← Testes de pressupostos
│  ├─ outputs_figuras/              ← Gráficos PNG
│  ├─ README.md                     ← Documentação técnica
│  ├─ GUIA_RAPIDO.txt               ← Guia prático
│  └─ EXEMPLOS_INTERPRETACAO.txt    ← Exemplos detalhados
│
├─ DOCUMENTACAO/
│  ├─ 00_INDEX.md                  ← Você está aqui
│  ├─ 01_COMECE_AQUI_PRIMEIRO.txt
│  ├─ 02_GUIA_RAPIDO.txt
│  ├─ 03_ROTEIRO_EXECUCAO.txt
│  ├─ 04_REQUIREMENTS.md
│  ├─ 05_DOCUMENTACAO_PASSOS_TCC.txt
│  ├─ 06_GUIA_INTERPRETAR_RESULTADOS.txt
│  ├─ 07_MAPA_ESTRUTURA_PASTAS.txt
│  ├─ 09_DIARIO_DE_TCC.md
│  ├─ 10_RESUMO_ANALISE_GRUPOS.md
│  ├─ HISTORICO_MUDANCAS.md
│  └─ utils_saeb.r                 ← Funções compartilhadas
│
├─ dados_por_escola/               ← OUTPUTS (gerado por scripts)
├─ processados/                    ← OUTPUTS (gerado por scripts)
└─ COMECE_AQUI.txt                 ← Guia rápido na raiz
```

---

## 🚀 Guia de Início Rápido (30 segundos)

1. **Primeira vez?**  
   Leia: `01_COMECE_AQUI_PRIMEIRO.txt`

2. **Quer executar agora?**  
   Copie comandos de: `02_GUIA_RAPIDO.txt`

3. **Pacotes instalados?**  
   Verifique: `04_REQUIREMENTS.md`

4. **Quer detalhes?**  
   Vá para: `03_ROTEIRO_EXECUCAO.txt`

5. **Quer fazer regressão linear?**  
   Vá para: `4_REGRESSAO_LINEAR/GUIA_RAPIDO.txt`

---

## 💡 Dicas

- **Todos os caminhos usam `/` (não `\`)**  
  Exemplo: `C:/Users/Usuario/Desktop/tcc/TESTE/...`

- **Scripts precisam rodar em ordem**  
  PASSO 1 → PASSO 2 → PASSO 4 → PASSO 5 → PASSO 7  
  (3 e 6 são opcionais)

- **Dados saem automaticamente**  
  Em `dados_por_escola/` e `processados/`

- **Altere configurações no INÍCIO dos scripts**  
  Antes de fazer `source()`

---

## 📞 Contato & Suporte

- **Erro ao executar?**  
  Veja "TROUBLESHOOTING" em `06_GUIA_INTERPRETAR_RESULTADOS.txt`

- **Arquivo não encontrado?**  
  Verifique o caminho em `07_MAPA_ESTRUTURA_PASTAS.txt`

- **Pacotes faltando?**  
  Execute comandos em `04_REQUIREMENTS.md`

---

**Última atualização:** 25/05/2026  
**Versão:** 1.1 (Incluida Seção 4: Regressão Linear Múltipla)

