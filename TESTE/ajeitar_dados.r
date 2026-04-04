# 1. Carregar a biblioteca necessária
library(tidyverse)

# Supondo que você já carregou sua base de dados e ela se chama 'dados_escola'

# Passo 1: Separar apenas as variáveis que nos interessam
dados_escola <- read.csv("C:/Users/Usuario/Desktop/tcc/MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM - Copia.csv")

dados_escola_limpos <- dados_escola %>%
  # -------------------------------------------------------------------------
  # FILTRO 1: TRATAR AS RESPOSTAS INVÁLIDAS (Branco, Nulo, etc)
  # A função 'across' aplica a regra em todas as colunas que começam com TX_RESP_Q
  # -------------------------------------------------------------------------
  mutate(across(starts_with("TX_RESP_Q"), ~ na_if(., "."))) %>%  # Transforma Branco em NA
  mutate(across(starts_with("TX_RESP_Q"), ~ na_if(., "*"))) %>%  # Transforma Nulo em NA
  mutate(across(starts_with("TX_RESP_Q"), ~ na_if(., " "))) %>%  # Transforma Espaço em NA
  # Se houver alguma opção "F" (Não sei responder), também tratamos como ausência de dados:
  mutate(across(starts_with("TX_RESP_Q"), ~ na_if(., "F"))) %>%  
  
  # -------------------------------------------------------------------------
  # FILTRO 2: TRANSFORMANDO LETRAS EM NÚMEROS (A=1, B=2, C=3...)
  # -------------------------------------------------------------------------
  mutate(across(starts_with("TX_RESP_Q"), ~ as.numeric(as.factor(.))))

# Salvar o resultado final limpo em um novo arquivo CSV (planilha)
write.csv(dados_escola_limpos, "C:/Users/Usuario/Desktop/tcc/TESTE/dados_escola_em_numeros.csv", row.names = FALSE)


# Opcional, mas recomendado:
# Ver como ficou a estrutura de uma coluna para ter certeza que funciou:
# table(dados_escola_limpos$TX_RESP_Q01, useNA = "always")