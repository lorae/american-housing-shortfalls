# accessory-fig06-hhsize-age-2per-line.R
#
# This figure is not in the actual manuscript, but its findings are described, and 
# an interested person may find some insight from it.

# ----- Step 0: Configuration ----- #
library("dplyr")
library("duckdb")
library("stringr")
library("tidyr")
library("purrr")
library("glue")
library("readxl")
library("ggplot2")
library("base64enc")
library("patchwork")
library("sf")
# TODO: remove whatever here is not needed

# ----- Step 1: Source helper functions ----- #

devtools::load_all("../demographr")
source("src/utils/aggregation-tools.R") # tabulate_summary and tabulate_summary_2yr

# ----- Step 2: Import and wrangle data ----- #

con <- dbConnect(duckdb::duckdb(), "data/db/ipums.duckdb")
ipums_db <- tbl(con, "ipums_processed")

hhsize_age <- tabulate_summary_2year(
  data = ipums_db, 
  years = c(2000,2019), 
  group_by = "AGE_bucket",
) |>
  mutate(
    subgroup = factor(
      subgroup,
      levels = c(
        "0-4", "5-9", "10-14", "15-19",
        "20-24", "25-29", "30-34", "35-39",
        "40-44", "45-49", "50-54", "55-59",
        "60-64", "65-69", "70-74", "75-79",
        "80-84", "85plus"
      )
    )
  ) |>
  arrange(subgroup)

# Make a *plotting copy* that drops the pctchg col
hhsize_age_for_plot <- hhsize_age |>
  select(-hhsize_pctchg_2000_2019) |>
  pivot_longer(
    cols = starts_with("hhsize_"),
    names_to = "year",
    values_to = "hhsize"
  ) |>
  mutate(year = case_when(
    year == "hhsize_2000" ~ 2000,
    year == "hhsize_2019" ~ 2019
  ))


fig06 <- ggplot(hhsize_age_for_plot, aes(x = subgroup, y = hhsize, group = year, color = factor(year))) +
  geom_line(size = 1) +
  geom_point() +
  labs(
    x = "Age group",
    y = "Average household size",
    color = "Year"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

fig06

# ----- Step 4: Save  ----- #
ggsave(
  "output/figures/fig06-accessory-hhsize-age-2per-line.jpeg",
  plot = fig06,
  width = 3000, height = 2000, units = "px", dpi = 300
)

write_csv(
  hhsize_age,
  "output/figure-data/fig06-accessory-hhsize-age-2per-line.csv"
)


