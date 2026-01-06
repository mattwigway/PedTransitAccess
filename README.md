# Pedestrian transit access

This repository contains code that supports the paper "Expanding Transit Access Through Street Network Investments"

Notably:

- `stop_isochrones.qmd` creates Figure 1
- `network_figure.qmd` creates Figure 2
- `identify_links.qmd` identifies and scores the links
- `access.qmd` computes access using `r5r` and creates the remaining figures
- `src/` contains Julia code that supports `identify_links.qmd`

Setup:

- Copy `.Renviron.template` to `.Renviron`, and update the path to the data (all data is referenced in the paper, and filenames are in the various scripts, or contact author for exact data used)
- Add a Mapbox key to `.Renviron`
- Install dependencies for R using `renv` and for Julia using the Julia package manager