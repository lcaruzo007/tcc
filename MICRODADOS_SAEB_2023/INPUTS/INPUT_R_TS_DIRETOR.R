a# /***************************************************************************************/
# /*  INEP/Daeb-Diretoria de Avaliação da Educação Básica                                */ 
# /*                                   			                                             */
# /*  Coordenação-Geral de Medidas da Educação Básica (CGMEB)                            */
# /*-------------------------------------------------------------------------------------*/
# /*  PROGRAMA:                                                                          */
# /*               INPUT_R_TS_DIRETOR                                                    */
# /*-------------------------------------------------------------------------------------*/
# /*  DESCRICAO:   PROGRAMA PARA LEITURA DO QUESTIONÁRIO DO DIRETOR DO SAEB 2023         */
# /*                                                                                     */
# /***************************************************************************************/
# /* Obs:                                                                                */
# /* 		                                                                                 */
# /* Para abrir os microdados, é necessário salvar este programa e o arquivo             */
# /* TS_DIRETOR.CSV no diretório C:\ do computador.	                                     */
# /*							                                                                       */ 
# /* Ao terminar esses procedimentos, execute o programa salvo utilizando                */
# /* as variáveis de interesse.                                                          */
# /***************************************************************************************/
# /*                                  ATENÇÃO                                            */ 
# /***************************************************************************************/
# /* Este programa abre a base de dados com os rótulos das variáveis de	                 */
# /* acordo com o dicionário de dados que compõe os microdados. Para abrir               */
# /* os dados sem os rótulos, basta importar diretamente no R, executando                */
# /* o programa apenas até a carga dos microdados.                                       */
# /* 							                                                                       */                                                         
# /***************************************************************************************/;
# 
# --------------------
# Intalação do pacote Data.Table
# (Se não estiver instalado 
# --------------------
if(!require(data.table)){install.packages('data.table')}

#--------------------
# Caso deseje trocar o local do arquivo, edite a função setwd() a seguir
# informando o local do arquivo.
# Ex. Windows setwd("C:/temp")
#     Linux   setwd("/home")
#--------------------
setwd('C:\\') 

#------------------
# Carga dos microdados

TS_DIRETOR <- data.table::fread(input='TS_DIRETOR.csv',integer64='character')

# A script a seguir formata os rótulos das variáveis
# Para formatar um item retire o caracter de comentário (#) no início na linha desejada 
# (Para retirar o caracter de comentário de várias linhas de uma só vez, selecione as linhas desejadas e tecle ctrl+shift+c)
#---------------------------

