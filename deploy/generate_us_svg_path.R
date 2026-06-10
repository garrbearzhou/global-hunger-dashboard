#!/usr/bin/env Rscript

if (!requireNamespace("maps", quietly = TRUE)) {
  install.packages("maps", repos = "https://cloud.r-project.org")
}

# Single national outline (lower 48); excludes Alaska/Hawaii insets.
usa <- maps::map("usa", plot = FALSE, fill = TRUE, resolution = 0)

x <- usa$x
y <- usa$y
rng_x <- range(x, na.rm = TRUE)
rng_y <- range(y, na.rm = TRUE)

map_x <- function(v) 48 + (v - rng_x[1]) / diff(rng_x) * (544)
map_y <- function(v) 372 - (v - rng_y[1]) / diff(rng_y) * (324)

polygons <- list()
i <- 1L
n <- length(x)

while (i <= n) {
  if (is.na(x[i])) {
    i <- i + 1L
    next
  }
  j <- i
  xs <- c()
  ys <- c()
  while (j <= n && !is.na(x[j])) {
    xs <- c(xs, x[j])
    ys <- c(ys, y[j])
    j <- j + 1L
  }
  polygons[[length(polygons) + 1L]] <- list(x = xs, y = ys)
  i <- j + 1L
}

# Keep only the mainland polygon (largest bounding-box area).
areas <- vapply(polygons, function(p) {
  diff(range(p$x)) * diff(range(p$y))
}, numeric(1))
main <- polygons[[which.max(areas)]]
xs <- main$x
ys <- main$y
step <- max(1L, floor(length(xs) / 120L))
k <- seq(1L, length(xs), by = step)
coords <- paste(
  sprintf("%.1f,%.1f", map_x(xs[k]), map_y(ys[k])),
  collapse = " L "
)
path_d <- paste0("M ", coords, " Z")
out <- file.path("www", "scenario_country_landscape.svg")

svg <- paste0(
  "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 640 420\" role=\"img\" aria-label=\"Scenario country map\">\n",
  "  <defs>\n",
  "    <linearGradient id=\"sc-ocean-deep\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"100%\">\n",
  "      <stop offset=\"0%\" stop-color=\"#0c4a6e\"/>\n",
  "      <stop offset=\"50%\" stop-color=\"#0369a1\"/>\n",
  "      <stop offset=\"100%\" stop-color=\"#075985\"/>\n",
  "    </linearGradient>\n",
  "  </defs>\n",
  "  <rect width=\"640\" height=\"420\" fill=\"url(#sc-ocean-deep)\"/>\n",
  "  <path class=\"scenario-country-shape\" fill=\"__FILL__\" stroke=\"#1c1917\" stroke-width=\"2\" stroke-linejoin=\"round\" d=\"",
  path_d,
  "\"/>\n",
  "</svg>\n"
)

writeLines(svg, out, useBytes = TRUE)
message("Wrote ", out, " (", nchar(path_d), " path chars)")
