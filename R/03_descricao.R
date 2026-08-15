# =============================================================================
# 03_descricao.R
# Curso de Epidemiologia Computacional com R, Positron e IA . MedTrop 2026
#
# O QUE ESTE SCRIPT FAZ
# Descreve o dado de chikungunya pelo arcabouco classico da epidemiologia:
# PESSOA, TEMPO e LUGAR. Quem adoece, quando os casos acontecem e onde se
# concentram. Produz (1) a Tabela 1 com gtsummary (pessoa), (2) a serie mensal
# de casos (tempo) e (3) dois retratos do lugar: barras de classificacao por
# regiao e um mapa de calor de regiao por mes. Tudo na paleta EPIC95.
#
# Um aviso de nome, para nao confundir: "mapa de calor" NAO e mapa geografico.
# E uma grade colorida onde a cor mostra a intensidade. Este projeto nao usa
# mapa de contorno (shapefile); o retrato do lugar aqui e regiao no eixo.
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

# Descricao pronta: pessoa (Tabela 1), tempo (serie mensal) e lugar (barras e
# mapa de calor). No 04_modelo_serie.R a gente sai da descricao e entra no
# modelo e na decomposicao da serie.
