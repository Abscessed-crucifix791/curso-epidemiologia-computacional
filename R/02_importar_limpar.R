# =============================================================================
# 02_importar_limpar.R
# Curso de Epidemiologia Computacional com R, Positron e IA . MedTrop 2026
#
# O QUE ESTE SCRIPT FAZ
# Pega o dado bruto de chikungunya e o deixa pronto para analisar. O foco sao as
# tres armadilhas classicas das bases do SUS: (1) o codigo de municipio que perde
# digito, (2) as datas e o mes, (3) o "Ignorado" que finge ser categoria mas e
# ausencia. Depois, calcula o primeiro indicador (casos confirmados por regiao e
# ano, e a proporcao de confirmados) e salva a base limpa para os proximos passos.
#
# Fonte do dado: SINAN arboviroses (febre de chikungunya), 2023 a 2025,
# Portal de Dados Abertos do SUS.
# =============================================================================


# ---- 1. Pacotes e leitura do dado -------------------------------------------
library(here)       # caminhos que nao quebram
library(readr)      # ler o CSV
library(dplyr)      # os cinco verbos de manipulacao (select, filter, mutate...)
library(tidyr)      # arrumar o formato da tabela (pivot_wider no fim)
library(stringr)    # tratar texto (o str_pad do municipio)
library(lubridate)  # tratar datas (extrair ano e mes)
library(forcats)    # ordenar fatores (faixa etaria na ordem certa)

# Le a base crua, do mesmo jeito do script 01.
chik <- read_csv(
  here("dados", "chikungunya_2023_2025.csv"),
  show_col_types = FALSE
)


# ---- 2. Armadilha 1: o codigo IBGE de municipio (6 digitos) ------------------
# O SUS usa o codigo IBGE de municipio com 6 digitos (sem o digito verificador).
# O perigo: se ele for lido como numero, um codigo que comece com zero perde o
# zero da frente (por exemplo "011000" viraria 11000, com 5 digitos), e depois
# nao casa mais com nenhuma tabela externa (populacao, por exemplo).
#
# A defesa e sempre a mesma: transforma em texto e completa a esquerda com zeros
# ate ter 6 digitos. str_pad faz isso. Mesmo que aqui os codigos ja venham
# certos, deixamos a garantia no codigo, porque na sua base do dia a dia ela salva.
chik <- chik |>
  mutate(
    municipio_ibge = str_pad(
      as.character(municipio_ibge),  # garante texto antes de tudo
      width = 6,                     # queremos 6 digitos
      side  = "left",                # completa pela esquerda
      pad   = "0"                    # com zeros
    )
  )

# Confere: nenhuma linha pode ter menos de 6 digitos.
chik |>
  mutate(n_digitos = nchar(municipio_ibge)) |>
  count(n_digitos)

# Dica de IA: peca ao Gemini CLI para padronizar municipio_ibge com str_pad e
# converter a data. Confira o codigo antes de aceitar. Veja ia/PROMPTS.md (Etapa 2).


# ---- 3. Armadilha 2: datas e o mes de notificacao ---------------------------
# O read_csv ja leu dt_notificacao como data de verdade (tipo <date>), porque o
# arquivo esta em ano-mes-dia. Nem sempre e assim: quando a data chega como texto,
# voce converte com lubridate::ymd() (ou dmy(), mdy(), conforme o formato).
# as_date() aqui e uma garantia: se ja for data, nao muda nada.
#
# Um aviso que vale o curso inteiro: cada notificacao tem mais de uma data (inicio
# dos sintomas, notificacao, digitacao). Escolha a certa para o seu indicador e
# diga qual usou. Aqui usamos a data de NOTIFICACAO.
chik <- chik |>
  mutate(
    dt_notificacao = as_date(dt_notificacao),           # garante o tipo data
    ano_notif      = year(dt_notificacao),              # extrai o ano
    mes            = floor_date(dt_notificacao, "month") # 1o dia do mes do caso
  )

chik |>
  select(dt_notificacao, ano, ano_notif, mes) |>
  head()


