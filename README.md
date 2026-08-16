# Projeto de chikungunya · o projeto do curso, pronto para rodar

**Curso:** Epidemiologia Computacional com R, Positron e IA · MedTrop 2026

Este é o projeto final do curso, completo e funcional. Você recebe ele pronto:
o dado já está aqui, o código já roda, e o relatório se gera sozinho. O curso vai
mostrar, peça por peça, como cada parte foi construída, para você conseguir
refazer e adaptar às suas próprias perguntas.

Você não precisa saber programar para começar.

---

## Como baixar

Duas formas, e nenhuma exige conta no GitHub.

**No Console do Positron (recomendado).** Cole e rode:

```r
install.packages("usethis")
usethis::use_course("https://github.com/wandersonepidemiologista/curso-epidemiologia-computacional/archive/refs/heads/main.zip")
```

Ele baixa o projeto, descompacta e abre no Positron. Pode escolher salvar na Área
de Trabalho quando ele perguntar.

**Pelo navegador.** Na página do repositório, clique no botão verde **Code →
Download ZIP** e descompacte a pasta.

---

## Como abrir e rodar (3 passos)

### 1. Abra o projeto no Positron

Descompacte a pasta e, no Positron, use **File → Open Folder** e escolha a pasta
`projeto-chikungunya`. Ou clique duas vezes no arquivo
`projeto-chikungunya.Rproj`. Abrir a pasta certa é o que faz os caminhos
funcionarem sozinhos.

### 2. Prepare os pacotes (uma vez)

No **Console** do Positron (o painel onde o R responde), rode:

```r
source("bootstrap.R")
```

Ele instala ou restaura os pacotes que o projeto usa. Na primeira vez pode levar
alguns minutos. É normal.

### 2.5. Prepare os mapas (uma vez, com internet)

Os dois mapas do Brasil usam os contornos oficiais do IBGE, baixados pelo pacote
`geobr`. Para o projeto abrir depois sem depender de download, baixe os contornos
uma vez, no **Console**:

```r
source(here::here("recursos", "preparar_mapas.R"))
```

Ele salva as malhas em `recursos/geo_uf.rds` e `recursos/geo_municipios.rds`. Feito
isso, os mapas do `R/03_descricao.R` e do relatório abrem offline.

### 3. Gere o relatório

Abra o arquivo `relatorio/relatorio-chikungunya.qmd` e clique em **Render**, no
topo do editor. O Positron gera o relatório em HTML e abre ao lado. Para gerar
também em Word ou PDF, use o menu ao lado do botão Render (o PDF exige o LaTeX,
que é opcional).

Pronto. Se o relatório apareceu, está tudo funcionando.

---

## O que tem dentro

```
projeto-chikungunya/
  projeto-chikungunya.Rproj   abre o projeto no Positron
  bootstrap.R                 instala/restaura os pacotes (rode uma vez)
  README.md                   este arquivo
  dados/
    chikungunya_2023_2025.csv o dado do curso (amostra real do SINAN)
  R/
    00_preparar_dados.R       como o dado foi montado (referencia)
    01_fundacao.R             a fundacao: projeto, here, renv
    02_importar_limpar.R      importar e limpar o dado
    03_descricao.R            descricao por pessoa, tempo e lugar
    04_modelo_serie.R         um modelo simples e a serie no tempo
    05_relatorio.R            juntar tudo e gerar o relatorio
  relatorio/
    relatorio-chikungunya.qmd o documento que gera HTML, Word e PDF
  recursos/
    epic95_paleta.R           as cores do curso para os graficos
    preparar_mapas.R          baixa os contornos do Brasil (rode uma vez)
    populacao_municipios_2022.csv  populacao por municipio (IBGE, Censo 2022)
  ia/
    GEMINI.md                 a memoria do projeto para o assistente de IA
    PROMPTS.md                exemplos de pedidos usados em cada etapa
  docs/
    passo-a-passo.md          o que cada etapa faz, explicado
```

## A ordem para entender o projeto

Se quiser seguir a lógica de construção, leia e rode, nesta ordem, os scripts da
pasta `R/`: `01_fundacao.R`, `02_importar_limpar.R`, `03_descricao.R`,
`04_modelo_serie.R` e `05_relatorio.R`. Cada um é muito comentado e explica o
que faz. O `docs/passo-a-passo.md` conta a história do fluxo inteiro.

## O assistente de IA no projeto

O arquivo `ia/GEMINI.md` é a memória que o agente lê ao abrir o projeto: quem
você é, os pacotes preferidos e a regra de segurança. O `ia/PROMPTS.md` traz
exemplos de pedidos em português que você pode usar em cada etapa. A regra vale
sempre: leia o que a IA propõe, entenda e valide antes de aceitar. Nunca envie
dado identificado de paciente ao assistente.

## O dado

`dados/chikungunya_2023_2025.csv` é uma amostra dos casos de febre de chikungunya
notificados no SINAN (arboviroses), de 2023 a 2025, do Portal de Dados Abertos do
SUS. É uma amostra leve, para o projeto rodar rápido em qualquer máquina. O
`R/00_preparar_dados.R` mostra como ela foi montada a partir do dado bruto.

## Licença e fonte

O código deste projeto está sob a licença MIT (ver o arquivo `LICENSE`). O dado é
uma amostra agregada e desidentificada, derivada do Portal de Dados Abertos do SUS
(OpenDataSUS), sistema SINAN, agravo chikungunya, 2023 a 2025. Ao reusar, cite a
fonte do dado e o curso.
