# /***************************************************************************************/
# /*  INEP/Daeb-Diretoria de Avaliação da Educação Básica                                */ 
# /*                                   			                                             */
# /*  Coordenação-Geral de Medidas da Educação Básica (CGMEB)                            */
# /*-------------------------------------------------------------------------------------*/
# /*  PROGRAMA:                                                                          */
# /*               INPUT_R_TS_ALUNO_34EM                                                 */
# /*-------------------------------------------------------------------------------------*/
# /* DESCRICAO:    PROGRAMA PARA LEITURA DOS RESULTADOS DOS ALUNOS DA                    */
# /*                   3ª/4ª SÉRIE DO ENSINO MÉDIO DO SAEB 2023                          */
# /***************************************************************************************/
# /***************************************************************************************/
# /* Obs:                                                                                */
# /* 		                                                                                 */
# /* Para abrir os microdados, é necessário salvar este programa e o arquivo             */
# /* TS_ALUNO_34EM.CSV no diretório C:\ do computador.	                                 */
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
# Localiza o arquivo CSV automaticamente, usando a pasta do script
#--------------------
script_dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)), error = function(e) getwd())
base_dir <- normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = FALSE)
csv_path <- file.path(base_dir, "DADOS", "TS_ALUNO_34EM.csv")

if (!file.exists(csv_path)) {
  stop(paste0("Arquivo nao encontrado: ", csv_path))
}

#------------------
# Carga dos microdados

TS_ALUNO_34EM <- data.table::fread(input = csv_path, integer64 = 'character')

# A script a seguir formata os rótulos das variáveis
# Para formatar um item retire o caracter de comentário (#) no início na linha desejada 
# (Para retirar o caracter de comentário de várias linhas de uma só vez, selecione as linhas desejadas e tecle ctrl+shift+c)
#---------------------------

