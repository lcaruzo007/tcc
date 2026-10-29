################################################################################
# SCRIPT: dados_saeb.r
# ENTRADA: Microdados SAEB 2023 de MG e dicionarios de utils_saeb.r.
# SAIDA: Contratos, limpeza, agregacao e elegibilidade compartilhados.
# VERSAO: 1.0 - Outubro 2026
################################################################################

library(tidyverse)

numero_estrito_saeb <- function(x, coluna) {
  texto <- trimws(as.character(x))
  ausente <- is.na(x) | texto %in% c("", "NA", ".", "*")
  numero <- suppressWarnings(as.numeric(texto))
  if (any(!ausente & (!is.finite(numero) | grepl(",", texto, fixed = TRUE)))) {
    stop("Conversao numerica invalida em ", coluna, "; confira a fonte e o separador decimal.")
  }
  numero[ausente] <- NA_real_
  numero
}

validar_recorte_saeb <- function(dados) {
  esperados <- list(ID_SAEB = 2023L, ID_UF = 31L, ID_SERIE = c(12L, 13L))
  for (coluna in names(esperados)) {
    if (!coluna %in% names(dados) || anyNA(dados[[coluna]]) ||
        any(!dados[[coluna]] %in% esperados[[coluna]])) {
      stop("Recorte invalido ou coluna ausente: ", coluna,
           ". Esperado SAEB 2023, MG, series 12/13.")
    }
  }
  if (!nrow(dados)) stop("Base de microdados vazia.")
  for (coluna in c("ID_ESCOLA", "ID_ALUNO", "ID_MUNICIPIO")) {
    if (!coluna %in% names(dados) || anyNA(dados[[coluna]]) ||
        any(!grepl("^[0-9]+$", as.character(dados[[coluna]])))) {
      stop("Identificador ausente ou invalido: ", coluna)
    }
  }
  if (anyDuplicated(dados$ID_ALUNO)) stop("ID_ALUNO duplicado no recorte SAEB.")
  invisible(TRUE)
}

limpar_indicadores_saeb <- function(dados) {
  dados <- as_tibble(dados)
  for (disciplina in c("MT", "LP")) {
    nota <- paste0("PROFICIENCIA_", disciplina, "_SAEB")
    flag <- paste0("IN_PROFICIENCIA_", disciplina)
    if (!all(c(nota, flag) %in% names(dados))) {
      stop("Colunas de validade ausentes: ", nota, " / ", flag)
    }
    valores <- numero_estrito_saeb(dados[[nota]], nota)
    validos <- !is.na(dados[[flag]]) & dados[[flag]] == 1 &
      is.finite(valores) & valores >= 150 & valores <= 800
    dados[[nota]] <- ifelse(validos, valores, NA_real_)
  }
  if (!all(c("IN_INSE", "INSE_ALUNO") %in% names(dados))) {
    stop("Colunas IN_INSE e INSE_ALUNO sao obrigatorias.")
  }
  inse <- numero_estrito_saeb(dados$INSE_ALUNO, "INSE_ALUNO")
  valido_inse <- !is.na(dados$IN_INSE) & dados$IN_INSE == 1 & is.finite(inse)
  dados$INSE_ALUNO <- ifelse(valido_inse, inse, NA_real_)
  if ("NU_TIPO_NIVEL_INSE" %in% names(dados)) {
    dados$NU_TIPO_NIVEL_INSE <- ifelse(
      valido_inse, numero_estrito_saeb(dados$NU_TIPO_NIVEL_INSE, "NU_TIPO_NIVEL_INSE"), NA_real_
    )
  }
  dados
}

