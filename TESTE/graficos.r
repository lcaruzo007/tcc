# =========================================================================
# PASSO 3: DASHBOARD INTERATIVO COM SHINY
# =========================================================================

library(shiny)
library(tidyverse)
source("utils_saeb.r")   # encontrar_arquivo_mais_recente

# -------------------------------------------------------------------------
# Configuração
# -------------------------------------------------------------------------
dir_resultados_por_escola <- "C:/Users/Usuario/Desktop/tcc/TESTE/dados_por_escola"

nota_MT <- "PROFICIENCIA_MT_SAEB"
nota_LP <- "PROFICIENCIA_LP_SAEB"

NOTAS <- c(nota_MT, nota_LP)

# -------------------------------------------------------------------------
# Validação inicial (falha cedo, antes de subir o app)
# -------------------------------------------------------------------------
if (!dir.exists(dir_resultados_por_escola)) {
  stop("Diretorio nao encontrado: ", dir_resultados_por_escola)
}

pastas_escola <- list.dirs(dir_resultados_por_escola,
                           full.names = FALSE, recursive = FALSE)
pastas_escola <- pastas_escola[nzchar(pastas_escola)]

if (length(pastas_escola) == 0L) {
  stop("Nenhuma pasta de escola encontrada em: ", dir_resultados_por_escola)
}

# -------------------------------------------------------------------------
# Dicionário de variáveis
# -------------------------------------------------------------------------
dicionario_perguntas <- c(
  TX_RESP_Q01  = "Sexo",
  TX_RESP_Q02  = "Idade",
  TX_RESP_Q04  = "Língua falada em casa",
  TX_RESP_Q06  = "Cor/raça",
  TX_RESP_Q07a = "Mora com mãe",
  TX_RESP_Q07b = "Mora com pai",
  TX_RESP_Q07c = "Mora com avó",
  TX_RESP_Q07d = "Mora com avô",
  TX_RESP_Q07e = "Mora com outros familiares",
  TX_RESP_Q08  = "Número de moradores",
  TX_RESP_Q09  = "Escolaridade da mãe",
  TX_RESP_Q10a = "Pais leem em casa",
  TX_RESP_Q10b = "Pais conversam sobre escola",
  TX_RESP_Q10c = "Pais incentivam estudo",
  TX_RESP_Q10d = "Pais incentivam tarefa",
  TX_RESP_Q10e = "Pais incentivam ir à escola",
  TX_RESP_Q10f = "Pais vão às reuniões",
  TX_RESP_Q11a = "Geladeira",
  TX_RESP_Q12a = "Tem streaming",
  TX_RESP_Q12b = "Tem wi-fi",
  TX_RESP_Q12c = "Quarto próprio",
  TX_RESP_Q12d = "Mesa de estudo",
  TX_RESP_Q12e = "Microondas",
  TX_RESP_Q12f = "Aspirador de pó",
  TX_RESP_Q12g = "Máquina de lavar",
  TX_RESP_Q13a = "Banheiros",
  TX_RESP_Q13b = "Carros",
  TX_RESP_Q13c = "Motos",
  TX_RESP_Q13d = "Computadores",
  TX_RESP_Q13e = "Televisão",
  TX_RESP_Q13f = "Celular com internet",
  TX_RESP_Q13g = "Rua tem asfalto",
  TX_RESP_Q13h = "Rua tem água tratada",
  TX_RESP_Q13i = "Rua tem iluminação",
  TX_RESP_Q14  = "Tempo até escola",
  TX_RESP_Q15b = "Transporte escolar",
  TX_RESP_Q16  = "Meio de transporte",
  TX_RESP_Q17  = "Idade que entrou na escola",
  TX_RESP_Q18  = "Tipo de escola",
  TX_RESP_Q19  = "Histórico de reprovação",
  TX_RESP_Q21a = "Tempo estudando",
  TX_RESP_Q21b = "Tempo trabalho doméstico",
  TX_RESP_Q21c = "Tempo lazer",
  TX_RESP_Q21d = "Tempo lazer lendo",
  TX_RESP_Q21e = "Tempo de lazer na internet",
  TX_RESP_Q22a = "Professores explicam conteúdo",
  TX_RESP_Q22b = "Professores perguntam conhecimento",
  TX_RESP_Q22c = "Professores usam temas do cotidiano",
  TX_RESP_Q22d = "Falam de desigualdade racial",
  TX_RESP_Q22e = "Falam de gênero",
  TX_RESP_Q22f = "Falam de bullying",
  TX_RESP_Q22g = "Trabalhos em grupo",
  TX_RESP_Q22h = "Falam de futuro profissional",
  TX_RESP_Q23a = "Interesse nas aulas",
  TX_RESP_Q23b = "Motivação",
  TX_RESP_Q23c = "Espaço para opinião",
  TX_RESP_Q23d = "Segurança",
  TX_RESP_Q23e = "Liberdade para discordar",
  TX_RESP_Q23f = "Capacidade de argumentar",
  TX_RESP_Q23g = "Avaliações refletem aprendizado",
  TX_RESP_Q23h = "Professores acreditam no aluno",
  TX_RESP_Q23i = "Professores motivam",
  TX_RESP_Q24  = "Planos após ensino médio",
  TX_RESP_Q25  = "Concluiu fundamental via EJA"
)

