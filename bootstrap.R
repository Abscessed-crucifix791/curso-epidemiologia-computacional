# =============================================================================
# bootstrap.R
# Prepara os pacotes do projeto. Rode UMA VEZ, no Console do Positron:
#   source("bootstrap.R")
#
# O que ele faz:
#   - Se existir um renv.lock (ambiente travado), restaura as versoes exatas.
#   - Se nao existir, instala os pacotes essenciais do curso.
# Nos dois casos, no fim voce tem tudo pronto para abrir o relatorio e renderizar.
# =============================================================================

# Pacotes que o projeto usa.
essenciais <- c(
  "here",       # caminhos que nao quebram
  "readr",      # ler o CSV
  "dplyr", "tidyr", "stringr", "lubridate", "forcats", "janitor",  # limpeza
  "ggplot2",    # graficos
  "gt", "gtsummary", "flextable",  # tabelas
  "sf", "geobr",  # mapas do Brasil (contornos oficiais do IBGE)
  "quarto"      # renderizar o relatorio
)

message("Preparando o ambiente do projeto de chikungunya...")

if (file.exists("renv.lock")) {
  # Ambiente travado: restaura as versoes exatas registradas no renv.lock.
  message("Encontrei o renv.lock. Restaurando as versoes exatas dos pacotes.")
  if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
  renv::restore(prompt = FALSE)
} else {
  # Sem lock: instala o que faltar dos essenciais.
  message("Sem renv.lock. Instalando os pacotes essenciais do curso.")
  faltando <- essenciais[!essenciais %in% rownames(installed.packages())]
  if (length(faltando) > 0) {
    install.packages(faltando)
  } else {
    message("Todos os pacotes essenciais ja estao instalados.")
  }
}

# ---- Pacotes dos mapas (sf e geobr) -----------------------------------------
# Estes dois entraram depois do renv.lock original, entao o restore acima pode
# nao traze-los. Garantimos aqui: se faltarem, instala. Depois de instalar pela
# primeira vez, rode renv::snapshot() UMA VEZ para grava-los no renv.lock.
mapas <- c("sf", "geobr")
faltam_mapas <- mapas[!mapas %in% rownames(installed.packages())]
if (length(faltam_mapas) > 0) {
  message("Instalando os pacotes dos mapas: ", paste(faltam_mapas, collapse = ", "))
  install.packages(faltam_mapas)
  message("Feito. Rode renv::snapshot() para travar sf e geobr no renv.lock.")
} else {
  message("Pacotes dos mapas (sf, geobr) ja instalados.")
}

message("\nPronto. Proximos passos:")
message("  1) Rode uma vez  source(here::here('recursos', 'preparar_mapas.R'))  para baixar os contornos do Brasil.")
message("  2) Abra 'relatorio/relatorio-chikungunya.qmd' e clique em Render.")
