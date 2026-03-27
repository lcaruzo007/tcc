# /***************************************************************************************/
# /*  INEP/Daeb-Diretoria de Avaliação da Educação Básica                                */ 
# /*                                   			                                             */
# /*  Coordenação-Geral de Medidas da Educação Básica (CGMEB)                            */
# /*-------------------------------------------------------------------------------------*/
# /*  PROGRAMA:                                                                          */
# /*               INPUT_R_TS_ITEM                                                       */
# /*-------------------------------------------------------------------------------------*/
# /*  DESCRICAO:   PROGRAMA PARA LEITURA DAS INFORMAÇÕES GERAIS SOBRE                    */
# /*               DESCRITORES, BLOCOS, ITENS E GABARITO DAS PROVAS DO SAEB 2023         */
# /***************************************************************************************/
# /***************************************************************************************/
# /* Obs:                                                                                */
# /* 		                                                                                 */
# /* Para abrir os microdados, é necessário salvar este programa e o arquivo             */
# /* TS_ITEM.CSV no diretório C:\ do computador.	                                       */
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
# Se não estiver instalado
# --------------------
if(!require(data.table)){install.packages('data.table')}

#--------------------
# Caso deseje trocar o local do arquivo, edite a função setwd() a seguir
# informando o local do arquivo.
# Ex. Windows setwd("C:/temp")
#     Linux   setwd("/home")
#--------------------
#setwd('C:\\') 
setwd('C:\\')

#------------------
# Carga dos microdados

TS_ITEM <- data.table::fread(input='TS_ITEM.csv',integer64='character')

#---------------------------
# A script a seguir formata os rótulos das variáveis
# Para formatar um item retire o caracter de comentário (#) no início na linha desejada 
# (Para retirar o caracter de comentário de várias linhas de uma só vez, selecione as linhas desejadas e tecle ctrl+shift+c)
#---------------------------

# TS_ITEM$ID_SERIE <- factor(TS_ITEM$ID_SERIE, levels = c(2, 5, 9, 3), labels = c('2º ano EF', '5º ano EF', '9º ano EF', '3ª/4ª série EM'))
# TS_ITEM$TP_DISCIPLINA <- factor(TS_ITEM$TP_DISCIPLINA, levels = c('LP', 'MT', 'CH', 'CN'), labels = c('Língua Portuguesa', 'Matemática', 'Ciências Humanas', 'Ciências da Natureza'))
# TS_ITEM$TP_ITEM_MODELO <- factor(TS_ITEM$TP_ITEM_MODELO, levels = c('M2PL', 'M3PL', 'MRG', 'M3P'), labels = c('Modelo logístico de 2 parâmetros', 'Modelo Logístico de 3 parâmetros', 'Modelo de resposta gradual', 'Modelo normal de 3 parâmetros'))

labels <- list(
  ID_SAEB = 'Ano de aplicação do Saeb',
  ID_SERIE1 = 'Série em que a prova foi aplicada',
  TP_DISCIPLINA = 'Disciplina do item',
  NU_BLOCO = 'Identificador do bloco',
  NU_POSICAO = 'Identificador da posição do item no bloco',
  ID_ITEM = 'Identificador do item',
  NU_DESCRITOR_HABILIDADE = 'Identificador do descritor do item',
  TX_GABARITO = 'Gabarito do Item',
  TP_ITEM = 'Tipo de resposta esperada para o Item',
  TP_ITEM_MODELO = 'Modelos da Teoria de Resposta ao Item',
  A = 'Parâmetro de discriminação: é o poder de discriminação do item para diferenciar os participantes que dominam dos participantes que não dominam a habilidade avaliada.',
  B = 'Parâmetro de dificuldade: associado à dificuldade do item, sendo que quanto maior seu valor, mais difícil é o item.',
  C = 'Parâmetro de acerto ao acaso: é a probabilidade de um participante acertar o item não dominando a habilidade exigida.',
  B1 = 'Parâmetro de dificuldade da transição entre as categorias de "erro" e "acerto parcial".',
  B2 = 'Parâmetro de dificuldade da transição entre as categorias de "acerto parcial" e "acerto total".',
  B3 = 'Parâmetro de dificuldade da transição entre as categorias de "acerto parcial" e "acerto total".'
)

# Aplicando LABELS às colunas de ITENS (Se a variável existe, o label correspondente é atribuído)
for (var in names(labels)) {
  if (var %in% names(TS_ITEM)) {
    attr(TS_ITEM[[var]], "label") <- labels[[var]]
  }
}
  
