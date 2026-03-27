# /***************************************************************************************/
# /*  INEP/Daeb-Diretoria de Avaliação da Educação Básica                                */ 
# /*                                   			                                         */
# /*  Coordenação-Geral de Medidas da Educação Básica (CGMEB)                            */
# /*-------------------------------------------------------------------------------------*/
# /*  PROGRAMA:                                                                          */
# /*               INPUT_R_TS_ALUNO_2EF                                                  */
# /*-------------------------------------------------------------------------------------*/
# /* DESCRICAO:     PROGRAMA PARA LEITURA DOS RESULTADOS DOS ALUNOS DO                   */
# /*                     2º ANO DO ENSINO FUNDAMENTAL DO SAEB 2023                       */
# /***************************************************************************************/
# /***************************************************************************************/
# /* Obs:                                                                                */
# /* 		                                                                                */
# /* Para abrir os microdados, é necessário salvar este programa e o arquivo             */
# /* TS_ALUNO_2EF.CSV no diretório C:\ do computador.	                                   */
# /*							                                                                 */ 
# /* Ao terminar esses procedimentos, execute o programa salvo utilizando                */
# /* as variáveis de interesse.                                                          */
# /***************************************************************************************/
# /*                                  ATEN??O                                            */ 
# /***************************************************************************************/
# /* Este programa abre a base de dados com os rótulos das variáveis de	                 */
# /* acordo com o dicionário de dados que compõe os microdados. Para abrir               */
# /* os dados sem os rótulos, basta importar diretamente no R, executando                */
# /* o programa apenas até a carga dos microdados.                                       */
# /* 							                                                                 */                                                         
# /***************************************************************************************/;
# 
# --------------------
# Instalação do pacote Data.Table
# (Se não estiver instalado 
# --------------------

 if(!require(data.table)) { install.packages('data.table') }
 if(!require(labelled)) { install.packages('labelled') }
 library(data.table)
 library(labelled)


#--------------------
# Caso deseje trocar o local do arquivo, edite a função setwd() a seguir
# informando o local do arquivo.
# Ex. Windows setwd("C:/temp")
#     Linux   setwd("/home")
#--------------------
setwd('C:/')


#------------------
# Carga dos microdados

TS_ALUNO_2EF <- fread('TS_ALUNO_2EF.csv', integer64 = 'character', sep = ';')

# O script a seguir formata os rótulos das variáveis
# Para formatar um item retire o caracter de comentário (#) no início na linha desejada 
# (Para retirar o caracter de comentário de várias linhas de uma só vez, selecione as linhas desejadas e tecle ctrl+shift+c)
#---------------------------


