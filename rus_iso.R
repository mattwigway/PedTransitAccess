options(java.parameters="-Xmx4G")
options(r5r.r5jar="../r5/build/libs/r5-v7.4-rc.4-4-gc5e8479.dirty-all.jar")
library(r5r)
library(sf)
library(tidyverse)
library(jsonlite)
DATA_PATH = Sys.getenv("DATA_PATH")

variant = "all"

# create config file to control linking distance

write_json(list(stopLinkRadiusMeters=unbox(20)), file.path(DATA_PATH, "networks", variant, "config.json"))
r5 = build_network(file.path(DATA_PATH, "networks", variant), verbose=T)#, overwrite=T)

points = tribble(
    ~loc, ~lat, ~lon,
    "RUS BUS", 35.7778375738474, -78.64661349567801
) |>
    mutate(id=1:n()) |>
    st_as_sf(coords=c("lon", "lat"), crs=4326)

# 41 seconds
system.time({iso = isochrone(r5, r5, points, mode="transit", cutoffs=c(45), departure_datetime=as.POSIXct("2025-07-17 07:00:00"))})
write_sf(iso, "iso_release.gpkg")

iso = isochrone(r5, r5, points, mode="transit", cutoffs=c(45), zoom=11,
    departure_datetime=as.POSIXct("2025-07-17 07:00:00"))
write_sf(iso, "iso_dev_z11.gpkg")

# First run: 6.3s
# Subsequent run: 0.3s
system.time({iso = isochrone(r5, r5, points, mode="transit", cutoffs=c(45), zoom=10,
    departure_datetime=as.POSIXct("2025-07-17 07:00:00"))})
write_sf(iso, "iso_dev_z10.gpkg")

iso = isochrone(r5, r5, points, mode="transit", cutoffs=c(45), zoom=9,
    departure_datetime=as.POSIXct("2025-07-17 07:00:00"))
write_sf(iso, "iso_dev_z9.gpkg")

# and make the transit isochrone for someone living in the apt at the end of the link
apt = tribble(
    ~id, ~lat, ~lon,
    "apt", 35.850682612449454, -78.69217349571225
)

write_sf(st_as_sf(apt, coords=c("lon", "lat"), crs=4326), file.path(DATA_PATH, "data", "origin.gpkg"))

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
