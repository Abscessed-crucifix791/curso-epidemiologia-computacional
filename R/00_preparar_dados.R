# =============================================================================
# 00_preparar_dados.R
# Curso de Epidemiologia Computacional com R, Positron e IA . MedTrop 2026
#
# O QUE ESTE SCRIPT FAZ
# Baixa os dados de febre de chikungunya (SINAN arboviroses) de 2023 a 2025 do
# Portal de Dados Abertos do SUS, seleciona um punhado de colunas didaticas,
# remove qualquer campo sensivel, padroniza os nomes e salva um arquivo unico e
# leve em dados/. Todo o curso le esse arquivo. Voce roda este script UMA VEZ,
# antes do curso, para gerar o dado.
#
# Fonte: https://dadosabertos.saude.gov.br/dataset/arboviroses-febre-de-chikungunya
# Recorte: apenas chikungunya, anos de 2023 a 2025.
#
# IMPORTANTE (leia antes de rodar)
# O Portal publica um arquivo .csv.zip por ano (SINAN arboviroses, chikungunya).
# As URLs abaixo ja apontam para 2023, 2024 e 2025. Se um dia mudarem, pegue as
# novas na pagina do dataset (botao de download de cada ano) e substitua aqui.
# O arquivo bruto e grande (2023 tem ~266 mil linhas), mas o dado preparado que
# sai daqui e leve, com poucas colunas.
#
# Os nomes de coluna previstos aqui foram conferidos contra o arquivo real de
# 2023. Se um ano vier diferente, o script avisa e mostra os nomes reais, para
# voce ajustar o de-para em MAPA_COLUNAS.
# =============================================================================

# ---- Pacotes -----------------------------------------------------------------
# Instale o que faltar com: install.packages(c("readr","dplyr","stringr","lubridate","janitor","here"))
library(readr)      # ler e escrever CSV
library(dplyr)      # manipular a tabela
library(stringr)    # tratar texto
library(lubridate)  # tratar datas
library(janitor)    # limpar nomes de coluna
library(here)       # caminhos que nao quebram

# ---- 1. Onde estao os dados brutos ------------------------------------------
# URLs dos arquivos .csv.zip de cada ano (chikungunya, SINAN arboviroses).
base_s3 <- "https://s3.sa-east-1.amazonaws.com/ckan.saude.gov.br/SINAN/Chikungunya/csv"
URLS_POR_ANO <- c(
  "2023" = paste0(base_s3, "/CHIKBR23.csv.zip"),
  "2024" = paste0(base_s3, "/CHIKBR24.csv.zip"),
  "2025" = paste0(base_s3, "/CHIKBR25.csv.zip")
)

# Onde salvar o dado preparado.
pasta_dados <- here("dados")
if (!dir.exists(pasta_dados)) dir.create(pasta_dados, recursive = TRUE)
# O arquivo do curso e uma AMOSTRA leve (rapida de carregar numa turma). O
# completo, com todas as linhas reais, fica ao lado com sufixo _completo.
arquivo_saida_csv      <- file.path(pasta_dados, "chikungunya_2023_2025.csv")
arquivo_saida_completo <- file.path(pasta_dados, "chikungunya_2023_2025_completo.csv")
arquivo_saida_parquet  <- file.path(pasta_dados, "chikungunya_2023_2025.parquet")

# Tamanho-alvo da amostra do curso. Ajuste se quiser mais ou menos linhas.
TAMANHO_AMOSTRA <- 50000

# ---- 2. De-para de colunas ---------------------------------------------------
# A esquerda, o nome padronizado que o curso usa. A direita, o nome provavel no
# arquivo bruto do SINAN (apos janitor::clean_names, tudo minusculo e com _).
# Se o arquivo bruto usar outro nome, ajuste o valor da direita.
MAPA_COLUNAS <- c(
  dt_notificacao = "dt_notific",   # data da notificacao
  ano            = "nu_ano",       # ano
  semana_epi     = "sem_not",      # semana epidemiologica da notificacao
  uf             = "sg_uf_not",    # UF de notificacao (codigo)
  municipio_ibge = "id_mn_resi",   # municipio de residencia (codigo IBGE)
  sexo_bruto     = "cs_sexo",      # sexo (M, F, I)
  idade_bruta    = "nu_idade_n",   # idade codificada do SINAN
  classi_fin     = "classi_fin",   # classificacao final do caso
  criterio       = "criterio",     # criterio de confirmacao
  evolucao       = "evolucao"      # evolucao do caso
)

