# Paleta EPIC95 para gráficos em R
# Curso de Epidemiologia Computacional (MedTrop 2026)
# Uso: source(here::here("recursos", "epic95_paleta.R"))

# Cores oficiais EPIC95
epic95_cores <- c(
  primaria  = "#4f8aac",
  secundaria = "#03658c",
  destaque  = "#02735e",
  neutra    = "#ffde59"
)

# Paleta estendida para variaveis categoricas com mais niveis
epic95_estendida <- c(
  "#4f8aac", "#03658c", "#02735e", "#ffde59",
  "#7ba8c0", "#3581a8", "#048972", "#ffe887"
)

# Escalas prontas para ggplot2
scale_color_epic95 <- function(...) {
  ggplot2::scale_color_manual(values = unname(epic95_estendida), ...)
}

scale_fill_epic95 <- function(...) {
  ggplot2::scale_fill_manual(values = unname(epic95_estendida), ...)
}

# Tema limpo para os graficos do curso
tema_epic95 <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", color = "#03658c"),
      plot.subtitle = ggplot2::element_text(color = "#5a6b64"),
      axis.title    = ggplot2::element_text(color = "#03658c"),
      legend.position = "bottom"
    )
}
