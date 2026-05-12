# =========================================================================
# PASSO 3: DASHBOARD INTERATIVO COM SHINY
# =========================================================================

library(shiny)
library(tidyverse)
library(dendextend)
library(ggdendro)

# =========================================================================
# Configuração de Caminhos
# =========================================================================
RAIZ <- "C:/Users/Usuario/Desktop/tcc"
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_RESULTADOS_POR_ESCOLA <- file.path(DIR_TESTE, "dados_por_escola")

source(file.path(RAIZ, "DOCUMENTACAO", "utils_saeb.r"))

# -------------------------------------------------------------------------
# Configuração
# -------------------------------------------------------------------------
dir_resultados_por_escola <- DIR_RESULTADOS_POR_ESCOLA

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
      tabsetPanel(
        tabPanel(
          "Dispersão",
          plotOutput("grafico_dispersao", height = "500px"),
          br(),
          uiOutput("painel_estatisticas")
        ),
        
        tabPanel(
          "Dendogramas",
          br(),
          fluidRow(
            column(4,
              selectInput("metodo_ligacao", "Método de Ligação:",
                          choices = c("ward.D2" = "ward.D2",
                                      "complete" = "complete",
                                      "average" = "average",
                                      "single" = "single"),
                          selected = "ward.D2"),
              helpText("Método de agrupamento hierárquico para as variáveis."),
              br(),
              checkboxInput("colorir_dendograma", 
                           "Colorir ramos por cluster", 
                           value = TRUE)
            )
          ),
          br(),
          plotOutput("dendograma_variaveis", height = "600px"),
          br(),
          verbatimTextOutput("info_dendograma")
        )
      )
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
    caminho_metodos <- encontrar_arquivo_mais_recente(pasta, "todas_correlacoes_calculadas")

    validate(
      need(!is.null(caminho_mt), "Arquivo de Matemática não encontrado para esta escola."),
      need(!is.null(caminho_lp), "Arquivo de Língua Portuguesa não encontrado para esta escola."),
      need(!is.null(caminho_metodos), "Tabela de métodos de correlação não encontrada para esta escola.")
    )

    # Carregar arquivos com validação
    tryCatch({
      mt <- read.csv(caminho_mt)
      lp <- read.csv(caminho_lp)
      metodos <- read.csv(caminho_metodos)
      
      # Validar que há dados
      validate(
        need(nrow(mt) > 0, "Arquivo de Matemática está vazio para esta escola."),
        need(nrow(lp) > 0, "Arquivo de Português está vazio para esta escola."),
        need(nrow(metodos) > 0, "Tabela de métodos está vazia para esta escola.")
      )
      
      list(
        mt         = mt,
        lp         = lp,
        metodos    = metodos,
        arquivo_mt = basename(caminho_mt),
        arquivo_lp = basename(caminho_lp)
      )
    }, error = function(e) {
      validate(need(FALSE, paste("Erro ao ler arquivos da escola:", conditionMessage(e))))
    })
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
          subtitle = paste("Escola", input$id_escola, "| Dados Escalonados (Z-score)"),
          x        = paste0(nome_bonito_x, " (Z-score padronizado)"),
          y        = paste0("Proficiência ", disc, " (Z-score padronizado)"),
          caption  = "Nota: Eixos em desvios-padrão (σ). Valores = 0 representam a média da escola."
        ) +
        theme(
          plot.title    = element_text(size = 17, face = "bold"),
          plot.subtitle = element_text(size = 11, color = "grey40"),
          plot.caption  = element_text(size = 10, color = "grey60", hjust = 0),
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

      # Obter o método correto da tabela de correlações
      metodos_df <- d$metodos
      metodo_var <- metodos_df$Metodo[metodos_df$Variavel == input$variavel_x]
      
      # Se não encontrar na tabela, usar Pearson como padrão
      metodo_usar <- if (length(metodo_var) > 0 && metodo_var[1] == "Spearman") {
        "spearman"
      } else {
        "pearson"
      }
      
      # Calcula correlação com o método apropriado
      teste <- cor.test(df_stat[[input$variavel_x]], df_stat[[nota_y]],
                        method = metodo_usar)
      r_val <- round(teste$estimate, 3)
      p_val <- teste$p.value
      n_val <- nrow(df_stat)
      
      # Intervalo de confiança 95%
      ic_low <- round(teste$conf.int[1], 3)
      ic_high <- round(teste$conf.int[2], 3)
      
      # Label do método (maiúscula)
      metodo_label <- if (metodo_usar == "spearman") "Spearman" else "Pearson"

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
            tags$div(style = "font-size: 11px; color: #666; margin-bottom: 2px;", 
                     paste0("Correlação de ", metodo_label)),
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
            tags$div(style = "font-size: 11px; color: #666; margin-bottom: 2px;", "IC 95%"),
            tags$div(style = "font-size: 13px; font-weight: bold; color: #333;", 
                     paste0("[", ic_low, " ; ", ic_high, "]")),
            tags$div(style = "font-size: 10px; color: #888; margin-top: 2px;", 
                     "Intervalo de confiança")
          ),

          tags$div(
            style = "flex: 1; min-width: 120px; background: #F4F6FA; border-left: 4px solid #333;
                     padding: 10px 14px; border-radius: 4px;",
            tags$div(style = "font-size: 11px; color: #666; margin-bottom: 2px;", "Observações"),
            tags$div(style = "font-size: 22px; font-weight: bold; color: #333;", paste0("n = ", n_val)),
            tags$div(style = "font-size: 11px; color: #888; margin-top: 2px;", "alunos com dados válidos")
          )
        )
      )
    }, error = function(e) NULL)
  })

  # — Dendograma de variáveis —
  output$dendograma_variaveis <- renderPlot({
    tryCatch({
      d      <- dados_escola_reactive()
      req(input$materia)

      eh_mt  <- input$materia == "MT"
      df     <- if (eh_mt) d$mt else d$lp
      nota_y <- if (eh_mt) nota_MT else nota_LP
      disc   <- if (eh_mt) "Matemática" else "Português"

      vars <- setdiff(names(df), NOTAS)

      if (length(vars) < 2L) {
        plot.new()
        text(0.5, 0.5, "Menos de 2 variáveis disponíveis para dendograma",
             cex = 1, col = "firebrick")
        return(invisible(NULL))
      }

      df_vals <- df[, c(vars, nota_y), drop = FALSE]
      df_vals <- df_vals[complete.cases(df_vals), , drop = FALSE]

      if (nrow(df_vals) < 5L) {
        plot.new()
        text(0.5, 0.5, "Dados insuficientes para análise de agrupamento",
             cex = 1, col = "firebrick")
        return(invisible(NULL))
      }

      vars_com_var <- vars[sapply(df_vals[, vars, drop = FALSE], function(x) {
        v <- var(x, na.rm = TRUE)
        !is.na(v) && v > 0
      })]

      if (length(vars_com_var) < 2L) {
        plot.new()
        text(0.5, 0.5, "Menos de 2 variáveis com variância para dendograma",
             cex = 1, col = "firebrick")
        return(invisible(NULL))
      }

      cor_matrix  <- cor(df_vals[, vars_com_var, drop = FALSE],
                         use = "pairwise.complete.obs")
      dist_matrix <- as.dist(1 - abs(cor_matrix))
      hc          <- hclust(dist_matrix, method = input$metodo_ligacao)
      dend        <- as.dendrogram(hc)

      titulo   <- paste0("Dendograma — Clustering de Variáveis (", disc, ")")
      subtitulo <- paste0("Escola ", input$id_escola,
                          "  |  Método: ", input$metodo_ligacao,
                          "  |  n = ", nrow(df_vals))

      if (input$colorir_dendograma) {
        # ── Usa dendextend::plot() — único método que colore ramos corretamente ──
        k_clusters <- min(4L, length(vars_com_var) - 1L)
        dend <- dendextend::color_branches(dend, k = k_clusters)
        dend <- dendextend::color_labels(dend,  k = k_clusters)

        # ── NOVO: traduz rótulos usando o dicionário ──────────────────────────
        rotulos_originais <- labels(dend)
        # Remove sufixo _num se existir (ordinais viram TX_RESP_Q10a_num)
        chaves <- sub("_num$", "", rotulos_originais)
        rotulos_traduzidos <- ifelse(
          chaves %in% names(dicionario_perguntas),
          paste0(dicionario_perguntas[chaves], "\n(", chaves, ")"),
          rotulos_originais
        )
        labels(dend) <- rotulos_traduzidos
        # ─────────────────────────────────────────────────────────────────────

        par(mar = c(14, 4, 4, 2))   # margem inferior maior para rótulos longos
        plot(dend,
             main     = titulo,
             sub      = subtitulo,
             ylab     = "Distância (1 - |r|)",
             cex.main = 1.1,
             cex.sub  = 0.8,
             cex      = 0.85)
      } else {
        # ── NOVO: traduz rótulos ──────────────────────────────────────────────
        rotulos_originais <- labels(dend)
        chaves <- sub("_num$", "", rotulos_originais)
        rotulos_traduzidos <- ifelse(
          chaves %in% names(dicionario_perguntas),
          paste0(dicionario_perguntas[chaves], "\n(", chaves, ")"),
          rotulos_originais
        )
        labels(dend) <- rotulos_traduzidos
        # ─────────────────────────────────────────────────────────────────────

        par(mar = c(14, 4, 4, 2))   # margem inferior maior para rótulos longos
        plot(dend,
             main     = titulo,
             sub      = subtitulo,
             ylab     = "Distância (1 - |r|)",
             cex.main = 1.1,
             cex.sub  = 0.8,
             cex      = 0.85)
      }

    }, error = function(e) {
      plot.new()
      text(0.5, 0.5,
           paste("Erro ao gerar dendograma:\n", conditionMessage(e)),
           cex = 0.9, col = "firebrick")
    })
  })

  # — Info sobre dendograma —
  output$info_dendograma <- renderText({
    tryCatch({
      d      <- dados_escola_reactive()
      req(input$materia)

      eh_mt  <- input$materia == "MT"
      df     <- if (eh_mt) d$mt else d$lp
      nota_y <- if (eh_mt) nota_MT else nota_LP

      vars <- setdiff(names(df), NOTAS)
      
      if (length(vars) < 2L) return("Dados insuficientes.")

      df_vals <- df[, c(vars, nota_y), drop = FALSE]
      df_vals <- df_vals[complete.cases(df_vals), , drop = FALSE]

      if (nrow(df_vals) < 5L) return("Dados insuficientes.")
      
      # Filtrar apenas variáveis com variância > 0
      vars_com_var <- vars[sapply(df_vals[, vars, drop = FALSE], function(x) {
        v <- var(x, na.rm = TRUE)
        !is.na(v) && v > 0
      })]
      
      if (length(vars_com_var) < 2L) return("Menos de 2 variáveis com variância.")

      cor_matrix <- cor(df_vals[, vars_com_var, drop = FALSE], use = "pairwise.complete.obs")
      dist_matrix <- as.dist(1 - abs(cor_matrix))
      hc <- hclust(dist_matrix, method = input$metodo_ligacao)

      paste0(
        "INFORMAÇÕES DO DENDOGRAMA\n",
        "─────────────────────────────\n",
        "Variáveis analisadas: ", length(vars), "\n",
        "Observações (após limpeza): ", nrow(df_vals), "\n",
        "Método de ligação: ", input$metodo_ligacao, "\n",
        "Distância usada: 1 - |Correlação de Pearson|\n",
        "\n",
        "Interpretação:\n",
        "• Ramos mais altos = variáveis mais dissimilares\n",
        "• Ramos próximos = variáveis altamente correlacionadas\n",
        "• Útil para identificar redundância de variáveis\n"
      )
    }, error = function(e) "Erro ao processar dados para informação.")
  })
}

# =========================================================================
# Iniciar app
# =========================================================================
shinyApp(ui = ui, server = server)
