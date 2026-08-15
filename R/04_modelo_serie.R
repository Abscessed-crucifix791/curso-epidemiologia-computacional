# =============================================================================
# 04_modelo_serie.R
# Curso de Epidemiologia Computacional com R, Positron e IA . MedTrop 2026
#
# O QUE ESTE SCRIPT FAZ
# Dois passos que fecham a analise. Primeiro, UM modelo: uma regressao de Poisson
# que compara a taxa de chikungunya confirmada entre as regioes, com a populacao
# entrando como offset e o Nordeste como referencia. A meta nao e dominar
# regressao, e ler o resultado: a razao de taxas (IRR) e o intervalo de confianca.
# Segundo, a serie mensal decomposta com stl (tendencia, sazonalidade e resto),
# com atencao ao 2025 incompleto por atraso de notificacao.
#
# Fonte do dado: SINAN arboviroses (febre de chikungunya), 2023 a 2025,
# Portal de Dados Abertos do SUS.
# =============================================================================


# ---- 1. Pacotes -------------------------------------------------------------
library(here)       # caminhos que nao quebram
library(readr)      # ler o CSV (na rede de seguranca)
library(dplyr)      # manipular a tabela
library(tibble)     # montar a tabela de populacao
library(stringr)    # str_pad, se precisar limpar de novo
library(lubridate)  # datas e mes
library(tidyr)      # completar a grade de meses
library(ggplot2)    # o grafico que motiva o modelo


# ---- 2. Carregar a base limpa (com rede de seguranca) -----------------------
# Mesmo padrao do script 03: usa o dados/chik_limpo.rds do script 02 se existir;
# senao, le o CSV cru e repete a limpeza, para rodar sozinho.
rds <- here("dados", "chik_limpo.rds")

if (file.exists(rds)) {
  chik <- readRDS(rds)
} else {
  chik <- read_csv(here("dados", "chikungunya_2023_2025.csv"),
                   show_col_types = FALSE) |>
    mutate(
      municipio_ibge = str_pad(as.character(municipio_ibge), 6, "left", "0"),
      dt_notificacao = as_date(dt_notificacao),
      sexo           = na_if(sexo, "Ignorado"),
      evolucao       = na_if(evolucao, "Ignorado")
    )
}

source(here("recursos", "epic95_paleta.R"))


# =============================================================================
# PARTE A . O MODELO DE POISSON (razao de taxas por regiao)
# =============================================================================

# ---- 3. Montar a tabela agregada: casos por regiao e ano --------------------
# A regressao de contagem gosta de uma tabela agregada. Duas decisoes deliberadas,
# e vale explica-las:
#   . contamos so os casos CONFIRMADOS (e a taxa de doenca que interessa, nao a
#     de notificacoes que depois foram descartadas);
#   . ficamos com 2023 e 2024, os anos fechados. O 2025 vem incompleto por atraso
#     de notificacao (a Parte B mostra isso), entao inclui-lo distorceria a taxa.
#
# Ficamos com uma linha por regiao e ano. Manter mais de uma linha por regiao
# (2023 e 2024) deixa graus de liberdade para o modelo; colapsar para uma linha
# por regiao saturaria o ajuste.
casos_regiao_ano <- chik |>
  filter(classificacao == "Chikungunya confirmada", ano %in% 2023:2024) |>
  count(regiao, ano, name = "casos")

casos_regiao_ano


# ---- 4. O denominador: populacao por regiao ---------------------------------
# Sem populacao, contagem nao vira taxa. A tabela abaixo traz um valor por regiao.
# Fonte: IBGE, estimativas da populacao residente por Grande Regiao (ordem de
# grandeza dos totais nacionais). Os numeros aqui sao ILUSTRATIVOS, arredondados,
# so para servir de denominador em aula. Num trabalho de verdade, use a estimativa
# populacional oficial do IBGE para o ano de referencia.
populacao_regiao <- tribble(
  ~regiao,         ~populacao,
  "Norte",          18900000,
  "Nordeste",       57700000,
  "Sudeste",        89600000,
  "Sul",            30400000,
  "Centro-Oeste",   16700000
)

# Junta casos e populacao. inner_join mantem so as regioes presentes nos casos,
# para nao sobrar linha sem contagem (nem NA solto).
dados_modelo <- casos_regiao_ano |>
  inner_join(populacao_regiao, by = "regiao")

dados_modelo


# ---- 5. Olhar a taxa antes de modelar ---------------------------------------
# Comparar contagem bruta engana: uma regiao populosa tem mais casos so por ter
# mais gente. O que se compara e a TAXA (casos por 100 mil habitantes). A razao
# de taxas entre duas regioes e o que o modelo vai estimar com intervalo.
dados_modelo |>
  group_by(regiao) |>
  summarise(casos = sum(casos), populacao = first(populacao), .groups = "drop") |>
  mutate(taxa_100mil = round(casos / populacao * 1e5, 1)) |>
  arrange(desc(taxa_100mil))


# ---- 6. A regressao de Poisson ----------------------------------------------
# Poisson e o classico para contagem (casos, obitos, internacoes). O detalhe que
# transforma contagem em taxa e o OFFSET: avisamos ao modelo o tamanho da
# populacao de cada linha, com offset(log(populacao)) DENTRO da formula. Sem ele,
# o modelo compararia numero de casos, o que nao faz sentido epidemiologico.
# Com ele, exp() do coeficiente vira razao de taxas.
#
# relevel define a referencia: todas as regioes serao comparadas com o Nordeste,
# escolhido por ser regiao de circulacao historica da chikungunya no Brasil.
dados_modelo <- dados_modelo |>
  mutate(regiao = relevel(factor(regiao), ref = "Nordeste"))

