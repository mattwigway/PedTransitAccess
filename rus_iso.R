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

points = tribble(
    ~loc, ~lat, ~lon,
    "RUS BUS", 35.84929, -78.692986,
) |>
    mutate(id=1:n()) |>
    st_as_sf(coords=c("lon", "lat"), crs=4326)

iso = isochrone(r5, r5, points, mode="walk", cutoffs=c(20), zoom=11)

write_sf(iso, file.path(DATA_PATH, "data", glue::glue("iso_{variant}.gpkg")))

# and make the transit isochrone for someone living in the apt at the end of the link
apt = tribble(
    ~id, ~lat, ~lon,
    "apt", 35.84951750734412, -78.69066513451033
)

tr_iso = isochrone(
    r5,
    r5,
    apt,
    mode = "TRANSIT",
    time_window=120L,
    cutoffs=c(60),
    departure_datetime=as.POSIXct("2025-07-17 07:00:00"),
    zoom=11)

write_sf(tr_iso, file.path(DATA_PATH, "data", glue::glue("iso_{variant}_transit.gpkg")))
