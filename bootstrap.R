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

message("\nPronto. Agora abra 'relatorio/relatorio-chikungunya.qmd' e clique em Render.")
