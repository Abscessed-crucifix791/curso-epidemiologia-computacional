# =============================================================================
# 03_descricao.R
# Curso de Epidemiologia Computacional com R, Positron e IA . MedTrop 2026
#
# O QUE ESTE SCRIPT FAZ
# Descreve o dado de chikungunya pelo arcabouco classico da epidemiologia:
# PESSOA, TEMPO e LUGAR. Quem adoece, quando os casos acontecem e onde se
# concentram. Produz (1) a Tabela 1 com gtsummary (pessoa), (2) a serie mensal
# de casos (tempo) e (3) o retrato do lugar em quatro cortes: barras de
# classificacao por regiao, um mapa de calor de regiao por mes e dois mapas
# coropleticos do Brasil (por UF e por municipio) com a taxa de incidencia.
# Tudo na paleta EPIC95.
#
# Um aviso de nome, para nao confundir: o "mapa de calor" da secao 7 NAO e mapa
# geografico. E uma grade colorida onde a cor mostra a intensidade. O mapa de
# contorno, com o desenho do Brasil, vem na secao 8, com o pacote geobr.
#
# Fonte do dado: SINAN arboviroses (febre de chikungunya), 2023 a 2025,
# Portal de Dados Abertos do SUS.
# =============================================================================


# ---- 1. Pacotes -------------------------------------------------------------
library(here)       # caminhos que nao quebram
library(readr)      # ler o CSV (na rede de seguranca)
library(dplyr)      # manipular a tabela
library(stringr)    # str_pad, se precisar limpar de novo
library(lubridate)  # datas e mes
library(forcats)    # ordenar fatores
library(ggplot2)    # os graficos
library(gtsummary)  # a Tabela 1


# ---- 2. Carregar a base limpa (com rede de seguranca) -----------------------
# O caminho natural e ler o dados/chik_limpo.rds que o 02_importar_limpar.R
# gravou. Se ele nao existir (voce pulou o script 02, por exemplo), a gente le o
# CSV cru e repete a mesma limpeza aqui, para este script rodar sozinho. O
# padrao file.exists() e a rede de seguranca: o codigo nunca quebra por falta do
# arquivo intermediario.
rds <- here("dados", "chik_limpo.rds")

if (file.exists(rds)) {
  chik <- readRDS(rds)                       # caminho normal: usa o produto do 02
} else {
  # Rede de seguranca: mesma limpeza do 02_importar_limpar.R, em forma compacta.
  chik <- read_csv(here("dados", "chikungunya_2023_2025.csv"),
                   show_col_types = FALSE) |>
    mutate(
      municipio_ibge = str_pad(as.character(municipio_ibge), 6, "left", "0"),
      dt_notificacao = as_date(dt_notificacao),
      sexo           = na_if(sexo, "Ignorado"),
      evolucao       = na_if(evolucao, "Ignorado"),
      faixa_etaria   = factor(faixa_etaria,
        levels = c("<1", "1-4", "5-9", "10-19", "20-39", "40-59", "60+")),
      sexo           = fct_relevel(as.factor(sexo), "Feminino", "Masculino")
    )
}


# ---- 3. Carregar a identidade visual do curso -------------------------------
# Traz as cores (epic95_cores), as escalas (scale_fill_epic95) e o tema do curso.
source(here("recursos", "epic95_paleta.R"))


# ---- 4. PESSOA: a Tabela 1 (descritiva) --------------------------------------
# Quase todo boletim e todo artigo abre com uma tabela que descreve a populacao
# estudada: sexo, idade, classificacao, desfecho. E a Tabela 1. Ela nao testa
# hipotese, so retrata quem esta no dado. O tbl_summary escolhe sozinho a
# estatistica de cada variavel: mediana e intervalo para idade (numerica),
# contagem e porcentagem para as categoricas.
chik |>
  select(sexo, idade, faixa_etaria, classificacao, evolucao) |>
  tbl_summary(
    label = list(
      sexo          ~ "Sexo",
      idade         ~ "Idade (anos)",
      faixa_etaria  ~ "Faixa etaria",
      classificacao ~ "Classificacao do caso",
      evolucao      ~ "Evolucao"
    )
  )