# TS_ALUNO_2EF$ID_REGIAO <- factor(TS_ALUNO_2EF$ID_REGIAO, levels = c(1, 2, 3, 4, 5), labels = c('Norte', 'Nordeste', 'Sudeste', 'Sul', 'Centro-Oeste'))
# TS_ALUNO_2EF$ID_UF <- factor(TS_ALUNO_2EF$ID_UF, levels = c(11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29, 31, 32, 33, 35, 41, 42, 43, 50, 51, 52, 53),
#                             labels = c('RO', 'AC', 'AM', 'RR', 'PA', 'AP', 'TO', 'MA', 'PI', 'CE', 'RN', 'PB', 'PE', 'AL', 'SE', 'BA', 'MG', 'ES', 'RJ', 'SP', 'PR', 'SC', 'RS', 'MS', 'MT', 'GO', 'DF'))
# TS_ALUNO_2EF$ID_AREA <- factor(TS_ALUNO_2EF$ID_AREA, levels = c(1, 2), labels = c('Capital', 'Interior'))
# TS_ALUNO_2EF$IN_PUBLICA <- factor(TS_ALUNO_2EF$IN_PUBLICA, levels = c(0, 1), labels = c('Privada', 'P?blica'))
# TS_ALUNO_2EF$ID_LOCALIZACAO <- factor(TS_ALUNO_2EF$ID_LOCALIZACAO, levels = c(1, 2), labels = c('Urbana', 'Rural'))
# TS_ALUNO_2EF$ID_SERIE <- factor(TS_ALUNO_2EF$ID_SERIE, levels = c(2), labels = c('2? Ano do Ensino Fundamental'))
# TS_ALUNO_2EF$IN_SITUACAO_CENSO <- factor(TS_ALUNO_2EF$IN_SITUACAO_CENSO, levels = c(0, 1), labels = c('N?o consistente', 'Consistente'))
# TS_ALUNO_2EF$IN_PREENCHIMENTO_LP <- factor(TS_ALUNO_2EF$IN_PREENCHIMENTO_LP, levels = c(0, 1), labels = c('Prova n?o preenchida', 'Prova preenchida'))
# TS_ALUNO_2EF$IN_PREENCHIMENTO_MT <- factor(TS_ALUNO_2EF$IN_PREENCHIMENTO_MT, levels = c(0, 1), labels = c('Prova n?o preenchida', 'Prova preenchida'))
# TS_ALUNO_2EF$IN_PRESENCA_LP <- factor(TS_ALUNO_2EF$IN_PRESENCA_LP, levels = c(0, 1), labels = c('Ausente', 'Presente'))
# TS_ALUNO_2EF$IN_PRESENCA_MT <- factor(TS_ALUNO_2EF$IN_PRESENCA_MT, levels = c(0, 1), labels = c('Ausente', 'Presente'))
# TS_ALUNO_2EF$CO_CONCEITO_Q1_LP <- factor(TS_ALUNO_2EF$CO_CONCEITO_Q1_LP, levels = c('A', 'B', 'E', 'F', 'G', '.', 'IP'), labels = c('Escrita ortogr?fica', 'Escrita alfab?tica', 'Escrita sil?bico-alfab?tica', 'Escrita sil?bica', 'Escrita incompreens?vel', 'Branco', 'Imagem com problema'))
# TS_ALUNO_2EF$CO_CONCEITO_Q2_LP <- factor(TS_ALUNO_2EF$CO_CONCEITO_Q2_LP, levels = c('A', 'B', 'E', 'F', 'G', '.', 'IP'), labels = c('Escrita ortogr?fica', 'Escrita alfab?tica', 'Escrita sil?bico-alfab?tica', 'Escrita sil?bica', 'Escrita incompreens?vel', 'Branco', 'Imagem com problema'))
# TS_ALUNO_2EF$CO_RESPOSTA_TEXTO <- factor(TS_ALUNO_2EF$CO_RESPOSTA_TEXTO, levels = c('BR', 'NL', 'TX'), labels = c('Branco', 'Nulo', 'Texto'))
# TS_ALUNO_2EF$CO_CONCEITO_SEQUENCIA <- factor(TS_ALUNO_2EF$CO_CONCEITO_SEQUENCIA, levels = c('A', 'B', 'C', '.', '*'), labels = c('A', 'B', 'C', 'Branco', 'Nulo'))
# TS_ALUNO_2EF$CO_CONCEITO_COESAO <- factor(TS_ALUNO_2EF$CO_CONCEITO_COESAO, levels = c('A', 'B', 'C', '.', '*'), labels = c('A', 'B', 'C', 'Branco', 'Nulo'))
# TS_ALUNO_2EF$CO_CONCEITO_PONTUACAO <- factor(TS_ALUNO_2EF$CO_CONCEITO_PONTUACAO, levels = c('A', 'B', 'C', '.', '*'), labels = c('A', 'B', 'C', 'Branco', 'Nulo'))
# TS_ALUNO_2EF$CO_CONCEITO_SEGMENTACAO <- factor(TS_ALUNO_2EF$CO_CONCEITO_SEGMENTACAO, levels = c('A', 'B', 'C', '.', '*'), labels = c('A', 'B', 'C', 'Branco', 'Nulo'))
# TS_ALUNO_2EF$CO_TEXTO_GRAFIA <- factor(TS_ALUNO_2EF$CO_TEXTO_GRAFIA, levels = c('A', 'B', 'C', '.', '*'), labels = c('A', 'B', 'C', 'Branco', 'Nulo'))
# TS_ALUNO_2EF$CO_CONCEITO_Q1_MT <- factor(TS_ALUNO_2EF$CO_CONCEITO_Q1_MT, levels = c(20, 21, 22, 23, 10, 11, 12, 13, 0, 7, NA), labels = c('Cr?dito completo', 'Cr?dito completo', 'Cr?dito completo', 'Cr?dito completo', 'Cr?dito parcial', 'Cr?dito parcial', 'Cr?dito parcial', 'Cr?dito parcial', 'Nenhum cr?dito', 'Erros de impressão ou digitaliza??o', 'Em branco'))
# TS_ALUNO_2EF$CO_CONCEITO_Q2_MT <- factor(TS_ALUNO_2EF$CO_CONCEITO_Q2_MT, levels = c(20, 21, 22, 23, 10, 11, 12, 13, 0, 7, NA), labels = c('Cr?dito completo', 'Cr?dito completo', 'Cr?dito completo', 'Cr?dito completo', 'Cr?dito parcial', 'Cr?dito parcial', 'Cr?dito parcial', 'Cr?dito parcial', 'Nenhum cr?dito', 'Erros de impressão ou digitaliza??o', 'Em branco'))
# TS_ALUNO_2EF$IN_PROFICIENCIA_LP <- factor(TS_ALUNO_2EF$IN_PROFICIENCIA_LP, levels = c(0, 1), labels = c('N?o', 'Sim'))
# TS_ALUNO_2EF$IN_PROFICIENCIA_MT <- factor(TS_ALUNO_2EF$IN_PROFICIENCIA_MT, levels = c(0, 1), labels = c('N?o', 'Sim'))
# TS_ALUNO_2EF$IN_AMOSTRA <- factor(TS_ALUNO_2EF$IN_AMOSTRA, levels = c(0, 1), labels = c('N?o', 'Sim'))
# TS_ALUNO_2EF$IN_ALFABETIZADO <- factor(TS_ALUNO_2EF$IN_ALFABETIZADO, levels = c(0, 1), labels = c('N?o', 'Sim'))