agregar_proporcoes_saeb <- function(dados, itens, minimo = 3L) {
  resultado <- dados |> distinct(ID_ESCOLA)
  for (item in itens) {
    contagem <- dados |>
      transmute(ID_ESCOLA, resp = limpar_resposta_saeb(.data[[item]], item)) |>
      filter(!is.na(resp)) |>
      count(ID_ESCOLA, resp) |>
      group_by(ID_ESCOLA) |>
      mutate(n_valid = sum(n), prop = if_else(n_valid >= minimo, n / n_valid, NA_real_)) |>
      ungroup()
    categorias <- sort(unique(contagem$resp))
    if (!length(setdiff(categorias, "A"))) next
    agregado <- contagem |>
      select(ID_ESCOLA, resp, prop) |>
      pivot_wider(names_from = resp, values_from = prop,
                  names_prefix = paste0(item, "_"), values_fill = 0) |>
      select(-any_of(paste0(item, "_A")))
    insuficientes <- contagem |> filter(n_valid < minimo) |> distinct(ID_ESCOLA)
    agregado[agregado$ID_ESCOLA %in% insuficientes$ID_ESCOLA, -1] <- NA_real_
    resultado <- left_join(resultado, agregado, by = "ID_ESCOLA", relationship = "one-to-one")
  }
  resultado
}

ler_microdados_saeb <- function(arquivo) {
  if (!file.exists(arquivo)) stop("Microdados nao encontrados: ", arquivo)
  dados <- data.table::fread(arquivo, integer64 = "character", showProgress = FALSE) |>
    as_tibble()
  validar_recorte_saeb(dados)
  registrar_entrada_saeb(arquivo)
  exclusoes <- map_dfr(c("MT", "LP"), function(s) {
    x <- numero_estrito_saeb(dados[[paste0("PROFICIENCIA_", s, "_SAEB")]], s)
    flag <- dados[[paste0("IN_PROFICIENCIA_", s)]]
    dados |>
      transmute(ID_ESCOLA, ID_ALUNO, Disciplina = s, Valor_original = x,
        Motivo = case_when(x > 800 ~ "ACIMA_800_CORRUPCAO",
                           x < 150 ~ "ABAIXO_150_FILTRO_METODOLOGICO", TRUE ~ NA_character_)) |>
      filter(!is.na(flag), flag == 1, !is.na(Motivo))
  })
  if (nrow(exclusoes)) {
    write_csv(exclusoes, caminho_saida(file.path(detectar_raiz(), "TESTE", "DOCUMENTACAO"),
                                       "diagnosticos", "notas_excluidas", "csv"))
    message("Notas fora da politica 150-800 registradas: ", nrow(exclusoes),
            ". Abaixo de 150 nao significa erro confirmado da fonte.")
  }
  limpar_indicadores_saeb(dados)
}

limpar_resposta_saeb <- function(x, item) {
  dominio <- names(DICT_ROTULOS_SAEB[[item]])
  if (!length(dominio)) stop("Item sem dominio no dicionario: ", item)
  x <- trimws(as.character(x))
  x[is.na(x) | !x %in% dominio] <- NA_character_
  x
}

transformar_respostas_saeb <- function(dados) {
  dados <- as_tibble(dados)
  itens <- grep("^TX_RESP_Q[0-9]+[a-z]?$", names(dados), value = TRUE)
  for (item in itens) dados[[item]] <- limpar_resposta_saeb(dados[[item]], item)
  for (item in intersect(names(ORDINAIS_SAEB), itens)) {
    dados[[paste0(item, "_num")]] <- match(dados[[item]], ORDINAIS_SAEB[[item]])
  }
  for (item in intersect(names(NOMINAIS_SAEB), itens)) {
    info <- NOMINAIS_SAEB[[item]]
    for (codigo in names(info$mapping)) {
      nome <- paste0(info$prefix, "_", info$mapping[[codigo]])
      dados[[nome]] <- ifelse(is.na(dados[[item]]), NA_integer_,
                              as.integer(dados[[item]] == codigo))
    }
  }
  dados
}

colunas_analiticas_saeb <- function(dados) {
  dummies <- unlist(lapply(NOMINAIS_SAEB, function(info) {
    paste0(info$prefix, "_", info$mapping)
  }), use.names = FALSE)
  esperadas <- c("PROFICIENCIA_MT_SAEB", "PROFICIENCIA_LP_SAEB",
                 paste0(names(ORDINAIS_SAEB), "_num"), dummies, CONTINUAS_SAEB)
  ausentes <- setdiff(esperadas, names(dados))
  if (length(ausentes)) stop("Colunas analiticas ausentes: ", paste(ausentes, collapse = ", "))
  if (!all(vapply(dados[esperadas], is.numeric, logical(1)))) {
    stop("Colunas analiticas devem ser numericas.")
  }
  esperadas
}

