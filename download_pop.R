library(tidycensus)
library(tigris)
library(sf)
options(tigris_use_cache=T)

blockpop = get_decennial(
    geography = "block",
    variables = "H1_001N", # total housing units are not affected by differential privacy
    state="NC",
    county=c("Orange", "Durham", "Wake", "Chatham", "Alamance", "Johnston", "Franklin", "Granville"),
    geometry=TRUE,
    output="wide"
)

blockpop = blockpop |>
    st_transform(32119)

blockpop |>
    write_sf(file.path(Sys.getenv("DATA_PATH"), "data", "hu.gpkg"))