# TS_DIRETOR$ID_REGIAO <- factor(TS_DIRETOR$ID_REGIAO, levels = c(1,2,3,4,5),
#                                labels = c('Norte', 'Nordeste', 'Sudeste', 'Sul', 'Centro-Oeste'))
# 
# TS_DIRETOR$ID_UF <- factor(TS_DIRETOR$ID_UF, levels = c(11,12,13,14,15,16,17,21,22,23,24,25,26,27,28,29,31,32,33,35,41,42,43,50,51,52,53),
#                            labels = c('RO', 'AC', 'AM', 'RR', 'PA', 'AP', 'TO', 'MA', 'PI', 'CE', 'RN', 'PB', 'PE', 'AL', 'SE', 'BA', 'MG', 'ES', 'RJ', 'SP', 'PR', 'SC', 'RS', 'MS', 'MT', 'GO', 'DF'))
# 
# TS_DIRETOR$ID_AREA <- factor(TS_DIRETOR$ID_AREA, levels = c(1,2),
#                              labels = c('Capital', 'Interior'))
# 
# TS_DIRETOR$IN_PUBLICA <- factor(TS_DIRETOR$IN_PUBLICA, levels = c(0,1),
#                                 labels = c('Não pública', 'Pública'))
# 
# TS_DIRETOR$ID_LOCALIZACAO <- factor(TS_DIRETOR$ID_LOCALIZACAO, levels = c(1,2),
#                                     labels = c('Urbana', 'Rural'))
# 
# TS_DIRETOR$IN_PREENCHIMENTO_QUESTIONARIO <- factor(TS_DIRETOR$IN_PREENCHIMENTO_QUESTIONARIO, levels = c(0,1),
#                                                    labels = c('Não preenchido', 'Preenchido parcial ou totalmente'))
# 
# TS_DIRETOR$ID_SERIE <- factor(TS_DIRETOR$ID_SERIE, levels = c(2,5,9,12,13),
#                               labels = c('2º ano do Ensino Fundamental', '5º ano do Ensino Fundamental', '9º ano do Ensino Fundamental', '3ª/4ª séries do Ensino Médio Tradicional', '3ª/4ª séries do Ensino Médio Integrado'))
# 
# TS_DIRETOR$TX_Q001 <- factor(TS_DIRETOR$TX_Q001, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q002 <- factor(TS_DIRETOR$TX_Q002, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q003 <- factor(TS_DIRETOR$TX_Q003, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q004 <- factor(TS_DIRETOR$TX_Q004, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q005 <- factor(TS_DIRETOR$TX_Q005, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q006 <- factor(TS_DIRETOR$TX_Q006, levels = c('A', 'B'),
#                              labels = c('Pública', 'Privada'))
# 
# TS_DIRETOR$TX_Q007 <- factor(TS_DIRETOR$TX_Q007, levels = c('A', 'B', 'C'),
#                              labels = c('Masculino', 'Feminino', 'Não quero declarar'))
# 
# TS_DIRETOR$TX_Q009 <- factor(TS_DIRETOR$TX_Q009, levels = c('A', 'B', 'C', 'D', 'E', 'F'),
#                              labels = c('Branca', 'Preta', 'Parda', 'Amarela', 'Indígena', 'Não quero declarar'))
# 
# TS_DIRETOR$TX_Q010 <- factor(TS_DIRETOR$TX_Q010, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q011 <- factor(TS_DIRETOR$TX_Q011, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q012 <- factor(TS_DIRETOR$TX_Q012, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q013 <- factor(TS_DIRETOR$TX_Q013, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q014 <- factor(TS_DIRETOR$TX_Q014, levels = c('A', 'B', 'C', 'D', 'E', 'F'),
#                              labels = c('Ensino Fundamental', 'Ensino Médio', 'Graduação', 'Especialização', 'Mestrado', 'Doutorado'))
# 
# TS_DIRETOR$TX_Q025 <- factor(TS_DIRETOR$TX_Q025, levels = c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'),
#                              labels = c('Até R$ 1.320,00', 'De R$ 1.320,01 até R$ 2.640,00', 'De R$ 2.640,01 até R$ 3.960,00', 'De R$ 3.960,01 até R$ 5.280,00', 'De R$ 5.280,01 até R$ 6.600,00', 'De R$ 6.600,01 até R$ 7.920,00', 'De R$ 7.920,01 até R$ 9.240,00', 'Acima de R$ 9.240,00'))
# 
# TS_DIRETOR$TX_Q026 <- factor(TS_DIRETOR$TX_Q026, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q027 <- factor(TS_DIRETOR$TX_Q027, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
#
# TS_DIRETOR$TX_Q028 <- factor(TS_DIRETOR$TX_Q028, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q029 <- factor(TS_DIRETOR$TX_Q029, levels = c('A','B','C','D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
#
# TS_DIRETOR$TX_Q030 <- factor(TS_DIRETOR$TX_Q030, levels = c('A','B','C','D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
#
# TS_DIRETOR$TX_Q031 <- factor(TS_DIRETOR$TX_Q031, levels = c('A','B','C','D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
#
# TS_DIRETOR$TX_Q032 <- factor(TS_DIRETOR$TX_Q032, levels = c('A','B','C','D','E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
#
# TS_DIRETOR$TX_Q033 <- factor(TS_DIRETOR$TX_Q033, levels = c('A','B','C','D','E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
#
# TS_DIRETOR$TX_Q034 <- factor(TS_DIRETOR$TX_Q034, levels = c('A','B','C','D','E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
#
# TS_DIRETOR$TX_Q035 <- factor(TS_DIRETOR$TX_Q035, levels = c('A','B','C','D','E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
#
# TS_DIRETOR$TX_Q036 <- factor(TS_DIRETOR$TX_Q036, levels = c('A','B','C','D','E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', '
#
# TS_DIRETOR$TX_Q037 <- factor(TS_DIRETOR$TX_Q037, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q038 <- factor(TS_DIRETOR$TX_Q038, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q039 <- factor(TS_DIRETOR$TX_Q039, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q040 <- factor(TS_DIRETOR$TX_Q040, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q041 <- factor(TS_DIRETOR$TX_Q041, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q042 <- factor(TS_DIRETOR$TX_Q042, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q043 <- factor(TS_DIRETOR$TX_Q043, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q044 <- factor(TS_DIRETOR$TX_Q044, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q045 <- factor(TS_DIRETOR$TX_Q045, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q046 <- factor(TS_DIRETOR$TX_Q046, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q047 <- factor(TS_DIRETOR$TX_Q047, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q048 <- factor(TS_DIRETOR$TX_Q048, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q049 <- factor(TS_DIRETOR$TX_Q049, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q050 <- factor(TS_DIRETOR$TX_Q050, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q051 <- factor(TS_DIRETOR$TX_Q051, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q052 <- factor(TS_DIRETOR$TX_Q052, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q053 <- factor(TS_DIRETOR$TX_Q053, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não tem', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q054 <- factor(TS_DIRETOR$TX_Q054, levels = c('A', 'B', 'C'),
#                              labels = c('A escola não oferece Ensino Fundamental e/ou Médio',
#                                         'Os(As) alunos(as) da Educação Infantil utilizam a área externa em horário diferenciado',
#                                         'Os(As) alunos(as) da Educação Infantil utilizam a área externa no mesmo horário'))
# 
# TS_DIRETOR$TX_Q055 <- factor(TS_DIRETOR$TX_Q055, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q056 <- factor(TS_DIRETOR$TX_Q056, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q057 <- factor(TS_DIRETOR$TX_Q057, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q058 <- factor(TS_DIRETOR$TX_Q058, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q059 <- factor(TS_DIRETOR$TX_Q059, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q060 <- factor(TS_DIRETOR$TX_Q060, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q061 <- factor(TS_DIRETOR$TX_Q061, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q062 <- factor(TS_DIRETOR$TX_Q062, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q063 <- factor(TS_DIRETOR$TX_Q063, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q064 <- factor(TS_DIRETOR$TX_Q064, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q065 <- factor(TS_DIRETOR$TX_Q065, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q066 <- factor(TS_DIRETOR$TX_Q066, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
#                                                            
# TS_DIRETOR$TX_Q067 <- factor(TS_DIRETOR$TX_Q067, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q068 <- factor(TS_DIRETOR$TX_Q068, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q069 <- factor(TS_DIRETOR$TX_Q069, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q070 <- factor(TS_DIRETOR$TX_Q070, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q071 <- factor(TS_DIRETOR$TX_Q071, levels = c('A', 'B'),
#                              labels = c('Suficiente', 'Insuficiente'))
# 
# TS_DIRETOR$TX_Q072 <- factor(TS_DIRETOR$TX_Q072, levels = c('A', 'B'),
#                              labels = c('Suficiente', 'Insuficiente'))
# 
# TS_DIRETOR$TX_Q073 <- factor(TS_DIRETOR$TX_Q073, levels = c('A', 'B'),
#                              labels = c('Suficiente', 'Insuficiente'))
# 
# TS_DIRETOR$TX_Q074 <- factor(TS_DIRETOR$TX_Q074, levels = c('A', 'B'),
#                              labels = c('Suficiente', 'Insuficiente'))
# 
# TS_DIRETOR$TX_Q075 <- factor(TS_DIRETOR$TX_Q075, levels = c('A', 'B'),
#                              labels = c('Suficiente', 'Insuficiente'))
# 
# TS_DIRETOR$TX_Q076 <- factor(TS_DIRETOR$TX_Q076, levels = c('A', 'B'),
#                              labels = c('Suficiente', 'Insuficiente'))
# 
# TS_DIRETOR$TX_Q077 <- factor(TS_DIRETOR$TX_Q077, levels = c('A', 'B'),
#                              labels = c('Suficiente', 'Insuficiente'))
# 
# TS_DIRETOR$TX_Q078 <- factor(TS_DIRETOR$TX_Q078, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q079 <- factor(TS_DIRETOR$TX_Q079, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q080 <- factor(TS_DIRETOR$TX_Q080, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q081 <- factor(TS_DIRETOR$TX_Q081, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q082 <- factor(TS_DIRETOR$TX_Q082, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q083 <- factor(TS_DIRETOR$TX_Q083, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q084 <- factor(TS_DIRETOR$TX_Q084, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q085 <- factor(TS_DIRETOR$TX_Q085, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q086 <- factor(TS_DIRETOR$TX_Q086, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q087 <- factor(TS_DIRETOR$TX_Q087, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q088 <- factor(TS_DIRETOR$TX_Q088, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q091 <- factor(TS_DIRETOR$TX_Q091, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q092 <- factor(TS_DIRETOR$TX_Q092, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q093 <- factor(TS_DIRETOR$TX_Q093, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q094 <- factor(TS_DIRETOR$TX_Q094, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q095 <- factor(TS_DIRETOR$TX_Q095, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q096 <- factor(TS_DIRETOR$TX_Q096, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q097 <- factor(TS_DIRETOR$TX_Q097, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q098 <- factor(TS_DIRETOR$TX_Q098, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q099 <- factor(TS_DIRETOR$TX_Q099, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q100 <- factor(TS_DIRETOR$TX_Q100, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q101 <- factor(TS_DIRETOR$TX_Q101, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q102 <- factor(TS_DIRETOR$TX_Q102, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q103 <- factor(TS_DIRETOR$TX_Q103, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# 
# TS_DIRETOR$TX_Q104 <- factor(TS_DIRETOR$TX_Q104, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q105 <- factor(TS_DIRETOR$TX_Q105, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q106 <- factor(TS_DIRETOR$TX_Q106, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q107 <- factor(TS_DIRETOR$TX_Q107, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q108 <- factor(TS_DIRETOR$TX_Q108, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q109 <- factor(TS_DIRETOR$TX_Q109, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# 
# TS_DIRETOR$TX_Q110 <- factor(TS_DIRETOR$TX_Q110, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q112 <- factor(TS_DIRETOR$TX_Q112, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q115 <- factor(TS_DIRETOR$TX_Q115, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q117 <- factor(TS_DIRETOR$TX_Q117, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q118 <- factor(TS_DIRETOR$TX_Q118, levels = c('A', 'B'),
#                              labels = c('Ativo', 'Inativo'))
# 
# TS_DIRETOR$TX_Q119 <- factor(TS_DIRETOR$TX_Q119, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q120 <- factor(TS_DIRETOR$TX_Q120, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q121 <- factor(TS_DIRETOR$TX_Q121, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q122 <- factor(TS_DIRETOR$TX_Q122, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q123 <- factor(TS_DIRETOR$TX_Q123, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q124 <- factor(TS_DIRETOR$TX_Q124, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q125 <- factor(TS_DIRETOR$TX_Q125, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q126 <- factor(TS_DIRETOR$TX_Q126, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q127 <- factor(TS_DIRETOR$TX_Q127, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q128 <- factor(TS_DIRETOR$TX_Q128, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q129 <- factor(TS_DIRETOR$TX_Q129, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q130 <- factor(TS_DIRETOR$TX_Q130, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q131 <- factor(TS_DIRETOR$TX_Q131, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q132 <- factor(TS_DIRETOR$TX_Q132, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q133 <- factor(TS_DIRETOR$TX_Q133, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q134 <- factor(TS_DIRETOR$TX_Q134, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q135 <- factor(TS_DIRETOR$TX_Q135, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q136 <- factor(TS_DIRETOR$TX_Q136, levels = c('A', 'B', 'C'),
#                              labels = c('Aquisição pela escola', 'Doação', 'Solicitação às famílias'))
# 
# TS_DIRETOR$TX_Q137 <- factor(TS_DIRETOR$TX_Q137, levels = c('A', 'B', 'C'),
#                              labels = c('Aquisição pela escola', 'Doação', 'Solicitação às famílias'))
# 
# TS_DIRETOR$TX_Q138 <- factor(TS_DIRETOR$TX_Q138, levels = c('A', 'B', 'C'),
#                              labels = c('Aquisição pela escola', 'Doação', 'Solicitação às famílias'))
# 
# TS_DIRETOR$TX_Q139 <- factor(TS_DIRETOR$TX_Q139, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q140 <- factor(TS_DIRETOR$TX_Q140, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Uma vez', 'Duas vezes', 'Três vezes ou mais', 'Não se aplica'))
# 
# TS_DIRETOR$TX_Q141 <- factor(TS_DIRETOR$TX_Q141, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Uma vez', 'Duas vezes', 'Três vezes ou mais', 'Não se aplica'))
# 
# TS_DIRETOR$TX_Q142 <- factor(TS_DIRETOR$TX_Q142, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Uma vez', 'Duas vezes', 'Três vezes ou mais', 'Não se aplica'))
# 
# TS_DIRETOR$TX_Q143 <- factor(TS_DIRETOR$TX_Q143, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q144 <- factor(TS_DIRETOR$TX_Q144, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q145 <- factor(TS_DIRETOR$TX_Q145, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q146 <- factor(TS_DIRETOR$TX_Q146, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q147 <- factor(TS_DIRETOR$TX_Q147, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q148 <- factor(TS_DIRETOR$TX_Q148, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q149 <- factor(TS_DIRETOR$TX_Q149, levels = c('A', 'B', 'C', 'D'),
#                              labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# 
# TS_DIRETOR$TX_Q150 <- factor(TS_DIRETOR$TX_Q150, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q151 <- factor(TS_DIRETOR$TX_Q151, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q152 <- factor(TS_DIRETOR$TX_Q152, levels = c('A', 'B', 'C'),
#                              labels = c('Não', 'Sim', 'Não sei'))
# 
# TS_DIRETOR$TX_Q153 <- factor(TS_DIRETOR$TX_Q153, levels = c('A', 'B', 'C'),
#                              labels = c('Não', 'Sim', 'Não sei'))
# 
# TS_DIRETOR$TX_Q154 <- factor(TS_DIRETOR$TX_Q154, levels = c('A', 'B', 'C'),
#                              labels = c('Não', 'Sim', 'Não sei'))
# 
# TS_DIRETOR$TX_Q155 <- factor(TS_DIRETOR$TX_Q155, levels = c('A', 'B', 'C'),
#                              labels = c('Não', 'Sim', 'Não sei'))
# 
# TS_DIRETOR$TX_Q156 <- factor(TS_DIRETOR$TX_Q156, levels = c('A', 'B', 'C'),
#                              labels = c('Não', 'Sim', 'Não sei'))
# 
# TS_DIRETOR$TX_Q157 <- factor(TS_DIRETOR$TX_Q157, levels = c('A', 'B', 'C'),
#                              labels = c('Não', 'Sim', 'Não sei'))
# 
# TS_DIRETOR$TX_Q158 <- factor(TS_DIRETOR$TX_Q158, levels = c('A', 'B', 'C'),
#                              labels = c('Não', 'Sim', 'Não sei'))
# 
# TS_DIRETOR$TX_Q159 <- factor(TS_DIRETOR$TX_Q159, levels = c('A', 'B', 'C'),
#                              labels = c('Não', 'Sim', 'Não sei'))
# 
# TS_DIRETOR$TX_Q160 <- factor(TS_DIRETOR$TX_Q160, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q161 <- factor(TS_DIRETOR$TX_Q161, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q162 <- factor(TS_DIRETOR$TX_Q162, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q163 <- factor(TS_DIRETOR$TX_Q163, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q164 <- factor(TS_DIRETOR$TX_Q164, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q165 <- factor(TS_DIRETOR$TX_Q165, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q166 <- factor(TS_DIRETOR$TX_Q166, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q167 <- factor(TS_DIRETOR$TX_Q167, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q169 <- factor(TS_DIRETOR$TX_Q169, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q170 <- factor(TS_DIRETOR$TX_Q170, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q171 <- factor(TS_DIRETOR$TX_Q171, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q172 <- factor(TS_DIRETOR$TX_Q172, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q173 <- factor(TS_DIRETOR$TX_Q173, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q174 <- factor(TS_DIRETOR$TX_Q174, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q175 <- factor(TS_DIRETOR$TX_Q175, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q176 <- factor(TS_DIRETOR$TX_Q176, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q177 <- factor(TS_DIRETOR$TX_Q177, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q178 <- factor(TS_DIRETOR$TX_Q178, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q179 <- factor(TS_DIRETOR$TX_Q179, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q180 <- factor(TS_DIRETOR$TX_Q180, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q181 <- factor(TS_DIRETOR$TX_Q181, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q182 <- factor(TS_DIRETOR$TX_Q182, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q183 <- factor(TS_DIRETOR$TX_Q183, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q184 <- factor(TS_DIRETOR$TX_Q184, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q185 <- factor(TS_DIRETOR$TX_Q185, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q186 <- factor(TS_DIRETOR$TX_Q186, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não foi realizada esta ação', 'Nada efetiva', 'Pouco efetiva', 'Efetiva', 'Muito efetiva'))
# 
# TS_DIRETOR$TX_Q187 <- factor(TS_DIRETOR$TX_Q187, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não foi realizada esta ação', 'Nada efetiva', 'Pouco efetiva', 'Efetiva', 'Muito efetiva'))
# 
# TS_DIRETOR$TX_Q188 <- factor(TS_DIRETOR$TX_Q188, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não foi realizada esta ação', 'Nada efetiva', 'Pouco efetiva', 'Efetiva', 'Muito efetiva'))
# 
# TS_DIRETOR$TX_Q189 <- factor(TS_DIRETOR$TX_Q189, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não foi realizada esta ação', 'Nada efetiva', 'Pouco efetiva', 'Efetiva', 'Muito efetiva'))
# 
# TS_DIRETOR$TX_Q190 <- factor(TS_DIRETOR$TX_Q190, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não foi realizada esta ação', 'Nada efetiva', 'Pouco efetiva', 'Efetiva', 'Muito efetiva'))
# 
# TS_DIRETOR$TX_Q191 <- factor(TS_DIRETOR$TX_Q191, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não foi realizada esta ação', 'Nada efetiva', 'Pouco efetiva', 'Efetiva', 'Muito efetiva'))
# 
# TS_DIRETOR$TX_Q192 <- factor(TS_DIRETOR$TX_Q192, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não foi realizada esta ação', 'Nada efetiva', 'Pouco efetiva', 'Efetiva', 'Muito efetiva'))
# 
# TS_DIRETOR$TX_Q193 <- factor(TS_DIRETOR$TX_Q193, levels = c('A', 'B', 'C', 'D', 'E'),
#                              labels = c('Não foi realizada esta ação', 'Nada efetiva', 'Pouco efetiva', 'Efetiva', 'Muito efetiva'))
# 
# TS_DIRETOR$TX_Q194 <- factor(TS_DIRETOR$TX_Q194, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q195 <- factor(TS_DIRETOR$TX_Q195, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q196 <- factor(TS_DIRETOR$TX_Q196, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q197 <- factor(TS_DIRETOR$TX_Q197, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q198 <- factor(TS_DIRETOR$TX_Q198, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q199 <- factor(TS_DIRETOR$TX_Q199, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q200 <- factor(TS_DIRETOR$TX_Q200, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q201 <- factor(TS_DIRETOR$TX_Q201, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q202 <- factor(TS_DIRETOR$TX_Q202, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q203 <- factor(TS_DIRETOR$TX_Q203, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q204 <- factor(TS_DIRETOR$TX_Q204, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q205 <- factor(TS_DIRETOR$TX_Q205, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q206 <- factor(TS_DIRETOR$TX_Q206, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q207 <- factor(TS_DIRETOR$TX_Q207, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q208 <- factor(TS_DIRETOR$TX_Q208, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q209 <- factor(TS_DIRETOR$TX_Q209, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q210 <- factor(TS_DIRETOR$TX_Q210, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q211 <- factor(TS_DIRETOR$TX_Q211, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q212 <- factor(TS_DIRETOR$TX_Q212, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q213 <- factor(TS_DIRETOR$TX_Q213, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q214 <- factor(TS_DIRETOR$TX_Q214, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q215 <- factor(TS_DIRETOR$TX_Q215, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q216 <- factor(TS_DIRETOR$TX_Q216, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q217 <- factor(TS_DIRETOR$TX_Q217, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q218 <- factor(TS_DIRETOR$TX_Q218, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q219 <- factor(TS_DIRETOR$TX_Q219, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q220 <- factor(TS_DIRETOR$TX_Q220, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q221 <- factor(TS_DIRETOR$TX_Q221, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q222 <- factor(TS_DIRETOR$TX_Q222, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))
# 
# TS_DIRETOR$TX_Q223 <- factor(TS_DIRETOR$TX_Q223, levels = c('A', 'B'),
#                              labels = c('Não', 'Sim'))

