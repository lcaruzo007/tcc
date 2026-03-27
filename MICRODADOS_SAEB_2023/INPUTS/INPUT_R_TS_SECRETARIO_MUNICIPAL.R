# /***************************************************************************************/
# /*  INEP/Daeb-Diretoria de Avaliação da Educação Básica                                */ 
# /*                                   			                                             */
# /*  Coordenação-Geral de Medidas da Educação Básica (CGMEB)                            */
# /*-------------------------------------------------------------------------------------*/
# /*  PROGRAMA:                                                                          */
# /*               INPUT_R_TS_SECRETARIO_MUNICIPAL                                       */
# /*-------------------------------------------------------------------------------------*/
# /*  DESCRICAO:   PROGRAMA PARA LEITURA DO QUESTIONÁRIO DO SECRETARIO                   */
# /*               MUNICIPAL DE EDUCAÇÃO DO SAEB 2023                                    */
# /*                                                                                     */
# /***************************************************************************************/
# /* Obs:                                                                                */
# /* 		                                                                                 */
# /* Para abrir os microdados, é necessário salvar este programa e o arquivo             */
# /* TS_SECRETARIO_MUNICIPAL.CSV no diretório C:\ do computador.	                       */
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

TS_SECRETARIO_MUNICIPAL <- data.table::fread(input='TS_SECRETARIO_MUNICIPAL.csv',integer64='character')

# A script a seguir formata os rótulos das variáveis
# Para formatar um item retire o caracter de comentário (#) no início na linha desejada 
# (Para retirar o caracter de comentário de várias linhas de uma só vez, selecione as linhas desejadas e tecle ctrl+shift+c)
#---------------------------

