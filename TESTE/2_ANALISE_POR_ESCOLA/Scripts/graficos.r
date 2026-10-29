# =========================================================================
# PASSO 3: DASHBOARD INTERATIVO COM SHINY
# =========================================================================

library(shiny)
library(tidyverse)
library(dendextend)
library(ggdendro)

# =========================================================================
# Deteccao Automatica de Caminhos - Funciona em qualquer computador!
# =========================================================================

detectar_raiz <- function() {
  # 1. Comecar do diretorio de trabalho atual
  cwd <- getwd()

  # 2. Procurar pela pasta "TESTE" subindo a arvore de diretorios
  while (cwd != dirname(cwd)) {  # enquanto nao chegar a raiz do sistema
    if (dir.exists(file.path(cwd, "TESTE"))) {
      message(" Projeto encontrado em: ", cwd)
      return(cwd)
    }
    cwd <- dirname(cwd)  # sobe um nivel
  }

  # 3. Se nao encontrar, pedir ao usuario
  message("  Nao consegui encontrar a pasta 'TESTE' automaticamente.")
  message("   Por favor, selecione manualmente a pasta raiz do projeto TCC")

  if (interactive()) {
    raiz <- utils::choose.dir(default = getwd(),
                              caption = "Selecione a pasta raiz do projeto TCC (onde esta a pasta TESTE)")
    if (is.na(raiz) || raiz == "") {
      stop("Caminho nao selecionado. Encerrando.")
    }
    message(" Pasta selecionada: ", raiz)
    return(raiz)
  } else {
    stop("Script nao pode rodar em modo nao-interativo sem encontrar o caminho.",
         "\nExecute no RStudio ou em um terminal interativo.")
  }
}

# =========================================================================
# Configuracao de Caminhos
# =========================================================================

# Detectar raiz e configurar caminhos
RAIZ <- detectar_raiz()
DIR_TESTE <- file.path(RAIZ, "TESTE")
DIR_ANALISE_2 <- file.path(DIR_TESTE, "2_ANALISE_POR_ESCOLA")
DIR_RESULTADOS_POR_ESCOLA <- file.path(DIR_ANALISE_2, "outputs")

message("Caminhos configurados:")
message("  RAIZ:                   ", RAIZ)
message("  Resultados por escola:  ", DIR_RESULTADOS_POR_ESCOLA)

source(file.path(RAIZ, "TESTE", "DOCUMENTACAO", "utils_saeb.r"))

# -------------------------------------------------------------------------
# Configuracao
# -------------------------------------------------------------------------
dir_resultados_por_escola <- DIR_RESULTADOS_POR_ESCOLA

nota_MT <- "PROFICIENCIA_MT_SAEB"
nota_LP <- "PROFICIENCIA_LP_SAEB"

NOTAS <- c(nota_MT, nota_LP)

# -------------------------------------------------------------------------
# Validacao inicial (falha cedo, antes de subir o app)
# -------------------------------------------------------------------------
message("\n Validacao de diretorio:")
message("  Procurando em: ", dir_resultados_por_escola)

if (!dir.exists(dir_resultados_por_escola)) {
  stop(" ERRO: Diretorio NAO encontrado: ", dir_resultados_por_escola,
       "\n   Verifique se PASSO 1 foi executado corretamente.")
}

message("   Diretorio encontrado")

pastas_escola <- listar_escolas_saeb(dir_resultados_por_escola)

message("  Escolas encontradas: ", length(pastas_escola))
if (length(pastas_escola) > 0L) {
  message("  IDs: ", paste(sort(pastas_escola), collapse = ", "))
}

if (length(pastas_escola) == 0L) {
  stop(" ERRO: Nenhuma pasta de escola encontrada em: ", dir_resultados_por_escola,
       "\n   Executar PASSO 2 (correlacao.r) antes de usar este dashboard.",
       "\n   Isto ira criar as pastas de escolas com dados processados.")
}

# -------------------------------------------------------------------------
# Dicionario de variaveis
# -------------------------------------------------------------------------
dicionario_perguntas <- rotulos_analiticos_saeb()

