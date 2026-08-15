# =============================================================================
# 01_fundacao.R
# Curso de Epidemiologia Computacional com R, Positron e IA . MedTrop 2026
#
# O QUE ESTE SCRIPT FAZ
# E o primeiro passo do projeto. Ele nao analisa nada ainda. A missao aqui e
# simples e importante: deixar o ambiente pronto e provar que o dado abre. Voce
# vai (1) carregar os pacotes basicos, (2) entender o papel do here e do renv,
# (3) ler o CSV de chikungunya com o readr e (4) espiar o dado com um glimpse.
# No fim, tambem carregamos a paleta de cores do curso.
#
# Rode este script de cima para baixo (no Positron, tecle Ctrl+Enter linha a
# linha, ou clique em "Source"). Se ele terminar sem erro, a fundacao esta de pe.
#
# Fonte do dado: SINAN arboviroses (febre de chikungunya), 2023 a 2025,
# Portal de Dados Abertos do SUS.
# =============================================================================


# ---- 1. Os pacotes -----------------------------------------------------------
# Um pacote e uma caixa de ferramentas que alguem ja escreveu para voce. Em vez
# de reinventar como ler um CSV, voce usa o pacote que ja sabe fazer isso.
#
# library() liga o pacote na sessao atual. Se der erro dizendo que o pacote nao
# esta instalado, rode uma vez (no Console):
#   install.packages(c("here", "readr", "dplyr"))
library(here)    # descobre a raiz do projeto e monta caminhos que nao quebram
library(readr)   # le e escreve arquivos de texto (CSV) com rapidez e cuidado
library(dplyr)   # o canivete suico para manipular tabelas (usaremos o glimpse)


# ---- 2. O papel do here: caminhos que nao quebram ---------------------------
# Nunca escreva o caminho da sua maquina dentro do codigo. Uma linha como
# setwd("C:/Users/voce/Documents/projeto") nao existe na maquina de outra pessoa,
# e quebra na hora. O pacote here resolve isso.
#
# Na raiz deste projeto existe um arquivo vazio chamado ".here". Ele funciona
# como uma bandeira fincada no chao: o here() olha para essa bandeira e sempre
# aponta para a raiz, nao importa de que subpasta voce chame a funcao.
here()                                     # mostra onde o projeto pensa que e a raiz
here("dados", "chikungunya_2023_2025.csv") # monta o caminho ate o dado, sem "\" na mao


# ---- 3. O papel do renv: a caixa lacrada do projeto -------------------------
# O renv guarda a versao exata de cada pacote que o projeto usa, num arquivo
# chamado renv.lock. Pense numa caixa lacrada: quando um colega (ou voce, no ano
# que vem) abrir o projeto, o comando renv::restore() reinstala as MESMAS versoes.
# Assim o resultado nao muda so porque um pacote foi atualizado por fora.
#
# Voce nao roda nada de renv agora. Fica so o registro de que ele existe e para
# que serve. Duas linhas resumem o ciclo, uma vez na vida do projeto:
#   renv::init()      # inicia o controle de pacotes (roda uma vez, ao criar)
#   renv::snapshot()  # registra o estado atual dos pacotes no renv.lock
#
# Dica de IA: peca ao Gemini CLI para explicar here e renv em uma frase cada,
# como se voce nunca tivesse programado. Veja o pedido pronto em ia/PROMPTS.md
# (Etapa 1).


# ---- 4. Ler o dado de chikungunya -------------------------------------------
# read_csv() (do readr) le o arquivo e devolve uma tabela (um data frame). Repare
# no caminho montado com here(): ele funciona em qualquer maquina que abra este
# projeto. Preferimos read_csv() ao read.csv() do R base porque ele e mais rapido,
# nao transforma texto em fator sem avisar e mostra os tipos de cada coluna.
chik <- read_csv(
  here("dados", "chikungunya_2023_2025.csv"),
  show_col_types = FALSE   # nao imprime o resumo dos tipos (deixa a saida limpa)
)


# ---- 5. Espiar o dado com glimpse -------------------------------------------
# Antes de mexer, olhe. glimpse() (do dplyr) vira a tabela de lado e mostra, uma
# coluna por linha, o nome, o tipo e as primeiras entradas. E o primeiro reflexo
# de quem trabalha com dado: ver o que esta na mao antes de qualquer analise.
glimpse(chik)

# O que voce deve enxergar aqui: 12 colunas. dt_notificacao como data (<date>),
# ano e idade como numero, e as categoricas (uf, regiao, sexo, classificacao,
# criterio, evolucao, faixa_etaria) como texto (<chr>). Guarde tres detalhes que
# voltam no proximo script:
#   . municipio_ibge e o codigo IBGE de 6 digitos (sem o nome do municipio);
#   . sexo e evolucao trazem a categoria "Ignorado", que e ausencia, nao dado;
#   . faixa_etaria chegou como texto, e vai precisar virar fator com ordem certa.

# Dica de IA: peca ao agente para ler o CSV e listar as colunas e as primeiras
# linhas. Confira se ele usou o caminho certo e read_csv (nao read.csv). O pedido
# esta em ia/PROMPTS.md (Etapa 1).


# ---- 6. Carregar a identidade visual do curso -------------------------------
# A paleta EPIC95 mora num script separado, em recursos/. source() executa esse
# arquivo e traz para a sua sessao os objetos que ele define: as cores
# (epic95_cores), a paleta estendida, as escalas para ggplot e o tema_epic95().
# A partir daqui, todo grafico do projeto sai na mesma identidade visual.
source(here("recursos", "epic95_paleta.R"))

# Confirma que a paleta entrou: deve aparecer o vetor de cores nomeadas.
epic95_cores

# Fundacao pronta. O dado abriu, a paleta carregou. No 02_importar_limpar.R a
# gente trata as armadilhas classicas do dado do SUS e tira o primeiro indicador.