# TS_SECRETARIO_MUNICIPAL$ID_REGIAO <- factor(TS_SECRETARIO_MUNICIPAL$ID_REGIAO, levels = c(1, 2, 3, 4, 5), labels = c('Norte', 'Nordeste', 'Sudeste', 'Sul', 'Centro-Oeste'))
# TS_SECRETARIO_MUNICIPAL$ID_UF <- factor(TS_SECRETARIO_MUNICIPAL$ID_UF, levels = c(11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29, 31, 32, 33, 35, 41, 42, 43, 50, 51, 52, 53), labels = c('RO', 'AC', 'AM', 'RR', 'PA', 'AP', 'TO', 'MA', 'PI', 'CE', 'RN', 'PB', 'PE', 'AL', 'SE', 'BA', 'MG', 'ES', 'RJ', 'SP', 'PR', 'SC', 'RS', 'MS', 'MT', 'GO', 'DF'))
# TS_SECRETARIO_MUNICIPAL$ID_AREA <- factor(TS_SECRETARIO_MUNICIPAL$ID_AREA, levels = c(2, 1), labels = c('Interior', 'Capital'))
# TS_SECRETARIO_MUNICIPAL$IN_PREENCHIMENTO <- factor(TS_SECRETARIO_MUNICIPAL$IN_PREENCHIMENTO, levels = c(0, 1), labels = c('Não preenchido','Preenchido parcial ou totalmente'))
# TS_SECRETARIO_MUNICIPAL$TX_Q001 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q001, levels = c('A', 'B', 'C'), labels = c('Masculino', 'Feminino', 'Não quero declarar'))
# TS_SECRETARIO_MUNICIPAL$TX_Q003 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q003, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Branca', 'Preta', 'Parda', 'Amarela', 'Indígena', 'Não quero declarar'))
# TS_SECRETARIO_MUNICIPAL$TX_Q004 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q004, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q005 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q005, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q006 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q006, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q007 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q007, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q008 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q008, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Ensino Fundamental', 'Ensino Médio', 'Graduação', 'Especialização', 'Mestrado', 'Doutorado'))
# TS_SECRETARIO_MUNICIPAL$TX_Q009 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q009, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q010 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q010, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q011 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q011, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q012 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q012, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q013 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q013, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q014 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q014, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q015 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q015, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q016 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q016, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q017 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q017, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q020 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q020, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q021 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q021, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q022 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q022, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_SECRETARIO_MUNICIPAL$TX_Q023 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q023, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_SECRETARIO_MUNICIPAL$TX_Q024 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q024, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_SECRETARIO_MUNICIPAL$TX_Q025 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q025, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_SECRETARIO_MUNICIPAL$TX_Q026 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q026, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_SECRETARIO_MUNICIPAL$TX_Q027 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q027, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q028 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q028, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q029 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q029, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q030 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q030, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q031 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q031, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q034 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q034, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_SECRETARIO_MUNICIPAL$TX_Q035 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q035, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q036 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q036, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q037 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q037, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q038 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q038, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q039 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q039, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q040 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q040, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q041 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q041, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q042 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q042, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q043 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q043, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q044 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q044, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q045 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q045, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q046 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q046, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q047 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q047, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q048 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q048, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q049 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q049, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q050 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q050, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q051 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q051, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q052 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q052, levels = c('A', 'B', 'C'), labels = c('Sim, a legislação contempla todos os critérios utilizados', 'Sim, a legislação contempla uma parte dos critérios utilizados', 'Não, não há legislação municipal para escolha dos(as) diretores(as)'))
# TS_SECRETARIO_MUNICIPAL$TX_Q053 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q053, levels = c('A', 'B', 'C'), labels = c('Não sei', 'Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q054 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q054, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q055 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q055, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q056 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q056, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q057 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q057, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q058 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q058, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q059 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q059, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q060 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q060, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q061 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q061, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q062 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q062, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q063 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q063, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q064 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q064, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q065 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q065, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q078 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q078, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q079 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q079, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q080 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q080, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q081 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q081, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q082 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q082, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q083 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q083, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q084 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q084, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q085 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q085, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q086 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q086, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q087 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q087, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q088 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q088, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q089 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q089, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q090 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q090, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q091 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q091, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q092 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q092, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q094 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q094, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q095 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q095, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q096 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q096, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q097 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q097, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q098 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q098, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q099 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q099, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q100 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q100, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q101 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q101, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q102 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q102, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q103 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q103, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q104 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q104, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q105 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q105, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q106 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q106, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q107 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q107, levels = c('A', 'B'), labels = c('Município', 'Instituições'))
# TS_SECRETARIO_MUNICIPAL$TX_Q108 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q108, levels = c('A', 'B'), labels = c('Município', 'Instituições'))
# TS_SECRETARIO_MUNICIPAL$TX_Q109 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q109, levels = c('A', 'B'), labels = c('Município', 'Instituições'))
# TS_SECRETARIO_MUNICIPAL$TX_Q110 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q110, levels = c('A', 'B'), labels = c('Município', 'Instituições'))
# TS_SECRETARIO_MUNICIPAL$TX_Q111 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q111, levels = c('A', 'B'), labels = c('Município', 'Instituições'))
# TS_SECRETARIO_MUNICIPAL$TX_Q112 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q112, levels = c('A', 'B'), labels = c('Município', 'Instituições'))
# TS_SECRETARIO_MUNICIPAL$TX_Q113 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q113, levels = c('A', 'B'), labels = c('Município', 'Instituições'))
# TS_SECRETARIO_MUNICIPAL$TX_Q114 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q114, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q115 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q115, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q116 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q116, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q118 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q118, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q119 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q119, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q120 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q120, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q121 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q121, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q122 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q122, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q123 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q123, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q124 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q124, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q125 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q125, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q126 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q126, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não se aplica'))
# TS_SECRETARIO_MUNICIPAL$TX_Q127 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q127, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não se aplica'))
# TS_SECRETARIO_MUNICIPAL$TX_Q128 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q128, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não se aplica'))
# TS_SECRETARIO_MUNICIPAL$TX_Q129 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q129, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não se aplica'))
# TS_SECRETARIO_MUNICIPAL$TX_Q130 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q130, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q131 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q131, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q132 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q132, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q133 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q133, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q134 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q134, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q135 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q135, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q136 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q136, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q137 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q137, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q138 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q138, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q139 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q139, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q140 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q140, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q141 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q141, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q142 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q142, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q143 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q143, levels = c('A', 'B', 'C', 'D'), labels = c('É inferior ao dos(as) professores(as) do Ensino Fundamental', 'É equivalente ao dos(as) professores(as) do Ensino Fundamental', 'É superior ao dos(as) professores(as) do Ensino Fundamental', 'Não existe este profissional na rede'))
# TS_SECRETARIO_MUNICIPAL$TX_Q144 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q144, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q154 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q154, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q155 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q155, levels = c('A', 'B'), labels = c('Aplicam-se provas externas', 'Não se aplicam provas externas'))
# TS_SECRETARIO_MUNICIPAL$TX_Q156 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q156, levels = c('A', 'B'), labels = c('Secretaria de Educação ou Órgão Gestor de Educação', 'Instituição contratada'))
# TS_SECRETARIO_MUNICIPAL$TX_Q157 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q157, levels = c('A', 'B'), labels = c('Aplicam-se provas externas', 'Não se aplicam provas externas'))
# TS_SECRETARIO_MUNICIPAL$TX_Q158 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q158, levels = c('A', 'B'), labels = c('Secretaria de Educação ou Órgão Gestor de Educação', 'Instituição contratada'))
# TS_SECRETARIO_MUNICIPAL$TX_Q159 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q159, levels = c('A', 'B'), labels = c('Aplicam-se provas externas', 'Não se aplicam provas externas'))
# TS_SECRETARIO_MUNICIPAL$TX_Q160 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q160, levels = c('A', 'B'), labels = c('Secretaria de Educação ou Órgão Gestor de Educação', 'Instituição contratada'))
# TS_SECRETARIO_MUNICIPAL$TX_Q161 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q161, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q162 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q162, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q163 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q163, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q164 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q164, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q165 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q165, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q166 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q166, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q167 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q167, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q168 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q168, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q169 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q169, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q170 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q170, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q171 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q171, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q172 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q172, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q173 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q173, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q174 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q174, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_SECRETARIO_MUNICIPAL$TX_Q175 <- factor(TS_SECRETARIO_MUNICIPAL$TX_Q175, levels = c('A', 'B'), labels = c('Não', 'Sim'))