# Converte vetor de variáveis em lista nomeada para selectInput
criar_opcoes_menu <- function(variaveis) {
  nomes <- ifelse(
    variaveis %in% names(dicionario_perguntas),
    paste0(variaveis, " — ", dicionario_perguntas[variaveis]),
    variaveis
  )
  setNames(as.list(variaveis), nomes)
}

# =========================================================================
# UI
# =========================================================================
ui <- fluidPage(
  titlePanel("Dashboard — Impacto Socioeconômico na Proficiência SAEB"),

  sidebarLayout(
    sidebarPanel(
      selectInput("id_escola", "Escola:",
                  choices = pastas_escola),

      selectInput("materia", "Disciplina:",
                  choices = c("Matemática" = "MT", "Língua Portuguesa" = "LP")),

      uiOutput("menu_variaveis"),

      br(),
      textOutput("status_arquivos"),
      br(),
      helpText("Somente variáveis não-degeneradas com |r| ≥ 0,3 estão disponíveis.")
    ),

    mainPanel(
      plotOutput("grafico_dispersao", height = "500px"),
      br(),
      uiOutput("painel_estatisticas")
    )
  )
)

# =========================================================================
# SERVER
# =========================================================================
server <- function(input, output, session) {

  # — Carrega dados da escola selecionada —
  dados_escola_reactive <- reactive({
    req(input$id_escola)

    pasta      <- file.path(dir_resultados_por_escola, input$id_escola)
    caminho_mt <- encontrar_arquivo_mais_recente(pasta, "dados_FINAL_MT_Filtrado")
    caminho_lp <- encontrar_arquivo_mais_recente(pasta, "dados_FINAL_LP_Filtrado")

    validate(
      need(!is.null(caminho_mt), "Arquivo de Matemática não encontrado para esta escola."),
      need(!is.null(caminho_lp), "Arquivo de Língua Portuguesa não encontrado para esta escola.")
    )

    list(
      mt         = read.csv(caminho_mt),
      lp         = read.csv(caminho_lp),
      arquivo_mt = basename(caminho_mt),
      arquivo_lp = basename(caminho_lp)
    )
  })

  # — Texto de status dos arquivos —
  output$status_arquivos <- renderText({
    d <- dados_escola_reactive()
    paste0("MT: ", d$arquivo_mt, "  |  LP: ", d$arquivo_lp)
  })

  # — Menu dinâmico de variáveis explicativas —
  output$menu_variaveis <- renderUI({
    d       <- dados_escola_reactive()
    eh_mt   <- input$materia == "MT"
    df_esc  <- if (eh_mt) d$mt else d$lp
    vars    <- setdiff(names(df_esc), NOTAS)

    if (length(vars) == 0L) {
      disciplina <- if (eh_mt) "Matemática" else "Língua Portuguesa"
      return(helpText(paste("Nenhuma variável disponível para", disciplina, "nesta escola.")))
    }

    selectInput("variavel_x",
                "Variável Socioeconômica (X):",
                choices = criar_opcoes_menu(vars))
  })

  # — Gráfico de dispersão —
  output$grafico_dispersao <- renderPlot({
    tryCatch({
      d      <- dados_escola_reactive()
      req(input$variavel_x)

      eh_mt  <- input$materia == "MT"
      df     <- if (eh_mt) d$mt else d$lp
      nota_y <- if (eh_mt) nota_MT else nota_LP
      cor_p  <- if (eh_mt) "#1B4F9A" else "#1A6B3A"
      disc   <- if (eh_mt) "Matemática" else "Português"

      nome_bonito_x <- ifelse(
        input$variavel_x %in% names(dicionario_perguntas),
        dicionario_perguntas[[input$variavel_x]],
        input$variavel_x
      )

      validate(
        need(input$variavel_x %in% names(df),
             "Variável selecionada não disponível para esta escola."),
        need(nota_y %in% names(df),
             "Variável de proficiência não encontrada.")
      )

      df_plot <- df[, c(input$variavel_x, nota_y), drop = FALSE]
      df_plot <- df_plot[complete.cases(df_plot), , drop = FALSE]

      validate(
        need(nrow(df_plot) >= 5L,
             "Dados insuficientes para o gráfico desta variável."),
        need(length(unique(df_plot[[input$variavel_x]])) >= 2L,
             "A variável X não apresenta variação nesta escola."),
        need(length(unique(df_plot[[nota_y]])) >= 2L,
             "A proficiência não apresenta variação nesta escola.")
      )

      usar_regressao <- nrow(df_plot) >= 8L &&
                        length(unique(df_plot[[input$variavel_x]])) >= 3L

      # Renomeia colunas para nomes fixos antes do ggplot — evita .data[[]] em
      # contexto reativo, que causa erro de data mask no Shiny.
      df_plot <- setNames(df_plot, c("var_x", "var_y"))

      g <- ggplot(df_plot, aes(x = var_x, y = var_y)) +
        geom_point(alpha = 0.55, color = cor_p, size = 2.8) +
        theme_minimal(base_size = 13) +
        labs(
          title    = paste(disc, "×", nome_bonito_x),
          subtitle = paste("Escola", input$id_escola),
          x        = paste0(nome_bonito_x, " (escalonado)"),
          y        = "Proficiência (escalonada)"
        ) +
        theme(
          plot.title    = element_text(size = 17, face = "bold"),
          plot.subtitle = element_text(size = 11, color = "grey40"),
          axis.title    = element_text(size = 13)
        )

      if (usar_regressao) {
        g <- g + geom_smooth(method = "lm", color = "#D62728",
                             linetype = "dashed", se = TRUE, linewidth = 1)
      }

      print(g)

    }, error = function(e) {
      plot.new()
      text(0.5, 0.5,
           paste("Erro ao gerar gráfico:\n", conditionMessage(e)),
           cex = 0.9, col = "firebrick")
    })
  })

  # — Painel de estatísticas abaixo do gráfico —
  output$painel_estatisticas <- renderUI({
    req(input$variavel_x)

    tryCatch({
      d      <- dados_escola_reactive()
      eh_mt  <- input$materia == "MT"
      df     <- if (eh_mt) d$mt else d$lp
      nota_y <- if (eh_mt) nota_MT else nota_LP

      if (!input$variavel_x %in% names(df) || !nota_y %in% names(df)) return(NULL)

      df_stat <- df[, c(input$variavel_x, nota_y), drop = FALSE]
      df_stat <- df_stat[complete.cases(df_stat), , drop = FALSE]

      if (nrow(df_stat) < 5L) return(NULL)

      # Calcula Pearson com p-valor
      teste <- cor.test(df_stat[[input$variavel_x]], df_stat[[nota_y]],
                        method = "pearson")
      r_val <- round(teste$estimate, 3)
      p_val <- teste$p.value
      n_val <- nrow(df_stat)

      # Formata p-valor
      p_fmt <- if (p_val < 0.001) "p < 0,001" else paste0("p = ", format(round(p_val, 3), nsmall = 3))

      # Classificação da força do efeito (Cohen 1988)
      forca <- dplyr::case_when(
        abs(r_val) >= 0.5 ~ "forte",
        abs(r_val) >= 0.3 ~ "moderada",
        TRUE              ~ "fraca"
      )
      sig <- p_val < 0.05

      # Cores
      cor_sig  <- if (sig) "#1A6B3A" else "#B03A2E"
      cor_r    <- if (r_val >= 0) "#1B4F9A" else "#B03A2E"
      sig_txt  <- if (sig) "✔ Significativo (p < 0,05)" else "✘ Não significativo (p ≥ 0,05)"

      tagList(
        tags$div(
          style = "display: flex; gap: 16px; flex-wrap: wrap; margin-top: 4px;",

          tags$div(
            style = paste0(
              "flex: 1; min-width: 120px; background: #F4F6FA; border-left: 4px solid ", cor_r, ";",
              "padding: 10px 14px; border-radius: 4px;"
            ),
            tags$div(style = "font-size: 11px; color: #666; margin-bottom: 2px;", "Correlação de Pearson"),
            tags$div(style = paste0("font-size: 22px; font-weight: bold; color: ", cor_r, ";"),
                     paste0("r = ", r_val)),
            tags$div(style = "font-size: 11px; color: #888; margin-top: 2px;",
                     paste0("Efeito ", forca))
          ),

          tags$div(
            style = "flex: 1; min-width: 120px; background: #F4F6FA; border-left: 4px solid #888;
                     padding: 10px 14px; border-radius: 4px;",
            tags$div(style = "font-size: 11px; color: #666; margin-bottom: 2px;", "Valor de p"),
            tags$div(style = "font-size: 22px; font-weight: bold; color: #333;", p_fmt),
            tags$div(style = "font-size: 11px; margin-top: 2px;",
                     tags$span(style = paste0("color: ", cor_sig, "; font-weight: bold;"), sig_txt))
          ),

          tags$div(
            style = "flex: 1; min-width: 120px; background: #F4F6FA; border-left: 4px solid #555;
                     padding: 10px 14px; border-radius: 4px;",
            tags$div(style = "font-size: 11px; color: #666; margin-bottom: 2px;", "Observações"),
            tags$div(style = "font-size: 22px; font-weight: bold; color: #333;", paste0("n = ", n_val)),
            tags$div(style = "font-size: 11px; color: #888; margin-top: 2px;", "alunos com dados válidos")
          )
        )
      )
    }, error = function(e) NULL)
  })
}

# =========================================================================
# Iniciar app
# =========================================================================
shinyApp(ui = ui, server = server)
