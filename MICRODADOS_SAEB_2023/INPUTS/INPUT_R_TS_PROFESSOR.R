# /***************************************************************************************/
# /*  INEP/Daeb-Diretoria de Avaliação da Educação Básica                                */ 
# /*                                   			                                             */
# /*  Coordenação-Geral de Medidas da Educação Básica (CGMEB)                            */
# /*-------------------------------------------------------------------------------------*/
# /*  PROGRAMA:                                                                          */
# /*              INPUT_R_TS_PROFESSOR                                                   */
# /*-------------------------------------------------------------------------------------*/
# /*  DESCRICAO:  PROGRAMA PARA LEITURA DOS QUESTIONÁRIOS DOS PROFESSORES DO SAEB 2023   */
# /*                                                                                     */
# /***************************************************************************************/
# /***************************************************************************************/
# /* Obs:                                                                                */
# /* 		                                                                                 */
# /* Para abrir os microdados, é necessário salvar este programa e o arquivo             */
# /* TS_PROFESSOR.CSV no diretório C:\ do computador.	                                   */
# /*							                                                                       */ 
# /* Ao terminar esses procedimentos, execute o programa salvo utilizando                */
# /* as variáveis de interesse.                                                          */
# /***************************************************************************************/
# /*                                  ATENÇÃO                                            */ 
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
#setwd('C:/')
setwd('C:\\')

#------------------
# Carga dos microdados

TS_PROFESSOR <- data.table::fread(input='TS_PROFESSOR.csv',integer64='character')

# A script a seguir formata os rótulos das variáveis
# Para formatar um item retire o caracter de comentário (#) no início na linha desejada 
# (Para retirar o caracter de comentário de várias linhas de uma só vez, selecione as linhas desejadas e tecle ctrl+shift+c)
#---------------------------

