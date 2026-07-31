# =========================================================================
# utils_saeb.r ? Funcoes utilitarias compartilhadas entre os scripts SAEB
# =========================================================================
# Fonte: source("utils_saeb.r")  (use caminho absoluto se necessario)

# =========================================================================
# STRUCTURE DE PASTAS DATADAS
# =========================================================================
# Convencao (Refatoracao #2 - Julho 2026):
#   <modulo>/outputs/<YYYY-MM-DD>/<tipo>/<nome>_<HHMMSS>.<ext>
#
# Exemplo:
#   TESTE/4_REGRESSAO_LINEAR/outputs/2026-07-22/tabelas/coeficientes_MT_100906.csv
#
# As funcoes abaixo percorrem subpastas datadas quando necessario e mantem
# compatibilidade reversa com o padrao antigo de timestamp sufixo no nome.
# -------------------------------------------------------------------------

# Constante de formato de data para a subpasta
FORMATO_DATA_PASTA <- "%Y-%m-%d"

# -------------------------------------------------------------------------
# Helper: caminho de saida sob pasta datada. Constroi automaticamente
#   <DIR_BASE>/outputs/<YYYY-MM-DD>/<subpasta>/<nome>_<HHMMSS>.<ext>
# (Subpasta tipicamente: "tabelas", "figuras", "modelos", "diagnosticos")
# Cria a pasta automaticamente.
# -------------------------------------------------------------------------
caminho_saida <- function(DIR_BASE_MODULO, subpasta, nome, ext = "csv") {
  data_run <- format(Sys.Date(), FORMATO_DATA_PASTA)
  hhmmss   <- format(Sys.time(), "%H%M%S")
  pasta_out <- file.path(DIR_BASE_MODULO, "outputs", data_run, subpasta)
  dir.create(pasta_out, showWarnings = FALSE, recursive = TRUE)
  if (nzchar(ext)) {
    arquivo <- paste0(nome, "_", hhmmss, ".", ext)
  } else {
    arquivo <- paste0(nome, "_", hhmmss)
  }
  file.path(pasta_out, arquivo)
}

# -------------------------------------------------------------------------
# Encontra o arquivo mais recente correspondente a nome_base dentro de
# `pasta`. Procura primeiro em subpastas datadas (mais recente primeiro),
# depois na propria pasta (compatibilidade com o padrao antigo).
#
# Aceita arquivos com:
#   <nome_base>_<YYYYMMDD>_<HHMMSS>.<ext>      (padrao antigo)
#   <nome_base>_<HHMMSS>.<ext>                   (padrao novo, pasta datada)
#   <nome_base>.<ext>                            (sem timestamp)
# -------------------------------------------------------------------------
encontrar_arquivo_mais_recente <- function(pasta, nome_base, tipo = NULL) {
  candidatos <- c()

  # 1) Procurar em subpastas datadas (YYYY-MM-DD)
  if (dir.exists(pasta)) {
    subpastas <- list.dirs(pasta, full.names = TRUE, recursive = TRUE)
    # Filtra apenas subpastas que terminam em YYYY-MM-DD (eventualmente aninhadas)
    datas <- grep("[0-9]{4}-[0-9]{2}-[0-9]{2}$", basename(subpastas), value = TRUE)
    pasta_datas <- subpastas[basename(subpastas) %in% datas]
    if (length(pasta_datas) > 0L) {
      # Se tipo especificado, concatena com subpasta do tipo
      if (!is.null(tipo)) {
        pasta_datas <- file.path(pasta_datas, tipo)
        pasta_datas <- pasta_datas[dir.exists(pasta_datas)]
      }
      padrao <- paste0("^", nome_base, "(_[0-9]{6}(_[0-9]+)?)?\\.[Cc][Ss][Vv]$")
      arqs <- unlist(lapply(pasta_datas, function(p) {
        list.files(p, pattern = padrao, full.names = TRUE)
      }))
      candidatos <- c(candidatos, arqs)
    }
  }

  # 2) Compatibilidade: pasta direta (padrao antigo de sufixo)
  padrao_antigo <- paste0("^", nome_base, "(_[0-9]{8}_[0-9]{6}(_[0-9]+)?)?\\.[Cc][Ss][Vv]$")
  arqs_antigos <- list.files(pasta, pattern = padrao_antigo, full.names = TRUE)
  candidatos <- c(candidatos, arqs_antigos)

  if (length(candidatos) == 0L) return(NULL)

  # Critério de "mais recente": mtime do arquivo OU, se empate, lexico do path
  info <- file.info(candidatos)
  candidatos[which.max(info$mtime)]
}

