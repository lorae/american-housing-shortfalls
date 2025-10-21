# src/figures/fine-grained-fig05-diff-state-map.R
#
# This script produces choropleth maps of differences between actual and expected
# household size and headship rates by state in 2019
#

# ----- Step 0: Config ----- #
library("dplyr")
library("duckdb")
library("stringr")
library("tidyr")
library("purrr")
library("glue")
library("readxl")
library("ggplot2")
library("base64enc")
library("sf")
library("readr")
options(scipen = 999)

devtools::load_all("../demographr")
source("src/utils/counterfactual-tools.R") # Includes function for counterfactual calculation

# ----- Step 1: Import data ----- #
state_sf <- readRDS("throughput/state_shapefiles.rds") # One shapefile row per state
hhsize_state_summary <- readRDS("throughput/fine-grained-hhsize-diff-state.rds")
headship_state_summary <- readRDS("throughput/fine-grained-headship-diff-state.rds")
cf_summaries <- readRDS("throughput/fine-grained-cf-summaries.rds")
cpuma_state_cross <- readRDS("data/helpers/cpuma-state-cross.rds") # Crosswalks CPUMA0010 to state

# ----- Step 2: Map Household Size Difference by State (Fig05A) ----- #
state_sf_hhsize <- state_sf |>
  left_join(hhsize_state_summary, by = "State")

fig05a <- ggplot(state_sf_hhsize) + 
  geom_sf(aes(geometry = geometry, fill = diff), color = "black", size = 0.5) +
  scale_fill_gradient2(
    name = "Unexplained \nDifference, \nPersons per \nHousehold",
    low = "blue", mid = "white", high = "#F94144", midpoint = 0,
    breaks = seq(from = -0.5, to = 0.2, by = 0.05)
  ) +
  theme_void()
fig05a

# ----- Step 3: Map Headship Difference by State (Fig05B) ----- #
state_sf_headship <- state_sf |>
  left_join(headship_state_summary, by = "State")

fig05b <- ggplot(state_sf_headship |> filter(State != "District of Columbia")) + 
  geom_sf(aes(geometry = geometry, fill = diff), color = "black", size = 0.5) +
  scale_fill_gradient2(
    name = "Unexplained \nDifference, \nHeadship \nRate",
    low = "#F94144", mid = "white", high = "blue", midpoint = 0,
    breaks = seq(from = -0.04, to = 0.1, by = 0.01)
  ) +
  theme_void()
fig05b

# ----- Step 4: Save ----- #
ggsave("output/figures/fig05a-hhsize-diff-state-map.jpeg", plot = fig05a, width = 6.5, height = 4, dpi = 300)
ggsave("output/figures/fig05b-headship-diff-state-map.jpeg", plot = fig05b, width = 6.5, height = 4, dpi = 300)

write_csv(hhsize_state_summary, "output/figure-data/fig05a-hhsize-diff-state-map.csv")
write_csv(headship_state_summary, "output/figure-data/fig05b-headship-diff-state-map.csv")