# Converte vetor de variaveis em lista nomeada para selectInput
criar_opcoes_menu <- function(variaveis) {
  nomes <- ifelse(
    variaveis %in% names(dicionario_perguntas),
    paste0(variaveis, " - ", dicionario_perguntas[variaveis]),
    variaveis
  )
  setNames(as.list(variaveis), nomes)
}

# =========================================================================
# UI
# =========================================================================
ui <- fluidPage(
  titlePanel("Dashboard - Impacto Socioeconomico na Proficiencia SAEB"),

  sidebarLayout(
    sidebarPanel(
      selectInput("id_escola", "Escola:",
                  choices = pastas_escola),

      selectInput("materia", "Disciplina:",
                  choices = c("Matematica" = "MT", "Lingua Portuguesa" = "LP")),

      uiOutput("menu_variaveis"),

      br(),
      textOutput("status_arquivos"),
      br(),
      helpText("Somente variaveis nao-degeneradas com |r| >= 0,3 estao disponiveis.")
    ),

    mainPanel(
      tabsetPanel(
        tabPanel(
          "Dispersao",
          plotOutput("grafico_dispersao", height = "500px"),
          br(),
          uiOutput("painel_estatisticas")
        ),

        tabPanel(
          "Dendogramas",
          br(),
          fluidRow(
            column(4,
              selectInput("metodo_ligacao", "Metodo de Ligacao:",
                          choices = c("complete" = "complete",
                                      "average" = "average",
                                      "single" = "single"),
                          selected = "average"),
              helpText("Metodo de agrupamento hierarquico para as variaveis."),
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

  # - Carrega dados da escola selecionada -
  dados_escola_reactive <- reactive({
    req(input$id_escola)

    message("\n Carregando escola: ", input$id_escola)

    caminho_mt <- encontrar_arquivo_escola_saeb(dir_resultados_por_escola, input$id_escola, "dados_FINAL_MT_Filtrado")
    caminho_lp <- encontrar_arquivo_escola_saeb(dir_resultados_por_escola, input$id_escola, "dados_FINAL_LP_Filtrado")
    caminho_metodos <- encontrar_arquivo_escola_saeb(dir_resultados_por_escola, input$id_escola, "todas_correlacoes_calculadas")

    # Validacao com mensagens descritivas
    if (is.null(caminho_mt)) {
      message("   Arquivo MT nao encontrado")
    } else {
      message("   MT: ", basename(caminho_mt))
    }

    if (is.null(caminho_lp)) {
      message("   Arquivo LP nao encontrado")
    } else {
      message("   LP: ", basename(caminho_lp))
    }

    if (is.null(caminho_metodos)) {
      message("   Arquivo de metodos nao encontrado")
    } else {
      message("   Metodos: ", basename(caminho_metodos))
    }

    validate(
      need(!is.null(caminho_mt), " Arquivo de Matematica nao encontrado para esta escola. Execute PASSO 2 (correlacao.r)."),
      need(!is.null(caminho_lp), " Arquivo de Lingua Portuguesa nao encontrado para esta escola. Execute PASSO 2 (correlacao.r)."),
      need(!is.null(caminho_metodos), " Tabela de metodos de correlacao nao encontrada para esta escola. Execute PASSO 2 (correlacao.r).")
    )

    # Carregar arquivos com validacao
    tryCatch({
      mt <- read.csv(caminho_mt)
      lp <- read.csv(caminho_lp)
      metodos <- read.csv(caminho_metodos)

      # Validar que ha dados
      validate(
        need(nrow(mt) > 0, "Arquivo de Matematica esta vazio para esta escola."),
        need(nrow(lp) > 0, "Arquivo de Portugues esta vazio para esta escola."),
        need(nrow(metodos) > 0, "Tabela de metodos esta vazia para esta escola.")
      )

      message("   Dados carregados com sucesso")

      list(
        mt         = mt,
        lp         = lp,
        metodos    = metodos,
        arquivo_mt = basename(caminho_mt),
        arquivo_lp = basename(caminho_lp)
      )
    }, error = function(e) {
      message("   ERRO ao ler arquivo: ", conditionMessage(e))
      validate(need(FALSE, paste("Erro ao ler arquivos da escola:", conditionMessage(e))))
    })
  })

  # - Texto de status dos arquivos -
  output$status_arquivos <- renderText({
    d <- dados_escola_reactive()
    paste0("MT: ", d$arquivo_mt, "  |  LP: ", d$arquivo_lp)
  })

  # - Menu dinamico de variaveis explicativas -
  output$menu_variaveis <- renderUI({
    d       <- dados_escola_reactive()
    eh_mt   <- input$materia == "MT"
    df_esc  <- if (eh_mt) d$mt else d$lp
    vars    <- setdiff(names(df_esc), NOTAS)

    if (length(vars) == 0L) {
      disciplina <- if (eh_mt) "Matematica" else "Lingua Portuguesa"
      return(helpText(paste("Nenhuma variavel disponivel para", disciplina, "nesta escola.")))
    }

    selectInput("variavel_x",
                "Variavel Socioeconomica (X):",
                choices = criar_opcoes_menu(vars))
  })

  # - Grafico de dispersao -
  output$grafico_dispersao <- renderPlot({
    tryCatch({
      d      <- dados_escola_reactive()
      req(input$variavel_x)

      eh_mt  <- input$materia == "MT"
      df     <- if (eh_mt) d$mt else d$lp
      nota_y <- if (eh_mt) nota_MT else nota_LP
      cor_p  <- if (eh_mt) "#1B4F9A" else "#1A6B3A"
      disc   <- if (eh_mt) "Matematica" else "Portugues"

      nome_bonito_x <- ifelse(
        input$variavel_x %in% names(dicionario_perguntas),
        dicionario_perguntas[[input$variavel_x]],
        input$variavel_x
      )

      validate(
        need(input$variavel_x %in% names(df),
             "Variavel selecionada nao disponivel para esta escola."),
        need(nota_y %in% names(df),
             "Variavel de proficiencia nao encontrada.")
      )

      df_plot <- df[, c(input$variavel_x, nota_y), drop = FALSE]
      df_plot <- df_plot[complete.cases(df_plot), , drop = FALSE]

      validate(
        need(nrow(df_plot) >= 5L,
             "Dados insuficientes para o grafico desta variavel."),
        need(length(unique(df_plot[[input$variavel_x]])) >= 2L,
             "A variavel X nao apresenta variacao nesta escola."),
        need(length(unique(df_plot[[nota_y]])) >= 2L,
             "A proficiencia nao apresenta variacao nesta escola.")
      )

      usar_regressao <- nrow(df_plot) >= 8L &&
                        length(unique(df_plot[[input$variavel_x]])) >= 3L

      # Renomeia colunas para nomes fixos antes do ggplot - evita .data[[]] em
      # contexto reativo, que causa erro de data mask no Shiny.
      df_plot <- setNames(df_plot, c("var_x", "var_y"))

      g <- ggplot(df_plot, aes(x = var_x, y = var_y)) +
        geom_point(alpha = 0.55, color = cor_p, size = 2.8) +
        theme_minimal(base_size = 13) +
        labs(
          title    = paste(disc, "x", nome_bonito_x),
          subtitle = paste("Escola", input$id_escola, "| Dados Escalonados (Z-score)"),
          x        = paste0(nome_bonito_x, " (Z-score padronizado)"),
          y        = paste0("Proficiencia ", disc, " (Z-score padronizado)"),
          caption  = "Nota: Eixos em desvios-padrao (). Valores = 0 representam a media da escola."
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
           paste("Erro ao gerar grafico:\n", conditionMessage(e)),
           cex = 0.9, col = "firebrick")
    })
  })

  # - Painel de estatisticas abaixo do grafico -
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

      # Obter o metodo correto da tabela de correlacoes
      metodos_df <- d$metodos
      metodo_var <- metodos_df$Metodo[metodos_df$Variavel == input$variavel_x]

      # Se nao encontrar na tabela, usar Pearson como padrao
      metodo_usar <- if (length(metodo_var) > 0 && metodo_var[1] == "Spearman") {
        "spearman"
      } else {
        "pearson"
      }

      # Calcula correlacao com o metodo apropriado
      teste <- cor.test(df_stat[[input$variavel_x]], df_stat[[nota_y]],
                        method = metodo_usar)
      r_val <- round(teste$estimate, 3)
      p_val <- teste$p.value
      n_val <- nrow(df_stat)

      # Intervalo de confianca 95%
      ic_texto <- if (length(teste$conf.int) == 2L) {
        paste0("[", round(teste$conf.int[1], 3), " ; ", round(teste$conf.int[2], 3), "]")
      } else "Nao disponivel para Spearman"

      # Label do metodo (maiuscula)
      metodo_label <- if (metodo_usar == "spearman") "Spearman" else "Pearson"

      # Formata p-valor
      p_fmt <- if (p_val < 0.001) "p < 0,001" else paste0("p = ", format(round(p_val, 3), nsmall = 3))

      # Classificacao da forca do efeito (Cohen 1988)
      forca <- dplyr::case_when(
        abs(r_val) >= 0.5 ~ "forte",
        abs(r_val) >= 0.3 ~ "moderada",
        TRUE              ~ "fraca"
      )
      sig <- p_val < 0.05

      # Cores
      cor_sig  <- if (sig) "#1A6B3A" else "#B03A2E"
      cor_r    <- if (r_val >= 0) "#1B4F9A" else "#B03A2E"
      sig_txt  <- if (sig) " Significativo (p < 0,05)" else " Nao significativo (p >= 0,05)"

      tagList(
        tags$div(
          style = "display: flex; gap: 16px; flex-wrap: wrap; margin-top: 4px;",

          tags$div(
            style = paste0(
              "flex: 1; min-width: 120px; background: #F4F6FA; border-left: 4px solid ", cor_r, ";",
              "padding: 10px 14px; border-radius: 4px;"
            ),
            tags$div(style = "font-size: 11px; color: #666; margin-bottom: 2px;",
                     paste0("Correlacao de ", metodo_label)),
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
                     ic_texto),
            tags$div(style = "font-size: 10px; color: #888; margin-top: 2px;",
                     "Intervalo de confianca")
          ),

          tags$div(
            style = "flex: 1; min-width: 120px; background: #F4F6FA; border-left: 4px solid #333;
                     padding: 10px 14px; border-radius: 4px;",
            tags$div(style = "font-size: 11px; color: #666; margin-bottom: 2px;", "Observacoes"),
            tags$div(style = "font-size: 22px; font-weight: bold; color: #333;", paste0("n = ", n_val)),
            tags$div(style = "font-size: 11px; color: #888; margin-top: 2px;", "alunos com dados validos")
          )
        )
      )
    }, error = function(e) NULL)
  })

  # - Dendograma de variaveis -
  output$dendograma_variaveis <- renderPlot({
    tryCatch({
      d      <- dados_escola_reactive()
      req(input$materia)

      eh_mt  <- input$materia == "MT"
      df     <- if (eh_mt) d$mt else d$lp
      nota_y <- if (eh_mt) nota_MT else nota_LP
      disc   <- if (eh_mt) "Matematica" else "Portugues"

      vars <- setdiff(names(df), NOTAS)

      if (length(vars) < 2L) {
        plot.new()
        text(0.5, 0.5, "Menos de 2 variaveis disponiveis para dendograma",
             cex = 1, col = "firebrick")
        return(invisible(NULL))
      }

      df_vals <- df[, c(vars, nota_y), drop = FALSE]
      df_vals <- df_vals[complete.cases(df_vals), , drop = FALSE]

      if (nrow(df_vals) < 5L) {
        plot.new()
        text(0.5, 0.5, "Dados insuficientes para analise de agrupamento",
             cex = 1, col = "firebrick")
        return(invisible(NULL))
      }

      vars_com_var <- vars[sapply(df_vals[, vars, drop = FALSE], function(x) {
        v <- var(x, na.rm = TRUE)
        !is.na(v) && v > 0
      })]

      if (length(vars_com_var) < 2L) {
        plot.new()
        text(0.5, 0.5, "Menos de 2 variaveis com variancia para dendograma",
             cex = 1, col = "firebrick")
        return(invisible(NULL))
      }

      cor_matrix  <- cor(df_vals[, vars_com_var, drop = FALSE],
                         use = "pairwise.complete.obs")
      dist_matrix <- as.dist(1 - abs(cor_matrix))
      hc          <- hclust(dist_matrix, method = input$metodo_ligacao)
      dend        <- as.dendrogram(hc)

      titulo   <- paste0("Dendograma - Clustering de Variaveis (", disc, ")")
      subtitulo <- paste0("Escola ", input$id_escola,
                          "  |  Metodo: ", input$metodo_ligacao,
                          "  |  n = ", nrow(df_vals))

      if (input$colorir_dendograma) {
        #  Usa dendextend::plot() - unico metodo que colore ramos corretamente
        k_clusters <- min(4L, length(vars_com_var) - 1L)
        dend <- dendextend::color_branches(dend, k = k_clusters)
        dend <- dendextend::color_labels(dend,  k = k_clusters)

        #  NOVO: traduz rotulos usando o dicionario
        rotulos_originais <- labels(dend)
        # Remove sufixo _num se existir (ordinais viram TX_RESP_Q10a_num)
        chaves <- sub("_num$", "", rotulos_originais)
        rotulos_traduzidos <- ifelse(
          chaves %in% names(dicionario_perguntas),
          paste0(dicionario_perguntas[chaves], "\n(", chaves, ")"),
          rotulos_originais
        )
        labels(dend) <- rotulos_traduzidos
        #

        par(mar = c(14, 4, 4, 2))   # margem inferior maior para rotulos longos
        plot(dend,
             main     = titulo,
             sub      = subtitulo,
             ylab     = "Distancia (1 - |r|)",
             cex.main = 1.1,
             cex.sub  = 0.8,
             cex      = 0.85)
      } else {
        #  NOVO: traduz rotulos
        rotulos_originais <- labels(dend)
        chaves <- sub("_num$", "", rotulos_originais)
        rotulos_traduzidos <- ifelse(
          chaves %in% names(dicionario_perguntas),
          paste0(dicionario_perguntas[chaves], "\n(", chaves, ")"),
          rotulos_originais
        )
        labels(dend) <- rotulos_traduzidos
        #

        par(mar = c(14, 4, 4, 2))   # margem inferior maior para rotulos longos
        plot(dend,
             main     = titulo,
             sub      = subtitulo,
             ylab     = "Distancia (1 - |r|)",
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

  # - Info sobre dendograma -
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

      # Filtrar apenas variaveis com variancia > 0
      vars_com_var <- vars[sapply(df_vals[, vars, drop = FALSE], function(x) {
        v <- var(x, na.rm = TRUE)
        !is.na(v) && v > 0
      })]

      if (length(vars_com_var) < 2L) return("Menos de 2 variaveis com variancia.")

      cor_matrix <- cor(df_vals[, vars_com_var, drop = FALSE], use = "pairwise.complete.obs")
      dist_matrix <- as.dist(1 - abs(cor_matrix))
      hc <- hclust(dist_matrix, method = input$metodo_ligacao)

      paste0(
        "INFORMACOES DO DENDOGRAMA\n",
        "\n",
        "Variaveis analisadas: ", length(vars), "\n",
        "Observacoes (apos limpeza): ", nrow(df_vals), "\n",
        "Metodo de ligacao: ", input$metodo_ligacao, "\n",
        "Distancia usada: 1 - |Correlacao de Pearson|\n",
        "\n",
        "Interpretacao:\n",
        " Ramos mais altos = variaveis mais dissimilares\n",
        " Ramos proximos = variaveis altamente correlacionadas\n",
        " Util para identificar redundancia de variaveis\n"
      )
    }, error = function(e) "Erro ao processar dados para informacao.")
  })
}

# =========================================================================
# Iniciar app
# =========================================================================
shinyApp(ui = ui, server = server)
