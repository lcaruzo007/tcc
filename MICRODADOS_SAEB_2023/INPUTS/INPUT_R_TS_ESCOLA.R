# /***************************************************************************************/
# /*  INEP/Daeb-Diretoria de Avaliação da Educação Básica                                */ 
# /*                                   			                                             */
# /*  Coordenação-Geral de Medidas da Educação Básica (CGMEB)                            */
# /*-------------------------------------------------------------------------------------*/
# /*  PROGRAMA:                                                                          */
# /*               INPUT_R_TS_ESCOLA                                                     */
# /*-------------------------------------------------------------------------------------*/
# /*  DESCRICAO:   PROGRAMA PARA LEITURA DOS RESULTADOS DAS ESCOLAS DO SAEB 2023         */
# /*                                                                                     */
# /***************************************************************************************/
# /* Obs:                                                                                */
# /* 		                                                                                 */
# /* Para abrir os microdados, é necessário salvar este programa e o arquivo             */
# /* TS_ESCOLA.CSV no diretório C:\ do computador.	                                     */
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

TS_ESCOLA <- data.table::fread(input='TS_ESCOLA.csv',integer64='character')

# A script a seguir formata os rótulos das variáveis
# Para formatar um item retire o caracter de comentário (#) no início na linha desejada 
# (Para retirar o caracter de comentário de várias linhas de uma só vez, selecione as linhas desejadas e tecle ctrl+shift+c)
#---------------------------

# TS_ESCOLA$ID_REGIAO <- factor(TS_ESCOLA$ID_REGIAO, levels = c(1,2,3,4,5),
#                               labels = c( 'Norte', 'Nordeste', 'Sudeste', 'Sul', 'Centro-Oeste'))
# 
# TS_ESCOLA$ID_UF <- factor(TS_ESCOLA$ID_UF, levels = c(11,12,13,14,15,16,17,21,22,23,24,25,26,27,28,29,31,32,33,35,41,42,43,50,51,52,53),
#                           labels = c( 'RO', 'AC', 'AM', 'RR', 'PA', 'AP', 'TO', 'MA', 'PI', 'CE', 'RN', 'PB', 'PE', 'AL', 'SE', 'BA', 'MG', 'ES', 'RJ', 'SP', 'PR', 'SC', 'RS', 'MS', 'MT', 'GO', 'DF'))
# 
# TS_ESCOLA$ID_AREA <- factor(TS_ESCOLA$ID_AREA, levels = c(1,2),
#                             labels = c( 'Capital', 'Interior'))
# 
# TS_ESCOLA$IN_PUBLICA <- factor(TS_ESCOLA$IN_PUBLICA, levels = c(0,1),
#                                        labels = c('Privada','Pública'))
# 
# TS_ESCOLA$ID_LOCALIZACAO <- factor(TS_ESCOLA$ID_LOCALIZACAO, levels = c(1,2),
#                                    labels = c('Urbana', 'Rural'))