# -------------------------------------------------------------------------
# Verifica se existe ao menos um arquivo com o padrao de nome_base
# (mantém compatibilidade com sufixo timestamp antigo).
# -------------------------------------------------------------------------
arquivo_com_versao_existe <- function(pasta, nome_base, tipo = NULL) {
  !is.null(encontrar_arquivo_mais_recente(pasta, nome_base, tipo))
}

# -------------------------------------------------------------------------
# Mantido por compatibilidade: gera caminho sem sobrescrever.
# Em geral, scripts novos devem usar caminho_saida() (com pasta datada).
# Esta funcao antiga continua disponivel para scripts que ainda nao foram
# migrados ou para casos excepcionais onde a pasta datada nao se aplica.
# -------------------------------------------------------------------------
gerar_caminho_sem_sobrescrever <- function(caminho_base, sobrescrever = FALSE) {
  if (sobrescrever || !file.exists(caminho_base)) return(caminho_base)

  pasta    <- dirname(caminho_base)
  nome     <- tools::file_path_sans_ext(basename(caminho_base))
  extensao <- tools::file_ext(caminho_base)
  sufixo   <- format(Sys.time(), "%Y%m%d_%H%M%S")

  montar <- function(contador = NULL) {
    parte_cnt <- if (!is.null(contador)) paste0("_", contador) else ""
    arquivo   <- paste0(nome, "_", sufixo, parte_cnt)
    if (nzchar(extensao)) arquivo <- paste0(arquivo, ".", extensao)
    file.path(pasta, arquivo)
  }

  candidato <- montar()
  contador  <- 1L
  while (file.exists(candidato)) {
    candidato <- montar(contador)
    contador  <- contador + 1L
  }
  candidato
}

# =========================================================================
# DICIONARIOS CENTRALIZADOS DE VARIAVEIS
# Usados em ajeitar_dados.r e correlacao.r para evitar duplicacao
# =========================================================================

# -------------------------------------------------------------------------
# ORDINAIS_SAEB: Variaveis com ordem explicita
# Mapeia cada variavel para seu vetor de niveis ordenados
# -------------------------------------------------------------------------
ORDINAIS_SAEB <- list(
  # Q10 ? frequencia pais: Nunca(A) < De vez em quando(B) < Sempre(C)
  TX_RESP_Q10a = c("A","B","C"), TX_RESP_Q10b = c("A","B","C"),
  TX_RESP_Q10c = c("A","B","C"), TX_RESP_Q10d = c("A","B","C"),
  TX_RESP_Q10e = c("A","B","C"), TX_RESP_Q10f = c("A","B","C"),

  # Q21 ? tempo fora da escola: Nao uso(A) < <1h(B) < 1-2h(C) < >2h(D)
  TX_RESP_Q21a = c("A","B","C","D"), TX_RESP_Q21b = c("A","B","C","D"),
  TX_RESP_Q21c = c("A","B","C","D"), TX_RESP_Q21d = c("A","B","C","D"),
  TX_RESP_Q21e = c("A","B","C","D"),

  # Q22 ? proporcao professores: Todos(A) > Maioria(B) > Poucos(C) > Nenhum(D)
  # invertido: Nenhum=1, Poucos=2, Maioria=3, Todos=4
  TX_RESP_Q22a = c("D","C","B","A"), TX_RESP_Q22b = c("D","C","B","A"),
  TX_RESP_Q22c = c("D","C","B","A"), TX_RESP_Q22d = c("D","C","B","A"),
  TX_RESP_Q22e = c("D","C","B","A"), TX_RESP_Q22f = c("D","C","B","A"),
  TX_RESP_Q22g = c("D","C","B","A"), TX_RESP_Q22h = c("D","C","B","A"),

  # Q23 ? concordancia: Discordo totalmente(D)=1 ... Concordo totalmente(A)=4
  TX_RESP_Q23a = c("D","C","B","A"), TX_RESP_Q23b = c("D","C","B","A"),
  TX_RESP_Q23c = c("D","C","B","A"), TX_RESP_Q23d = c("D","C","B","A"),
  TX_RESP_Q23e = c("D","C","B","A"), TX_RESP_Q23f = c("D","C","B","A"),
  TX_RESP_Q23g = c("D","C","B","A"), TX_RESP_Q23h = c("D","C","B","A"),
  TX_RESP_Q23i = c("D","C","B","A"),

  # Q19 ? reprovacao: Nao(A)=1, 1x(B)=2, 2x+(C)=3
  TX_RESP_Q19 = c("A","B","C"),

  # Q20 ? abandono: Nunca(A)=1, 1x(B)=2, 2x+(C)=3
  TX_RESP_Q20 = c("A","B","C")
)