media_segura_saeb <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) return(NA_real_)
  mean(x)
}

moda_saeb <- function(x) {
  x <- x[!is.na(x)]
  if (!length(x)) return(NA_real_)
  as.numeric(names(sort(table(x), decreasing = TRUE)[1]))
}

contexto_unico_saeb <- function(x, validos) {
  x <- unique(x[!is.na(x) & x %in% validos])
  if (length(x) > 1L) stop("Contexto escolar inconsistente dentro de ID_ESCOLA.")
  if (!length(x)) return(NA_real_)
  as.numeric(x)
}

agregar_escolas_saeb <- function(dados, pareadas = FALSE) {
  dados <- limpar_indicadores_saeb(dados) |>
    mutate(.par = is.finite(PROFICIENCIA_MT_SAEB) & is.finite(PROFICIENCIA_LP_SAEB))
  dados |>
    group_by(ID_ESCOLA) |>
    summarise(
      MEDIA_MT = media_segura_saeb(PROFICIENCIA_MT_SAEB[!pareadas | .par]),
      MEDIA_LP = media_segura_saeb(PROFICIENCIA_LP_SAEB[!pareadas | .par]),
      INSE_MEDIO = media_segura_saeb(INSE_ALUNO),
      N_ALUNOS = n(),
      N_ALUNOS_MT_VALIDOS = sum(is.finite(PROFICIENCIA_MT_SAEB)),
      N_ALUNOS_LP_VALIDOS = sum(is.finite(PROFICIENCIA_LP_SAEB)),
      N_ALUNOS_PAREADOS = sum(.par),
      N_ALUNOS_MT = if (pareadas) sum(.par) else sum(is.finite(PROFICIENCIA_MT_SAEB)),
      N_ALUNOS_INSE = sum(is.finite(INSE_ALUNO)),
      NIVEL_INSE_MODAL = moda_saeb(NU_TIPO_NIVEL_INSE),
      .publica = contexto_unico_saeb(IN_PUBLICA, c(0, 1)),
      .area = contexto_unico_saeb(ID_AREA, c(1, 2)),
      .local = contexto_unico_saeb(ID_LOCALIZACAO, c(1, 2)),
      .groups = "drop"
    ) |>
    mutate(
      TIPO_ESCOLA = case_when(.publica == 1 ~ "Publica", .publica == 0 ~ "Privada"),
      AREA = case_when(.area == 1 ~ "Capital", .area == 2 ~ "Interior"),
      LOCALIZACAO = case_when(.local == 1 ~ "Urbana", .local == 2 ~ "Rural"),
      AREA_LOCAL = if_else(is.na(AREA) | is.na(LOCALIZACAO), NA_character_,
                           paste0(LOCALIZACAO, "_", AREA)),
      MEDIAS_PAREADAS = pareadas
    ) |>
    select(-.publica, -.area, -.local)
}

classificar_quantis_saeb <- function(x, probs, rotulos) {
  resultado <- rep(NA_character_, length(x))
  validos <- is.finite(x)
  if (!any(validos)) return(resultado)
  cortes <- quantile(x[validos], probs = probs, names = FALSE)
  resultado[validos] <- rotulos[vapply(x[validos], function(v) sum(v >= cortes) + 1L, integer(1))]
  resultado
}

amostra_escolas_saeb <- function(base, minimo = 5L, minimo_inse = 3L,
                                 exigir_inse = TRUE) {
  base |>
    mutate(
      Incluida = N_ALUNOS_MT >= minimo & N_ALUNOS_LP_VALIDOS >= minimo &
        is.finite(MEDIA_MT) & is.finite(MEDIA_LP) &
        (!exigir_inse | (N_ALUNOS_INSE >= minimo_inse & is.finite(INSE_MEDIO))) &
        !is.na(TIPO_ESCOLA) & !is.na(AREA_LOCAL),
      Motivo = case_when(
        !is.finite(MEDIA_MT) | !is.finite(MEDIA_LP) ~ "SEM_NOTAS_VALIDAS",
        N_ALUNOS_MT < minimo | N_ALUNOS_LP_VALIDOS < minimo ~ "POUCOS_ALUNOS",
        exigir_inse & (N_ALUNOS_INSE < minimo_inse | !is.finite(INSE_MEDIO)) ~ "INSE_INSUFICIENTE",
        is.na(TIPO_ESCOLA) | is.na(AREA_LOCAL) ~ "CONTEXTO_AUSENTE",
        TRUE ~ "INCLUIDA"
      )
    )
}