labels <- list(
  ID_SAEB = 'Ano de aplicação do Saeb',                                                                                                    
  ID_REGIAO = 'Código da Região',                                                                                                                         
  ID_UF = 'Código da Unidade da Federação',                                                                                                               
  ID_MUNICIPIO = 'Máscaras dos Códigos de Municípios (são códigos fictícios)',                                                                                                                   
  ID_AREA = 'Área',
  ID_ESCOLA= 'Máscaras dos Códigos de Escola (são códigos fictícios)',
  IN_PUBLICA= 'Indica se a escola é pública ou não',
  ID_LOCALIZACAO= 'Localização',
  IN_PREENCHIMENTO_QUESTIONARIO = 'Indicador de preenchimento do questionário',
  ID_SERIE = 'Ano escolar para o qual a escola participou do Saeb',
  ESTRATO = 'Descrição dos estratos',
  VL_PESO_ESCOLA = 'Peso da Escola para análise do questionário de Diretor, por ano escolar avaliado',
  TX_Q001 = 'Educação Infantil - Creche (0 a 3 anos)',
  TX_Q002 = 'Educação Infantil - Pré-escola (4 e 5 anos)',
  TX_Q003 = 'Anos Iniciais do Ensino Fundamental',
  TX_Q004 = 'Anos Finais do Ensino Fundamental',
  TX_Q005 = 'Ensino Médio',
  TX_Q006 = 'Sua escola é',
  TX_Q007 = 'Qual é o seu sexo?',
  TX_Q008 = 'Qual é a sua idade?',
  TX_Q009 = 'Qual é a sua cor ou raça?',
  TX_Q010 = 'Você possui deficiência, transtorno do espectro autista ou superdotação?',
  TX_Q011 = 'Indique qual a sua condição. Deficiência',
  TX_Q012 = 'Indique qual a sua condição. Transtorno do espectro autista',
  TX_Q013 = 'Indique qual a sua condição. Altas habilidades/superdotação',
  TX_Q014 = 'Qual é o MAIS ALTO nível de escolaridade que você concluiu?',
  TX_Q015_A = 'Quanto anos você trabalhou como professor(a) antes de se tornar diretor(a)?',
  TX_Q015_B = 'Quanto anos você trabalhou como professor(a) antes de se tornar diretor(a)? Nunca trabalhei',
  TX_Q016 = 'Há quantos anos você exerce a função de diretor(a) de escola?',
  TX_Q017 = 'Há quantos anos você é diretor(a) desta escola?',
  TX_Q018 = 'Em uma semana normal de trabalho, quantas HORAS, no total, você gasta com TODAS as atividades de direção da escola?',
  TX_Q019 = 'Coordenar a gestão curricular, os métodos de aprendizagem, a avaliação e o planejamento pedagógico',
  TX_Q020 = 'Liderar as equipes de trabalho (reunião com professores, delegar tarefas para outros profissionais etc.)',
  TX_Q021 = 'Gerenciar os recursos financeiros (prestação de contas etc.) e as atividades administrativas (merenda, segurança, manutenção predial etc.)',
  TX_Q022 = 'Atendimento à comunidade escolar - pais ou responsáveis, professores(as) e estudantes, colaboradores etc.',
  TX_Q023 = 'Outras atividades',
  TX_Q024 = 'Qual a sua carga horária semanal total de trabalho como diretor(a)?',
  TX_Q025 = 'Qual é o seu salário bruto como diretor(a)?',
  TX_Q026 = 'Você possui outra atividade remunerada?',
  TX_Q027 = 'Repetir de ano é bom para o(a) estudante que não apresentou desempenho satisfatório',
  TX_Q028 = 'As avaliações externas (municipais, estaduais ou federais) têm direcionado o que deve ser ensinado',
  TX_Q029 = 'As avaliações externas (federais, estaduais ou municipais) têm ajudado a melhorar o processo de ensino e aprendizagem',
  TX_Q030 = 'A maioria dos estudantes da escola apresenta problemas de aprendizagem',
  TX_Q031 = 'Eu acredito que a totalidade dos(as) estudantes da escola são capazes de concluir a Educação Básica e prosseguir seus estudos',
  TX_Q032 = 'Televisão',
  TX_Q033 = 'Projetor multimídia (datashow)',
  TX_Q034 = 'Computador (de mesa ou portátil)',
  TX_Q035 = 'Softwares educacionais',
  TX_Q036 = 'Internet banda larga',
  TX_Q037 = 'Recursos pedagógicos para atendimento educacional especializado',
  TX_Q038 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Bebedouro ao alcance das crianças',
  TX_Q039 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Chuveiro para as crianças',
  TX_Q040 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Área sombreada',
  TX_Q041 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Área externa coberta',
  TX_Q042 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Vegetação e jardim',
  TX_Q043 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Horta',
  TX_Q044 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Tanque de areia',
  TX_Q045 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Gira-gira',
  TX_Q046 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Gangorra',
  TX_Q047 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Escorregador',
  TX_Q048 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Casinha',
  TX_Q049 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Balanço',
  TX_Q050 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Brinquedo para escalar',
  TX_Q051 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Banheiro infantil',
  TX_Q052 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Espaço destinado à amamentação',
  TX_Q053 = 'Avalie, abaixo, as condições dos EQUIPAMENTOS da sua escola: Condições para armazenamento de leite materno',
  TX_Q054 = 'Caso sua escola ofereça Ensino Fundamental e/ou Médio, a área externa (pátio, área verde e parque) é utilizada em horários diferenciados pelos(as) alunos(as) da Educação Infantil?',
  TX_Q055 = 'Os recursos financeiros foram suficientes',
  TX_Q056 = 'Houve atraso no repasse de recursos financeiros para pagamento de pessoal',
  TX_Q057 = 'O quadro de professores estava completo',
  TX_Q058 = 'Havia quantidade suficiente de pessoal de apoio (serviços gerais)',
  TX_Q059 = 'Havia quantidade suficiente de pessoal administrativo (secretaria)',
  TX_Q060 = 'Havia quantidade suficiente de pessoal para apoio pedagógico (coordenador e orientador)',
  TX_Q061 = 'Recebi apoio da Secretaria de Educação',
  TX_Q062 = 'Os(As) professores(as) foram assíduos(as)',
  TX_Q063 = 'As substituições das ausências de professores(as) foram facilmente realizadas',
  TX_Q064 = 'Os(As) estudantes foram assíduos(as)',
  TX_Q065 = 'A comunidade apoiou a gestão da escola',
  TX_Q066 = 'A comunidade executou trabalhos voluntários na escola',
  TX_Q067 = 'As famílias contribuíram com o trabalho pedagógico.',
  TX_Q068 = 'Os(As) estudantes com deficiência, transtorno do espectro autista ou com altas habilidades/superdotação receberam atendimento educacional especializado (AEE).',
  TX_Q069 = 'No início do ano letivo, todos(as) os(as) estudantes receberam os livros didáticos.',
  TX_Q070 = 'Neste ano, houve a necessidade de profissionais para atendimento educacional especializado?',
  TX_Q071 = 'Caso tenha havido necessidade, indique se a quantidade de profissionais foi suficiente ou insuficiente para a necessidade da escola. Professor(a) de Braille.',
  TX_Q072 = 'Caso tenha havido necessidade, indique se a quantidade de profissionais foi suficiente ou insuficiente para a necessidade da escola. Professor(a) bilíngue para surdos.',
  TX_Q073 = 'Caso tenha havido necessidade, indique se a quantidade de profissionais foi suficiente ou insuficiente para a necessidade da escola. Professor ou Instrutor de Libras',
  TX_Q074 = 'Caso tenha havido necessidade, indique se a quantidade de profissionais foi suficiente ou insuficiente para a necessidade da escola. Guia-interprete',
  TX_Q075 = 'Caso tenha havido necessidade, indique se a quantidade de profissionais foi suficiente ou insuficiente para a necessidade da escola. Professor(a) da sala de recursos multifuncionais.',
  TX_Q076 = 'Caso tenha havido necessidade, indique se a quantidade de profissionais foi suficiente ou insuficiente para a necessidade da escola. Professor(a) itinerante.',
  TX_Q077 = 'Caso tenha havido necessidade, indique se a quantidade de profissionais foi suficiente ou insuficiente para a necessidade da escola. Monitor(a) de apoio à educação especial.',
  TX_Q078 = 'Falta de água.',
  TX_Q079 = 'Falta de energia.',
  TX_Q080 = 'Falta de merenda.',
  TX_Q081 = 'Greve de professores.',
  TX_Q082 = 'Episódios de violência.',
  TX_Q083 = 'Problemas de infraestrutura predial.',
  TX_Q084 = 'Paralisação do transporte.',
  TX_Q085 = 'Eventos climáticos (inundação, desmoronamento etc.).',
  TX_Q086 = 'Eventos comemorativos.',
  TX_Q087 = 'Problemas de saúde pública.',
  TX_Q088 = 'Outros.',
  TX_Q089 = '[Descreva os outros problemas].',
  TX_Q090 = 'Em relação a todas as interrupções que assinalou, por quantos dias o calendário escolar de 2023 foi interrompido?',
  TX_Q091 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Atentado à vida.',
  TX_Q092 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Lesão corporal.',
  TX_Q093 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Roubo ou furto.',
  TX_Q094 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Tráfico de drogas.',
  TX_Q095 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Permanência de pessoas sob efeito de álcool.',
  TX_Q096 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Permanência de pessoas sob efeito de drogas.',
  TX_Q097 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Porte de arma (revólver, faca, canivete).',
  TX_Q098 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Assédio sexual.',
  TX_Q099 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Discriminação (racial, gênero, orientação sexual, econômica/social, deficiência).',
  TX_Q100 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Bullying (ameaças ou ofensas verbais).',
  TX_Q101 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Invasão do espaço escolar.',
  TX_Q102 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Depredação do patrimônio escolar (vandalismo).',
  TX_Q103 = 'Sobre os episódios listados abaixo, indique a frequência com que ocorreram neste ano, nesta escola: Tiroteio ou bala perdida.',
  TX_Q104 = 'Condições de segurança na entrada e saída da escola.',
  TX_Q105 = 'Muros e/ou grades que isolam a escola do ambiente externo.',
  TX_Q106 = 'Identificação externa que caracterize o prédio como uma instituição escolar.',
  TX_Q107 = 'O acesso à entrada principal adequado ao público-alvo da educação especial (rampas, marcadores no chão).',
  TX_Q108 = 'Condições de uso dos equipamentos da área externa de recreação (parque infantil, pátio, quadra poliesportiva).',
  TX_Q109 = 'O acesso dos(as) estudantes público-alvo da educação especial à área externa de recreação (parque infantil, pátio, quadra poliesportiva).',
  TX_Q110 = 'Há Conselho Escolar na sua escola?',
  TX_Q111 = 'Quantas vezes o Conselho Escolar se reuniu neste ano?',
  TX_Q112 = 'Há Conselho de Classe na sua escola?',
  TX_Q113 = 'Quantas vezes o Conselho de Classe se reuniu neste ano?',
  TX_Q114 = 'Quantos estudantes participam do Conselho de Classe?',
  TX_Q115 = 'Existe Associação de Pais e Mestres - APM (ou caixa escolar) nesta escola?',
  TX_Q116 = 'Quantas vezes a APM se reuniu neste ano?',
  TX_Q117 = 'Há grêmio estudantil na sua escola?',
  TX_Q118 = 'O grêmio estudantil está:',
  TX_Q119 = 'Com relação à gestão da escola: A escola é militar ou militarizada.',
  TX_Q120 = 'Com relação à gestão da escola: A escola é confessional ou segue uma orientação religiosa.',
  TX_Q121 = 'A escola desenvolve REGULARMENTE trabalhos em conjunto com: Serviços de saúde (postos de saúde).',
  TX_Q122 = 'A escola desenvolve REGULARMENTE trabalhos em conjunto com: Serviços de assistência social (CRAS e outros).',
  TX_Q123 = 'A escola desenvolve REGULARMENTE trabalhos em conjunto com: Segurança pública (polícia militar, guarda municipal e outros).',
  TX_Q124 = 'A escola desenvolve REGULARMENTE trabalhos em conjunto com: Conselho Tutelar (Ministério Público e outros).',
  TX_Q125 = 'A escola desenvolve REGULARMENTE trabalhos em conjunto com: Instituições de apoio ao público-alvo da educação especial (Apae).',
  TX_Q126 = 'A escola desenvolve REGULARMENTE trabalhos em conjunto com: Instituições de ensino superior (faculdades, universidades, IFs).',
  TX_Q127 = 'A escola desenvolve REGULARMENTE trabalhos em conjunto com: Instituições privadas (empresas, ONGs, corporações).',
  TX_Q128 = 'A escola desenvolve REGULARMENTE trabalhos em conjunto com: Outros órgãos da prefeitura ou do governo estadual ou federal.',
  TX_Q129 = 'Quais as fontes de financiamento da escola? Recursos federais (Programa Dinheiro Direto na Escola etc.).',
  TX_Q130 = 'Quais as fontes de financiamento da escola? Recursos estaduais ou municipais.',
  TX_Q131 = 'Quais as fontes de financiamento da escola? Eventos da escola (festa, rifa etc.).',
  TX_Q132 = 'Quais as fontes de financiamento da escola? Empresas que apoiam a escola.',
  TX_Q133 = 'Quais as fontes de financiamento da escola? Organizações sem fins lucrativos que apoiam a escola.',
  TX_Q134 = 'Quais as fontes de financiamento da escola? Contribuições dos familiares dos(as) estudantes.',
  TX_Q135 = 'Quais as fontes de financiamento da escola? Contribuições dos(as) profissionais da escola.',
  TX_Q136 = 'Como a escola adquire os seguintes recursos: Brinquedos.',
  TX_Q137 = 'Como a escola adquire os seguintes recursos: Recursos pedagógicos.',
  TX_Q138 = 'Como a escola adquire os seguintes recursos: Materiais de higiene pessoal.',
  TX_Q139 = 'A escola oferece merenda aos(às) estudantes?',
  TX_Q140 = 'Quantas refeições são oferecidas nesta escola em relação ao tempo de permanência dos(as) estudantes? Para estudantes que permanecem até 4 horas na escola:',
  TX_Q141 = 'Quantas refeições são oferecidas nesta escola em relação ao tempo de permanência dos(as) estudantes? Para estudantes que permanecem mais que 4 e menos que 7 horas na escola:',
  TX_Q142 = 'Quantas refeições são oferecidas nesta escola em relação ao tempo de permanência dos(as) estudantes? Para estudantes que permanecem 7 horas ou mais na escola:',
  TX_Q143 = 'Em relação à merenda escolar, como você avalia os seguintes aspectos: A quantidade de alimentos é suficiente para todos(as).',
  TX_Q144 = 'Em relação à merenda escolar, como você avalia os seguintes aspectos: Os alimentos são de boa qualidade.',
  TX_Q145 = 'Em relação à merenda escolar, como você avalia os seguintes aspectos: Há dietas específicas para estudantes com restrições alimentares.',
  TX_Q146 = 'Em relação à merenda escolar, como você avalia os seguintes aspectos: A cozinha atende as necessidades do preparo da merenda.',
  TX_Q147 = 'Em relação à merenda escolar, como você avalia os seguintes aspectos: O local de alimentação é adequado.',
  TX_Q148 = 'Em relação à merenda escolar, como você avalia os seguintes aspectos: O acesso ao local de alimentação é livre para estudantes com mobilidade reduzida.',
  TX_Q149 = 'Em relação à merenda escolar, como você avalia os seguintes aspectos: Há pias para higienização das mãos próximas ao local de alimentação.',
  TX_Q150 = 'A merenda escolar é preparada na própria instituição?',
  TX_Q151 = 'A escola possui Projeto Político-Pedagógico?',
  TX_Q152 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Seu conteúdo é discutido em reuniões?',
  TX_Q153 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Os(As) professores(as) participaram da elaboração?',
  TX_Q154 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Os profissionais não docentes participaram da elaboração?',
  TX_Q155 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Os pais participaram da elaboração?',
  TX_Q156 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Os(As) estudantes participaram da elaboração?',
  TX_Q157 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Estabelece metas de aprendizagem?',
  TX_Q158 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Considera os resultados de avaliações externas (Saeb, estaduais, municipais etc.)?',
  TX_Q159 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Há metas de alcance de indicadores externos (Ideb, índices estaduais ou municipais)?',
  TX_Q160 = 'Neste ano e nesta escola, todos que solicitaram vagas conseguiram se matricular?',
  TX_Q161 = 'Quais foram os critérios de seleção para novas matrículas neste ano e nesta escola: Sorteio.',
  TX_Q162 = 'Quais foram os critérios de seleção para novas matrículas neste ano e nesta escola: Local de moradia.',
  TX_Q163 = 'Quais foram os critérios de seleção para novas matrículas neste ano e nesta escola: Prova de conhecimentos.',
  TX_Q164 = 'Quais foram os critérios de seleção para novas matrículas neste ano e nesta escola: Ordem da inscrição/lista de espera.',
  TX_Q165 = 'Quais foram os critérios de seleção para novas matrículas neste ano e nesta escola: Características socioeconômicas.',
  TX_Q166 = 'Quais foram os critérios de seleção para novas matrículas neste ano e nesta escola: Desempenho do(a) estudante no ano anterior.',
  TX_Q167 = 'Quais foram os critérios de seleção para novas matrículas neste ano e nesta escola: Outros critérios definidos pela Secretaria de Educação ou pelo Órgão Gestor de Educação.',
  TX_Q168 = 'Descreva os critérios.',
  TX_Q169 = 'Idade.',
  TX_Q170 = 'Capacidade física da sala de aula.',
  TX_Q171 = 'Manter estudantes na mesma etapa de ensino.',
  TX_Q172 = 'Manter as turmas existentes do ano anterior.',
  TX_Q173 = 'Critérios disciplinares.',
  TX_Q174 = 'Desempenho escolar.',
  TX_Q175 = 'Disponibilidade de vagas na turma.',
  TX_Q176 = 'Ordem da matrícula.',
  TX_Q177 = 'Atendimento à solicitação dos pais/responsáveis.',
  TX_Q178 = 'Preferência dos(as) professores(as).',
  TX_Q179 = 'Tempo de serviço.',
  TX_Q180 = 'Cursos de formação continuada realizados.',
  TX_Q181 = 'Professores(as) experientes nas turmas com facilidade de aprendizagem.',
  TX_Q182 = 'Professores(as) experientes nas turmas com dificuldade de aprendizagem.',
  TX_Q183 = 'Manutenção do(a) professor(a) com a mesma turma.',
  TX_Q184 = 'Revezamento dos(as) professores(as) entre séries/anos.',
  TX_Q185 = 'Atribuição pela gestão da escola.',
  TX_Q186 = 'Neste ano, a escola realizou as seguintes ações para redução da REPETÊNCIA ESCOLAR? Caso tenham sido realizadas, indique a eficácia das seguintes ações: Oferta de reforço escolar.',
  TX_Q187 = 'Neste ano, a escola realizou as seguintes ações para redução da REPETÊNCIA ESCOLAR? Oferta de atendimento educacional especializado para estudantes com deficiência, transtornos do espectro autista ou com altas habilidades/superdotação.',
  TX_Q188 = 'Neste ano, a escola realizou as seguintes ações para redução da REPETÊNCIA ESCOLAR? Os(As) estudantes são estimulados(as) a apoiar uns(umas) aos(às) outros(as).',
  TX_Q189 = 'Neste ano, a escola realizou as seguintes ações para redução da REPETÊNCIA ESCOLAR? Revisão dos procedimentos de avaliação.',
  TX_Q190 = 'Neste ano, a escola realizou as seguintes ações para redução da REPETÊNCIA ESCOLAR? Revisão das práticas pedagógicas.',
  TX_Q191 = 'Neste ano, a escola realizou as seguintes ações para redução do ABANDONO ESCOLAR? Caso tenham sido realizadas, indique a eficácia das seguintes ações: Entrar em contato com os familiares/responsáveis do(a) estudante.',
  TX_Q192 = 'Neste ano, a escola realizou as seguintes ações para redução do ABANDONO ESCOLAR? Ir à residência do(a) estudante.',
  TX_Q193 = 'Neste ano, a escola realizou as seguintes ações para redução do ABANDONO ESCOLAR? Informar ao Conselho Tutelar.',
  TX_Q194 = 'Nesta escola, há projetos com as seguintes temáticas: Ciência e tecnologia.',
  TX_Q195 = 'Nesta escola, há projetos com as seguintes temáticas: Combate à discriminação (racial, gênero, orientação sexual, econômica/social, deficiência, religiosa).',
  TX_Q196 = 'Nesta escola, há projetos com as seguintes temáticas: Combate à violência (física, verbal, bullying, entre outras).',
  TX_Q197 = 'Nesta escola, há projetos com as seguintes temáticas: Direitos humanos (de idosos, pessoas com deficiência, mulheres, crianças, adolescentes e outros).',
  TX_Q198 = 'Nesta escola, há projetos com as seguintes temáticas: Educação ambiental e consumo sustentável.',
  TX_Q199 = 'Nesta escola, há projetos com as seguintes temáticas: Educação para o trânsito.',
  TX_Q200 = 'Nesta escola, há projetos com as seguintes temáticas: Mundo do trabalho (direitos, relações, entre outros).',
  TX_Q201 = 'Nesta escola, há projetos com as seguintes temáticas: Nutrição e alimentação.',
  TX_Q202 = 'Nesta escola, há projetos com as seguintes temáticas: Promoção da democracia e da cidadania.',
  TX_Q203 = 'Nesta escola, há projetos com as seguintes temáticas: Uso de drogas.',
  TX_Q204 = 'Nesta escola, há projetos com as seguintes temáticas: Sexualidade.',
  TX_Q205 = 'Preparação dos(as) estudantes para os testes de avaliação externos.',
  TX_Q206 = 'Inscrição dos(as) estudantes em olímpiadas de conhecimento.',
  TX_Q207 = 'Feira de ciências.',
  TX_Q208 = 'Feira de artes',
  TX_Q209 = 'Campeonatos esportivos.',
  TX_Q210 = 'Outros.',
  TX_Q211 = '[Descreva os outros tipos de ações.]',
  TX_Q212 = 'Conteúdo e compreensão dos conceitos da(s) área(s) de ensino.',
  TX_Q213 = 'Avaliação da aprendizagem.',
  TX_Q214 = 'Avaliação em larga escala.',
  TX_Q215 = 'Metodologias de ensino.',
  TX_Q216 = 'Base Nacional Comum Curricular - BNCC.',
  TX_Q217 = 'Gestão da sala de aula.',
  TX_Q218 = 'Educação especial.',
  TX_Q219 = 'Novas tecnologias educacionais.',
  TX_Q220 = 'Gestão e administração escolar.',
  TX_Q221 = 'Ensino híbrido.',
  TX_Q222 = 'Alfabetização e letramento.',
  TX_Q223 = 'Gestão democrática.',
  TX_Q224 = 'Sugestões de melhoria para o instrumento (inclusão de temas, estrutura do questionário etc.)'
)

# Aplicando LABELS às colunas de ITENS (Se a variável existe, o label correspondente é atribuído)
for (var in names(labels)) {
  if (var %in% names(TS_DIRETOR)) {
    attr(TS_DIRETOR[[var]], "label") <- labels[[var]]
  }
}