# A mesma tabela quebrada por sexo, para comparar homens e mulheres lado a lado.
# Detalhe importante: o gtsummary nao aceita NA na variavel do by. Como tratamos
# "Ignorado" de sexo como NA no script 02, precisamos tirar esses registros ANTES
# e, por rigor, dizer quantos sairam. Assim a coluna nao mente sobre o total.
n_sem_sexo <- sum(is.na(chik$sexo))
message("Registros sem sexo informado (fora da tabela por sexo): ", n_sem_sexo)

tabela1 <- chik |>
  filter(!is.na(sexo)) |>                    # by nao aceita NA
  select(sexo, idade, faixa_etaria, classificacao, evolucao) |>
  tbl_summary(
    by = sexo,
    label = list(
      idade         ~ "Idade (anos)",
      faixa_etaria  ~ "Faixa etaria",
      classificacao ~ "Classificacao do caso",
      evolucao      ~ "Evolucao"
    )
  ) |>
  add_overall() |>                           # coluna com o total geral
  modify_header(label ~ "**Caracteristica**")

tabela1

# Dica de IA: peca ao Gemini CLI uma Tabela 1 com gtsummary quebrada por sexo.
# Confira se as colunas batem com a base. Veja ia/PROMPTS.md (Etapa 3).


# ---- 5. TEMPO: a serie mensal de casos --------------------------------------
# A curva de casos ao longo do tempo e o grafico mais usado na vigilancia. Como
# o dado cobre tres anos, contamos por mes de NOTIFICACAO (a coluna mes, que ja
# aponta o primeiro dia do mes de cada caso). Assim jan/2023 e jan/2024 ficam em
# pontos diferentes da linha, e a serie anda de verdade no tempo.
serie <- chik |>
  mutate(mes = floor_date(dt_notificacao, "month")) |>
  count(mes, name = "casos")

ggplot(serie, aes(x = mes, y = casos)) +
  geom_line(color = epic95_cores["primaria"], linewidth = 1) +
  geom_point(color = epic95_cores["secundaria"], size = 1.8) +
  labs(
    title = "Casos de chikungunya por mes de notificacao",
    subtitle = "SINAN arboviroses, 2023 a 2025 (a cauda de 2025 vem incompleta)",
    x = NULL, y = "Casos notificados"
  ) +
  tema_epic95()

# Tres coisas para ler na curva: tendencia (sobe ou desce ao longo dos anos),
# sazonalidade (a chikungunya acompanha o periodo chuvoso, quando o Aedes
# prolifera) e padrao incomum (um pico fora de hora). O 04_modelo_serie.R
# decompoe essa serie para separar cada componente.

# Dica de IA: peca o grafico de linha de casos por mes, na paleta do projeto.
# Confira se os meses estao em ordem. Veja ia/PROMPTS.md (Etapa 3).


