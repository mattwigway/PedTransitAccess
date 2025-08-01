library(sf)
library(tidyverse)
library(ggunc)
DATA_PATH = Sys.getenv("DATA_PATH")

base = read_sf(file.path(DATA_PATH, "data", "accessibility_baseline.gpkg"))
scenario = read_sf(file.path(DATA_PATH, "data", "accessibility_scenario.gpkg"))
rus = read_sf(file.path(DATA_PATH, "data", "accessibility_rus.gpkg"))

combined = base |>
    st_drop_geometry() |>
    select(id, accessibility_baseline=accessibility) |>
    left_join(scenario, by="id") |>
    rename(accessibility_scenario="accessibility") |>
    left_join(rus, by="id")

combined |>
    write_sf(file.path(DATA_PATH, "data", "accessibility_combined.gpkg"))

combined |>
    filter(accessibility_baseline != 0) |>
    ggplot(aes(x=pmin(accessibility_diff_pct, 200))) +
    geom_histogram() +
    ylim(0, 100)

