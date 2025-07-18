library(tidycensus)
library(tigris)
library(sf)
options(tigris_use_cache=T)

blockpop = get_decennial(
    geography = "block",
    variables = "P1_001N",
    state="NC",
    county=c("Orange", "Durham", "Wake"),
    geometry=TRUE,
    output="wide"
)

blockpop = blockpop |>
    st_transform(32119)

blockpop |>
    write_sf(file.path(Sys.getenv("DATA_PATH"), "data", "population.gpkg"))