# Atribui os labels para as variÃ¡veis
labels <- list(
  ID_SAEB = 'Ano de aplicação do Saeb',
  ID_REGIAO = 'Código da Região',
  ID_UF = 'Código da Unidade da Federação',
  ID_MUNICIPIO = 'Código do Município',
  ID_AREA = 'Área',
  ID_ESCOLA = 'Máscaras dos Códigos de Escola (são códigos fictícios)',
  IN_PUBLICA = 'Indica se a escola é pública ou não',
  ID_LOCALIZACAO = 'Localização',
  PC_FORMACAO_DOCENTE_INICIAL = 'Indicador de Adequação da Formação Docente (Informação referente ao Grupo 1, para os Anos Iniciais do EF)',
  PC_FORMACAO_DOCENTE_FINAL = 'Indicador de Adequação da Formação Docente (Informação referente ao Grupo 1, para os Anos Finais do EF)',
  PC_FORMACAO_DOCENTE_MEDIO = 'Indicador de Adequação da Formação Docente (Informação referente ao Grupo 1, para o Ensino Médio)',
  NIVEL_SOCIO_ECONOMICO = 'Indicador de Nível Socioeconômico (Inse)',
  NU_MATRICULADOS_CENSO_5EF = 'Número de alunos matriculados no 5º ano no censo 2023',
  NU_PRESENTES_5EF = 'Número de alunos presentes na aplicação',
  TAXA_PARTICIPACAO_5EF = 'Razão entre o total de alunos presentes no SAEB (NU_PRESENTES_5EF) e o total de alunos cadastrados no Censo Escolar que são público alvo do SAEB (NU_MATRICULADOS_CENSO_5EF)',
  NIVEL_0_LP5 = '(-00;125)',
  NIVEL_1_LP5 = '[125;150)',
  NIVEL_2_LP5 = '[150;175)',
  NIVEL_3_LP5 = '[175;200)',
  NIVEL_4_LP5 = '[200;225)',
  NIVEL_5_LP5 = '[225;250)',
  NIVEL_6_LP5 = '[250;275)',
  NIVEL_7_LP5 = '[275;300)',
  NIVEL_8_LP5 = '[300;325)',
  NIVEL_9_LP5 = '[325;+00)',
  NIVEL_0_MT5 = '(-00;125)',
  NIVEL_1_MT5 = '[125;150)',
  NIVEL_2_MT5 = '[150;175)',
  NIVEL_3_MT5 = '[175;200)',
  NIVEL_4_MT5 = '[200;225)',
  NIVEL_5_MT5 = '[225;250)',
  NIVEL_6_MT5 = '[250;275)',
  NIVEL_7_MT5 = '[275;300)',
  NIVEL_8_MT5 = '[300;325)',
  NIVEL_9_MT5 = '[325;350)',
  NIVEL_10_MT5 = '[350;+00)',
  NU_MATRICULADOS_CENSO_9EF = 'Número de alunos matriculados no 9º ano no censo 2023',
  NU_PRESENTES_9EF = 'Número de alunos presentes na aplicação',
  TAXA_PARTICIPACAO_9EF = 'Razão entre o total de alunos presentes no SAEB (NU_PRESENTES_9EF) e o total de alunos cadastrados no Censo Escolar que são público alvo do SAEB (NU_MATRICULADOS_CENSO_9EF)',
  NIVEL_0_LP9 = '(-00;200)',
  NIVEL_1_LP9 = '[200;225)',
  NIVEL_2_LP9 = '[225;250)',
  NIVEL_3_LP9 = '[250;275)',
  NIVEL_4_LP9 = '[275;300)',
  NIVEL_5_LP9 = '[300;325)',
  NIVEL_6_LP9 = '[325;350)',
  NIVEL_7_LP9 = '[350;375)',
  NIVEL_8_LP9 = '[375;+00)',
  NIVEL_0_MT9 = '(-00;200)',
  NIVEL_1_MT9 = '[200;225)',
  NIVEL_2_MT9 = '[225;250)',
  NIVEL_3_MT9 = '[250;275)',
  NIVEL_4_MT9 = '[275;300)',
  NIVEL_5_MT9 = '[300;325)',
  NIVEL_6_MT9 = '[325;350)',
  NIVEL_7_MT9 = '[350;375)',
  NIVEL_8_MT9 = '[375;400)',
  NIVEL_9_MT9 = '[400;+00)',
  NU_MATRICULADOS_CENSO_EMT = 'Número de alunos matriculados na 3ª/4ª série do ensino médio tradicional no Censo 2023',
  NU_PRESENTES_EMT = 'Número de alunos presentes na aplicação',
  TAXA_PARTICIPACAO_EMT = 'Razão entre o total de alunos presentes no SAEB (NU_PRESENTES_EMT) e o total de alunos cadastrados no Censo Escolar que são público alvo do SAEB (NU_MATRICULADOS_CENSO_EMT)',
  NIVEL_0_LPEMT = '(-00;225)',
  NIVEL_1_LPEMT = '[225;250)',
  NIVEL_2_LPEMT = '[250;275)',
  NIVEL_3_LPEMT = '[275;300)',
  NIVEL_4_LPEMT = '[300;325)',
  NIVEL_5_LPEMT = '[325;350)',
  NIVEL_6_LPEMT = '[350;375)',
  NIVEL_7_LPEMT = '[375;400)',
  NIVEL_8_LPEMT = '[400;+00)',
  NIVEL_0_MTEMT = '[-00;225)',
  NIVEL_1_MTEMT = '[225;250)',
  NIVEL_2_MTEMT = '[250;275)',
  NIVEL_3_MTEMT = '[275;300)',
  NIVEL_4_MTEMT = '[300;325)',
  NIVEL_5_MTEMT = '[325;350)',
  NIVEL_6_MTEMT = '[350;375)',
  NIVEL_7_MTEMT = '[375;400)',
  NIVEL_8_MTEMT = '[400;425)',
  NIVEL_9_MTEMT = '[425;450)',
  NIVEL_10_MTEMT = '[450;+00)',
  NU_MATRICULADOS_CENSO_EMI = 'Número de alunos matriculados na 3ª/4ª série do ensino médio integrado no censo 2023',
  NU_PRESENTES_EMI = 'Número de alunos presentes na aplicação',
  TAXA_PARTICIPACAO_EMI = 'Razão entre o total de alunos presentes no SAEB (NU_PRESENTES_EMI) e o total de alunos cadastrados no Censo Escolar que são público alvo do SAEB (NU_MATRICULADOS_CENSO_EMI)',
  NIVEL_0_LPEMI = '(-00;225)',
  NIVEL_1_LPEMI = '[225;250)',
  NIVEL_2_LPEMI = '[250;275)',
  NIVEL_3_LPEMI = '[275;300)',
  NIVEL_4_LPEMI = '[300;325)',
  NIVEL_5_LPEMI = '[325;350)',
  NIVEL_6_LPEMI = '[350;375)',
  NIVEL_7_LPEMI = '[375;400)',
  NIVEL_8_LPEMI = '[400;+00)',
  NIVEL_0_MTEMI = '[-00;225)',
  NIVEL_1_MTEMI = '[225;250)',
  NIVEL_2_MTEMI = '[250;275)',
  NIVEL_3_MTEMI = '[275;300)',
  NIVEL_4_MTEMI = '[300;325)',
  NIVEL_5_MTEMI = '[325;350)',
  NIVEL_6_MTEMI = '[350;375)',
  NIVEL_7_MTEMI = '[375;400)',
  NIVEL_8_MTEMI = '[400;425)',
  NIVEL_9_MTEMI = '[425;450)',
  NIVEL_10_MTEMI = '[450;+00)',
  NU_MATRICULADOS_CENSO_EM = 'Número de alunos matriculados na 3ª/4ª série do ensino médio tradicional ou integrado no censo 2023',
  NU_PRESENTES_EM = 'Número de alunos presentes na aplicação',
  TAXA_PARTICIPACAO_EM = 'Razão entre o total de alunos presentes no SAEB (NU_PRESENTES_EM) e o total de alunos cadastrados no Censo Escolar que são público alvo do SAEB (NU_MATRICULADOS_CENSO_EM)',
  NIVEL_0_LPEM = '(-00;225)',
  NIVEL_1_LPEM = '[225;250)',
  NIVEL_2_LPEM = '[250;275)',
  NIVEL_3_LPEM = '[275;300)',
  NIVEL_4_LPEM = '[300;325)',
  NIVEL_5_LPEM = '[325;350)',
  NIVEL_6_LPEM = '[350;375)',
  NIVEL_7_LPEM = '[375;400)',
  NIVEL_8_LPEM = '[400;+00)',
  NIVEL_0_MTEM = '(-00;225)',
  NIVEL_1_MTEM = '[225;250)',
  NIVEL_2_MTEM = '[250;275)',
  NIVEL_3_MTEM = '[275;300)',
  NIVEL_4_MTEM = '[300;325)',
  NIVEL_5_MTEM = '[325;350)',
  NIVEL_6_MTEM = '[350;375)',
  NIVEL_7_MTEM = '[375;400)',
  NIVEL_8_MTEM = '[400;425)',
  NIVEL_9_MTEM = '[425;450)',
  NIVEL_10_MTEM = '[450;+00)',
  MEDIA_5EF_LP = 'Média em Língua Portuguesa 5º ano',
  MEDIA_5EF_MT = 'Média em Matemática 5º ano',
  MEDIA_9EF_LP = 'Média em Língua Portuguesa 9º ano',
  MEDIA_9EF_MT = 'Média em Matemática 9º ano',
  MEDIA_EMT_LP = 'Média em Língua Portuguesa 3ª/4ª série do ensino médio tradicional',
  MEDIA_EMT_MT = 'Média em Matemática 3ª/4ª série do ensino médio tradicional',
  MEDIA_EMI_LP = 'Média em Língua Portuguesa 3ª/4ª série do ensino médio integrado',
  MEDIA_EMI_MT = 'Média em Matemática 3ª/4ª série do ensino médio integrado',
  MEDIA_EM_LP = 'Média em Língua Portuguesa 3ª/4ª série do ensino médio tradicional ou integrado',
  MEDIA_EM_MT = 'Média em Matemática 3ª/4ª série do ensino médio tradicional ou integrado'
)

# Aplicando LABELS às colunas de ITENS (Se a variável existe, o label correspondente é atribuído)
for (var in names(labels)) {
  if (var %in% names(TS_ESCOLA)) {
    attr(TS_ESCOLA[[var]], "label") <- labels[[var]]
  }
}