# -------------------------------------------------------------------------
# NOMINAIS_SAEB: Variaveis categoricas sem ordem (convertem para dummies)
# Estrutura: list(nome_col = list(prefix = "Qnn", mapping = c(cod = label)))
# -------------------------------------------------------------------------
NOMINAIS_SAEB <- list(
  TX_RESP_Q01 = list(
    prefix = "Q01",
    mapping = c("A" = "masculino", "B" = "feminino")
  ),
  TX_RESP_Q04 = list(
    prefix = "Q04",
    mapping = c("A" = "Branca", "B" = "Preta", "C" = "Parda", 
                "D" = "Amarela", "E" = "Indigena")
  )
)

# -------------------------------------------------------------------------
# CONTINUAS_SAEB: Variaveis numericas continuas (sem transformacao)
# -------------------------------------------------------------------------
CONTINUAS_SAEB <- c("INSE_ALUNO", "NU_TIPO_NIVEL_INSE")

# -------------------------------------------------------------------------
# Dicionarios centralizados das PERGUNTAS e ROTULOS DAS CATEGORIAS do
# questionario socioeconomico SAEB (TX_RESP_Q01-Q25 + subitens).
# Fonte: extracao programatica de MICRODADOS_SAEB_2023/INPUTS/
# INPUT_R_TS_ALUNO_34EM.R (INEP), normalizado para ASCII puro conforme
# a convencao do projeto (sem acentos). 72 itens, 245 pares
# (Item, Cat) rotulados. Usados nos graficos de coeficientes do modulo 5
# (e disponiveis a outros modulos).
# -------------------------------------------------------------------------
DICT_PERGUNTAS_SAEB <- c(
  TX_RESP_Q01 = "Qual e o seu sexo?",
  TX_RESP_Q02 = "Qual e a sua idade?",
  TX_RESP_Q03 = "Qual lingua que seus pais falam com mais frequencia em casa?",
  TX_RESP_Q04 = "Qual e a sua cor ou raca?",
  TX_RESP_Q05a = "Voce possui deficiencia, transtorno do espectro autista ou superdotacao? - Deficiencia.",
  TX_RESP_Q05b = "Voce possui deficiencia, transtorno do espectro autista ou superdotacao? - Transtorno do espectro autista.",
  TX_RESP_Q05c = "Voce possui deficiencia, transtorno do espectro autista ou superdotacao? - Altas habilidades ou superdotacao.",
  TX_RESP_Q06 = "Quantas pessoas moram na sua casa, contando com voce?",
  TX_RESP_Q07a = "Normalmente, quem mora na sua casa? - Mae(s) ou madrasta(s).",
  TX_RESP_Q07b = "Normalmente, quem mora na sua casa? - Pai(s) ou padrasto(s).",
  TX_RESP_Q07c = "Normalmente, quem mora na sua casa? - Avo(s).",
  TX_RESP_Q07d = "Normalmente, quem mora na sua casa? - Avo(s).",
  TX_RESP_Q07e = "Normalmente, quem mora na sua casa? - Outros familiares, irmaos(as), tios(as), primos(as) etc.",
  TX_RESP_Q08 = "Qual e a maior escolaridade da sua mae (ou madrasta ou mulher responsavel por voce)?",
  TX_RESP_Q09 = "Qual e a maior escolaridade de seu pai (ou padrasto homem responsavel por voce)?",
  TX_RESP_Q10a = "Com que frequencia seus pais ou responsaveis costumam: - Ler em casa.",
  TX_RESP_Q10b = "Com que frequencia seus pais ou responsaveis costumam: - Conversar com voce sobre o que acontece na escola.",
  TX_RESP_Q10c = "Com que frequencia seus pais ou responsaveis costumam: - Incentivar voce a estudar.",
  TX_RESP_Q10d = "Com que frequencia seus pais ou responsaveis costumam: - Incentivar voce a fazer a tarefa de casa.",
  TX_RESP_Q10e = "Com que frequencia seus pais ou responsaveis costumam: - Incentivar voce a comparecer as aulas.",
  TX_RESP_Q10f = "Com que frequencia seus pais ou responsaveis costumam: - Ir as reunioes de pais na escola.",
  TX_RESP_Q11a = "Na rua em que voce mora tem: - Asfalto ou calcamento.",
  TX_RESP_Q11b = "Na rua em que voce mora tem: - Agua tratada.",
  TX_RESP_Q11c = "Na rua em que voce mora tem: - Iluminacao.",
  TX_RESP_Q12a = "Dos itens relacionados abaixo, quantos existem na sua casa? - Geladeira.",
  TX_RESP_Q12b = "Dos itens relacionados abaixo, quantos existem na sua casa? - Computador (ou notebook).",
  TX_RESP_Q12c = "Dos itens relacionados abaixo, quantos existem na sua casa? - Quartos para dormir.",
  TX_RESP_Q12d = "Dos itens relacionados abaixo, quantos existem na sua casa? - Televisao.",
  TX_RESP_Q12e = "Dos itens relacionados abaixo, quantos existem na sua casa? - Banheiro.",
  TX_RESP_Q12f = "Dos itens relacionados abaixo, quantos existem na sua casa? - Carro.",
  TX_RESP_Q12g = "Dos itens relacionados abaixo, quantos existem na sua casa? - Celular com internet (smartphone).",
  TX_RESP_Q13a = "Na sua casa tem: - Tv por internet (Netflix, GloboPlay, etc.).",
  TX_RESP_Q13b = "Na sua casa tem: - Rede Wi-Fi.",
  TX_RESP_Q13c = "Na sua casa tem: - Um quarto so seu.",
  TX_RESP_Q13d = "Na sua casa tem: - Mesa para estudar.",
  TX_RESP_Q13e = "Na sua casa tem: - Forno de microondas.",
  TX_RESP_Q13f = "Na sua casa tem: - Aspirador de po.",
  TX_RESP_Q13g = "Na sua casa tem: - Maquina de lavar roupa.",
  TX_RESP_Q13h = "Na sua casa tem: - Freezer (independente ou segunda porta da geladeira).",
  TX_RESP_Q13i = "Na sua casa tem: - Garagem.",
  TX_RESP_Q14 = "Quanto tempo voce demora para chegar a sua escola?",
  TX_RESP_Q15a = "Voce utiliza para ir a escola: - Transporte gratuito escolar.",
  TX_RESP_Q15b = "Voce utiliza para ir a escola: - Passe escolar.",
  TX_RESP_Q16 = "Considerando a maior distancia percorrida, normalmente de que forma voce chega a sua escola?",
  TX_RESP_Q17 = "Com que idade voce entrou na escola?",
  TX_RESP_Q18 = "A partir do primeiro ano do ensino fundamental, em que tipo de escola voce estudou?",
  TX_RESP_Q19 = "Voce ja foi reprovado(a)?",
  TX_RESP_Q20 = "Alguma vez voce abandonou a escola deixando de frequenta-la ate o final do ano escolar?",
  TX_RESP_Q21a = "Fora da escola em dias de aula, quanto tempo voce usa para: - Estudar (licao de casa, trabalhos escolares, etc.).",
  TX_RESP_Q21b = "Fora da escola em dias de aula, quanto tempo voce usa para: - Fazer cursos ou atividades extracurriculares (idioma, artes, informatica etc.).",
  TX_RESP_Q21c = "Fora da escola em dias de aula, quanto tempo voce usa para: - Trabalhar em casa (lavar louca, limpar quintal, cuidar dos irmaos, etc.).",
  TX_RESP_Q21d = "Fora da escola em dias de aula, quanto tempo voce usa para: - Trabalhar fora de casa (recebendo ou nao um salario).",
  TX_RESP_Q21e = "Fora da escola em dias de aula, quanto tempo voce usa para: - Lazer (TV, brincar, internet, musica etc.).",
  TX_RESP_Q22a = "Para os proximos itens, indique qual e a proporcao de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - No inicio do ano, eles(as) informaram sobre o que seria ensinado e aprendido?",
  TX_RESP_Q22b = "Para os proximos itens, indique qual e a proporcao de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Antes de iniciar um novo conteudo, eles(as) perguntam o que voces sabem sobre o conteudo?",
  TX_RESP_Q22c = "Para os proximos itens, indique qual e a proporcao de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) trazem temas do cotidiano para serem debatidos em sala de aula?",
  TX_RESP_Q22d = "Para os proximos itens, indique qual e a proporcao de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) abordam temas sobre desigualdade racial?",
  TX_RESP_Q22e = "Para os proximos itens, indique qual e a proporcao de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) abordam temas sobre desigualdade de genero?",
  TX_RESP_Q22f = "Para os proximos itens, indique qual e a proporcao de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) abordam temas como bullying e outras formas de violencia?",
  TX_RESP_Q22g = "Para os proximos itens, indique qual e a proporcao de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) desenvolvem trabalhos em grupos?",
  TX_RESP_Q22h = "Para os proximos itens, indique qual e a proporcao de professores(as) da sua turma que abordam os seguintes temas em sala de aula: - Eles(as) abordam questoes relacionadas ao futuro profissional dos(as) estudantes?",
  TX_RESP_Q23a = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: - Eu me interesso sobre o que foi ensinado na escola neste ano.",
  TX_RESP_Q23b = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: - Eu me sinto motivado(a), no dia a dia, a usar o que foi ensinado.",
  TX_RESP_Q23c = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: - Ha espaco para diferentes opinioes na minha sala de aula.",
  TX_RESP_Q23d = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: - Eu me sinto seguro(a) quando estou na escola.",
  TX_RESP_Q23e = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: - Eu me sinto a vontade para discordar dos(as) meus(minhas) professores(as).",
  TX_RESP_Q23f = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: - Eu consigo argumentar sobre conteudos dificeis.",
  TX_RESP_Q23g = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: - Os resultados das avaliacoes representam o quanto eu aprendi.",
  TX_RESP_Q23h = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: - Meus (Minhas) professores(as) acreditam que eu sou capaz de aprender.",
  TX_RESP_Q23i = "Sobre sua escola, indique o quanto voce concorda ou discorda das afirmacoes abaixo: -Meus (Minhas) professores(as) me motivam a continuar meus estudos.",
  TX_RESP_Q24 = "Quando terminar o Ensino Medio, voce pretende:",
  TX_RESP_Q25 = "Voce concluiu o Ensino Fundamental na Educacao de Jovens e Adultos (EJA), antigo supletivo?"
)

