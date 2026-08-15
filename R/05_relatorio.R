# =============================================================================
# 05_relatorio.R
# Curso de Epidemiologia Computacional com R, Positron e IA . MedTrop 2026
#
# O QUE ESTE SCRIPT FAZ
# Fecha o projeto. Os scripts 01 a 04 prepararam o dado, descreveram e modelaram.
# O produto final, porem, nao e um script: e um RELATORIO reprodutivel, escrito
# em Quarto, que mistura texto e codigo no mesmo arquivo e sai em HTML, Word ou
# PDF. Este script apenas explica onde esse relatorio mora e mostra como pedir ao
# R que o renderize. Ele nao produz analise nova.
#
# O relatorio final e: relatorio/relatorio-chikungunya.qmd
# =============================================================================


# ---- 1. Pacotes -------------------------------------------------------------
library(here)     # caminhos que nao quebram
library(quarto)   # a ponte do R para o Quarto (a funcao quarto_render)

# Se o pacote quarto nao estiver instalado, rode uma vez no Console:
#   install.packages("quarto")
# E confirme que o programa Quarto existe na maquina (o Positron ja vem com ele):
#   quarto::quarto_version()


# ---- 2. Onde esta o relatorio -----------------------------------------------
# O .qmd e o coracao do curso. Ele repete, num documento so, o fluxo dos scripts
# 01 a 04, na estrutura de um artigo: Introducao, Metodos, Resultados, Discussao.
# Cada bloco de codigo (chunk) roda na hora da renderizacao e injeta a tabela ou
# a figura no lugar certo. Voce edita o texto entre os chunks; o codigo cuida dos
# numeros. E o mesmo padrao que voce viu nos modulos do curso.
relatorio <- here("relatorio", "relatorio-chikungunya.qmd")

file.exists(relatorio)   # deve devolver TRUE: confirma que o arquivo esta la


# ---- 3. Como renderizar (o comando principal) -------------------------------
# quarto_render() pega o .qmd, roda todo o codigo de dentro e gera o documento
# final. O formato de saida sai do cabecalho YAML do proprio .qmd; o argumento
# output_format escolhe qual gerar quando o YAML oferece mais de um.
#
# ATENCAO: as chamadas abaixo estao dentro de if (FALSE) DE PROPOSITO, para nao
# renderizar sozinho quando voce der "Source" neste script (renderizar leva tempo
# e abre o documento). Para rodar de verdade, troque FALSE por TRUE, ou copie a
# linha que voce quer para o Console e tecle Enter.

if (FALSE) {

  # HTML: o formato mais rapido e o primeiro a testar. Bom para revisar em tela.
  quarto::quarto_render(relatorio, output_format = "html")

  # Word (.docx): quando o destino e um documento editavel, para colegas que
  # trabalham no Word. A formatacao das tabelas sai pronta.
  quarto::quarto_render(relatorio, output_format = "docx")

  # PDF: para imprimir ou anexar. O PDF exige um motor de LaTeX instalado. A
  # forma mais simples de resolver isso, uma vez na vida da maquina, e:
  #   quarto::quarto_install_tinytex()   # instala um LaTeX leve (o TinyTeX)
  # Depois disso, o PDF renderiza:
  quarto::quarto_render(relatorio, output_format = "pdf")

}


# ---- 4. Pelo Terminal, se preferir ------------------------------------------
# Voce nao precisa do R para renderizar: o Quarto tambem roda direto no Terminal
# do Positron (aquele painel que fala com o sistema, nao com o R). Os comandos,
# rodados na raiz do projeto, sao:
#
#   quarto render relatorio/relatorio-chikungunya.qmd --to html
#   quarto render relatorio/relatorio-chikungunya.qmd --to docx
#   quarto render relatorio/relatorio-chikungunya.qmd --to pdf
#
# O botao "Render" no topo do editor do Positron faz o mesmo, com um clique,
# quando o .qmd esta aberto.


# ---- 5. O ciclo de reproducao completo --------------------------------------
# Para alguem reproduzir este projeto do zero, na ordem:
#   1. Abrir a pasta do projeto no Positron (nao um arquivo solto). O here()
#      passa a apontar para a raiz sozinho.
#   2. renv::restore()  . reinstala as versoes exatas dos pacotes (renv.lock).
#   3. Rodar os scripts na ordem: 01 -> 02 -> 03 -> 04 (o 02 salva a base limpa
#      que o 03 e o 04 reaproveitam).
#   4. Renderizar o relatorio (passo 3 deste script).
#
# O microdado identificado nao e versionado (ver .gitignore). O dado deste curso
# ja e agregado e seguro. Fonte: SINAN arboviroses (febre de chikungunya),
# Portal de Dados Abertos do SUS.

# Dica de IA: peca ao Gemini CLI para escrever a secao de Metodos ou um paragrafo
# de Resultados do relatorio, a partir do que os scripts fazem. Confira que todo
# numero citado existe num objeto do projeto; a IA nao inventa numero nem
# citacao. Veja ia/PROMPTS.md (Etapa 5).