# TS_ALUNO_34EM$ID_REGIAO <- factor(TS_ALUNO_34EM$ID_REGIAO, levels = c(1, 2, 3, 4, 5), labels = c('Norte', 'Nordeste', 'Sudeste', 'Sul', 'Centro-Oeste'))
# TS_ALUNO_34EM$ID_UF <- factor(TS_ALUNO_34EM$ID_UF, levels = c(11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29, 31, 32, 33, 35, 41, 42, 43, 50, 51, 52, 53), labels = c('RO', 'AC', 'AM', 'RR', 'PA', 'AP', 'TO', 'MA', 'PI', 'CE', 'RN', 'PB', 'PE', 'AL', 'SE', 'BA', 'MG', 'ES', 'RJ', 'SP', 'PR', 'SC', 'RS', 'MS', 'MT', 'GO', 'DF'))
# TS_ALUNO_34EM$ID_AREA <- factor(TS_ALUNO_34EM$ID_AREA, levels = c(1, 2), labels = c('Capital', 'Interior'))
# TS_ALUNO_34EM$IN_PUBLICA <- factor(TS_ALUNO_34EM$IN_PUBLICA, levels = c(0, 1), labels = c('Privada', 'Pública'))
# TS_ALUNO_34EM$ID_LOCALIZACAO <- factor(TS_ALUNO_34EM$ID_LOCALIZACAO, levels = c(1, 2), labels = c('Urbana', 'Rural'))
# TS_ALUNO_34EM$ID_SERIE <- factor(TS_ALUNO_34EM$ID_SERIE, levels = c(12, 13), labels = c('3ª/4ª séries do Ensino Médio Tradicional', '3ª/4ª séries do Ensino Médio Integrado'))
# TS_ALUNO_34EM$IN_SITUACAO_CENSO <- factor(TS_ALUNO_34EM$IN_SITUACAO_CENSO, levels = c(0, 1), labels = c('Não consistente', 'Consistente'))
# TS_ALUNO_34EM$IN_PREENCHIMENTO_LP <- factor(TS_ALUNO_34EM$IN_PREENCHIMENTO_LP, levels = c(0, 1), labels = c('Prova não preenchida', 'Prova preenchida'))
# TS_ALUNO_34EM$IN_PREENCHIMENTO_MT <- factor(TS_ALUNO_34EM$IN_PREENCHIMENTO_MT, levels = c(0, 1), labels = c('Prova não preenchida', 'Prova preenchida'))
# TS_ALUNO_34EM$IN_PRESENCA_LP <- factor(TS_ALUNO_34EM$IN_PRESENCA_LP, levels = c(0, 1), labels = c('Ausente', 'Presente'))
# TS_ALUNO_34EM$IN_PRESENCA_MT <- factor(TS_ALUNO_34EM$IN_PRESENCA_MT, levels = c(0, 1), labels = c('Ausente', 'Presente'))
# TS_ALUNO_34EM$IN_PROFICIENCIA_LP <- factor(TS_ALUNO_34EM$IN_PROFICIENCIA_LP, levels = c(0, 1), labels = c('Não', 'Sim'))
# TS_ALUNO_34EM$IN_PROFICIENCIA_MT <- factor(TS_ALUNO_34EM$IN_PROFICIENCIA_MT, levels = c(0, 1), labels = c('Não', 'Sim'))
# TS_ALUNO_34EM$IN_AMOSTRA <- factor(TS_ALUNO_34EM$IN_AMOSTRA, levels = c(0, 1), labels = c('Não', 'Sim'))
# TS_ALUNO_34EM$IN_PREENCHIMENTO_QUESTIONARIO <- factor(TS_ALUNO_34EM$IN_PREENCHIMENTO_QUESTIONARIO, levels = c(0, 1), labels = c('Não preenchido', 'Preenchido parcial ou totalmente'))
# TS_ALUNO_34EM$IN_INSE <- factor(TS_ALUNO_34EM$IN_INSE, levels = c(0, 1), labels = c('Não', 'Sim'))
# TS_ALUNO_34EM$NU_TIPO_NIVEL_INSE <- factor(TS_ALUNO_34EM$NU_TIPO_NIVEL_INSE, levels = c(1, 2, 3, 4, 5, 6, 7, 8), labels = c('Nível I', 'Nível II', 'Nível III', 'Nível IV', 'Nível V', 'Nível VI', 'Nível VII', 'Nível VIII'))
# TS_ALUNO_34EM$TX_RESP_Q01_ <- factor(TS_ALUNO_34EM$TX_RESP_Q01_, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Masculino', 'Feminino', 'Não quero declarar'))
# TS_ALUNO_34EM$TX_RESP_Q02_ <- factor(TS_ALUNO_34EM$TX_RESP_Q02_, levels = c('*', '.', 'A', 'B', 'C', 'D', 'E', 'F'), labels = c('Nulo', 'Branco', '16 anos ou menos', '17 anos', '18 anos', '19 anos', '20 anos', '21 anos ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q03_ <- factor(TS_ALUNO_34EM$TX_RESP_Q03_, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Português', 'Espanhol', 'Língua de Sinais', 'Outra língua'))
# TS_ALUNO_34EM$TX_RESP_Q04_ <- factor(TS_ALUNO_34EM$TX_RESP_Q04_, levels = c('*', '.', 'A', 'B', 'C', 'D', 'E', 'F'), labels = c('Nulo', 'Branco', 'Branca', 'Preta', 'Parda', 'Amarela', 'Indígena', 'Não quero declarar'))
# TS_ALUNO_34EM$TX_RESP_Q05a <- factor(TS_ALUNO_34EM$TX_RESP_Q05a, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q05b <- factor(TS_ALUNO_34EM$TX_RESP_Q05b, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q05c <- factor(TS_ALUNO_34EM$TX_RESP_Q05c, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q06_ <- factor(TS_ALUNO_34EM$TX_RESP_Q06_, levels = c('*', '.', 'A', 'B', 'C', 'D', 'E'), labels = c('Nulo', 'Branco', '2 pessoas', '3 pessoas', '4 pessoas', '5 pessoas', '6 pessoas ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q07a <- factor(TS_ALUNO_34EM$TX_RESP_Q07a, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q07b <- factor(TS_ALUNO_34EM$TX_RESP_Q07b, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q07c <- factor(TS_ALUNO_34EM$TX_RESP_Q07c, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q07d <- factor(TS_ALUNO_34EM$TX_RESP_Q07d, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q07e <- factor(TS_ALUNO_34EM$TX_RESP_Q07e, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q08_ <- factor(TS_ALUNO_34EM$TX_RESP_Q08_, levels = c('*', '.', 'A', 'B', 'C', 'D', 'E', 'F'), labels = c('Nulo', 'Branco', 'Não completou o 5º ano do Ensino Fundamental', 'Ensino Fundamental, até o 5º ano', 'Ensino Fundamental completo', 'Ensino Médio completo', 'Ensino Superior completo (faculdade ou graduação)', 'Não sei'))
# TS_ALUNO_34EM$TX_RESP_Q09_ <- factor(TS_ALUNO_34EM$TX_RESP_Q09_, levels = c('*', '.', 'A', 'B', 'C', 'D', 'E', 'F'), labels = c('Nulo', 'Branco', 'Não completou o 5º ano do Ensino Fundamental', 'Ensino Fundamental, até o 5º ano', 'Ensino Fundamental completo', 'Ensino Médio completo', 'Ensino Superior completo (faculdade ou graduação)', 'Não sei'))
# TS_ALUNO_34EM$TX_RESP_Q10a <- factor(TS_ALUNO_34EM$TX_RESP_Q10a, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Nunca ou quase nunca', 'De vez em quando', 'Sempre ou quase sempre'))
# TS_ALUNO_34EM$TX_RESP_Q10b <- factor(TS_ALUNO_34EM$TX_RESP_Q10b, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Nunca ou quase nunca', 'De vez em quando', 'Sempre ou quase sempre'))
# TS_ALUNO_34EM$TX_RESP_Q10c <- factor(TS_ALUNO_34EM$TX_RESP_Q10c, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Nunca ou quase nunca', 'De vez em quando', 'Sempre ou quase sempre'))
# TS_ALUNO_34EM$TX_RESP_Q10d <- factor(TS_ALUNO_34EM$TX_RESP_Q10d, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Nunca ou quase nunca', 'De vez em quando', 'Sempre ou quase sempre'))
# TS_ALUNO_34EM$TX_RESP_Q10e <- factor(TS_ALUNO_34EM$TX_RESP_Q10e, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Nunca ou quase nunca', 'De vez em quando', 'Sempre ou quase sempre'))
# TS_ALUNO_34EM$TX_RESP_Q10f <- factor(TS_ALUNO_34EM$TX_RESP_Q10f, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Nunca ou quase nunca', 'De vez em quando', 'Sempre ou quase sempre'))
# TS_ALUNO_34EM$TX_RESP_Q11a <- factor(TS_ALUNO_34EM$TX_RESP_Q11a, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q11b <- factor(TS_ALUNO_34EM$TX_RESP_Q11b, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q11c <- factor(TS_ALUNO_34EM$TX_RESP_Q11c, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q12a <- factor(TS_ALUNO_34EM$TX_RESP_Q12a, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Nenhum', '1', '2', '3 ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q12b <- factor(TS_ALUNO_34EM$TX_RESP_Q12b, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Nenhum', '1', '2', '3 ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q12c <- factor(TS_ALUNO_34EM$TX_RESP_Q12c, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Nenhum', '1', '2', '3 ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q12d <- factor(TS_ALUNO_34EM$TX_RESP_Q12d, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Nenhum', '1', '2', '3 ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q12e <- factor(TS_ALUNO_34EM$TX_RESP_Q12e, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Nenhum', '1', '2', '3 ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q12f <- factor(TS_ALUNO_34EM$TX_RESP_Q12f, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Nenhum', '1', '2', '3 ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q12g <- factor(TS_ALUNO_34EM$TX_RESP_Q12g, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Nenhum', '1', '2', '3 ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q13a <- factor(TS_ALUNO_34EM$TX_RESP_Q13a, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q13b <- factor(TS_ALUNO_34EM$TX_RESP_Q13b, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q13c <- factor(TS_ALUNO_34EM$TX_RESP_Q13c, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q13d <- factor(TS_ALUNO_34EM$TX_RESP_Q13d, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q13e <- factor(TS_ALUNO_34EM$TX_RESP_Q13e, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q13f <- factor(TS_ALUNO_34EM$TX_RESP_Q13f, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q13g <- factor(TS_ALUNO_34EM$TX_RESP_Q13g, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q13h <- factor(TS_ALUNO_34EM$TX_RESP_Q13h, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q13i <- factor(TS_ALUNO_34EM$TX_RESP_Q13i, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q14_ <- factor(TS_ALUNO_34EM$TX_RESP_Q14_, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Menos de 30 minutos', 'Entre 30 minutos e uma hora', 'Mais de uma hora'))
# TS_ALUNO_34EM$TX_RESP_Q15a <- factor(TS_ALUNO_34EM$TX_RESP_Q15a, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q15b <- factor(TS_ALUNO_34EM$TX_RESP_Q15b, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))
# TS_ALUNO_34EM$TX_RESP_Q16_ <- factor(TS_ALUNO_34EM$TX_RESP_Q16_, levels = c('*', '.', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'), labels = c('Nulo', 'Branco', 'À pé', 'De bicicleta', 'De Van (ou Kombi)', 'De ônibus', 'De metrô (ou trem urbano)', 'De carro', 'De barco', 'De motocicleta', 'Outro meio de transporte'))
# TS_ALUNO_34EM$TX_RESP_Q17_ <- factor(TS_ALUNO_34EM$TX_RESP_Q17_, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', '3 anos ou menos', '4 ou 5 anos', '6 ou 7 anos', '8 anos ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q18_ <- factor(TS_ALUNO_34EM$TX_RESP_Q18_, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Somente em escola pública', 'Somente em escola particular', 'Em escola pública e em escola particular'))
# TS_ALUNO_34EM$TX_RESP_Q19_ <- factor(TS_ALUNO_34EM$TX_RESP_Q19_, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Não', 'Sim, uma vez', 'Sim, duas vezes ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q20_ <- factor(TS_ALUNO_34EM$TX_RESP_Q20_, levels = c('*', '.', 'A', 'B', 'C'), labels = c('Nulo', 'Branco', 'Nunca', 'Sim, uma vez', 'Sim, duas vezes ou mais'))
# TS_ALUNO_34EM$TX_RESP_Q21a <- factor(TS_ALUNO_34EM$TX_RESP_Q21a, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Não uso meu tempo para isso.', 'Menos de 1 hora.', 'Entre 1 e 2 horas.', 'Mais de 2 horas.'))
# TS_ALUNO_34EM$TX_RESP_Q21b <- factor(TS_ALUNO_34EM$TX_RESP_Q21b, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Não uso meu tempo para isso', 'Menos de 1 hora', 'Entre 1 e 2 horas', 'Mais de 2 horas'))
# TS_ALUNO_34EM$TX_RESP_Q21c <- factor(TS_ALUNO_34EM$TX_RESP_Q21c, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Não uso meu tempo para isso', 'Menos de 1 hora', 'Entre 1 e 2 horas', 'Mais de 2 horas'))
# TS_ALUNO_34EM$TX_RESP_Q21d <- factor(TS_ALUNO_34EM$TX_RESP_Q21d, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Não uso meu tempo para isso', 'Menos de 1 hora', 'Entre 1 e 2 horas', 'Mais de 2 horas'))
# TS_ALUNO_34EM$TX_RESP_Q21e <- factor(TS_ALUNO_34EM$TX_RESP_Q21e, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Não uso meu tempo para isso', 'Menos de 1 hora', 'Entre 1 e 2 horas', 'Mais de 2 horas'))
# TS_ALUNO_34EM$TX_RESP_Q22a <- factor(TS_ALUNO_34EM$TX_RESP_Q22a, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Todos eles', 'A maior parte deles', 'Poucos deles', 'Nenhum deles'))
# TS_ALUNO_34EM$TX_RESP_Q22b <- factor(TS_ALUNO_34EM$TX_RESP_Q22b, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Todos eles', 'A maior parte deles', 'Poucos deles', 'Nenhum deles'))
# TS_ALUNO_34EM$TX_RESP_Q22c <- factor(TS_ALUNO_34EM$TX_RESP_Q22c, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Todos eles', 'A maior parte deles', 'Poucos deles', 'Nenhum deles'))
# TS_ALUNO_34EM$TX_RESP_Q22d <- factor(TS_ALUNO_34EM$TX_RESP_Q22d, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Todos eles', 'A maior parte deles', 'Poucos deles', 'Nenhum deles'))
# TS_ALUNO_34EM$TX_RESP_Q22e <- factor(TS_ALUNO_34EM$TX_RESP_Q22e, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Todos eles', 'A maior parte deles', 'Poucos deles', 'Nenhum deles'))
# TS_ALUNO_34EM$TX_RESP_Q22f <- factor(TS_ALUNO_34EM$TX_RESP_Q22f, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Todos eles', 'A maior parte deles', 'Poucos deles', 'Nenhum deles'))
# TS_ALUNO_34EM$TX_RESP_Q22g <- factor(TS_ALUNO_34EM$TX_RESP_Q22g, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Todos eles', 'A maior parte deles', 'Poucos deles', 'Nenhum deles'))
# TS_ALUNO_34EM$TX_RESP_Q22h <- factor(TS_ALUNO_34EM$TX_RESP_Q22h, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Todos eles', 'A maior parte deles', 'Poucos deles', 'Nenhum deles'))
# TS_ALUNO_34EM$TX_RESP_Q23a <- factor(TS_ALUNO_34EM$TX_RESP_Q23a, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q23b <- factor(TS_ALUNO_34EM$TX_RESP_Q23b, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q23c <- factor(TS_ALUNO_34EM$TX_RESP_Q23c, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q23d <- factor(TS_ALUNO_34EM$TX_RESP_Q23d, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q23e <- factor(TS_ALUNO_34EM$TX_RESP_Q23e, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q23f <- factor(TS_ALUNO_34EM$TX_RESP_Q23f, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q23g <- factor(TS_ALUNO_34EM$TX_RESP_Q23g, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q23h <- factor(TS_ALUNO_34EM$TX_RESP_Q23h, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q23i <- factor(TS_ALUNO_34EM$TX_RESP_Q23i, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Concordo totalmente', 'Concordo', 'Discordo', 'Discordo totalmente'))
# TS_ALUNO_34EM$TX_RESP_Q24 <- factor(TS_ALUNO_34EM$TX_RESP_Q24, levels = c('*', '.', 'A', 'B', 'C', 'D'), labels = c('Nulo', 'Branco', 'Somente continuar estudando', 'Somente trabalhar', 'Continuar estudando e trabalhar', 'Ainda não sei'))
# TS_ALUNO_34EM$TX_RESP_Q25 <- factor(TS_ALUNO_34EM$TX_RESP_Q25, levels = c('*', '.', 'A', 'B'), labels = c('Nulo', 'Branco', 'Não', 'Sim'))


