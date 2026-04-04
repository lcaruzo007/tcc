# =========================================================================
# PASSO 3: DASHBOARD INTERATIVO COM SHINY (GRÁFICOS DE DISPERSÃO)
# =========================================================================

# 1. Carregar pacotes
library(shiny)
library(tidyverse)

# 2. Ler as bases de dados finais, já numéricas, filtradas e autoescaladas
dados_MT <- read.csv("C:/Users/Usuario/Desktop/tcc/TESTE/dados_FINAL_MT_Filtrado.csv")
dados_LP <- read.csv("C:/Users/Usuario/Desktop/tcc/TESTE/dados_FINAL_LP_Filtrado.csv")

nota_MT <- "PROFICIENCIA_MT_SAEB"
nota_LP <- "PROFICIENCIA_LP_SAEB"

# Pegar quais variáveis sobraram para montar o menu
vars_explicativas_MT <- setdiff(names(dados_MT), c(nota_MT, nota_LP))
vars_explicativas_LP <- setdiff(names(dados_LP), c(nota_MT, nota_LP))

# =========================================================================
# INTERFACE DO USUÁRIO (UI) - A "Cara" do Site
# =========================================================================
ui <- fluidPage(
  titlePanel("Dashboard Interativo - Impacto Socioeconômico na Proficiência SAEB"),
  
  sidebarLayout(
    sidebarPanel(
      # Menu 1: Escolher a Disciplina
      selectInput("materia", "Escolha a Disciplina:",
                  choices = c("Matemática" = "MT", "Língua Portuguesa" = "LP")),
      
      # Menu 2: Escolher as variáveis que passaram pelo filtro (> 0.3)
      # Esse menu vai aparecer dependendo da disciplina que o usuário escolheu
      uiOutput("menu_variaveis"),
      
      br(),
      helpText("Nota: Apenas as variáveis não-degeneradas e com correlação (|r| >= 0.3) estão disponíveis para visualização.")
    ),
    
    mainPanel(
      # Onde o gráfico vai aparecer grande na tela
      plotOutput("grafico_dispersao", height = "500px")
    )
  )
)

# =========================================================================
# DICIONÁRIO DE TRADUÇÃO DAS VARIÁVEIS (Fora das funções para não ter erro no Shiny)
# =========================================================================
dicionario_perguntas <- c(
  "TX_RESP_Q01" = "Sexo",
  "TX_RESP_Q02" = "Idade",
  "TX_RESP_Q04" = "Língua falada em casa",
  "TX_RESP_Q06" = "Cor/raça",
  "TX_RESP_Q07a" = "Mora com mãe",
  "TX_RESP_Q07b" = "Mora com pai",
  "TX_RESP_Q07c" = "Mora com avó",
  "TX_RESP_Q07d" = "Mora com avô",
  "TX_RESP_Q07e" = "Mora com outros familiares",
  "TX_RESP_Q08" = "Número de moradores",
  "TX_RESP_Q09" = "Escolaridade da mãe",
  "TX_RESP_Q10a" = "Pais leem em casa",
  "TX_RESP_Q10b" = "Pais conversam sobre escola",
  "TX_RESP_Q10c" = "Pais incentivam estudo",
  "TX_RESP_Q10d" = "Pais incentivam tarefa",
  "TX_RESP_Q10e" = "Pais incentivam ir à escola",
  "TX_RESP_Q10f" = "Pais vão às reuniões",
  "TX_RESP_Q11a" = "Geladeira",
  "TX_RESP_Q12a" = "Tem streaming",
  "TX_RESP_Q12b" = "Tem wi-fi",
  "TX_RESP_Q12c" = "Quarto próprio",
  "TX_RESP_Q12d" = "Mesa de estudo",
  "TX_RESP_Q12e" = "Microondas",
  "TX_RESP_Q12f" = "Aspirador de pó",
  "TX_RESP_Q12g" = "Máquina de lavar",
  "TX_RESP_Q13a" = "Banheiros",
  "TX_RESP_Q13b" = "Carros",
  "TX_RESP_Q13c" = "Motos",
  "TX_RESP_Q13d" = "Computadores",
  "TX_RESP_Q13e" = "Televisão",
  "TX_RESP_Q13f" = "Celular com internet",
  "TX_RESP_Q13g" = "Rua tem asfalto",
  "TX_RESP_Q13h" = "Rua tem água tratada",
  "TX_RESP_Q13i" = "Rua tem iluminação",
  "TX_RESP_Q14" = "Tempo até escola",
  "TX_RESP_Q15b" = "Transporte escolar",
  "TX_RESP_Q16" = "Meio de transporte",
  "TX_RESP_Q17" = "Idade que entrou na escola",
  "TX_RESP_Q18" = "Tipo de escola",
  "TX_RESP_Q19" = "Histórico de reprovação",
  "TX_RESP_Q21a" = "Tempo estudando",
  "TX_RESP_Q21b" = "Tempo trabalho doméstico",
  "TX_RESP_Q21c" = "Tempo lazer",
  "TX_RESP_Q21d" = "Tempo lazer lendo",
  "TX_RESP_Q21e" = "Tempo de lazer na internet",
  "TX_RESP_Q22a" = "Professores explicam conteúdo",
  "TX_RESP_Q22b" = "Professores perguntam conhecimento",
  "TX_RESP_Q22c" = "Professores usam temas do cotidiano",
  "TX_RESP_Q22d" = "Falam de desigualdade racial",
  "TX_RESP_Q22e" = "Falam de gênero",
  "TX_RESP_Q22f" = "Falam de bullying",
  "TX_RESP_Q22g" = "Trabalhos em grupo",
  "TX_RESP_Q22h" = "Falam de futuro profissional",
  "TX_RESP_Q23a" = "Interesse nas aulas",
  "TX_RESP_Q23b" = "Motivação",
  "TX_RESP_Q23c" = "Espaço para opinião",
  "TX_RESP_Q23d" = "Segurança",
  "TX_RESP_Q23e" = "Liberdade para discordar",
  "TX_RESP_Q23f" = "Capacidade de argumentar",
  "TX_RESP_Q23g" = "Avaliações refletem aprendizado",
  "TX_RESP_Q23h" = "Professores acreditam no aluno",
  "TX_RESP_Q23i" = "Professores motivam",
  "TX_RESP_Q24" = "Planos após ensino médio",
  "TX_RESP_Q25" = "Concluiu fundamental via EJA"
)