# DICT_ROTULOS_SAEB: lista nomeada por Item -> vetor nomeado Cat -> Rotulo.
DICT_ROTULOS_SAEB <- list(
  TX_RESP_Q01  = c(A = "Masculino", B = "Feminino", C = "Nao quero declarar"),
  TX_RESP_Q02  = c(A = "16 anos ou menos", B = "17 anos", C = "18 anos",
                   D = "19 anos", E = "20 anos", F = "21 anos ou mais"),
  TX_RESP_Q03  = c(A = "Portugues", B = "Espanhol",
                   C = "Lingua de Sinais", D = "Outra lingua"),
  TX_RESP_Q04  = c(A = "Branca", B = "Preta", C = "Parda",
                   D = "Amarela", E = "Indigena", F = "Nao quero declarar"),
  TX_RESP_Q05a = c(A = "Nao", B = "Sim"),
  TX_RESP_Q05b = c(A = "Nao", B = "Sim"),
  TX_RESP_Q05c = c(A = "Nao", B = "Sim"),
  TX_RESP_Q06  = c(A = "2 pessoas", B = "3 pessoas", C = "4 pessoas",
                   D = "5 pessoas", E = "6 pessoas ou mais"),
  TX_RESP_Q07a = c(A = "Nao", B = "Sim"),
  TX_RESP_Q07b = c(A = "Nao", B = "Sim"),
  TX_RESP_Q07c = c(A = "Nao", B = "Sim"),
  TX_RESP_Q07d = c(A = "Nao", B = "Sim"),
  TX_RESP_Q07e = c(A = "Nao", B = "Sim"),
  TX_RESP_Q08  = c(A = "Nao completou o 5 ano do Ensino Fundamental",
                   B = "Ensino Fundamental, ate o 5 ano",
                   C = "Ensino Fundamental completo",
                   D = "Ensino Medio completo",
                   E = "Ensino Superior completo (faculdade ou graduacao)",
                   F = "Nao sei"),
  TX_RESP_Q09  = c(A = "Nao completou o 5 ano do Ensino Fundamental",
                   B = "Ensino Fundamental, ate o 5 ano",
                   C = "Ensino Fundamental completo",
                   D = "Ensino Medio completo",
                   E = "Ensino Superior completo (faculdade ou graduacao)",
                   F = "Nao sei"),
  TX_RESP_Q10a = c(A = "Nunca ou quase nunca",
                   B = "De vez em quando", C = "Sempre ou quase sempre"),
  TX_RESP_Q10b = c(A = "Nunca ou quase nunca",
                   B = "De vez em quando", C = "Sempre ou quase sempre"),
  TX_RESP_Q10c = c(A = "Nunca ou quase nunca",
                   B = "De vez em quando", C = "Sempre ou quase sempre"),
  TX_RESP_Q10d = c(A = "Nunca ou quase nunca",
                   B = "De vez em quando", C = "Sempre ou quase sempre"),
  TX_RESP_Q10e = c(A = "Nunca ou quase nunca",
                   B = "De vez em quando", C = "Sempre ou quase sempre"),
  TX_RESP_Q10f = c(A = "Nunca ou quase nunca",
                   B = "De vez em quando", C = "Sempre ou quase sempre"),
  TX_RESP_Q11a = c(A = "Nao", B = "Sim"),
  TX_RESP_Q11b = c(A = "Nao", B = "Sim"),
  TX_RESP_Q11c = c(A = "Nao", B = "Sim"),
  TX_RESP_Q12a = c(A = "Nenhum", B = "1", C = "2", D = "3 ou mais"),
  TX_RESP_Q12b = c(A = "Nenhum", B = "1", C = "2", D = "3 ou mais"),
  TX_RESP_Q12c = c(A = "Nenhum", B = "1", C = "2", D = "3 ou mais"),
  TX_RESP_Q12d = c(A = "Nenhum", B = "1", C = "2", D = "3 ou mais"),
  TX_RESP_Q12e = c(A = "Nenhum", B = "1", C = "2", D = "3 ou mais"),
  TX_RESP_Q12f = c(A = "Nenhum", B = "1", C = "2", D = "3 ou mais"),
  TX_RESP_Q12g = c(A = "Nenhum", B = "1", C = "2", D = "3 ou mais"),
  TX_RESP_Q13a = c(A = "Nao", B = "Sim"),
  TX_RESP_Q13b = c(A = "Nao", B = "Sim"),
  TX_RESP_Q13c = c(A = "Nao", B = "Sim"),
  TX_RESP_Q13d = c(A = "Nao", B = "Sim"),
  TX_RESP_Q13e = c(A = "Nao", B = "Sim"),
  TX_RESP_Q13f = c(A = "Nao", B = "Sim"),
  TX_RESP_Q13g = c(A = "Nao", B = "Sim"),
  TX_RESP_Q13h = c(A = "Nao", B = "Sim"),
  TX_RESP_Q13i = c(A = "Nao", B = "Sim"),
  TX_RESP_Q14  = c(A = "Menos de 30 minutos",
                   B = "Entre 30 minutos e uma hora", C = "Mais de uma hora"),
  TX_RESP_Q15a = c(A = "Nao", B = "Sim"),
  TX_RESP_Q15b = c(A = "Nao", B = "Sim"),
  TX_RESP_Q16  = c(A = "A pe", B = "De bicicleta", C = "De Van (ou Kombi)",
                   D = "De onibus", E = "De metro (ou trem urbano)",
                   F = "De carro", G = "De barco",
                   H = "De motocicleta", I = "Outro meio de transporte"),
  TX_RESP_Q17  = c(A = "3 anos ou menos", B = "4 ou 5 anos",
                   C = "6 ou 7 anos", D = "8 anos ou mais"),
  TX_RESP_Q18  = c(A = "Somente em escola publica",
                   B = "Somente em escola particular",
                   C = "Em escola publica e em escola particular"),
  TX_RESP_Q19  = c(A = "Nao", B = "Sim, uma vez", C = "Sim, duas vezes ou mais"),
  TX_RESP_Q20  = c(A = "Nunca", B = "Sim, uma vez", C = "Sim, duas vezes ou mais"),
  TX_RESP_Q21a = c(A = "Nao uso meu tempo para isso.",
                   B = "Menos de 1 hora.",
                   C = "Entre 1 e 2 horas.",
                   D = "Mais de 2 horas."),
  TX_RESP_Q21b = c(A = "Nao uso meu tempo para isso",
                   B = "Menos de 1 hora",
                   C = "Entre 1 e 2 horas",
                   D = "Mais de 2 horas"),
  TX_RESP_Q21c = c(A = "Nao uso meu tempo para isso",
                   B = "Menos de 1 hora",
                   C = "Entre 1 e 2 horas",
                   D = "Mais de 2 horas"),
  TX_RESP_Q21d = c(A = "Nao uso meu tempo para isso",
                   B = "Menos de 1 hora",
                   C = "Entre 1 e 2 horas",
                   D = "Mais de 2 horas"),
  TX_RESP_Q21e = c(A = "Nao uso meu tempo para isso",
                   B = "Menos de 1 hora",
                   C = "Entre 1 e 2 horas",
                   D = "Mais de 2 horas"),
  TX_RESP_Q22a = c(A = "Todos eles", B = "A maior parte deles",
                   C = "Poucos deles", D = "Nenhum deles"),
  TX_RESP_Q22b = c(A = "Todos eles", B = "A maior parte deles",
                   C = "Poucos deles", D = "Nenhum deles"),
  TX_RESP_Q22c = c(A = "Todos eles", B = "A maior parte deles",
                   C = "Poucos deles", D = "Nenhum deles"),
  TX_RESP_Q22d = c(A = "Todos eles", B = "A maior parte deles",
                   C = "Poucos deles", D = "Nenhum deles"),
  TX_RESP_Q22e = c(A = "Todos eles", B = "A maior parte deles",
                   C = "Poucos deles", D = "Nenhum deles"),
  TX_RESP_Q22f = c(A = "Todos eles", B = "A maior parte deles",
                   C = "Poucos deles", D = "Nenhum deles"),
  TX_RESP_Q22g = c(A = "Todos eles", B = "A maior parte deles",
                   C = "Poucos deles", D = "Nenhum deles"),
  TX_RESP_Q22h = c(A = "Todos eles", B = "A maior parte deles",
                   C = "Poucos deles", D = "Nenhum deles"),
  TX_RESP_Q23a = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q23b = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q23c = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q23d = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q23e = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q23f = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q23g = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q23h = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q23i = c(A = "Concordo totalmente", B = "Concordo",
                   C = "Discordo", D = "Discordo totalmente"),
  TX_RESP_Q24  = c(A = "Somente continuar estudando",
                   B = "Somente trabalhar",
                   C = "Continuar estudando e trabalhar",
                   D = "Ainda nao sei"),
  TX_RESP_Q25  = c(A = "Nao", B = "Sim")
)
# Limiar de correlacao minima (Cohen 1988: 0.30 = efeito pequeno a moderado)
LIMIAR_COR_PADRAO <- 0.30