# TS_PROFESSOR$ID_REGIAO <- factor(TS_PROFESSOR$ID_REGIAO, levels = c(1, 2, 3, 4, 5), labels = c('Norte', 'Nordeste', 'Sudeste', 'Sul', 'Centro-Oeste'))
# TS_PROFESSOR$ID_UF <- factor(TS_PROFESSOR$ID_UF, levels = c(11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29, 31, 32, 33, 35, 41, 42, 43, 50, 51, 52, 53), labels = c('RO', 'AC', 'AM', 'RR', 'PA', 'AP', 'TO', 'MA', 'PI', 'CE', 'RN', 'PB', 'PE', 'AL', 'SE', 'BA', 'MG', 'ES', 'RJ', 'SP', 'PR', 'SC', 'RS', 'MS', 'MT', 'GO', 'DF'))
# TS_PROFESSOR$ID_AREA <- factor(TS_PROFESSOR$ID_AREA, levels = c(2, 1), labels = c('Interior', 'Capital'))
# TS_PROFESSOR$IN_PUBLICA <- factor(TS_PROFESSOR$IN_PUBLICA, levels = c(0, 1), labels = c('Privada', 'Pública'))
# TS_PROFESSOR$ID_LOCALIZACAO <- factor(TS_PROFESSOR$ID_LOCALIZACAO, levels = c(1, 2), labels = c('Urbana', 'Rural'))
# TS_PROFESSOR$ID_SERIE <- factor(TS_PROFESSOR$ID_SERIE, levels = c(2, 5, 9, 12, 13), labels = c('2º Ano do Ensino Fundamental','5º Ano do Ensino Fundamental', '9º Ano do Ensino Fundamental', '3ª/4ª séries do Ensino Médio Tradicional', '3ª/4ª séries do Ensino Médio Integrado'))
# TS_PROFESSOR$SQ_QUESTIONARIO <- factor(TS_PROFESSOR$SQ_QUESTIONARIO, levels = c(0, 5, 1, 2, 3, 4), labels = c('Turmas que não participaram da aplicação do questionário eletrônico', 'Professor único - 2º e 5º ano', 'Língua /Literatura Portuguesa', 'Matemática', 'Ciências Humanas', 'Ciências Da Natureza'))
# TS_PROFESSOR$IN_PREENCHIMENTO_QUESTIONARIO <- factor(TS_PROFESSOR$IN_PREENCHIMENTO_QUESTIONARIO, levels = c(0, 1), labels = c('Não preenchido', 'Preenchido parcial ou totalmente'))
# TS_PROFESSOR$IN_PREENCHIMENTO_OUTRA_TURMA <- factor(TS_PROFESSOR$IN_PREENCHIMENTO_OUTRA_TURMA, levels = c(0, 1), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q001 <- factor(TS_PROFESSOR$TX_Q001, levels = c('A', 'B', 'C'), labels = c('Masculino', 'Feminino', 'Não quero declarar'))
# TS_PROFESSOR$TX_Q003 <- factor(TS_PROFESSOR$TX_Q003, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Branca', 'Preta', 'Parda', 'Amarela', 'Indígena', 'Não quero declarar'))
# TS_PROFESSOR$TX_Q004 <- factor(TS_PROFESSOR$TX_Q004, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q005 <- factor(TS_PROFESSOR$TX_Q005, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q006 <- factor(TS_PROFESSOR$TX_Q006, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q007 <- factor(TS_PROFESSOR$TX_Q007, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q008 <- factor(TS_PROFESSOR$TX_Q008, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q009 <- factor(TS_PROFESSOR$TX_Q009, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q010 <- factor(TS_PROFESSOR$TX_Q010, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q011 <- factor(TS_PROFESSOR$TX_Q011, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q012 <- factor(TS_PROFESSOR$TX_Q012, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q013 <- factor(TS_PROFESSOR$TX_Q013, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q014 <- factor(TS_PROFESSOR$TX_Q014, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q015 <- factor(TS_PROFESSOR$TX_Q015, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q016 <- factor(TS_PROFESSOR$TX_Q016, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q017 <- factor(TS_PROFESSOR$TX_Q017, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q018 <- factor(TS_PROFESSOR$TX_Q018, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q003 <- factor(TS_PROFESSOR$TX_Q003, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Branca', 'Preta', 'Parda', 'Amarela', 'Indígena', 'Não quero declarar'))
# TS_PROFESSOR$TX_Q019 <- factor(TS_PROFESSOR$TX_Q019, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q020 <- factor(TS_PROFESSOR$TX_Q020, levels = c('A', 'B', 'C', 'D', 'E'), labels = c('Ensino Médio - Magistério', 'Graduação', 'Especialização', 'Mestrado', 'Doutorado'))
# TS_PROFESSOR$TX_Q021 <- factor(TS_PROFESSOR$TX_Q021, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma', 'Uma', 'Duas', 'Três ou mais'))
# TS_PROFESSOR$TX_Q022 <- factor(TS_PROFESSOR$TX_Q022, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma', 'Uma', 'Duas', 'Três ou mais'))
# TS_PROFESSOR$TX_Q023 <- factor(TS_PROFESSOR$TX_Q023, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma', 'Uma', 'Duas', 'Três ou mais'))
# TS_PROFESSOR$TX_Q024 <- factor(TS_PROFESSOR$TX_Q024, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q025 <- factor(TS_PROFESSOR$TX_Q025, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q026 <- factor(TS_PROFESSOR$TX_Q026, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q027 <- factor(TS_PROFESSOR$TX_Q027, levels = c('A', 'B', 'C', 'D'), labels = c('Não contribuiu', 'Contribuiu pouco', 'Contribuiu razoavelmente', 'Contribuiu muito'))
# TS_PROFESSOR$TX_Q028 <- factor(TS_PROFESSOR$TX_Q028, levels = c('A', 'B', 'C', 'D'), labels = c('Não contribuiu', 'Contribuiu pouco', 'Contribuiu razoavelmente', 'Contribuiu muito'))
# TS_PROFESSOR$TX_Q029 <- factor(TS_PROFESSOR$TX_Q029, levels = c('A', 'B', 'C', 'D'), labels = c('Não contribuiu', 'Contribuiu pouco', 'Contribuiu razoavelmente', 'Contribuiu muito'))
# TS_PROFESSOR$TX_Q030 <- factor(TS_PROFESSOR$TX_Q030, levels = c('A', 'B', 'C', 'D'), labels = c('Não contribuiu', 'Contribuiu pouco', 'Contribuiu razoavelmente', 'Contribuiu muito'))
# TS_PROFESSOR$TX_Q031 <- factor(TS_PROFESSOR$TX_Q031, levels = c('A', 'B', 'C', 'D'), labels = c('Não contribuiu', 'Contribuiu pouco', 'Contribuiu razoavelmente', 'Contribuiu muito'))
# TS_PROFESSOR$TX_Q032 <- factor(TS_PROFESSOR$TX_Q032, levels = c('A', 'B', 'C', 'D'), labels = c('Não contribuiu', 'Contribuiu pouco', 'Contribuiu razoavelmente', 'Contribuiu muito'))
# TS_PROFESSOR$TX_Q033 <- factor(TS_PROFESSOR$TX_Q033, levels = c('A', 'B', 'C'), labels = c('Todas as atividades formativas', 'Algumas atividades formativas (ou parte delas)', 'Nenhuma atividade formativa'))
# TS_PROFESSOR$TX_Q034 <- factor(TS_PROFESSOR$TX_Q034, levels = c('A', 'B', 'C', 'D'), labels = c('Não fiz curso de pós-graduação', 'Especialização (mínimo de 360 horas)', 'Mestrado (acadêmico ou profissional)', 'Doutorado'))
# TS_PROFESSOR$TX_Q035 <- factor(TS_PROFESSOR$TX_Q035, levels = c('A', 'B', 'C'), labels = c('SEM apoio', 'Com apoio parcial', 'Com apoio total'))
# TS_PROFESSOR$TX_Q036 <- factor(TS_PROFESSOR$TX_Q036, levels = c('A', 'B', 'C'), labels = c('Curso gratuito', 'Curso pago por algum órgão ou instituição (total ou parcialmente)', 'Eu paguei integralmente o curso'))
# TS_PROFESSOR$TX_Q037 <- factor(TS_PROFESSOR$TX_Q037, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q038 <- factor(TS_PROFESSOR$TX_Q038, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q039 <- factor(TS_PROFESSOR$TX_Q039, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q040 <- factor(TS_PROFESSOR$TX_Q040, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q041 <- factor(TS_PROFESSOR$TX_Q041, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q042 <- factor(TS_PROFESSOR$TX_Q042, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q043 <- factor(TS_PROFESSOR$TX_Q043, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q044 <- factor(TS_PROFESSOR$TX_Q044, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q045 <- factor(TS_PROFESSOR$TX_Q045, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q046 <- factor(TS_PROFESSOR$TX_Q046, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q047 <- factor(TS_PROFESSOR$TX_Q047, levels = c('A', 'B', 'C', 'D'), labels = c('Nenhuma necessidade', 'Pouca necessidade', 'Moderada necessidade', 'Muita necessidade'))
# TS_PROFESSOR$TX_Q050 <- factor(TS_PROFESSOR$TX_Q050, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q051 <- factor(TS_PROFESSOR$TX_Q051, levels = c('A', 'B', 'C'), labels = c('Apenas nesta', 'Em 2', 'Em 3 ou mais'))
# TS_PROFESSOR$TX_Q052 <- factor(TS_PROFESSOR$TX_Q052, levels = c('A', 'B', 'C', 'D'), labels = c('Concursado/efetivo/estável', 'Contrato temporário', 'Contrato CLT', 'Outra situação trabalhista'))
# TS_PROFESSOR$TX_Q054 <- factor(TS_PROFESSOR$TX_Q054, levels = c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'), labels = c('Até R$ 1.320,00', 'De R$ 1.320,01 até R$ 2.640,00', 'De R$ 2.640,01 até R$ 3.960,00', 'De R$ 3.960,01 até R$ 5.280,00', 'De R$ 5.280,01 até R$ 6.600,00', 'De R$ 6.600,01 até R$ 7.920,00', 'De R$ 7.920,01 até R$ 9.240,00', 'Acima de R$ 9.240,00'))
# TS_PROFESSOR$TX_Q056 <- factor(TS_PROFESSOR$TX_Q056, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q057 <- factor(TS_PROFESSOR$TX_Q057, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q058 <- factor(TS_PROFESSOR$TX_Q058, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q059 <- factor(TS_PROFESSOR$TX_Q059, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q060 <- factor(TS_PROFESSOR$TX_Q060, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q061 <- factor(TS_PROFESSOR$TX_Q061, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q062 <- factor(TS_PROFESSOR$TX_Q062, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q063 <- factor(TS_PROFESSOR$TX_Q063, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q064 <- factor(TS_PROFESSOR$TX_Q064, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q065 <- factor(TS_PROFESSOR$TX_Q065, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q066 <- factor(TS_PROFESSOR$TX_Q066, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q067 <- factor(TS_PROFESSOR$TX_Q067, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q068 <- factor(TS_PROFESSOR$TX_Q068, levels = c('A', 'B', 'C', 'D'), labels = c('Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q069 <- factor(TS_PROFESSOR$TX_Q069, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Não tem', 'Não uso', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q070 <- factor(TS_PROFESSOR$TX_Q070, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Não tem', 'Não uso', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q071 <- factor(TS_PROFESSOR$TX_Q071, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Não tem', 'Não uso', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q072 <- factor(TS_PROFESSOR$TX_Q072, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Não tem', 'Não uso', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q073 <- factor(TS_PROFESSOR$TX_Q073, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Não tem', 'Não uso', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q074 <- factor(TS_PROFESSOR$TX_Q074, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Não tem', 'Não uso', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q075 <- factor(TS_PROFESSOR$TX_Q075, levels = c('A', 'B', 'C', 'D', 'E', 'F'), labels = c('Não tem', 'Não uso', 'Muito inadequado', 'Inadequado', 'Adequado', 'Muito adequado'))
# TS_PROFESSOR$TX_Q076 <- factor(TS_PROFESSOR$TX_Q076, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q077 <- factor(TS_PROFESSOR$TX_Q077, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q078 <- factor(TS_PROFESSOR$TX_Q078, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q079 <- factor(TS_PROFESSOR$TX_Q079, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q080 <- factor(TS_PROFESSOR$TX_Q080, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q081 <- factor(TS_PROFESSOR$TX_Q081, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q082 <- factor(TS_PROFESSOR$TX_Q082, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q083 <- factor(TS_PROFESSOR$TX_Q083, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q084 <- factor(TS_PROFESSOR$TX_Q084, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q085 <- factor(TS_PROFESSOR$TX_Q085, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q086 <- factor(TS_PROFESSOR$TX_Q086, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q087 <- factor(TS_PROFESSOR$TX_Q087, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q088 <- factor(TS_PROFESSOR$TX_Q088, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q089 <- factor(TS_PROFESSOR$TX_Q089, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q090 <- factor(TS_PROFESSOR$TX_Q090, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q091 <- factor(TS_PROFESSOR$TX_Q091, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q092 <- factor(TS_PROFESSOR$TX_Q092, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q093 <- factor(TS_PROFESSOR$TX_Q093, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q094 <- factor(TS_PROFESSOR$TX_Q094, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q095 <- factor(TS_PROFESSOR$TX_Q095, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q096 <- factor(TS_PROFESSOR$TX_Q096, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q097 <- factor(TS_PROFESSOR$TX_Q097, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q098 <- factor(TS_PROFESSOR$TX_Q098, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q099 <- factor(TS_PROFESSOR$TX_Q099, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q100 <- factor(TS_PROFESSOR$TX_Q100, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q101 <- factor(TS_PROFESSOR$TX_Q101, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não sei'))
# TS_PROFESSOR$TX_Q102 <- factor(TS_PROFESSOR$TX_Q102, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não sei'))
# TS_PROFESSOR$TX_Q103 <- factor(TS_PROFESSOR$TX_Q103, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não sei'))
# TS_PROFESSOR$TX_Q104 <- factor(TS_PROFESSOR$TX_Q104, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não sei'))
# TS_PROFESSOR$TX_Q105 <- factor(TS_PROFESSOR$TX_Q105, levels = c('A', 'B', 'C'), labels = c('Não', 'Sim', 'Não sei'))
# TS_PROFESSOR$TX_Q106 <- factor(TS_PROFESSOR$TX_Q106, levels = c('A', 'B'), labels = c('Não', 'Sim'))
# TS_PROFESSOR$TX_Q109 <- factor(TS_PROFESSOR$TX_Q109, levels = c('A', 'B', 'C', 'D'), labels = c('Docente da turma', 'Todo o corpo docente da escola', 'Equipe gestora', 'Decisão externa à escola (Secretaria de Educação, sistema apostilado de ensino etc.)'))
# TS_PROFESSOR$TX_Q110 <- factor(TS_PROFESSOR$TX_Q110, levels = c('A', 'B', 'C', 'D'), labels = c('Docente da turma', 'Todo o corpo docente da escola', 'Equipe gestora', 'Decisão externa à escola (Secretaria de Educação, sistema apostilado de ensino etc.)'))
# TS_PROFESSOR$TX_Q111 <- factor(TS_PROFESSOR$TX_Q111, levels = c('A', 'B', 'C', 'D'), labels = c('Docente da turma', 'Todo o corpo docente da escola', 'Equipe gestora', 'Decisão externa à escola (Secretaria de Educação, sistema apostilado de ensino etc.)'))
# TS_PROFESSOR$TX_Q112 <- factor(TS_PROFESSOR$TX_Q112, levels = c('A', 'B', 'C', 'D'), labels = c('Docente da turma', 'Todo o corpo docente da escola', 'Equipe gestora', 'Decisão externa à escola (Secretaria de Educação, sistema apostilado de ensino etc.)'))
# TS_PROFESSOR$TX_Q113 <- factor(TS_PROFESSOR$TX_Q113, levels = c('A', 'B', 'C', 'D'), labels = c('Docente da turma', 'Todo o corpo docente da
# TS_PROFESSOR$TX_Q114 <- factor(TS_PROFESSOR$TX_Q114, levels = c('A', 'B', 'C', 'D'), labels = c('Docente da turma', 'Todo o corpo docente da escola', 'Equipe gestora', 'Decisão externa à escola (Secretaria de Educação, sistema apostilado de ensino etc.)'))
# TS_PROFESSOR$TX_Q115 <- factor(TS_PROFESSOR$TX_Q115, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q116 <- factor(TS_PROFESSOR$TX_Q116, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q117 <- factor(TS_PROFESSOR$TX_Q117, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q118 <- factor(TS_PROFESSOR$TX_Q118, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q119 <- factor(TS_PROFESSOR$TX_Q119, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q120 <- factor(TS_PROFESSOR$TX_Q120, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q121 <- factor(TS_PROFESSOR$TX_Q121, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q122 <- factor(TS_PROFESSOR$TX_Q122, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q123 <- factor(TS_PROFESSOR$TX_Q123, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q124 <- factor(TS_PROFESSOR$TX_Q124, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q125 <- factor(TS_PROFESSOR$TX_Q125, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q126 <- factor(TS_PROFESSOR$TX_Q126, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q127 <- factor(TS_PROFESSOR$TX_Q127, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q128 <- factor(TS_PROFESSOR$TX_Q128, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q129 <- factor(TS_PROFESSOR$TX_Q129, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q130 <- factor(TS_PROFESSOR$TX_Q130, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q131 <- factor(TS_PROFESSOR$TX_Q131, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q132 <- factor(TS_PROFESSOR$TX_Q132, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q133 <- factor(TS_PROFESSOR$TX_Q133, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q134 <- factor(TS_PROFESSOR$TX_Q134, levels = c('A', 'B', 'C', 'D'), labels = c('Discordo fortemente', 'Discordo', 'Concordo', 'Concordo fortemente'))
# TS_PROFESSOR$TX_Q135 <- factor(TS_PROFESSOR$TX_Q135, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q136 <- factor(TS_PROFESSOR$TX_Q136, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q137 <- factor(TS_PROFESSOR$TX_Q137, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q138 <- factor(TS_PROFESSOR$TX_Q138, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q139 <- factor(TS_PROFESSOR$TX_Q139, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q140 <- factor(TS_PROFESSOR$TX_Q140, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q141 <- factor(TS_PROFESSOR$TX_Q141, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q142 <- factor(TS_PROFESSOR$TX_Q142, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q143 <- factor(TS_PROFESSOR$TX_Q143, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q144 <- factor(TS_PROFESSOR$TX_Q144, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q145 <- factor(TS_PROFESSOR$TX_Q145, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q146 <- factor(TS_PROFESSOR$TX_Q146, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))
# TS_PROFESSOR$TX_Q147 <- factor(TS_PROFESSOR$TX_Q147, levels = c('A', 'B', 'C', 'D'), labels = c('Nunca', 'Poucas vezes', 'Muitas vezes', 'Sempre'))

