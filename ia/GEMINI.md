# Memória do projeto: projeto-chikungunya

Este arquivo é a memória do projeto. O Gemini CLI o lê ao abrir a pasta, e assim
acerta o padrão do curso já na primeira resposta. Se quiser conectar o agente ao
editor: no Terminal do Positron rode `gemini`, responda "Yes" (ou `/ide enable`)
e confira com `/ide status`.

## Quem sou e o que este projeto faz

Sou profissional de saúde, iniciante em programação. Este projeto é um relatório
epidemiológico reprodutível sobre a febre de chikungunya notificada no SINAN
(arboviroses), de 2023 a 2025, com dado do Portal de Dados Abertos do SUS. O
produto final é um documento Quarto que roda do início ao fim sem erro e gera
HTML, Word e PDF do mesmo arquivo-fonte.

Explique tudo em linguagem simples e assuma que sou iniciante: comente o código e
diga o resultado esperado. Prefira uma solução clara a uma solução esperta.

## Regra de segurança que não se negocia

Nunca solicite, gere, exiba ou processe dado identificado de paciente (nome, CPF,
Cartão SUS, endereço, telefone, data de nascimento completa). Se algum pedido ou
arquivo parecer conter isso, pare e me avise antes de seguir. O dado deste projeto
já é agregado e desidentificado, e assim deve permanecer.

## Convenções de código

- Escreva em R, no estilo `tidyverse` (`dplyr`, `tidyr`, `stringr`, `lubridate`,
  `forcats`).
- Use o pacote `here` para todos os caminhos. Nunca `setwd()` nem caminho absoluto.
- Não altere o dado bruto à mão. Toda transformação vira código.
- Comente em português, de forma que um iniciante entenda o porquê de cada passo.
- Gráficos com `ggplot2`, na paleta EPIC95 (`source(here("recursos","epic95_paleta.R"))`,
  funções `scale_*_epic95`), com rótulos claros.
- Tabelas com `gtsummary`, `gt` ou `flextable`, prontas para o documento Quarto.
- Sempre cite a fonte do dado e a definição do indicador (o que é, o período e a
  população de referência).

## Pacotes deste projeto

- Projeto e documento: `here`, `renv`, `quarto`
- Leitura e limpeza: `readr`, `dplyr`, `tidyr`, `stringr`, `lubridate`, `forcats`, `janitor`
- Tabelas e gráficos: `ggplot2`, `gt`, `gtsummary`, `flextable`
- Modelo e série: `glm` do R base (Poisson) e `stats::stl` para a série

Fique nesta lista. Só sugira um pacote de fora se não houver alternativa aqui, e
explique por quê. Nada de exigir pacotes pesados que a turma não instalou.

## Estrutura do projeto

```
projeto-chikungunya/
  dados/     chikungunya_2023_2025.csv   (a amostra do curso)
  R/         01_fundacao.R ... 05_relatorio.R   (o codigo, um passo por arquivo)
  relatorio/ relatorio-chikungunya.qmd   (o relatorio final, 3 saidas)
  recursos/  epic95_paleta.R             (as cores do curso)
  ia/        GEMINI.md, PROMPTS.md
  docs/      passo-a-passo.md
```

Ao criar um arquivo novo, siga esta estrutura. O dado em `dados/`, o código em
`R/`, o relatório em `relatorio/`.

## O dado e as colunas

O arquivo `dados/chikungunya_2023_2025.csv` tem as colunas: `dt_notificacao`
(data), `ano`, `semana_epi`, `uf`, `municipio_ibge` (6 dígitos), `regiao`, `sexo`,
`idade`, `faixa_etaria`, `classificacao` ("Chikungunya confirmada" ou "Descartado"),
`criterio`, `evolucao`. Atenção: o campo "Ignorado" é ausência, não um valor. O ano
de 2025 vem incompleto por atraso de notificação.

## Contexto epidemiológico

A chikungunya é uma arbovirose transmitida pelo *Aedes aegypti*, de notificação
compulsória. Ao analisar:

- Use a linguagem certa: caso notificado e caso confirmado não são a mesma coisa.
- Taxa de incidência precisa do denominador populacional (IBGE), nunca do próprio
  arquivo de casos.
- Descreva por pessoa, tempo e lugar.
- A queda no fim de 2025 é atraso de notificação, não redução real dos casos.
- O código de município do IBGE costuma vir com 6 dígitos (sem o dígito verificador).

## Como quero que você trabalhe comigo

- Se a tarefa estiver ambígua, confirme o objetivo antes de escrever muito código.
- Ao corrigir um erro, explique o que estava errado, não só entregue o conserto.
- Numa revisão, aponte inconsistências metodológicas e ausentes não tratados,
  mesmo sem eu pedir.
- Lembre-me de verificar contra a fonte todo número que você gerar. O que você
  propõe é um rascunho. A validação é minha.