labels <- list(
  ID_SAEB = 'Ano de aplicação do Saeb',
  ID_REGIAO = 'Código da Região',
  ID_UF = 'Código da Unidade da Federação',
  CO_MUNICIPIO = 'Código do Município',
  ID_AREA = 'Área',
  IN_PREENCHIMENTO = 'Indicador de preenchimento válido do questionário',
  TX_Q001 = 'Qual é o seu sexo?',
  TX_Q002 = 'Qual é a sua idade?',
  TX_Q003 = 'Qual é a sua cor ou raça?',
  TX_Q004 = 'Você possui deficiência, transtorno do espectro autista ou superdotação?',
  TX_Q005 = 'Indique qual é a sua condição: Deficiência.',
  TX_Q006 = 'Indique qual é a sua condição: Transtorno do espectro autista.',
  TX_Q007 = 'Indique qual é a sua condição: Altas habilidades/superdotação.',
  TX_Q008 = 'Qual é o MAIS ALTO nível de escolaridade que você concluiu?',
  TX_Q009 = 'Este mais alto nível de escolaridade é relacionado ao campo educacional?',
  TX_Q010 = 'Além de Secretário (a) Municipal de Educação neste município, você exerceu alguma outra função na área de educação?',
  TX_Q011 = 'Indique as funções que exerceu: Professor(a) da Educação Básica.',
  TX_Q012 = 'Indique as funções que exerceu: Professor(a) da Educação Superior.',
  TX_Q013 = 'Indique as funções que exerceu: Diretor(a) ou vice-diretor(a) de escola de Educação Básica.',
  TX_Q014 = 'Indique as funções que exerceu: Membro de equipe pedagógica de escola de Educação Básica.',
  TX_Q015 = 'Indique as funções que exerceu: Membro de equipe da Secretaria de Educação ou Órgão Gestor de Educação municipal ou estadual (direção, pedagógico, administrativo etc.).',
  TX_Q016 = 'Indique as funções que exerceu: Membro de equipe de Instituição de Educação Superior (direção, pedagógico, administrativo etc.).',
  TX_Q017 = 'Indique as funções que exerceu: Secretário (a) Municipal de Educação em outra rede.',
  TX_Q018 = 'Qual o seu tempo total de experiência, em ano, na área de educação?',
  TX_Q019 = 'Qual o seu tempo de experiência, em ano, como Secretário (a) Municipal de Educação neste ou em outro município?',
  TX_Q020 = 'Você ocupa o cargo de Secretário (a) Municipal de Educação desde o início da gestão do atual prefeito?',
  TX_Q021 = 'Além de atividades como Secretário (a) Municipal de Educação, você exerce OUTRA atividade profissional?',
  TX_Q022 = 'Repetir de ano é bom para o(a) estudante que não apresentou desempenho satisfatório.',
  TX_Q023 = 'As avaliações externas (municipais, estaduais ou federais) têm direcionado o que deve ser ensinado na rede municipal.',
  TX_Q024 = 'As avaliações externas (federal, estadual ou municipal) têm ajudado a melhorar o processo de ensino e aprendizagem na rede municipal.',
  TX_Q025 = 'A maioria dos estudantes da rede municipal apresenta problemas de aprendizagem.',
  TX_Q026 = 'Eu acredito que a totalidade dos estudantes da rede municipal são capazes de concluir a Educação Básica e prosseguir seus estudos.',
  TX_Q027 = 'Autonomia em relação ao Conselho Estadual de Educação?',
  TX_Q028 = 'Sistema Municipal de Ensino (define normas municipais, regras de funcionamento da rede, acompanha a execução dos programas do órgão gestor etc.)?',
  TX_Q029 = 'Plano Municipal de Educação?',
  TX_Q030 = 'Fórum Permanente ou Municipal de Educação?',
  TX_Q031 = 'Conselho Municipal de Educação?',
  TX_Q032 = 'Quantos servidores/funcionários SEM FUNÇÕES DOCENTES estão lotados na sede da Secretaria de Educação ou do Órgão Gestor de Educação?',
  TX_Q033 = 'Quantos servidores/funcionários SEM FUNÇÕES DOCENTES lotados na sede da Secretaria de Educação ou Órgão Gestor de Educação desenvolvem atividades de apoio pedagógico às escolas?',
  TX_Q034 = 'O(A) Secretário (a) Municipal de Educação determina quanto, quando e como usar os recursos financeiros disponíveis no orçamento anual da educação?',
  TX_Q035 = 'O município repassa recursos municipais diretamente às suas escolas?',
  TX_Q036 = 'Serviços de saúde (postos de saúde etc.).',
  TX_Q037 = 'Serviços de assistência social (CRAS etc.).',
  TX_Q038 = 'Segurança pública (polícia militar, guarda municipal etc.).',
  TX_Q039 = 'Conselho Tutelar (Ministério Público e outros).',
  TX_Q040 = 'Instituições de apoio ao público-alvo da educação especial (APAE etc.).',
  TX_Q041 = 'Instituições de ensino superior (faculdades, universidades etc.).',
  TX_Q042 = 'Instituições privadas (empresas, ONGs, corporações etc.).',
  TX_Q043 = 'Outros órgãos da prefeitura ou dos governos estadual ou federal.',
  TX_Q044 = 'Livre indicação pelo Executivo (prefeito, Secretário (a) Municipal de Educação etc.).',
  TX_Q045 = 'Concurso público para o cargo de diretor(a).',
  TX_Q046 = 'Consulta pública/eleição.',
  TX_Q047 = 'Nenhum critério técnico.',
  TX_Q048 = 'Titulação acadêmica.',
  TX_Q049 = 'Participação/aprovação em curso de formação para diretor(a) escolar.',
  TX_Q050 = 'Tempo de serviço.',
  TX_Q051 = 'Experiência em gestão.',
  TX_Q052 = 'Os critérios utilizados para o provimento ao cargo, ou função, de diretor(a) de escola estão definidos em legislação municipal?',
  TX_Q053 = 'O município possui legislação que disciplina a gestão democrática da educação pública?',
  TX_Q054 = 'Conteúdo e compreensão dos conceitos da(s) área(s) de ensino.',
  TX_Q055 = 'Avaliação da aprendizagem.',
  TX_Q056 = 'Avaliação em larga escala.',
  TX_Q057 = 'Metodologias de ensino.',
  TX_Q058 = 'Base Nacional Comum Curricular - BNCC.',
  TX_Q059 = 'Gestão da sala de aula.',
  TX_Q060 = 'Educação especial.',
  TX_Q061 = 'Novas tecnologias educacionais.',
  TX_Q062 = 'Gestão e administração escolar.',
  TX_Q063 = 'Ensino híbrido.',
  TX_Q064 = 'Alfabetização e letramento.',
  TX_Q065 = 'Gestão democrática.',
  TX_Q066 = 'Outros.',
  TX_Q067 = 'Descreva outros cursos de formação continuada.',
  TX_Q068 = 'Construção de escolas.',
  TX_Q069 = 'Reforma de escolas (melhoria e/ou adequação do espaço físico etc.).',
  TX_Q070 = 'Aquisição de mobiliário para as escolas (carteiras, armários etc.).',
  TX_Q071 = 'Aquisição de material de higiene, limpeza e equipamento de proteção individual (álcool, sabonete, máscara etc).',
  TX_Q072 = 'Aquisição de material pedagógico (livros, software, material audiovisual etc.).',
  TX_Q073 = 'Aquisição de equipamentos para estudantes e/ou professores (computador, tablet, celular, chip para internet etc.).',
  TX_Q074 = 'Produção de material didático audiovisual ou impresso.',
  TX_Q075 = 'Contratação de profissionais para a educação.',
  TX_Q076 = 'Distribuição da alimentação para os estudantes.',
  TX_Q077 = 'Formação continuada dos(as) professores(as) da rede.',
  TX_Q078 = 'Garantia da liberdade religiosa.',
  TX_Q079 = 'Inclusão das pessoas público-alvo da educação especial.',
  TX_Q080 = 'Combate ao abuso e à violência sexual.',
  TX_Q081 = 'Combate ao preconceito ou à discriminação baseada no sexo ou no gênero.',
  TX_Q082 = 'Combate ao racismo.',
  TX_Q083 = 'Mediação de conflitos ou problemas de relacionamento na escola.',
  TX_Q084 = 'Combate ao bullying e outras formas de violência.',
  TX_Q085 = 'Promoção da cultura da paz e da não violência.',
  TX_Q086 = 'Levantamento de conhecimentos prévios dos estudantes antes de iniciar um conteúdo curricular.',
  TX_Q087 = 'Apresentação aos estudantes do currículo e das atividades a serem executadas.',
  TX_Q088 = 'Incentivo aos estudantes para perguntar, comentar, sugerir e divergir durante as aulas.',
  TX_Q089 = 'Estímulo aos estudantes para dialogar e tirar dúvidas com colegas durante as aulas.',
  TX_Q090 = 'Organização de trabalhos em grupo nas aulas.',
  TX_Q091 = 'Diversificação das metodologias de ensino conforme as dificuldades que os(as) estudantes evidenciam.',
  TX_Q092 = 'A Secretaria de Educação ou Órgão Gestor de Educação possui instituições de Educação Infantil sob sua responsabilidade direta ou indireta?',
  TX_Q093 = 'Para responder a esta questão, considere os funcionários/servidores que trabalham EXCLUSIVAMENTE na sede da Secretaria de Educação ou do Órgão Gestor de Educação. Quantos servidores/funcionários SEM FUNÇÕES DOCENTES lotados na sede da Secretaria de Educação ou do Órgão Gestor de Educação estão dedicados EXCLUSIVAMENTE à Educação Infantil?',
  TX_Q094 = 'Para a EDUCAÇÃO INFANTIL, o município possui: Cálculo da demanda por vagas?',
  TX_Q095 = 'Para a EDUCAÇÃO INFANTIL, o município possui: Supervisão escolar?',
  TX_Q096 = 'Para a EDUCAÇÃO INFANTIL, o município possui: Programa de formação de professores?',
  TX_Q097 = 'Para a EDUCAÇÃO INFANTIL, o município possui: Busca ativa de crianças para a pré-escola?',
  TX_Q098 = 'Para a EDUCAÇÃO INFANTIL, o município possui: Comitê Intersetorial de Políticas Públicas para a Primeira Infância?',
  TX_Q099 = 'Para a EDUCAÇÃO INFANTIL, o município possui: Transporte escolar?',
  TX_Q100 = 'Para a EDUCAÇÃO INFANTIL, o município possui: Ações para atingir metas de matrícula (garantia de acesso)?',
  TX_Q101 = 'O município possui currículo municipal para a Educação Infantil?',
  TX_Q102 = 'O currículo municipal da educação infantil está atualizado conforme a BNCC - Base Nacional Comum Curricular?',
  TX_Q103 = 'Creche - Crianças de 0 a 3 anos?',
  TX_Q104 = 'Pré-escola - Crianças 4 a 5 anos?',
  TX_Q105 = 'As instituições conveniadas e/ou aquelas que celebram parcerias com o município são selecionadas através de chamada pública?',
  TX_Q106 = 'Existem normas para o funcionamento das conveniadas e/ou aquelas que celebram parcerias com o município?',
  TX_Q107 = 'Com relação à maior parte das instituições conveniadas e/ou aquelas que celebram parcerias com o município, indique o principal responsável pelas ações abaixo: Propriedade das instalações.',
  TX_Q108 = 'Com relação à maior parte das instituições conveniadas e/ou aquelas que celebram parcerias com o município, indique o principal responsável pelas ações abaixo: Manutenção das instalações.',
  TX_Q109 = 'Com relação à maior parte das instituições conveniadas e/ou aquelas que celebram parcerias com o município, indique o principal responsável pelas ações abaixo: Pagamento dos professores.',
  TX_Q110 = 'Com relação à maior parte das instituições conveniadas e/ou aquelas que celebram parcerias com o município, indique o principal responsável pelas ações abaixo: Capacitação dos professores.',
  TX_Q111 = 'Com relação à maior parte das instituições conveniadas e/ou aquelas que celebram parcerias com o município, indique o principal responsável pelas ações abaixo: Fornecimento de recursos pedagógicos.',
  TX_Q112 = 'Com relação à maior parte das instituições conveniadas e/ou aquelas que celebram parcerias com o município, indique o principal responsável pelas ações abaixo: Oferta de merenda.',
  TX_Q113 = 'Com relação à maior parte das instituições conveniadas e/ou aquelas que celebram parcerias com o município, indique o principal responsável pelas ações abaixo: Transporte escolar.',
  TX_Q114 = 'A Secretaria de Educação ou Órgão Gestor de Educação possui escolas de Ensino Fundamental?',
  TX_Q115 = 'O Ensino Fundamental é oferecido em ciclos?',
  TX_Q116 = 'A rede municipal de ensino utiliza um sistema apostilado desenvolvido por empresa, ONG ou instituição?',
  TX_Q117 = 'Para responder a esta questão, considere os funcionários/servidores que trabalham EXCLUSIVAMENTE na sede da Secretaria de Educação ou do Órgão Gestor de Educação. Quantos servidores/funcionários SEM FUNÇÕES DOCENTES lotados na sede da Secretaria de Educação ou do Órgão Gestor de Educação estão dedicados EXCLUSIVAMENTE ao Ensino Fundamental?',
  TX_Q118 = 'Para o ENSINO FUNDAMENTAL, o município possui: Cálculo da demanda por vagas?',
  TX_Q119 = 'Para o ENSINO FUNDAMENTAL, o município possui: Supervisão escolar?',
  TX_Q120 = 'Para o ENSINO FUNDAMENTAL, o município possui: Programa de formação de professores?',
  TX_Q121 = 'Para o ENSINO FUNDAMENTAL, o município possui: Busca ativa de crianças e jovens para o Ensino Fundamental?',
  TX_Q122 = 'Para o ENSINO FUNDAMENTAL, o município possui: Transporte escolar?',
  TX_Q123 = 'Para o ENSINO FUNDAMENTAL, o município possui: Ações para atingir metas de matrícula (garantia de acesso)?',
  TX_Q124 = 'O município possui currículo municipal para o Ensino Fundamental?',
  TX_Q125 = 'O currículo municipal está atualizado conforme a BNCC - Base Nacional Comum Curricular?',
  TX_Q126 = 'Auxiliares e assistentes da Educação Infantil.',
  TX_Q127 = 'Professores(as) da Educação Infantil.',
  TX_Q128 = 'Professores(as) do Ensino Fundamental.',
  TX_Q129 = 'Profissionais não docentes.',
  TX_Q130 = 'Até 20 horas semanais.',
  TX_Q131 = 'De 21 a 30 horas semanais.',
  TX_Q132 = 'De 31 a 40 horas semanais.',
  TX_Q133 = 'Mais de 40 horas semanais.',
  TX_Q134 = 'Para os(as) professores(as), está previsto o limite máximo de 2/3 da jornada de trabalho semanal em sala de aula?',
  TX_Q135 = 'Quais critérios de progressão ou promoção são utilizados no plano de carreira do magistério? Tempo de efetivo exercício no cargo.',
  TX_Q136 = 'Quais critérios de progressão ou promoção são utilizados no plano de carreira do magistério? Qualificação.',
  TX_Q137 = 'Quais critérios de progressão ou promoção são utilizados no plano de carreira do magistério? Titulação.',
  TX_Q138 = 'Quais critérios de progressão ou promoção são utilizados no plano de carreira do magistério? Assiduidade.',
  TX_Q139 = 'Quais critérios de progressão ou promoção são utilizados no plano de carreira do magistério? Avaliação de desempenho.',
  TX_Q140 = 'Quais critérios de progressão ou promoção são utilizados no plano de carreira do magistério? Prova de conhecimentos para professores.',
  TX_Q141 = 'Quais critérios de progressão ou promoção são utilizados no plano de carreira do magistério? Desempenho dos alunos em avaliações externas.',
  TX_Q142 = 'Para os(as) professores(as) com jornada de trabalho de 40 HORAS SEMANAIS, o VENCIMENTO INICIAL é igual ou superior a R$ 4.420,55?',
  TX_Q143 = 'O VENCIMENTO INICIAL dos(as) professores(as) de EDUCAÇÃO INFANTIL, comparado com o dos(as) professores(as) do Ensino Fundamental:',
  TX_Q144 = 'A Secretaria utiliza os resultados do IDEB?',
  TX_Q145 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Coletar informações para a formação continuada de professores.',
  TX_Q146 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Avaliar programas ou projetos da Secretaria de Educação ou Órgão Gestor de Educação.',
  TX_Q147 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Produzir materiais didáticos e pedagógicos pela Secretaria de Educação ou Órgão Gestor de Educação.',
  TX_Q148 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Adquirir materiais didáticos e pedagógicos de empresas ou instituições.',
  TX_Q149 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Premiar escolas com melhores resultados.',
  TX_Q150 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Desenvolver ações pedagógicas voltadas para unidades escolares com piores resultados.',
  TX_Q151 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Definir pagamento de bonificação para professores.',
  TX_Q152 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Definir remanejamento de diretores.',
  TX_Q153 = 'Indique o grau de importância que tem o Ideb para que a Secretaria de Educação ou Órgão Gestor de Educação do seu município possa desenvolver cada uma das seguintes ações: Autoavaliação da rede municipal de ensino.',
  TX_Q154 = 'O município aplica PROVAS EXTERNAS, preparadas pela Secretaria de Educação ou pelo Órgão Gestor de Educação ou por instituição contratada, aos estudantes da rede municipal?',
  TX_Q155 = 'Para cada etapa da Educação Básica, indique se são aplicadas, ou não, PROVAS EXTERNAS aos estudantes da rede municipal. Pré-escola',
  TX_Q156 = 'Quem é responsável por elaborar as PROVAS EXTERNAS aplicadas aos estudantes da pré-escola?',
  TX_Q157 = 'Indique as etapas da Educação Básica nas quais são aplicadas as provas preparadas pela secretaria ou instituicao contratada: Ensino Fundamental - Anos Iniciais',
  TX_Q158 = 'Quem é responsável por elaborar as PROVAS EXTERNAS aplicadas aos estudantes dos anos iniciais do Ensino Fundamental?',
  TX_Q159 = 'Indique as etapas da Educação Básica nas quais são aplicadas as provas preparadas pela secretaria ou instituicao contratada: Ensino Fundamental - Anos finais',
  TX_Q160 = 'Quem é responsável por elaborar as PROVAS EXTERNAS aplicadas aos estudantes dos anos finais do Ensino Fundamental?',
  TX_Q161 = 'Indique a periodicidade da aplicação das PROVAS EXTERNAS elaboradas pelo Secretaria de Educação ou pelo Órgão Gestor de Educação ou por instituição contratada: Mensal',
  TX_Q162 = 'Indique a periodicidade da aplicação das PROVAS EXTERNAS elaboradas pelo Secretaria de Educação ou pelo Órgão Gestor de Educação ou por instituição contratada: Bimestral',
  TX_Q163 = 'Indique a periodicidade da aplicação das PROVAS EXTERNAS elaboradas pelo Secretaria de Educação ou pelo Órgão Gestor de Educação ou por instituição contratada: Trimestral',
  TX_Q164 = 'Indique a periodicidade da aplicação das PROVAS EXTERNAS elaboradas pelo Secretaria de Educação ou pelo Órgão Gestor de Educação ou por instituição contratada: Semestral',
  TX_Q165 = 'Indique a periodicidade da aplicação das PROVAS EXTERNAS elaboradas pelo Secretaria de Educação ou pelo Órgão Gestor de Educação ou por instituição contratada: Anual',
  TX_Q166 = 'Indique a periodicidade da aplicação das PROVAS EXTERNAS elaboradas pelo Secretaria de Educação ou pelo Órgão Gestor de Educação ou por instituição contratada: Bianual',
  TX_Q167 = 'A Secretaria de Educação ou Órgão Gestor de Educação realiza PERIODICAMENTE monitoramento ou avaliação da sua rede de ensino?',
  TX_Q168 = 'Para cada uma das ações a seguir, indique se são, ou não, PERIODICAMENTE realizadas para monitorar ou avaliar a sua rede: Autoavaliação das escolas.',
  TX_Q169 = 'Para cada uma das ações a seguir, indique se são, ou não, PERIODICAMENTE realizadas para monitorar ou avaliar a sua rede: Avaliação do Projeto Pedagógico das escolas.',
  TX_Q170 = 'Para cada uma das ações a seguir, indique se são, ou não, PERIODICAMENTE realizadas para monitorar ou avaliar a sua rede: Desempenho dos(as) professores(as).',
  TX_Q171 = 'Para cada uma das ações a seguir, indique se são, ou não, PERIODICAMENTE realizadas para monitorar ou avaliar a sua rede: Desempenho dos(as) diretores(as) das escolas.',
  TX_Q172 = 'Para cada uma das ações a seguir, indique se são, ou não, PERIODICAMENTE realizadas para monitorar ou avaliar a sua rede: Infraestrutura das escolas.',
  TX_Q173 = 'Para cada uma das ações a seguir, indique se são, ou não, PERIODICAMENTE realizadas para monitorar ou avaliar a sua rede: Transporte escolar.',
  TX_Q174 = 'Para cada uma das ações a seguir, indique se são, ou não, PERIODICAMENTE realizadas para monitorar ou avaliar a sua rede: Merenda escolar.',
  TX_Q175 = 'Para cada uma das ações a seguir, indique se são, ou não, PERIODICAMENTE realizadas para monitorar ou avaliar a sua rede: Organização administrativa das escolas.'
)

# Aplicando LABELS às colunas de ITENS (Se a variável existe, o label correspondente é atribuído)
for (var in names(labels)) {
  if (var %in% names(TS_SECRETARIO_MUNICIPAL)) {
    attr(TS_SECRETARIO_MUNICIPAL[[var]], "label") <- labels[[var]]
  }
}