m_pois <- glm(
  casos ~ regiao + offset(log(populacao)),
  family = poisson(link = "log"),
  data   = dados_modelo
)

summary(m_pois)


# ---- 7. Do coeficiente a razao de taxas (IRR) e o intervalo -----------------
# O summary mostra os coeficientes na escala do logaritmo. Ninguem interpreta
# nessa escala. A gente exponencia (exp) para trazer para a escala de razao de
# taxas, a que se le. O intervalo de 95% sai por Wald: exp(coef +/- 1,96 * erro).
co <- summary(m_pois)$coefficients

tabela_irr <- tibble(
  termo   = rownames(co),
  IRR     = exp(co[, "Estimate"]),
  IC_inf  = exp(co[, "Estimate"] - 1.96 * co[, "Std. Error"]),
  IC_sup  = exp(co[, "Estimate"] + 1.96 * co[, "Std. Error"]),
  valor_p = co[, "Pr(>|z|)"]
) |>
  filter(termo != "(Intercept)") |>        # o intercepto nao tem leitura direta
  mutate(across(c(IRR, IC_inf, IC_sup), \(x) round(x, 2)))

tabela_irr

# Como ler, sempre nesta ordem: DIRECAO, MAGNITUDE, INCERTEZA.
#   . Direcao: IRR acima de 1, risco maior que o Nordeste; abaixo de 1, menor.
#   . Magnitude: IRR de 2 quer dizer o dobro da taxa do Nordeste (nao 2% a mais).
#   . Incerteza: se o IC de 95% cruza o 1, nao da para afirmar diferenca. Reporte
#     sempre o IRR com o intervalo, nunca o ponto sozinho.

# Dica de IA: peca ao Gemini CLI a regressao de Poisson com offset(log(populacao))
# e Nordeste como referencia, so 2023 e 2024, devolvendo IRR com IC 95%. Confira
# se o offset esta la e se a referencia esta certa. Veja ia/PROMPTS.md (Etapa 4).


# =============================================================================
# PARTE B . A SERIE MENSAL E A DECOMPOSICAO STL
# =============================================================================

# ---- 8. Montar a serie mensal com a grade completa --------------------------
# count(mes) omite, sem avisar, os meses que ficaram sem caso. Isso "encolhe" o
# eixo do tempo e desalinha a decomposicao (que precisa de 12 meses por ciclo).
# Por isso montamos a grade completa de meses e preenchemos com zero onde faltou.
contagem <- chik |>
  mutate(mes = floor_date(dt_notificacao, "month")) |>
  count(mes, name = "casos")

grade_meses <- tibble(
  mes = seq(min(contagem$mes), max(contagem$mes), by = "month")
)

serie <- grade_meses |>
  left_join(contagem, by = "mes") |>
  mutate(casos = replace_na(casos, 0)) |>       # mes sem caso vira 0, nao NA
  arrange(mes)

# Quantos casos por ano? Esse numero guarda a pegadinha do 2025 incompleto.
serie |>
  mutate(ano = year(mes)) |>
  group_by(ano) |>
  summarise(casos_no_ano = sum(casos), meses = n(), .groups = "drop")


# ---- 9. Decompor a serie com stl --------------------------------------------
# Decompor e separar a serie em tres componentes: sazonalidade, tendencia e
# resto. A funcao stl (Seasonal-Trend decomposition using Loess) faz isso sem
# instalar nada. Ela precisa saber quantas observacoes formam um ciclo: em serie
# mensal, o ciclo anual tem 12 meses (frequency = 12). O stl exige pelo menos
# dois ciclos completos (24 meses); a nossa serie de 2023 a 2025 tem mais.
inicio   <- c(year(min(serie$mes)), month(min(serie$mes)))  # ano e mes iniciais
serie_ts <- ts(serie$casos, frequency = 12, start = inicio)

decomp <- stl(serie_ts, s.window = "periodic")

# O grafico padrao mostra quatro paineis: dado, sazonal, tendencia e resto.
plot(decomp, main = "Decomposicao STL da serie de chikungunya")

# O ouro do modulo: a tendencia que o stl desenha DESCE no fim da serie. Parece
# que a chikungunya recuou. Nao caia nessa. A queda vem do 2025 incompleto: os
# meses mais recentes ainda vao receber notificacoes atrasadas. O metodo separa
# tendencia e sazonalidade com honestidade, mas ele nao sabe que o dado do ano
# corrente ainda esta chegando. Quem sabe disso e voce.
#
# Regra pratica: nunca leia a ponta de uma serie de notificacao como tendencia
# epidemiologica. Antes de dizer que os casos cairam, pergunte se aquele mes ja
# fechou. Boletins serios marcam os ultimos periodos como "dados sujeitos a
# revisao" justamente por isso.

# Dica de IA: peca a decomposicao stl da serie mensal e a explicacao de por que
# a parte final de 2025 aparece mais baixa. Confira que a resposta cita o atraso
# de notificacao, nao uma queda real. Veja ia/PROMPTS.md (Etapa 4).

# Modelo lido e serie decomposta. No 05_relatorio.R a gente costura tudo no
# relatorio final e mostra como renderizar para HTML, Word e PDF.
