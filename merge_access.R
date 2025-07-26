library(sf)
library(tidyverse)
DATA_PATH = Sys.getenv("DATA_PATH")

base = read_sf(file.path(DATA_PATH, "data", "accessibility_baseline.gpkg"))
scenario = read_sf(file.path(DATA_PATH, "data", "accessibility_scenario.gpkg"))

base |>
    st_drop_geometry() |>
    select(id, accessibility_baseline=accessibility) |>
    left_join(scenario, by="id") |>
    rename(accessibility_scenario="accessibility") |>
    mutate(
        accessibility_diff=accessibility_scenario - accessibility_baseline,
        accessibility_diff_pct=accessibility_diff / accessibility_baseline * 100
    ) |>
    write_sf(file.path(DATA_PATH, "data", "accessibility_combined.gpkg"))

