options(java.parameters="-Xmx4G")
library(r5r)
library(sf)
library(tidyverse)
DATA_PATH = Sys.getenv("DATA_PATH")

variant = "scenario"

# todo gotta figure out how to control linking distance here...
r5 = setup_r5(file.path(DATA_PATH, "networks", variant), verbose=T, overwrite=T)

blocks = read_sf(file.path(DATA_PATH, "data", "population.gpkg"))
jobs = read_csv(file.path(DATA_PATH, "data", "nc_wac_S000_JT00_2022.csv.gz"), col_types=cols(w_geocode=col_character()))

blocks = blocks |>
    # TODO these are same vintage right?
    left_join(jobs, by=c("GEOID"="w_geocode")) |>
    mutate(C000=replace_na(C000, 0)) |>
    rename(id="GEOID")

points = st_centroid(blocks) |> st_transform(4326)

acc = accessibility(
    r5,
    points,
    points,
    opportunities_colnames = "C000",
    mode = "TRANSIT",
    time_window=120L,
    cutoffs=c(60),
    departure_datetime=as.POSIXct("2025-07-17 07:00:00"),
    progress=T
)

blocks = blocks |>
    left_join(acc, by="id")

write_sf(blocks, file.path(DATA_PATH, "data", glue::glue("accessibility_{variant}.gpkg")))
