


# Set up ----

# install.packages(c("foreign", "rlandfire", "sf", "terra", "tidyverse"))
# 
# library(foreign)
# library(rlandfire)
# library(sf)
# library(terra)
# library(tidyverse)

dir.create("inputs", showWarnings = FALSE)

# rlandfire uses utils::download.file(); long timeout + libcurl help on Linux / partial curl issues
op <- options(
  timeout = 7200,
  download.file.method = "libcurl"
)
on.exit(options(op), add = FALSE)

# Area of interest ----

shp <- st_read("inputs/up_cntys.gpkg", quiet = TRUE) %>%
  st_transform(crs = 5070) %>%
  st_union() %>%
  st_sf()

plot(shp)

aoi <- getAOI(shp)


# LANDFIRE order & download ----

products <- c(
  "LF2020_BPS",
  "LF2024_SClass",
  "LF2024_EVC",
  "LF2024_EVH",
  "LF2024_EVT"
)
projection <- 5070
resolution <- 30
email <- "rswaty@tnc.org" # REPLACE WITH YOUR E-MAIL

dest_file <- file.path("inputs", "landfire_data.zip")
ncal <- NULL

if (!file.exists(dest_file)) {
  save_file <- tempfile(fileext = ".zip")
  ncal <- landfireAPIv2(
    products,
    aoi,
    projection,
    resolution,
    path = save_file,
    email = email
  )
  file.rename(save_file, dest_file)
} else {
  message("Skipping API: using existing ", dest_file)
}

# Optional: saveRDS(ncal, file.path("inputs", "landfire_ncal_last.rds"))


# Unzip and rename to inputs/landfire_data.* ----

temp_dir <- tempfile()
dir.create(temp_dir)
unzip(dest_file, exdir = temp_dir)
