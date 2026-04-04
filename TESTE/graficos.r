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
# LÓGICA DO SERVIDOR (SERVER) - O "Cérebro" do Site
# =========================================================================
server <- function(input, output, session) {
  
  # Ação 1: Atualizar o menu de perguntas do questionário dependendo da matéria
  output$menu_variaveis <- renderUI({
    if (input$materia == "MT") {
      selectInput("variavel_x", "Selecione a Variável Socioeconômica (X):", choices = vars_explicativas_MT)
    } else {
      selectInput("variavel_x", "Selecione a Variável Socioeconômica (X):", choices = vars_explicativas_LP)
    }
  })
  
  # Ação 2: Desenhar o gráfico de acordo com o que foi selecionado
  output$grafico_dispersao <- renderPlot({
    
    # Exigir que tenha uma variável selecionada antes de plotar para não dar erro
    req(input$variavel_x) 
    
    # Preparar as cores e eixos de acordo com a matéria
    if (input$materia == "MT") {
      df <- dados_MT
      nome_y <- nota_MT
      cor_pontos <- "blue"
      titulo <- paste("Matemática vs\n", input$variavel_x)
    } else {
      df <- dados_LP
      nome_y <- nota_LP
      cor_pontos <- "darkgreen"
      titulo <- paste("Português vs\n", input$variavel_x)
    }
    
    # Plotar o gráfico estatístico
    ggplot(df, aes_string(x = input$variavel_x, y = nome_y)) +
      geom_point(alpha = 0.6, color = cor_pontos, size = 3) + 
      geom_smooth(method = "lm", color = "red", linetype = "dashed", se = TRUE, size = 1.2) + 
      theme_minimal() +
      labs(
        title = titulo,
        subtitle = "Reta de Regressão Linear - Microdados Censitários em Z-Score",
        x = paste("Questionário:", input$variavel_x, "(Escalonado)"),
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