# ---- 3. Funcoes de apoio -----------------------------------------------------

# Decodifica a idade do SINAN (campo NU_IDADE_N). Regra classica:
# o primeiro digito indica a unidade (1=hora, 2=dia, 3=mes, 4=ano) e os tres
# ultimos, o valor. Ex.: 4030 = 30 anos; 3011 = 11 meses (vira 0 ano completo).
decodifica_idade <- function(x) {
  x <- suppressWarnings(as.integer(x))
  unidade <- x %/% 1000
  valor   <- x %% 1000
  dplyr::case_when(
    unidade == 4 ~ as.numeric(valor),        # anos
    unidade == 3 ~ 0,                         # meses, menos de 1 ano
    unidade %in% c(1, 2) ~ 0,                 # horas ou dias
    TRUE ~ NA_real_
  )
}

# Mapeia o codigo de UF (2 digitos do IBGE) para a regiao.
uf_para_regiao <- function(uf) {
  uf <- str_sub(as.character(uf), 1, 2)
  dplyr::case_when(
    uf %in% c("11","12","13","14","15","16","17") ~ "Norte",
    uf %in% c("21","22","23","24","25","26","27","28","29") ~ "Nordeste",
    uf %in% c("31","32","33","35") ~ "Sudeste",
    uf %in% c("41","42","43") ~ "Sul",
    uf %in% c("50","51","52","53") ~ "Centro-Oeste",
    TRUE ~ NA_character_
  )
}

# Baixa o .csv.zip de um ano, descompacta e devolve so as colunas do MAPA_COLUNAS.
# O arquivo do SINAN vem separado por VIRGULA (read_csv, nao read_csv2).
ler_ano <- function(url, ano_rotulo) {
  message("Baixando ", ano_rotulo, " ...")
  zip_tmp <- tempfile(fileext = ".zip")
  utils::download.file(url, zip_tmp, mode = "wb", quiet = TRUE)

  # Descompacta o CSV de dentro do zip para uma pasta temporaria.
  nome_csv <- utils::unzip(zip_tmp, list = TRUE)$Name[1]
  csv_tmp  <- utils::unzip(zip_tmp, files = nome_csv, exdir = tempdir())

  bruto <- readr::read_csv(csv_tmp, show_col_types = FALSE, guess_max = 100000) |>
    janitor::clean_names()

  faltando <- setdiff(unname(MAPA_COLUNAS), names(bruto))
  if (length(faltando) > 0) {
    message("  ATENCAO: colunas nao encontradas em ", ano_rotulo, ": ",
            paste(faltando, collapse = ", "))
    message("  Colunas disponiveis no arquivo: ")
    print(names(bruto))
    message("  Ajuste o MAPA_COLUNAS e rode de novo.")
  }

  presentes <- MAPA_COLUNAS[MAPA_COLUNAS %in% names(bruto)]
  bruto |>
    select(all_of(unname(presentes))) |>
    rename(!!!setNames(unname(presentes), names(presentes)))
}

# ---- 4. Baixa, junta e limpa -------------------------------------------------
if (any(str_detect(URLS_POR_ANO, "COLE_AQUI"))) {
  stop("Cole as URLs dos CSV de 2023, 2024 e 2025 em URLS_POR_ANO antes de rodar.")
}

lista <- purrr::imap(URLS_POR_ANO, ~ ler_ano(.x, .y))
bruto <- dplyr::bind_rows(lista)