# ---- 4. Armadilha 3: o "Ignorado" e ausencia, nao categoria ------------------
# As colunas sexo e evolucao trazem "Ignorado". Isso nao e uma categoria a mais:
# e falta de informacao. Se voce deixa o "Ignorado" no denominador ou no grafico,
# ele infla a conta e distorce a proporcao. O certo e transformar em NA (ausente)
# de proposito e, no fim, relatar quanto se perdeu.
#
# na_if(x, "Ignorado") troca todo "Ignorado" por NA. (Repare que na coluna
# evolucao o dado real tambem traz "Obito por outra causa", alem de "Cura" e
# "Obito pelo agravo". Nos so tratamos o "Ignorado" como ausente; as demais
# categorias sao informacao legitima e ficam.)
chik <- chik |>
  mutate(
    sexo     = na_if(sexo, "Ignorado"),
    evolucao = na_if(evolucao, "Ignorado")
  )

# Quanto de informacao de sexo se perdeu? Rigor e relatar o ausente (o NA).
chik |>
  count(sexo)


# ---- 5. Colocar os fatores na ordem certa -----------------------------------
# faixa_etaria e sexo chegaram do CSV como texto. Se ficarem assim, tabelas e
# graficos ordenam em ordem alfabetica, e "10-19" apareceria antes de "5-9", o
# que confunde qualquer leitor. Transformamos em fator (factor) com os niveis na
# ordem epidemiologica que faz sentido.
chik <- chik |>
  mutate(
    faixa_etaria = factor(
      faixa_etaria,
      levels = c("<1", "1-4", "5-9", "10-19", "20-39", "40-59", "60+")
    ),
    # Feminino e Masculino na frente. Como ja tratamos "Ignorado" como NA, ele
    # nao vira nivel. fct_relevel nao cria categoria vazia se ela nao existe.
    sexo = fct_relevel(as.factor(sexo), "Feminino", "Masculino")
  )

glimpse(chik)


# ---- 6. O primeiro indicador: confirmados por regiao e ano ------------------
# Dado limpo vira numero que se interpreta. Todo indicador carrega definicao,
# periodo e fonte. Definicao: casos com classificacao "Chikungunya confirmada".
# Periodo: 2023 a 2025. Fonte: SINAN arboviroses (Portal de Dados Abertos do SUS).
casos_confirmados <- chik |>
  filter(classificacao == "Chikungunya confirmada") |>  # so os confirmados
  count(regiao, ano, name = "casos")                    # conta por regiao e ano

casos_confirmados

# A mesma tabela em formato largo (um ano por coluna) fica mais legivel num
# relatorio. pivot_wider faz essa virada. values_fill = 0 evita NA onde uma
# regiao ficou sem caso num ano.
casos_confirmados |>
  pivot_wider(names_from = ano, values_from = casos, values_fill = 0)


# ---- 7. O segundo indicador: proporcao de confirmados -----------------------
# Uma parte sobre o total, em porcentagem. Aqui, a proporcao de notificacoes que
# terminam confirmadas como chikungunya, por ano. E uma leitura da qualidade do
# encerramento dos casos. O denominador e o TOTAL de notificacoes do ano.
chik |>
  group_by(ano) |>
  summarise(
    total       = n(),
    confirmados = sum(classificacao == "Chikungunya confirmada"),
    prop_pct    = round(confirmados / total * 100, 1),
    .groups     = "drop"
  )

# Repare que 2025 tende a vir com menos casos. Isso nao quer dizer que a doenca
# sumiu: o dado de 2025 esta INCOMPLETO por atraso de notificacao (o registro
# ainda esta entrando no sistema). Voltamos a esse ponto no 04_modelo_serie.R.

# Dica de IA: peca ao agente a contagem por classificacao e a proporcao de
# confirmados. Confira se o denominador e o total. Veja ia/PROMPTS.md (Etapa 2).


# ---- 8. Salvar a base limpa para os proximos passos -------------------------
# A base tratada e o produto deste script. Salvamos num arquivo .rds (formato do
# proprio R, que preserva os tipos: datas continuam datas, fatores continuam
# fatores). Os scripts 03 e 04 carregam este arquivo, sem repetir a limpeza.
# saveRDS grava um unico objeto; readRDS le de volta.
saveRDS(chik, here("dados", "chik_limpo.rds"))

# Base limpa salva em dados/chik_limpo.rds. No 03_descricao.R a gente descreve o
# dado por pessoa, tempo e lugar.
