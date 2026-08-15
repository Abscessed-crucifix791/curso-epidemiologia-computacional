# O passo a passo do projeto

Este documento conta a história do projeto, etapa por etapa. Ele amarra o que
cada script faz ao raciocínio epidemiológico por trás. Leia junto com os arquivos
da pasta `R/`.

O dado é sempre o mesmo: a febre de chikungunya notificada no SINAN (arboviroses),
de 2023 a 2025. Uma arbovirose transmitida pelo *Aedes aegypti*, de notificação
compulsória no Brasil.

---

## Etapa 1: a fundação (`R/01_fundacao.R`)

Antes de qualquer análise, montamos um projeto que roda de novo, na sua máquina e
na de qualquer colega, e dá o mesmo resultado. Duas peças garantem isso. O `here`
resolve os caminhos a partir da raiz do projeto, então o código não depende de
onde a pasta está. O `renv` guarda a versão exata de cada pacote, para o resultado
não mudar quando um pacote for atualizado.

**Por que isso é epidemiologia.** Uma análise que não se reproduz não se audita.
Se alguém questionar um número do boletim, você precisa poder rodar de novo e
mostrar de onde ele veio. Reprodutibilidade não é capricho de programador, é a
base de uma análise defensável.

## Etapa 2: importar e limpar (`R/02_importar_limpar.R`)

Carregamos o dado e o preparamos. Aqui entram os sistemas de informação em saúde.
O SINAN é o Sistema de Informação de Agravos de Notificação: ele registra os casos
que os serviços de saúde notificam. Todo caso de chikungunya que chega a uma
unidade e é notificado vira um registro, e é esse fluxo de notificação que enche a
base.

O dado do SUS raramente chega pronto. O código do município vem com seis dígitos
onde o IBGE usa sete. As datas chegam em formatos que precisam ser padronizados. E
há o campo "Ignorado", que não é um valor de verdade, é ausência de informação.

**Por que isso é epidemiologia.** Cada tratamento aqui é uma decisão sobre a
qualidade do dado. O "Ignorado" mal tratado infla ou esvazia um indicador. A
subnotificação, casos que existem mas não chegam ao sistema, faz o número ser um
piso, não o total. Entender o que o dado esconde é parte da análise, não um
detalhe técnico. Todo indicador que a gente calcular carrega essas ressalvas.

## Etapa 3: descrição, por pessoa, tempo e lugar (`R/03_descricao.R`)

Com o dado limpo, descrevemos. A epidemiologia descritiva tem um arcabouço de mais
de um século: pessoa, tempo e lugar. Quem adoece (idade, sexo), quando os casos
acontecem (a curva no tempo) e onde se concentram (a região). A Tabela 1 responde
à pessoa, a série mensal ao tempo, o mapa de calor e as barras por região ao
lugar.

**Por que isso é epidemiologia.** A descrição é o primeiro produto da vigilância e
o mais lido. Antes de qualquer modelo, ela já responde muita coisa: a chikungunya
está pegando mais homens ou mulheres? Que faixa etária? Em que meses? Onde? E cada
indicador que reportamos vem com a fonte, a definição e o período, para outra
pessoa poder conferir.

## Etapa 4: modelo e série (`R/04_modelo_serie.R`)

Damos dois passos além da descrição, ambos enxutos. Primeiro, um modelo de Poisson
para comparar a taxa de incidência entre regiões, com a população como *offset*: a
saída é a razão de taxas, quanto a taxa de uma região difere da referência. Sempre
lida junto do intervalo de confiança. Segundo, a série mensal, separada em
tendência e sazonalidade, para reconhecer o padrão e o que foge dele.

**Por que isso é epidemiologia.** A razão de taxas é uma das medidas mais usadas
na vigilância, e o intervalo diz se a diferença é consistente ou pode ser acaso. A
série ensina a separar o esperado do incomum: um pico no verão pode ser só
sazonalidade; um pico fora de época merece investigação. E a cauda de 2025 aparece
mais baixa não porque a doença caiu, mas porque o dado ainda está chegando, o
atraso de notificação. Confundir os dois geraria um alarme falso, ou o contrário.

## Etapa 5: o relatório (`R/05_relatorio.R` e `relatorio/relatorio-chikungunya.qmd`)

Juntamos tudo num relatório reprodutível, na estrutura de um artigo: introdução,
métodos, resultados e discussão. O mesmo arquivo `.qmd` gera HTML, Word e PDF. A IA
ajuda a redigir Métodos e Resultados a partir dos objetos já calculados, e você
verifica cada número antes de aceitar.

**Por que isso é epidemiologia.** O relatório é onde a análise vira comunicação e
decisão. Nos Resultados, você reporta; na Discussão, interpreta e declara os
limites (subnotificação, atraso, o que o modelo simples não captura). Um bom
relatório é honesto sobre o que o dado permite e o que não permite afirmar.

---

> Em resumo: fundação reprodutível, dado tratado com consciência da sua qualidade,
> descrição por pessoa, tempo e lugar, um passo de modelo e de série, e um
> relatório que comunica com honestidade. É o fluxo inteiro da epidemiologia
> computacional, num projeto que você leva pronto e aprende a refazer.