# Metodo de deteccao de degeneracao:
#   "zero_variancia" - remove apenas colunas sem variacao (var = 0)
#   "near_zero"      - aplica somente nearZeroVar
#   "hibrido"        - zero_variancia + nearZeroVar (quando n >= min_linhas)
METODO_DEGENERACAO_PADRAO <- "zero_variancia"

# Minimo de linhas para aplicar nearZeroVar (evita falsos positivos com n pequeno)
MIN_LINHAS_NEAR_ZERO <- 30L

# Parametros do caret::nearZeroVar (se aplicavel)
FREQ_CUT_NZV <- 19      # razao freq(1a)/freq(2a); 19 ? padrao 95/5
UNIQUE_CUT_NZV <- 10    # % minima de valores unicos

# =========================================================================
# TEMA VISUAL CENTRALIZADO ? Para todos os graficos do projeto
# =========================================================================
# Uso: tema_saeb() + labs(title = "Figura X ? ...")
# Requisitos: library(ggplot2) antes de source()

tema_saeb <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold", size = base_size + 3,
                                                colour = "#1A1A1A", margin = ggplot2::margin(b = 4)),
      plot.subtitle    = ggplot2::element_text(size = base_size, colour = "#555555",
                                                margin = ggplot2::margin(b = 10)),
      plot.caption     = ggplot2::element_text(size = base_size - 2, colour = "#777777",
                                                face = "italic", hjust = 0,
                                                margin = ggplot2::margin(t = 10)),
      plot.background  = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.grid.major = ggplot2::element_line(colour = "#E8E8E8", linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      plot.margin      = ggplot2::margin(16, 20, 12, 16),
      axis.title       = ggplot2::element_text(size = base_size, face = "bold", colour = "#333333"),
      axis.text        = ggplot2::element_text(size = base_size - 1, colour = "#444444"),
      strip.text       = ggplot2::element_text(size = base_size, face = "bold", colour = "#1A1A1A"),
      legend.title     = ggplot2::element_text(size = base_size - 1, face = "bold"),
      legend.text      = ggplot2::element_text(size = base_size - 1)
    )
}