preparar_contraste_area_saeb <- function(dados, categoria) {
  if (identical(categoria, "Urbana_Capital")) stop("Categoria deve diferir da referencia.")
  resultado <- dados |>
    filter(AREA_LOCAL %in% c("Urbana_Capital", categoria))
  if (!all(c("Urbana_Capital", categoria) %in% resultado$AREA_LOCAL)) {
    stop("Contraste sem os dois grupos: ", categoria)
  }
  resultado
}

rotulos_analiticos_saeb <- function() {
  rotulos <- c(DICT_PERGUNTAS_SAEB, INSE_ALUNO = "INSE do estudante",
                NU_TIPO_NIVEL_INSE = "Nivel ordinal do INSE")
  for (item in names(ORDINAIS_SAEB)) {
    rotulos[paste0(item, "_num")] <- DICT_PERGUNTAS_SAEB[[item]]
  }
  for (item in names(NOMINAIS_SAEB)) {
    info <- NOMINAIS_SAEB[[item]]
    for (codigo in names(info$mapping)) {
      rotulos[paste0(info$prefix, "_", info$mapping[[codigo]])] <- paste(
        DICT_PERGUNTAS_SAEB[[item]], DICT_ROTULOS_SAEB[[item]][[codigo]]
      )
    }
  }
  rotulos
}

correlacao_segura_saeb <- function(x, y, metodo) {
  ok <- is.finite(x) & is.finite(y)
  n <- sum(ok)
  status <- if (n < 3L) "SEM_PARES" else if (var(x[ok]) == 0) {
    "SEM_VARIANCIA_X"
  } else if (var(y[ok]) == 0) "SEM_VARIANCIA_Y" else "OK"
  valor <- if (status == "OK") cor(x[ok], y[ok], method = tolower(metodo)) else NA_real_
  list(valor = valor, status = status, n = n)
}

validar_metadados_saeb <- function(dados) {
  obrigatorias <- c("ID_ESCOLA", "TIPO_ESCOLA", "AREA_LOCAL", "MEDIA_MT", "MEDIA_LP",
                    "INSE_MEDIO", "FAIXA_MT", "FAIXA_LP", "GRUPO_INSE",
                    "N_ALUNOS_MT_VALIDOS", "N_ALUNOS_LP_VALIDOS", "N_ALUNOS_INSE")
  if (length(setdiff(obrigatorias, names(dados)))) stop("Metadados incompletos; regenere o passo 4.")
  if (anyNA(dados$ID_ESCOLA) || anyDuplicated(dados$ID_ESCOLA)) stop("ID_ESCOLA invalido.")
  if (any(!na.omit(dados$AREA_LOCAL) %in% c("Urbana_Capital", "Urbana_Interior",
                                           "Rural_Capital", "Rural_Interior"))) {
    stop("AREA_LOCAL invalida.")
  }
  for (disciplina in c("MT", "LP")) {
    x <- dados[[paste0("MEDIA_", disciplina)]]
    faixa <- dados[[paste0("FAIXA_", disciplina)]]
    n <- dados[[paste0("N_ALUNOS_", disciplina, "_VALIDOS")]]
    if (any(is.nan(x)) || any(!is.na(x) & (!is.finite(x) | x < 150 | x > 800))) {
      stop("Media invalida: ", disciplina)
    }
    if (any(is.na(x) != is.na(faixa)) || any(n == 0 & !is.na(x))) {
      stop("Faixa ou denominador inconsistente: ", disciplina)
    }
  }
  if (any(is.nan(dados$INSE_MEDIO)) ||
      any(is.na(dados$INSE_MEDIO) != is.na(dados$GRUPO_INSE))) {
    stop("Grupo INSE inconsistente com ausencia do indicador.")
  }
  invisible(TRUE)
}

dados_dendrograma_saeb <- function(hc, type = "rectangle") {
  if (grDevices::dev.cur() == 1L) {
    grDevices::pdf(file = NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  ggdendro::dendro_data(hc, type = type)
}
