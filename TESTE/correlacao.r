# 1. Carregar pacotes
library(tidyverse)
library(caret)

# 2. Ler os dados numéricos já tratados
dados <- read.csv("C:/Users/Usuario/Desktop/tcc/TESTE/dados_escola_em_numeros.csv")

# 3. Definir as nossas Variáveis Dependentes (Y)
nota_MT <- "PROFICIENCIA_MT_SAEB"
nota_LP <- "PROFICIENCIA_LP_SAEB"

# Pegamos as duas notas e todas as perguntas do questionário
dados_filtrados <- dados %>%
  select(all_of(nota_MT), all_of(nota_LP), starts_with("TX_RESP_Q"))

# 4. REMOVER E IDENTIFICAR VARIÁVEIS DEGENERADAS (NEAR ZERO VARIANCE)
# Vai analisar a escola e jogar fora perguntas onde quase todos responderam igual
nzv <- nearZeroVar(dados_filtrados, saveMetrics = TRUE)

# -> IDENTIFICANDO AS DEGENERADAS (Para você citar no seu TCC/Paper)
variaveis_degeneradas <- rownames(nzv[nzv$nzv == TRUE, ])
print("--------------------------------------------------")
print(" VARIÁVEIS DEGENERADAS IDENTIFICADAS ")
print("--------------------------------------------------")
print(variaveis_degeneradas)

# Salvar a lista de degeneradas em um arquivo para você colocar nos anexos
write.csv(data.frame(Variavel_Degenerada = variaveis_degeneradas), "C:/Users/Usuario/Desktop/tcc/TESTE/variaveis_degeneradas.csv", row.names = FALSE)

# Filtrando os dados para manter apenas as que NÃO SÃO degeneradas
colunas_validas <- rownames(nzv[nzv$nzv == FALSE, ]) # Aviso: Adicionada a vírgula para pegar as linhas!
dados_sem_degeneradas <- dados_filtrados[, colunas_validas]

# 5. CALCULAR A MATRIZ DE CORRELAÇÃO (Entre -1 e 1)
# O "pairwise.complete.obs" ignora alunos que faltaram em uma das provas sem quebrar a conta
matriz_cor <- cor(dados_sem_degeneradas, use = "pairwise.complete.obs", method = "pearson")

# 6. AUTOESCALAMENTO (z-score: (x - media) / desvio)
# Coloca tudo na mesma balança
dados_escalados <- as.data.frame(scale(dados_sem_degeneradas))

# =========================================================================
# RESULTADO 1: MATEMÁTICA
# =========================================================================
cor_MT <- matriz_cor[, nota_MT]

print("--------------------------------------------------")
print(" TODAS AS CORRELAÇÕES - MATEMÁTICA (ORDENADAS)    ")
print("--------------------------------------------------")
# O 'sort' vai imprimir da menor (ou mais negativa) para a maior correlação
print(sort(cor_MT))

# RETIRAR AS COLUNAS COM CORRELAÇÃO PEQUENA (Matemática)
# (Baixamos o limiar para 0.30, pois a maior correlação para Matemática foi 0.32)
fortes_MT <- names(cor_MT[abs(cor_MT) >= 0.30])
dados_finais_MT <- dados_escalados[, fortes_MT, drop = FALSE] # <- drop=FALSE evita que vire vetor

print("--- VARIÁVEIS SELECIONADAS (MT >= 0.30) ---")
print(names(dados_finais_MT))


# =========================================================================
# RESULTADO 2: LÍNGUA PORTUGUESA
# =========================================================================
cor_LP <- matriz_cor[, nota_LP]

print("--------------------------------------------------")
print(" TODAS AS CORRELAÇÕES - PORTUGUÊS (ORDENADAS)     ")
print("--------------------------------------------------")
print(sort(cor_LP))

# RETIRAR AS COLUNAS COM CORRELAÇÃO PEQUENA (Português)
# (Baixamos o limiar para 0.30, pois a maior para Português foi 0.26)
fortes_LP <- names(cor_LP[abs(cor_LP) >= 0.30])
dados_finais_LP <- dados_escalados[, fortes_LP, drop = FALSE] # <- drop=FALSE evita que vire vetor

print("--- VARIÁVEIS SELECIONADAS (LP >= 0.30) ---")
print(names(dados_finais_LP))


# 7. EXPORTAÇÃO DOS DADOS FINAIS FILTRADOS!
# Estas planilhas conterão APENAS os alunos da escola e as perguntas (colunas)
# que provaram ter uma correlação forte com as notas, já padronizadas.
write.csv(dados_finais_MT, "C:/Users/Usuario/Desktop/tcc/TESTE/dados_FINAL_MT_Filtrado.csv", row.names = FALSE)
write.csv(dados_finais_LP, "C:/Users/Usuario/Desktop/tcc/TESTE/dados_FINAL_LP_Filtrado.csv", row.names = FALSE)

# =========================================================================
# 8. EXPORTAÇÃO DA TABELA GERAL E FILTRADA DE CORRELAÇÕES
# =========================================================================
# Criar um DataFrame com todas as correlações calculadas ANTES do corte
df_correlacoes_MT <- data.frame(Variavel = names(cor_MT), Correlacao_Matematica = as.numeric(cor_MT))
df_correlacoes_LP <- data.frame(Variavel = names(cor_LP), Correlacao_Portugues = as.numeric(cor_LP))

# Juntar Matemática e Português em uma tabela só
df_todas_correlacoes <- merge(df_correlacoes_MT, df_correlacoes_LP, by = "Variavel")

# Salvar a tabela com o valor exato da correlação de TODAS as variáveis
write.csv(df_todas_correlacoes, "C:/Users/Usuario/Desktop/tcc/TESTE/todas_correlacoes_calculadas.csv", row.names = FALSE)




# E AGORA: Tabelas APENAS com as variáveis que mantivemos
df_fortes_MT <- df_correlacoes_MT[abs(df_correlacoes_MT$Correlacao_Matematica) >= 0.30, ]
df_fortes_MT <- subset(df_fortes_MT, Variavel != nota_MT)
write.csv(df_fortes_MT, "C:/Users/Usuario/Desktop/tcc/TESTE/correlacoes_mantidas_MT.csv", row.names = FALSE)

df_fortes_LP <- df_correlacoes_LP[abs(df_correlacoes_LP$Correlacao_Portugues) >= 0.30, ]
df_fortes_LP <- subset(df_fortes_LP, Variavel != nota_LP)
write.csv(df_fortes_LP, "C:/Users/Usuario/Desktop/tcc/TESTE/correlacoes_mantidas_LP.csv", row.names = FALSE)