# =========================================================================
# LÓGICA DO SERVIDOR (SERVER) - O "Cérebro" do Site
# =========================================================================

server <- function(input, output, session) {
  
  # Ação 1: Atualizar o menu de perguntas do questionário dependendo da matéria
  output$menu_variaveis <- renderUI({
    
    # Helper fofinho pra mapear os TX_RESP pro nome do dicionário no menu drop-down
    criar_opcoes_menu <- function(variaveis_puras) {
      nomes_bonitos <- sapply(variaveis_puras, function(v) {
        ifelse(v %in% names(dicionario_perguntas), paste0(v, " - ", dicionario_perguntas[v]), v)
      })
      setNames(variaveis_puras, nomes_bonitos)
    }
    
    if (input$materia == "MT") {
      selectInput("variavel_x", "Selecione a Variável Socioeconômica (X):", 
                  choices = criar_opcoes_menu(vars_explicativas_MT))
    } else {
      selectInput("variavel_x", "Selecione a Variável Socioeconômica (X):", 
                  choices = criar_opcoes_menu(vars_explicativas_LP))
    }
  })
  
  # Ação 2: Desenhar o gráfico de acordo com o que foi selecionado
  output$grafico_dispersao <- renderPlot({
    
    # Exigir que tenha uma variável selecionada antes de plotar para não dar erro
    req(input$variavel_x) 
    
    # Pegar o título mapeado no dicionário (ou usar o original caso não exista lá)
    nome_bonito_x <- ifelse(input$variavel_x %in% names(dicionario_perguntas), 
                            dicionario_perguntas[input$variavel_x], 
                            input$variavel_x)
                            
    # Preparar as cores e eixos de acordo com a matéria
    if (input$materia == "MT") {
      df <- dados_MT
      nome_y <- nota_MT
      cor_pontos <- "blue"
      titulo <- paste("Matemática vs\n", nome_bonito_x)
    } else {
      df <- dados_LP
      nome_y <- nota_LP
      cor_pontos <- "darkgreen"
      titulo <- paste("Português vs\n", nome_bonito_x)
    }
    
    # Plotar o gráfico estatístico
    ggplot(df, aes(x = .data[[input$variavel_x]], y = .data[[nome_y]])) +
      geom_point(alpha = 0.6, color = cor_pontos, size = 3) + 
      geom_smooth(method = "lm", color = "red", linetype = "dashed", se = TRUE, size = 1.2) + 
      theme_minimal() +
      labs(
        title = titulo,
        subtitle = paste("Reta de Regressão Linear -", input$variavel_x),
        x = paste(nome_bonito_x, "(Escalonado)"),
        y = "Nota de Proficiência Escalonada"
      ) +
      theme(
        plot.title = element_text(size = 18, face = "bold"),
        plot.subtitle = element_text(size = 12, color = "gray40"),
        axis.title = element_text(size = 14)
      )
  })
}

# =========================================================================
# RODAR O APLICATIVO SHINY
# =========================================================================
shinyApp(ui = ui, server = server)