labels <- list(
  ID_SAEB = 'Ano de aplicação do Saeb',
  ID_REGIAO = 'Código da Região',
  ID_UF = 'Código da Unidade da Federação',
  ID_MUNICIPIO = 'Máscaras dos Códigos de Municípios (são códigos fictícios)',
  ID_AREA = 'Área',
  ID_ESCOLA = 'Máscaras dos Códigos de Escola (são códigos fictícios)',
  IN_PUBLICA = 'Indica se a escola é pública ou não',
  ID_LOCALIZACAO = 'Localização',
  ID_TURMA = 'Código da turma no Saeb',
  ID_SERIE = 'Ano Escolar',
  ID_ALUNO = 'Código do aluno no Saeb',
  IN_SITUACAO_CENSO = 'Indicador de consistência entre os dados da aplicação do Saeb 2023 com o Censo da Educação Básica 2023 finalizado',
  IN_PREENCHIMENTO_LP = 'Indicador de preenchimento da prova de Língua Portuguesa',
  IN_PREENCHIMENTO_MT = 'Indicador de preenchimento da prova de Matemática',
  IN_PRESENCA_LP = 'Indicador de presença na prova de Língua Portuguesa',
  IN_PRESENCA_MT = 'Indicador de presença na prova de Matemática',
  ID_CADERNO_LP = 'Número do caderno de prova de Língua Portuguesa',
  ID_BLOCO_1_LP = 'Identificador do Bloco 1 de Língua Portuguesa',
  ID_BLOCO_2_LP = 'Identificador do Bloco 2 de Língua Portuguesa',
  ID_CADERNO_MT = 'Número do caderno de prova de Matemática',
  ID_BLOCO_1_MT = 'Identificador do Bloco 1 de Matemática',
  ID_BLOCO_2_MT = 'Identificador do Bloco 2 de Matemática',
  TX_RESP_BLOCO1_LP = 'Resposta do aluno ao Bloco 1 de Língua Portuguesa',
  TX_RESP_BLOCO2_LP = 'Resposta do aluno ao Bloco 2 de Língua Portuguesa',
  TX_RESP_BLOCO1_MT = 'Resposta do aluno ao Bloco 1 de Matemática',
  TX_RESP_BLOCO2_MT = 'Resposta do aluno ao Bloco 2 de Matemática',
  IN_PROFICIENCIA_LP = 'Indicador para cálculo da proficiência (no mínimo três itens respondidos no caderno de prova de Língua Portuguesa e Matemática)',
  IN_PROFICIENCIA_MT = 'Indicador para cálculo da proficiência (no mínimo três itens respondidos no caderno de prova de Língua Portuguesa e Matemática)',
  IN_AMOSTRA = 'Indicador de participação da amostra',
  ESTRATO = 'Descrição dos estratos',
  PESO_ALUNO_LP = 'Peso do aluno em Língua Portuguesa',
  PROFICIENCIA_LP = 'Proficiência do aluno em Língua Portuguesa calculada na escala única do SAEB, com média = 0 e desvio = 1 na população de referência',
  ERRO_PADRAO_LP = 'Erro padrão da proficiência em Língua Portuguesa',
  PROFICIENCIA_LP_SAEB = 'Proficiência em Língua Portuguesa transformada na escala única do SAEB, com média = 250, desvio = 50 (do SAEB/97)',
  ERRO_PADRAO_LP_SAEB = 'Erro padrão da proficiência transformada em Língua Portuguesa',
  PESO_ALUNO_MT = 'Peso do aluno em Matemática',
  PROFICIENCIA_MT = 'Proficiência do aluno em Matemática calculada na escala única do SAEB, com média = 0 e desvio = 1 na população de referência',
  ERRO_PADRAO_MT = 'Erro padrão da proficiência em Matemática',
  PROFICIENCIA_MT_SAEB = 'Proficiência do aluno em Matemática transformada na escala única do SAEB, com média = 250, desvio = 50 (do SAEB/97)',
  ERRO_PADRAO_MT_SAEB = 'Erro padrão da proficiência transformada em Matemática',
  IN_PREENCHIMENTO_QUESTIONARIO = 'Indicador de preenchimento do questionário',
  IN_INSE = 'Indicador para cálculo do INSE (São considerados válidos os estudantes que responderam pelo menos 8 itens, dentre os 17 utilizados para o cálculo do indicador)',
  INSE_ALUNO = 'Resultado individual do INSE para o aluno',
  NU_TIPO_NIVEL_INSE = 'Classificação do Indicador de Nível Socioeconômico em 8 Grupos (para melhor entendimento dos grupos, consultar a nota técnica disponível no portal do Inep)',
  PESO_ALUNO_INSE = 'Peso do Aluno para cálculo do INSE 2023',
  TX_RESP_Q01 = 'Qual é o seu sexo?',
  TX_RESP_Q02 = 'Qual é a sua idade?',
  TX_RESP_Q03 = 'Qual língua que seus pais falam com mais frequência em casa?',
  TX_RESP_Q04 = 'Qual é a sua cor ou raça?',
  TX_RESP_Q05a = 'Você possui deficiência, transtorno do espectro autista ou superdotação? - Deficiência.',
  TX_RESP_Q05b = 'Você possui deficiência, transtorno do espectro autista ou superdotação? - Transtorno do espectro autista.',
  TX_RESP_Q05c = 'Você possui deficiência, transtorno do espectro autista ou superdotação? - Altas habilidades ou superdotação.',
  TX_RESP_Q06 = 'Quantas pessoas moram na sua casa, contando com você?',
  TX_RESP_Q07a = 'Normalmente, quem mora na sua casa? - Mãe(s) ou madrasta(s).',
  TX_RESP_Q07b = 'Normalmente, quem mora na sua casa? - Pai(s) ou padrasto(s).',
  TX_RESP_Q07c = 'Normalmente, quem mora na sua casa? - Avó(s).',
  TX_RESP_Q07d = 'Normalmente, quem mora na sua casa? - Avô(s).',
  TX_RESP_Q07e = 'Normalmente, quem mora na sua casa? - Outros familiares, irmãos(ãs), tios(as), primos(as) etc.',
  TX_RESP_Q08 = 'Qual é a maior escolaridade da sua mãe (ou madrasta ou mulher responsável por você)?',
  TX_RESP_Q09 = 'Qual é a maior escolaridade de seu pai (ou padrasto homem responsável por você)?',
  TX_RESP_Q10a = 'Com que frequência seus pais ou responsáveis costumam: - Ler em casa.',
  TX_RESP_Q10b = 'Com que frequência seus pais ou responsáveis costumam: - Conversar com você sobre o que acontece na escola.',
  TX_RESP_Q10c = 'Com que frequência seus pais ou responsáveis costumam: - Incentivar você a estudar.',
  TX_RESP_Q10d = 'Com que frequência seus pais ou responsáveis costumam: - Incentivar você a fazer a tarefa de casa.',
  TX_RESP_Q10e = 'Com que frequência seus pais ou responsáveis costumam: - Incentivar você a comparecer às aulas.',
  TX_RESP_Q10f = 'Com que frequência seus pais ou responsáveis costumam: - Ir às reuniões de pais na escola.',
  TX_RESP_Q11a = 'Na rua em que você mora tem: - Asfalto ou calçamento.',
  TX_RESP_Q11b = 'Na rua em que você mora tem: - Água tratada.',
  TX_RESP_Q11c = 'Na rua em que você mora tem: - Iluminação.',
  TX_RESP_Q12a = 'Dos itens relacionados abaixo, quantos existem na sua casa? - Geladeira.',
  TX_RESP_Q12b = 'Dos itens relacionados abaixo, quantos existem na sua casa? - Computador (ou notebook).',
  TX_RESP_Q12c = 'Dos itens relacionados abaixo, quantos existem na sua casa? - Quartos para dormir.',
  TX_RESP_Q12d = 'Dos itens relacionados abaixo, quantos existem na sua casa? - Televisão.',
  TX_RESP_Q12e = 'Dos itens relacionados abaixo, quantos existem na sua casa? - Banheiro.',
  TX_RESP_Q12f = 'Dos itens relacionados abaixo, quantos existem na sua casa? - Carro.',
  TX_RESP_Q12g = 'Dos itens relacionados abaixo, quantos existem na sua casa? - Celular com internet (smartphone).',
  TX_RESP_Q13a = 'Na sua casa tem: - Tv por internet (Netflix, GloboPlay, etc.).',
  TX_RESP_Q13b = 'Na sua casa tem: - Rede Wi-Fi.',
  TX_RESP_Q13c = 'Na sua casa tem: - Um quarto só seu.',
  TX_RESP_Q13d = 'Na sua casa tem: - Mesa para estudar.',
  TX_RESP_Q13e = 'Na sua casa tem: - Forno de microondas.',
  TX_RESP_Q13f = 'Na sua casa tem: - Aspirador de pó.',
  TX_RESP_Q13g = 'Na sua casa tem: - Máquina de lavar roupa.',
  TX_RESP_Q13h = 'Na sua casa tem: - Freezer (independente ou segunda porta da geladeira).',
  TX_RESP_Q13i = 'Na sua casa tem: - Garagem.',
  TX_RESP_Q14 = 'Quanto tempo você demora para chegar à sua escola?',
  TX_RESP_Q15a = 'Você utiliza para ir à escola: - Transporte gratuito escolar.',
  TX_RESP_Q15b = 'Você utiliza para ir à escola: - Passe escolar.',
  TX_RESP_Q16 = 'Considerando a maior distância percorrida, normalmente de que forma você chega à sua escola?',
  TX_RESP_Q17 = 'Com que idade você entrou na escola?',
  TX_RESP_Q18 = 'A partir do primeiro ano do ensino fundamental, em que tipo de escola você estudou?',
  TX_RESP_Q19 = 'Você já foi reprovado(a)?',
  TX_RESP_Q20 = 'Alguma vez você abandonou a escola deixando de frequentá-la até o final do ano escolar?',
  TX_RESP_Q21a = 'Fora da escola em dias de aula, quanto tempo você usa para: - Estudar (lição de casa, trabalhos escolares, etc.).',
  TX_RESP_Q21b = 'Fora da escola em dias de aula, quanto tempo você usa para: - Fazer cursos ou atividades extracurriculares (idioma, artes, informática etc.).',
  TX_RESP_Q21c = 'Fora da escola em dias de aula, quanto tempo você usa para: - Trabalhar em casa (lavar louça, limpar quintal, cuidar dos irmãos, etc.).',
  TX_RESP_Q21d = 'Fora da escola em dias de aula, quanto tempo você usa para: - Trabalhar fora de casa (recebendo ou não um salário).',
  TX_RESP_Q21e = 'Fora da escola em dias de aula, quanto tempo você usa para: - Lazer (TV, brincar, internet, música etc.).',
  TX_RESP_Q22a = 'Para os próximos itens, indique qual é a proporção de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - No início do ano, eles(as) informaram sobre o que seria ensinado e aprendido?',
  TX_RESP_Q22b = 'Para os próximos itens, indique qual é a proporção de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Antes de iniciar um novo conteúdo, eles(as) perguntam o que vocês sabem sobre o conteúdo?',
  TX_RESP_Q22c = 'Para os próximos itens, indique qual é a proporção de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) trazem temas do cotidiano para serem debatidos em sala de aula?',
  TX_RESP_Q22d = 'Para os próximos itens, indique qual é a proporção de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) abordam temas sobre desigualdade racial?',
  TX_RESP_Q22e = 'Para os próximos itens, indique qual é a proporção de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) abordam temas sobre desigualdade de gênero?',
  TX_RESP_Q22f = 'Para os próximos itens, indique qual é a proporção de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) abordam temas como bullying e outras formas de violência?',
  TX_RESP_Q22g = 'Para os próximos itens, indique qual é a proporção de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) desenvolvem trabalhos em grupos?',
  TX_RESP_Q22h = 'Para os próximos itens, indique qual é a proporção de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) abordam questões relacionadas ao futuro profissional dos(as) estudantes?',
  TX_RESP_Q23a = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: - Eu me interesso sobre o que foi ensinado na escola neste ano.',
  TX_RESP_Q23b = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: - Eu me sinto motivado(a), no dia a dia, a usar o que foi ensinado.',
  TX_RESP_Q23c = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: - Há espaço para diferentes opiniões na minha sala de aula.',
  TX_RESP_Q23d = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: - Eu me sinto seguro(a) quando estou na escola.',
  TX_RESP_Q23e = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: - Eu me sinto à vontade para discordar dos(as) meus(minhas) professores(as).',
  TX_RESP_Q23f = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: - Eu consigo argumentar sobre conteúdos difíceis.',
  TX_RESP_Q23g = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: - Os resultados das avaliações representam o quanto eu aprendi.',
  TX_RESP_Q23h = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: - Meus (Minhas) professores(as) acreditam que eu sou capaz de aprender.',
  TX_RESP_Q23i = 'Sobre sua escola, indique o quanto você concorda ou discorda das afirmações abaixo: -Meus (Minhas) professores(as) me motivam a continuar meus estudos.',
  TX_RESP_Q24 = 'Quando terminar o Ensino Médio, você pretende:',
  TX_RESP_Q25 = 'Você concluiu o Ensino Fundamental na Educação de Jovens e Adultos (EJA), antigo supletivo?'
)

# Aplicando LABELS às colunas de ITENS (Se a variável existe, o label correspondente é atribuído)
for (var in names(labels)) {
  if (var %in% names(TS_ALUNO_34EM)) {
    attr(TS_ALUNO_34EM[[var]], "label") <- labels[[var]]
  }
}
  
