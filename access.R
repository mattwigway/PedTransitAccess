options(java.parameters="-Xmx4G")
options(r5r.r5jar="../r5/build/libs/r5-v7.4.dirty-all.jar")
devtools::load_all("../r5r/r-package")
library(sf)
library(tidyverse)
library(jsonlite)
DATA_PATH = Sys.getenv("DATA_PATH")

variant = "rus"

# create config file to control linking distance

write_json(list(stopLinkRadiusMeters=unbox(20)), file.path(DATA_PATH, "networks", variant, "config.json"))
r5 = build_network(file.path(DATA_PATH, "networks", variant), verbose=T, overwrite=T)

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