chik <- bruto |>
  mutate(
    dt_notificacao = suppressWarnings(lubridate::ymd(dt_notificacao)),
    ano            = suppressWarnings(as.integer(ano)),
    semana_epi     = suppressWarnings(as.integer(str_sub(as.character(semana_epi), -2))),
    municipio_ibge = str_pad(as.character(municipio_ibge), 6, side = "left", pad = "0"),
    regiao = uf_para_regiao(uf),
    sexo = dplyr::recode(as.character(sexo_bruto),
                         "M" = "Masculino", "F" = "Feminino",
                         .default = "Ignorado"),
    idade = decodifica_idade(idade_bruta),
    faixa_etaria = cut(
      idade,
      breaks = c(-Inf, 1, 5, 10, 20, 40, 60, Inf),
      labels = c("<1", "1-4", "5-9", "10-19", "20-39", "40-59", "60+"),
      right = FALSE
    ),
    classificacao = dplyr::recode(as.character(classi_fin),
                                  "5"  = "Descartado",
                                  "13" = "Chikungunya confirmada",
                                  .default = "Outro/ignorado"),
    criterio = dplyr::recode(as.character(criterio),
                             "1" = "Laboratorial",
                             "2" = "Clinico-epidemiologico",
                             "3" = "Em investigacao",
                             .default = "Ignorado"),
    evolucao = dplyr::recode(as.character(evolucao),
                             "1" = "Cura", "2" = "Obito pelo agravo",
                             "3" = "Obito por outra causa",
                             .default = "Ignorado")
  ) |>
  # Mantem so o recorte do curso e remove qualquer linha sem data ou ano util.
  filter(ano %in% 2023:2025, !is.na(dt_notificacao)) |>
  # Fica so com as colunas didaticas, ja com nomes limpos.
  select(dt_notificacao, ano, semana_epi, uf, municipio_ibge, regiao,
         sexo, idade, faixa_etaria, classificacao, criterio, evolucao)

# ---- 5. Salva ----------------------------------------------------------------
# Primeiro o completo, com todas as linhas reais.
readr::write_csv(chik, arquivo_saida_completo)
message("Salvo (completo): ", arquivo_saida_completo, " (", nrow(chik), " linhas)")

# Depois a amostra do curso: leve, rapida de carregar, com as mesmas proporcoes.
# A semente fixa garante que todo mundo receba exatamente a mesma amostra.
set.seed(2026)
chik_amostra <- dplyr::slice_sample(chik, n = min(TAMANHO_AMOSTRA, nrow(chik)))
readr::write_csv(chik_amostra, arquivo_saida_csv)
message("Salvo (amostra do curso): ", arquivo_saida_csv,
        " (", nrow(chik_amostra), " linhas)")

# Parquet e opcional. Serve para o modulo que fala de arrow. Se o pacote nao
# estiver instalado, o curso segue com o CSV.
if (requireNamespace("arrow", quietly = TRUE)) {
  arrow::write_parquet(chik_amostra, arquivo_saida_parquet)
  message("Salvo: ", arquivo_saida_parquet)
}

# ---- 6. Conferencia rapida ---------------------------------------------------
message("\nResumo da amostra do curso:")
dplyr::glimpse(chik_amostra)
chik <- chik_amostra  # o resumo abaixo usa a amostra
message("\nCasos por ano:")
print(dplyr::count(chik, ano))

# =============================================================================
# ESQUEMA FINAL (o que o curso inteiro usa). Todos os .qmd leem este arquivo:
#   dados/chikungunya_2023_2025.csv
#
# Colunas:
#   dt_notificacao  data da notificacao (Date)
#   ano             ano da notificacao (2023, 2024, 2025)
#   semana_epi      semana epidemiologica (1 a 53)
#   uf              codigo da UF de notificacao
#   municipio_ibge  codigo IBGE do municipio de residencia (6 digitos)
#   regiao          regiao do pais (Norte, Nordeste, ...)
#   sexo            Masculino, Feminino, Ignorado
#   idade           idade em anos completos (numerico)
#   faixa_etaria    faixa etaria (<1, 1-4, 5-9, 10-19, 20-39, 40-59, 60+)
#   classificacao   classificacao final do caso
#   criterio        criterio de confirmacao
#   evolucao        desfecho do caso
#
# OBSERVACAO didatica: 2025 costuma vir INCOMPLETO por atraso de notificacao.
# Isso e esperado e vira exemplo no Modulo 6 (por que a serie "cai" no fim).
# =============================================================================
