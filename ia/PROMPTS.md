# Exemplos de prompts para o assistente de IA

Estes são pedidos em português que você pode colar no Gemini CLI (no Terminal do
Positron) em cada etapa do projeto. Copie, cole, tecle Enter, e leia o que o
agente propõe antes de aceitar.

A regra vale para todos: **verificar, entender, validar.** Com o Companion
conectado, você lê o diff (verde e vermelho) e aceita com um clique. E nunca
envie dado identificado de paciente ao agente. O dado deste projeto já é agregado
e seguro.

Para conectar o agente ao Positron: no Terminal, rode `gemini`, responda "Yes"
quando ele perguntar (ou `/ide install` e `/ide enable`), e confira com
`/ide status`.

---

## Etapa 1: a fundação do projeto

> Explique, em uma frase cada, para que servem os pacotes `here` e `renv` neste
> projeto, como se eu nunca tivesse programado.

> Leia o arquivo `dados/chikungunya_2023_2025.csv` com o `readr` e me mostre os
> nomes das colunas e as primeiras linhas.

**O que verificar:** ele usou o caminho certo? Leu com `read_csv` (não `read.csv`)?

## Etapa 2: importar e limpar

> Neste dado de chikungunya, padronize a coluna `municipio_ibge` para seis
> dígitos com `str_pad`, converta `dt_notificacao` para data e transforme os
> valores "Ignorado" da coluna `sexo` em ausente. Use o `dplyr` e o `stringr`.

> Conte quantos registros existem por `classificacao` e me diga qual é a
> proporção de casos confirmados de chikungunya.

**O que verificar:** ele tratou o "Ignorado"? A conta da proporção usa o
denominador certo (o total)? Um número que não bate com o tamanho do dado é sinal
de erro.

## Etapa 3: descrição (pessoa, tempo e lugar)

> Monte uma tabela descritiva (Tabela 1) com `gtsummary`, quebrada por `sexo`,
> com as colunas idade, faixa etária, classificação e evolução.

> Gere um gráfico de linha com o número de casos de chikungunya por mês de
> notificação, usando `dt_notificacao` e o `ggplot2`, na paleta do projeto
> (`recursos/epic95_paleta.R`).

**O que verificar:** a série sobe no período chuvoso, como se espera da
chikungunya? Os meses estão em ordem?

## Etapa 4: modelo e série

> Ajuste uma regressão de Poisson dos casos confirmados de chikungunya por
> `regiao`, usando `offset(log(populacao))`, com o Nordeste como referência.
> Considere só 2023 e 2024. Devolva a razão de taxas (IRR) com intervalo de
> confiança de 95%.

> Faça a decomposição da série mensal em tendência e sazonalidade com `stl`, e
> me explique por que a parte final de 2025 aparece mais baixa.

**O que verificar:** a razão de taxas foi lida com o intervalo? A queda de 2025 é
atraso de notificação, não redução real.

## Etapa 5: o relatório

> Escreva a seção de Métodos deste relatório em português técnico, com base no
> que os scripts do projeto fazem: a fonte do dado (SINAN arboviroses,
> chikungunya, 2023 a 2025), o tratamento e o modelo de Poisson.

> A partir da tabela `tab` e do modelo `mod_pois` do projeto, escreva um parágrafo
> de Resultados reportando os números, sem interpretar.

**O que verificar:** todo número no texto existe num objeto do projeto? Confira
cada valor contra a tabela e o modelo. A IA não pode inventar citação nem
comparação com a literatura.