labels <- list(
  ID_SAEB = 'Ano de Aplicação do Saeb',                                                                                                    
  ID_REGIAO = 'Código da Região',                                                                                                                         
  ID_UF = 'Código da Unidade da Federação' ,
  ID_MUNICIPIO = 'Máscaras dos Códigos de Municípios (são códigos fictícios)',
  ID_AREA = 'Área',
  ID_ESCOLA = 'Máscaras dos Códigos de Escola (são códigos fictícios)',
  IN_PUBLICA = 'Indica se a escola é pública ou não',
  ID_LOCALIZACAO = 'Localização',
  ID_TURMA = 'Código da turma no Saeb',
  ID_PROFESSOR = 'Código do Professor no Saeb',
  ID_SERIE = 'Ano Escolar',
  SQ_QUESTIONARIO = 'Sequencial do questionário na turma',
  IN_PREENCHIMENTO_QUESTIONARIO = 'Indicador de preenchimento do questionário',
  IN_PREENCHIMENTO_OUTRA_TURMA = 'Indicador de preenchimento do questionário para outra turma, pelo mesmo professor',
  TX_Q001 = 'Qual é o seu sexo?',
  TX_Q002 = 'Qual é a sua idade?',
  TX_Q003 = 'Qual é a sua cor ou raça?',
  TX_Q004 = 'Você possui deficiência, transtorno do espectro autista ou superdotação?',
  TX_Q005 = 'Indique qual é a sua condição:  Deficiência.',
  TX_Q006 = 'Indique qual é a sua condição: Transtorno do espectro autista.',
  TX_Q007 = 'Indique qual é a sua condição: Altas habilidades/superdotação.',
  TX_Q008 = 'Leio livros não relacionados à Educação.',
  TX_Q009 = 'Acesso blogs, Youtube, redes sociais (Twitter, Instagram, Facebook etc.).',
  TX_Q010 = 'Assisto a filmes.',
  TX_Q011 = 'Vou a exposições (museus, centros culturais).',
  TX_Q012 = 'Assisto a espetáculos (teatro, shows, circo, etc)',
  TX_Q013 = 'Estudo.',
  TX_Q014 = 'Assisto a telejornal.',
  TX_Q015 = 'Tornar-me professor(a) foi a realização de um dos meus sonhos.',
  TX_Q016 = 'A profissão de professor(a) é valorizada pela sociedade.',
  TX_Q017 = 'As vantagens de ser professor(a) superam claramente as desvantagens.',
  TX_Q018 = 'No geral, estou satisfeito(a) com o meu trabalho de professor(a).',
  TX_Q019 = 'Tenho vontade de desistir da profissão',
  TX_Q020 = 'Qual é o MAIS ALTO nível de escolaridade que você concluiu?',
  TX_Q021 = 'Atividades formativas com menos de 20 horas',
  TX_Q022 = 'Curso com carga horária total de 20 horas até 179 horas.',
  TX_Q023 = 'Curso com carga horária total com mais de 180 e menos 360 horas',
  TX_Q024 = 'Considerando as atividades formativas de curta duração (inferiores a 360 horas) das quais participou neste ano, com que frequência estava previsto: Participação de professor(es) da(s) escola(s) em que leciono?',
  TX_Q025 = 'Considerando as atividades formativas de curta duração (inferiores a 360 horas) das quais participou neste ano, com que frequência estava previsto: Atividades colaborativas de aprendizado?',
  TX_Q026 = 'Considerando as atividades formativas de curta duração (inferiores a 360 horas) das quais participou neste ano, com que frequência estava previsto: Atividades intercaladas com seu trabalho normal de sala de aula?',
  TX_Q027 = 'Indique o nível de contribuição das atividades formativas e cursos realizados neste ano para:  Aprofundar seus conhecimentos sobre as disciplinas que leciona.',
  TX_Q028 = 'Indique o nível de contribuição das atividades formativas e cursos realizados neste ano para:  Aprimorar os processos avaliativos.',
  TX_Q029 = 'Indique o nível de contribuição das atividades formativas e cursos realizados neste ano para:  Utilizar novas tecnologias para apoiar suas atividades.',
  TX_Q030 = 'Indique o nível de contribuição das atividades formativas e cursos realizados neste ano para:  Colaborar com seus colegas na preparação de atividades e projetos.',
  TX_Q031 = 'Indique o nível de contribuição das atividades formativas e cursos realizados neste ano para:  Aprimorar as metodologias de ensino.',
  TX_Q032 = 'Indique o nível de contribuição das atividades formativas e cursos realizados neste ano para:  Auxiliar na mediação de conflitos.',
  TX_Q033 = 'Dentre as atividades formativas listadas anteriormente das quais você participou neste ano, a instituição ou Secretaria de Educação financiou:',
  TX_Q034 = 'Durante este ano, indique se participou de algum dos cursos de pós-graduação listados abaixo:',
  TX_Q035 = 'Recebeu apoio da Secretaria ou mantenedora para realizá-lo?',
  TX_Q036 = 'Indique quem pagou por esse curso de pós-graduação:',
  TX_Q037 = 'Uso de novas tecnologias de informação e comunicação.',
  TX_Q038 = 'Gestão de conflitos.',
  TX_Q039 = 'Metodologia de avaliação.',
  TX_Q040 = 'Metodologia de ensino para o público-alvo da educação especial.',
  TX_Q041 = 'Utilização de elementos da cultura local na prática pedagógica.',
  TX_Q042 = 'Identificação de problemas extraescolares.',
  TX_Q043 = 'Gestão democrática.',
  TX_Q044 = 'Ensino do conteúdo que leciono.',
  TX_Q045 = 'Desenvolvimento da aprendizagem.',
  TX_Q046 = 'Planejamento pedagógico.',
  TX_Q047 = 'Recursos e práticas pedagógicas.',
  TX_Q048 = 'Há quantos anos você trabalha como professor(a)?',
  TX_Q049 = 'Há quantos anos você trabalha como professor(a) nesta escola?',
  TX_Q050 = 'Além de ser professor(a), você exerce outra atividade remunerada?',
  TX_Q051 = 'Em quantas escolas você trabalha?',
  TX_Q052 = 'Qual o seu tipo de vínculo trabalhista nesta escola?',
  TX_Q053 = 'Qual a sua carga horária semanal total de trabalho como professor(a)?',
  TX_Q054 = 'Qual é o seu salário bruto como professor(a)? Indique a faixa salarial em que seu salário se encontra.',
  TX_Q055 = 'Nesta escola, quantas horas você trabalha em uma semana normal (desenvolvendo as atividades pedagógicas, presente em sala, preparando atividades, murais, participando de reuniões etc.)?',
  TX_Q056 = 'Esta escola, em seu planejamento, prevê um tempo para atividades como preparação de aulas, reuniões, atendimento aos pais etc.?',
  TX_Q057 = 'Em uma semana normal de trabalho, você costuma levar trabalho desta escola para fazer em casa?',
  TX_Q058 = 'Tamanho da sala com relação ao número de estudantes.',
  TX_Q059 = 'Acústica.',
  TX_Q060 = 'Iluminação natural.',
  TX_Q061 = 'Ventilação natural.',
  TX_Q062 = 'Temperatura.',
  TX_Q063 = 'Instalações elétricas.',
  TX_Q064 = 'Limpeza.',
  TX_Q065 = 'Acessibilidade física.',
  TX_Q066 = 'Mobiliário (mesas, carteiras, armários).',
  TX_Q067 = 'Infraestrutura (paredes, teto, assoalho, portas, piso).',
  TX_Q068 = 'Lousa (quadro de giz ou quadro branco).',
  TX_Q069 = 'Livro didático.',
  TX_Q070 = 'Televisão.',
  TX_Q071 = 'Projetor multimídia (datashow).',
  TX_Q072 = 'Computador (de mesa, portátil, tablet).',
  TX_Q073 = 'Software.',
  TX_Q074 = 'Internet.',
  TX_Q075 = 'Recursos pedagógicos para atendimento educacional especializado.',
  TX_Q076 = 'Repetir de ano é bom para o(a) estudante que não apresentou desempenho satisfatório.',
  TX_Q077 = 'A quantidade de avaliações externas (municipais, estaduais ou federais) é excessiva.',
  TX_Q078 = 'As avaliações externas (municipais, estaduais ou federais) têm direcionado o que deve ser ensinado.',
  TX_Q079 = 'As avaliações externas têm ajudado a melhorar o processo de ensino e aprendizagem.',
  TX_Q080 = 'A maior parte dos estudantes apresentam problemas de aprendizagem.',
  TX_Q081 = 'Propor dever de casa.',
  TX_Q082 = 'Corrigir com os(as) estudantes o dever de casa.',
  TX_Q083 = 'Desenvolver trabalhos em grupo com os(as) estudantes.',
  TX_Q084 = 'Solicitar que os(as) estudantes copiem textos e atividades do livro didático ou da lousa (quadro de giz ou quadro branco).',
  TX_Q085 = 'Estimular os(as) estudantes a expressarem suas opiniões e a desenvolverem argumentos a partir de temas diversos.',
  TX_Q086 = 'Propor situações de aprendizagem que sejam familiares ou de interesse dos(as) estudantes.',
  TX_Q087 = 'Informar aos(às) estudantes, no início do ano, o que será ensinado ou aprendido.',
  TX_Q088 = 'Perguntar aos(às) estudantes o que sabem sobre o tema, ao iniciar um novo conteúdo.',
  TX_Q089 = 'Trazer temas do cotidiano para serem debatidos em sala de aula.',
  TX_Q090 = 'Diversificar as metodologias de ensino conforme as dificuldades dos(as) estudantes.',
  TX_Q091 = 'Considerar que os resultados das avaliações indicam o quanto os(as) estudantes aprenderam.',
  TX_Q092 = 'Buscar estratégias para melhorar a aprendizagem dos(as) estudantes com menor desempenho.',
  TX_Q093 = 'Abordar questões sobre desigualdade racial com os(as) estudantes.',
  TX_Q094 = 'Abordar questões sobre desigualdade de gênero com os(as) estudantes.',
  TX_Q095 = 'Abordar questões sobre bullying e outras formas de violência com os(as) estudantes.',
  TX_Q096 = 'Abordar questões relacionadas ao futuro profissional dos(as) estudantes.',
  TX_Q097 = 'Há estudantes público-alvo da educação especial nesta escola?',
  TX_Q098 = 'Indique com que frequência a escola oferece suporte para os estudantes público-alvo da educação especial.',
  TX_Q099 = 'Há um espaço para atendimento educacional especializado na escola?',
  TX_Q100 = 'A escola possui Projeto Político-Pedagógico?',
  TX_Q101 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Seu conteúdo é discutido em reuniões?',
  TX_Q102 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Os(As) professores(as) participaram da elaboração.',
  TX_Q103 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Os profissionais não docentes participaram da elaboração?',
  TX_Q104 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Os pais participaram da elaboração?',
  TX_Q105 = 'Indique se as situações abaixo se aplicam ou não ao Projeto Político-Pedagógico desta escola. Os(As) estudantes participaram da elaboração?',
  TX_Q106 = 'Há Conselho de Classe na sua escola?',
  TX_Q107 = 'Quantas vezes o Conselho de Classe se reuniu neste ano?',
  TX_Q108 = 'Quantos estudantes, NORMALMENTE, participam do Conselho de Classe por reunião?',
  TX_Q109 = 'Escolha do material didático.',
  TX_Q110 = 'Metodologia de ensino.',
  TX_Q111 = 'Conteúdos trabalhados em sala.',
  TX_Q112 = 'Instrumentos para avaliar os(as) estudantes.',
  TX_Q113 = 'Peso de cada instrumento de avaliação nas notas finais dos(as) estudantes.',
  TX_Q114 = 'Seleção de conteúdos usados nas provas.',
  TX_Q115 = 'O(A) diretor(a) debate as metas educacionais com os(as) professores(as) nas reuniões.',
  TX_Q116 = 'O(A) diretor(a) e os(as) professores(as) tratam a qualidade de ensino como uma responsabilidade coletiva.',
  TX_Q117 = 'O(A) diretor(a) informa aos(às) professores(as) sobre as possibilidades de aperfeiçoamento profissional.',
  TX_Q118 = 'O(A) diretor(a) dá atenção especial a aspectos relacionados à aprendizagem dos(as) estudantes.',
  TX_Q119 = 'O(A) diretor(a) dá atenção especial a aspectos relacionados às normas administrativas.',
  TX_Q120 = 'O(A) diretor(a) me anima e me motiva para o trabalho.',
  TX_Q121 = 'Tenho confiança no(a) diretor(a) como profissional.',
  TX_Q122 = 'O(A) diretor(a) e os(as) professores(as) asseguram que as questões relacionadas à qualidade da convivência e gestão de conflitos sejam uma responsabilidade coletiva.',
  TX_Q123 = 'Colaboração da família para superar problemas relacionados aos estudantes (ausências, acompanhamento das atividades escolares etc.).',
  TX_Q124 = 'Colaboração entre colegas (feedback, trocas, projetos interdisciplinares).',
  TX_Q125 = 'Colaboração da gestão da instituição (equipe gestora, equipe pedagógica) para superar dificuldades de sala de aula.',
  TX_Q126 = 'Apoio da Secretaria de Educação para superar as dificuldades do cotidiano escolar.',
  TX_Q127 = 'Respeitam os acordos estabelecidos em sala.',
  TX_Q128 = 'São assíduos(as).',
  TX_Q129 = 'São respeitosos(as) comigo.',
  TX_Q130 = 'São respeitosos(as) com os(as) colegas da turma.',
  TX_Q131 = 'Expressam diferentes opiniões.',
  TX_Q132 = 'Se interessam sobre o que ensinei neste ano.',
  TX_Q133 = 'Sentem-se motivados(as) para aprender os temas ligados à minha disciplina.',
  TX_Q134 = 'São capazes de concluir a Educação Básica e prosseguir seus estudos.',
  TX_Q135 = 'Atentado à vida.',
  TX_Q136 = 'Lesão corporal.',
  TX_Q137 = 'Roubo ou furto.',
  TX_Q138 = 'Tráfico de drogas.',
  TX_Q139 = 'Permanência de pessoas sob efeito de álcool.',
  TX_Q140 = 'Permanência de pessoas sob efeito de drogas.',
  TX_Q141 = 'Porte de arma (revólver, faca, canivete).',
  TX_Q142 = 'Assédio sexual.',
  TX_Q143 = 'Discriminação (racial, gênero, orientação sexual, econômica/social, deficiência etc.).',
  TX_Q144 = 'Bullying (ameaças ou ofensas verbais).',
  TX_Q145 = 'Invasão do espaço escolar.',
  TX_Q146 = 'Depredação do patrimônio escolar (vandalismo).',
  TX_Q147 = 'Tiroteio ou bala perdida.',
  TX_Q148 = 'Sugestões de melhoria para o instrumento (inclusão de temas, estrutura do questionário etc.)' 
)

# Aplicando LABELS às colunas de ITENS (Se a variável existe, o label correspondente é atribuído)
for (var in names(labels)) {
  if (var %in% names(TS_PROFESSOR)) {
    attr(TS_PROFESSOR[[var]], "label") <- labels[[var]]
  }
}