# ---- 6. LUGAR (parte 1): classificacao por regiao ---------------------------
# Uma barra por regiao, cada barra dividida pela classificacao final. Com
# position = "fill" cada barra vira 100%, entao o que se compara e a PROPORCAO,
# nao o total. A leitura vira positividade: em qual regiao a fatia de confirmados
# e maior.
ggplot(chik, aes(x = regiao, fill = classificacao)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_epic95() +
  labs(
    title = "Classificacao final do caso de chikungunya por regiao",
    subtitle = "Proporcao dentro de cada regiao (SINAN arboviroses, 2023 a 2025)",
    x = NULL, y = "Proporcao", fill = "Classificacao"
  ) +
  tema_epic95()


# ---- 7. LUGAR (parte 2): mapa de calor de regiao por mes --------------------
# Cada celula cruza regiao (linhas) e mes do calendario de 1 a 12 (colunas), e a
# cor mostra a quantidade de casos. Cruzar regiao com mes revela de uma vez o
# lugar e a sazonalidade: onde a cor fica mais forte, ali esta a concentracao.
calor <- chik |>
  mutate(mes_num = month(dt_notificacao)) |>       # so o numero do mes (1 a 12)
  count(regiao, mes_num) |>
  mutate(mes_nome = factor(month.abb[mes_num], levels = month.abb))

ggplot(calor, aes(x = mes_nome, y = regiao, fill = n)) +
  geom_tile(color = "white") +
  # Gradiente na cor do curso: claro para poucos casos, escuro para muitos.
  scale_fill_gradient(low = "#e6eef3", high = epic95_cores[["secundaria"]]) +
  labs(
    title = "Casos de chikungunya por regiao e mes",
    subtitle = "Cor mais forte, mais casos (SINAN arboviroses, 2023 a 2025)",
    x = NULL, y = NULL, fill = "Casos"
  ) +
  tema_epic95()

# ---- 8. LUGAR (parte 3): mapas coropleticos do Brasil -----------------------
# Ate aqui o "lugar" foi a regiao no eixo de um grafico. Agora desenhamos o Brasil
# de verdade, com contorno geografico, e pintamos cada area pela TAXA DE
# INCIDENCIA de chikungunya confirmada por 100 mil habitantes (anos fechados de
# 2023 e 2024). Dois recortes: por UF (27 areas) e por municipio (5.570 areas). A
# cor mostra onde a doenca circulou com mais intensidade POR HABITANTE, e nao onde
# simplesmente ha mais gente. E o mesmo salto da barra de incidencia por regiao do
# relatorio, agora no mapa: da pra ver o foco de um relance.
#
# As malhas (contornos) vem do pacote geobr, que entrega os limites oficiais do
# IBGE. Para nao depender do download na hora do curso, rode UMA VEZ, com internet,
# o recursos/preparar_mapas.R: ele salva os contornos em recursos/*.rds. O codigo
# abaixo le esses arquivos (rede de seguranca file.exists) e so baixa ao vivo se
# eles nao existirem.

library(sf)         # dados espaciais: o mapa e uma tabela com uma coluna geometry

# 8.1 Carregar as malhas: do .rds pre-baixado ou, se faltar, ao vivo do geobr.
carregar_malha <- function(arquivo, baixar) {
  caminho <- here("recursos", arquivo)
  if (file.exists(caminho)) {
    readRDS(caminho)
  } else {
    message("Malha ", arquivo, " ausente; baixando do geobr (precisa de internet)...")
    baixar()
  }
}
geo_uf  <- carregar_malha("geo_uf.rds",
  function() geobr::read_state(year = 2020, simplified = TRUE, showProgress = FALSE))
geo_mun <- carregar_malha("geo_municipios.rds",
  function() geobr::read_municipality(year = 2020, simplified = TRUE, showProgress = FALSE))

# 8.2 Denominador: populacao residente (IBGE, Censo 2022).
# O SINAN traz o codigo do municipio com 6 digitos; o geobr e o arquivo de
# populacao usam o codigo de 7 digitos (o 7o e digito verificador). Para os
# codigos casarem, cortamos o 7o digito com str_sub(x, 1, 6) dos dois lados.
pop_mun <- read_csv(here("recursos", "populacao_municipios_2022.csv"),
                    show_col_types = FALSE) |>
  mutate(cod6 = str_sub(as.character(cod_ibge7), 1, 6))

pop_uf <- tribble(
  ~uf,  ~populacao,
  "11",  1581196, "12",   830018, "13",  3941613, "14",   636707,
  "15",  8120131, "16",   733759, "17",  1511460, "21",  6776699,
  "22",  3271199, "23",  8794957, "24",  3302729, "25",  3974687,
  "26",  9058931, "27",  3127683, "28",  2210004, "29", 14141626,
  "31", 20539989, "32",  3833712, "33", 16055174, "35", 44411238,
  "41", 11444380, "42",  7610361, "43", 10882965, "50",  2757013,
  "51",  3658649, "52",  7056495, "53",  2817381
)

# 8.3 Numerador: casos confirmados por UF e por municipio (2023-2024).
chik_conf <- chik |>
  filter(classificacao == "Chikungunya confirmada", ano %in% 2023:2024)

casos_uf <- chik_conf |>
  mutate(uf = str_pad(as.character(uf), 2, "left", "0")) |>
  count(uf, name = "casos")

casos_mun <- chik_conf |>
  mutate(cod6 = str_pad(as.character(municipio_ibge), 6, "left", "0")) |>
  count(cod6, name = "casos")

# 8.4 Faixas de incidencia (estilo boletim). Agrupar em faixas deixa o mapa
# legivel e evita que um municipio minusculo, com poucos casos e taxa altissima,
# domine toda a escala de cor. Do claro (pouca incidencia) ao escuro (muita).
faixas  <- c(0, 10, 50, 100, 300, Inf)
rotulos <- c("< 10", "10 a 50", "50 a 100", "100 a 300", "300+")
cores_faixa <- c("#e6eef3", "#9dc0d2", "#5f97b4", "#03658c", "#02405a")

em_faixa <- function(incidencia) {
  cut(incidencia, breaks = faixas, labels = rotulos,
      right = FALSE, include.lowest = TRUE)
}

tema_mapa <- function() {
  tema_epic95() +
    theme(axis.text = element_blank(), axis.title = element_blank(),
          panel.grid = element_blank())
}

# 8.5 Mapa por UF: junta casos e populacao na malha e calcula a taxa.
mapa_uf <- geo_uf |>
  mutate(uf = str_pad(as.character(code_state), 2, "left", "0")) |>
  left_join(casos_uf, by = "uf") |>
  left_join(pop_uf,   by = "uf") |>
  mutate(casos = coalesce(casos, 0L),
         incidencia = casos / populacao * 1e5,
         faixa = em_faixa(incidencia))

ggplot(mapa_uf) +
  geom_sf(aes(fill = faixa), color = "white", linewidth = 0.15) +
  scale_fill_manual(values = cores_faixa, drop = FALSE, na.value = "grey85") +
  labs(
    title = "Incidencia de chikungunya por Unidade da Federacao",
    subtitle = "Casos confirmados por 100 mil hab., 2023-2024 (SINAN)",
    fill = "Por 100 mil hab."
  ) +
  tema_mapa()

# 8.6 Mapa por municipio: mesma logica, 5.570 areas. Os municipios sem caso
# notificado ficam com taxa zero (a cor mais clara), o que ja aponta os focos.
mapa_mun <- geo_mun |>
  mutate(cod6 = str_sub(as.character(code_muni), 1, 6)) |>
  left_join(casos_mun, by = "cod6") |>
  left_join(select(pop_mun, cod6, populacao), by = "cod6") |>
  mutate(casos = coalesce(casos, 0L),
         incidencia = casos / populacao * 1e5,
         faixa = em_faixa(incidencia))

ggplot(mapa_mun) +
  geom_sf(aes(fill = faixa), color = NA) +
  geom_sf(data = geo_uf, fill = NA, color = "white", linewidth = 0.2) +  # divisa das UFs
  scale_fill_manual(values = cores_faixa, drop = FALSE, na.value = "grey90") +
  labs(
    title = "Incidencia de chikungunya por municipio",
    subtitle = "Casos confirmados por 100 mil hab., 2023-2024 (SINAN)",
    fill = "Por 100 mil hab."
  ) +
  tema_mapa()

# Dica de IA: peca ao Gemini CLI para transformar o mapa por UF em mapa por
# municipio (mesma paleta e faixas), ou para trocar as faixas de incidencia.
# Confira se a legenda e as cores batem. Veja ia/PROMPTS.md (Etapa 3).

# Descricao pronta: pessoa (Tabela 1), tempo (serie mensal) e lugar (barras, mapa
# de calor e os dois mapas do Brasil). No 04_modelo_serie.R a gente sai da
# descricao e entra no modelo e na decomposicao da serie.