# -------------------------------------------------------------------------
# Paletas de cores padronizadas
# -------------------------------------------------------------------------
PALETA_PUBLICA_PRIVADA <- c("Publica" = "#2E86AB", "Privada" = "#A23B72")
PALETA_URBANA_RURAL    <- c("Urbana" = "#06A77D", "Rural" = "#D5622B")
PALETA_CAPITAL_INTERIOR <- c("Capital" = "#4A90E2", "Interior" = "#F5A623")
PALETA_INSE            <- c("Baixo_INSE" = "#E74C3C", "Medio_INSE" = "#F39C12", "Alto_INSE" = "#27AE60")
PALETA_DISCIPLINA      <- c("Matematica" = "#1B4F9A", "Lingua Portuguesa" = "#1A6B3A")

# -------------------------------------------------------------------------
# Constantes de saida
# -------------------------------------------------------------------------
DPI_PADRAO <- 600
LARGURA_PADRAO <- 12
ALTURA_PADRAO <- 7

# -------------------------------------------------------------------------
# Funcao auxiliar: formatar p-valor para anotacao em graficos
# -------------------------------------------------------------------------
formatar_p_annot <- function(p) {
  if (p < 0.001) return("p < 0,001")
  if (p < 0.01)  return("p < 0,01")
  if (p < 0.05)  return("p < 0,05")
  return(paste0("p = ", format(round(p, 3), nsmall = 3)))
}

# -------------------------------------------------------------------------
# Funcao auxiliar: interpretar tamanho de efeito (Cohen)
# -------------------------------------------------------------------------
interpretar_efeito <- function(r) {
  abs_r <- abs(r)
  if (abs_r < 0.1) return("desprezivel")
  if (abs_r < 0.3) return("pequeno")
  if (abs_r < 0.5) return("moderado")
  return("grande")
}

# -------------------------------------------------------------------------
# Funcao auxiliar: detectar raiz do projeto automaticamente
# -------------------------------------------------------------------------
detectar_raiz <- function() {
  cwd <- getwd()
  while (cwd != dirname(cwd)) {
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message("? Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)
  }
  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC")
    if (is.na(raiz) || raiz == "") stop("Caminho nao selecionado.")
    message("? Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Nao foi possivel detectar o caminho automaticamente.")
  }
}
