# =============================================================================
# preparar_mapas.R
# Curso de Epidemiologia Computacional com R, Positron e IA . MedTrop 2026
#
# RODE UMA VEZ, no Console do Positron:
#   source(here::here("recursos", "preparar_mapas.R"))
#
# POR QUE ESTE SCRIPT EXISTE
# O pacote geobr baixa os contornos do Brasil (IBGE) na primeira vez que voce
# pede um mapa. No dia do curso, com o wifi da sala disputado por 40 pessoas,
# esse download vira um risco. Este script baixa os contornos UMA VEZ, ja
# simplificados (mais leves), e salva em recursos/ como .rds. Depois disso os
# mapas do 03_descricao.R e do relatorio abrem offline, direto do arquivo.
#
# Passo a passo:
#   1) Rode este script uma vez, com internet.
#   2) Confira que apareceram recursos/geo_uf.rds e recursos/geo_municipios.rds.
#   3) Commite os dois .rds. Assim quem baixar o projeto ja tem os mapas prontos.
#
# So precisa rodar de novo se quiser atualizar o ano de referencia das malhas.
# =============================================================================

library(here)

# Os mapas usam geobr (malhas do IBGE) e sf (dados espaciais). Se faltarem,
# instale antes: install.packages(c("geobr", "sf")).
if (!requireNamespace("geobr", quietly = TRUE) ||
    !requireNamespace("sf", quietly = TRUE)) {
  stop("Faltam pacotes. Rode: install.packages(c(\"geobr\", \"sf\"))")
}

ano_malha <- 2020   # ano da malha territorial do IBGE que o geobr entrega

# Afina a malha para o mapa nacional ficar leve, sem perda visivel na escala do
# Brasil. Se o rmapshaper estiver instalado, usamos ms_simplify (preserva a
# topologia, nao abre buracos entre municipios); senao, seguimos com a malha do
# geobr como veio. E salvamos com compressao xz, bem menor que o padrao.
afinar <- function(x, keep) {
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    rmapshaper::ms_simplify(x, keep = keep, keep_shapes = TRUE)
  } else {
    message("  (rmapshaper ausente; salvando a malha sem afinar. Para reduzir mais: install.packages(\"rmapshaper\"))")
    x
  }
}

message("Baixando o contorno das Unidades da Federacao (27 poligonos)...")
geo_uf <- geobr::read_state(year = ano_malha, simplified = TRUE, showProgress = FALSE)
saveRDS(geo_uf, here("recursos", "geo_uf.rds"), compress = "xz")

message("Baixando o contorno dos municipios (5.570 poligonos). Pode demorar...")
geo_municipios <- geobr::read_municipality(year = ano_malha, simplified = TRUE, showProgress = FALSE)
geo_municipios <- afinar(geo_municipios, keep = 0.10)   # mantem ~10% dos vertices
saveRDS(geo_municipios, here("recursos", "geo_municipios.rds"), compress = "xz")

tam_uf  <- round(file.size(here("recursos", "geo_uf.rds")) / 1024)
tam_mun <- round(file.size(here("recursos", "geo_municipios.rds")) / 1024^2, 1)
message("\nPronto.")
message("  recursos/geo_uf.rds .......... ", tam_uf, " KB")
message("  recursos/geo_municipios.rds .. ", tam_mun, " MB")
message("Commite os dois arquivos para que os mapas abram offline no curso.")