# Atribui os labels para as variáveis
labels <- list(
   ID_SAEB = 'Ano de aplicação do Saeb',
   ID_REGIAO = 'Código da Região',   
   ID_UF = 'Código da Unidade da Federação',
   ID_MUNICIPIO = 'Máscaras dos Códigos de Municípios (são Códigos fictícios)',
   ID_AREA = 'Àrea',
   ID_ESCOLA = 'Máscaras dos Códigos de Escola (são Códigos fictícios)',
   IN_PUBLICA = 'Indica se a escola é pública ou não',
   ID_LOCALIZACAO = 'Localização',
   ID_TURMA = 'Código da turma no Saeb',
   ID_SERIE = 'Ano Escolar',
   ID_ALUNO = 'Código do aluno no Saeb',
   IN_SITUACAO_CENSO = 'Indicador de consistência entre os dados da aplicação do Saeb 2023 com o Censo da Educa??o B?sica 2023 finalizado',
   IN_PREENCHIMENTO_LP = 'Indicador de preenchimento da prova de Língua Portuguesa',
   IN_PREENCHIMENTO_MT = 'Indicador de preenchimento da prova de Matemática',
   IN_PRESENCA_LP = 'Indicador de presença na prova de Língua Portuguesa',
   IN_PRESENCA_MT = 'Indicador de presença na prova de Matemática',
   ID_CADERNO_LP = 'N?mero do caderno de prova de Língua Portuguesa',
   ID_BLOCO_1_LP = 'Identificador do Bloco 1 de Língua Portuguesa',
   ID_BLOCO_2_LP = 'Identificador do Bloco 2 de Língua Portuguesa',
   NU_BLOCO_1_ABERTA_LP = 'Identificador do Bloco 1 de resposta construída em Língua Portuguesa',
   NU_BLOCO_2_ABERTA_LP = 'Identificador do Bloco 2 de resposta construída em Língua Portuguesa',
   ID_CADERNO_MT = 'Número de caderno de prova de Matemática',
   ID_BLOCO_1_MT = 'Identificador do Bloco 1 de Matemática',
   ID_BLOCO_2_MT = 'Identificador do Bloco 2 de Matemática',
   NU_BLOCO_1_ABERTA_MT = 'Identificador do Bloco 1 de resposta construída em Matemática',
   NU_BLOCO_2_ABERTA_MT = 'Identificador do Bloco 2 de resposta construída em Matemática',
   TX_RESP_BLOCO1_LP = 'Resposta do aluno ao Bloco 1 da Prova de Língua Portuguesa',
   TX_RESP_BLOCO2_LP = 'Resposta do aluno ao Bloco 2 da Prova de Língua Portuguesa',
   CO_CONCEITO_Q1_LP = 'Conceito obtido na questão 1 de resposta construída em Língua Portuguesa',
   CO_CONCEITO_Q2_LP = 'Conceito obtido na questão 2 de resposta construída em Língua Portuguesa',
   CO_RESPOSTA_TEXTO = 'Análise da produção Textual',
   CO_CONCEITO_SEQUENCIA = 'Conceito obtido para sequência narrativa na produção de texto em Língua Portuguesa',
   CO_CONCEITO_COESAO = 'Conceito obtido para coesão na produção de texto em Língua Portuguesa',
   CO_CONCEITO_PONTUACAO = 'Conceito obtido para pontuação na produção de texto em Língua Portuguesa',
   CO_CONCEITO_SEGMENTACAO = 'Conceito obtido para segmentação na produção de texto em Língua Portuguesa',
   CO_TEXTO_GRAFIA = 'Conceito obtido para grafia na produção de texto em Língua Portuguesa',
   TX_RESP_BLOCO1_MT = 'Resposta do aluno ao Bloco 1 da Prova de Matemática',
   TX_RESP_BLOCO2_MT = 'Resposta do aluno ao Bloco 2 da Prova de Matemática',
   CO_CONCEITO_Q1_MT = 'Conceito obtido na questão 1 de resposta construída em Matemática',
   CO_CONCEITO_Q2_MT = 'Conceito obtido na questão 2 de resposta construída em Matemática',
   IN_PROFICIENCIA_LP = 'Indicador para cálculo da proficiência (no mínimo três itens respondidos no caderno de prova de Língua Portuguesa)',
   IN_PROFICIENCIA_MT = 'Indicador para cálculo da proficiência (no mínimo três itens respondidos no caderno de prova de Matemática)',
   IN_AMOSTRA = 'Indicador de participação da amostra',
   ESTRATO = 'Descrição dos estratos',
   PESO_ALUNO_LP = 'Peso do aluno em Língua Portuguesa',
   IN_ALFABETIZADO = 'Indicador para o aluno classificado como alfabetizado em Língua Portuguesa, ou seja, aquele com PROFICIENCIA_LP_SAEB maior ou igual a 743',
   PROFICIENCIA_LP = 'proficiência do aluno em Língua Portuguesa calculada na escala única do SAEB, com m?dia = 0 e desvio = 1 na popula??o de refer?ncia',
   ERRO_PADRAO_LP = 'Erro padrão da proficiência em Língua Portuguesa',
   PROFICIENCIA_LP_SAEB = 'proficiência em Língua Portuguesa transformada na escala única do SAEB, com m?dia = 750, desvio = 50 (do SAEB/19)',
   ERRO_PADRAO_LP_SAEB = 'Erro padrão da proficiência transformada em Língua Portuguesa',
   PESO_ALUNO_MT = 'Peso do aluno em Matemática',
   PROFICIENCIA_MT = 'proficiência do aluno em Matemática calculada na escala única do SAEB, com m?dia = 0 e desvio = 1 na popula??o de refer?ncia',
   ERRO_PADRAO_MT = 'Erro padrão da proficiência em Matemática',
   PROFICIENCIA_MT_SAEB = 'proficiência do aluno em Matemática transformada na escala única do SAEB, com m?dia = 750, desvio = 50 (do SAEB/19)',
   ERRO_PADRAO_MT_SAEB = 'Erro padrão da proficiência transformada em Matemática'
 )

# Aplicando LABELS às colunas de TS_ALUNO_2EF (Se a variável existe, o label correspondente é atribuído)
for (var in names(labels)) {
  if (var %in% names(TS_ALUNO_2EF)) {
    attr(TS_ALUNO_2EF[[var]], "label") <- labels[[var]]
  }
}
