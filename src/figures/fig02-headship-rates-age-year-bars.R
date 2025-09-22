# #src/figures/fig-02-headship-rates-age-year-bars.R
#
# Produce bar charts showing people per bedroom (room) by tenure in two panels
# (upper and lower) as well as by race/ethnicity (groups of two bars) and year
# (paired bars)
#
# Input: data/db/ipums.duckdb
# Output: output/figures/fig05-crowding-race-tenure-year-bars.png, 
#         output/figures/fig05-appendix-crowding-race-tenure-year-bars.png
#
# TODO: write unit tests for functions

# ----- Step 0: Config ----- 
library("patchwork")
library("ggplot2")
library("tidyr")
library("purrr")
library("dplyr")
library("patchwork")
library("duckdb")
library("scales")
library("forcats")

devtools::load_all("../dataduck")

# ----- Step 1: Define functions -----
source("src/utils/aggregation-tools.R")  # tabulate_summary()
source("src/utils/plotting-tools.R")     # plot_year_subgroup_bars()

# ----- Step 2: Import and wrangle data ----- #
con <- dbConnect(duckdb::duckdb(), "data/db/ipums.duckdb")
ipums_db <- tbl(con, "ipums_processed") |>
  # add an is_hoh column that is TRUE if the person is head of household, false otherwise
  mutate(is_hoh = as.integer(PERNUM == 1))

# Common bar styling
bar_fills <- list(
  per1 = list(color = "skyblue",     alpha = 0.4, line_type = "dashed"), # 2000
  per2 = list(color = "forestgreen", alpha = 0.5, line_type = "solid")   # 2019
)

# =======================
# A05 (persons per bedroom)
# =======================
ymin_XX <- 0
ymax_XX <- 100
ytitle_XX <- "Headship Rate"

figXX_data <- crosstab_mean(
  data = ipums_db |> filter(GQ %in% c(0,1,2)),
  value = "is_hoh",
  wt_col = "PERWT",
  group_by = c("AGE_bucket", "YEAR")
) |>
  rename(
    year = YEAR,
    subgroup = AGE_bucket,
    is_hoh = weighted_mean
  ) |>
  mutate(
    is_hoh = is_hoh * 100 
  ) |>
  select(subgroup, year, is_hoh) |>
  mutate(
    subgroup = factor(
      subgroup,
      levels = c(
        "0-4", "5-9", "10-14", "15-19", "20-24", "25-29",
        "30-34", "35-39", "40-44", "45-49", "50-54", "55-59",
        "60-64", "65-69", "70-74", "75-79", "80-84", "85plus"
      )
    )
  ) |>
  mutate(
    subgroup = fct_recode(
      subgroup,
      "85+" = "85plus"
    )
  )

figXX <- plot_year_subgroup_bars(
  figXX_data,
  yvar = is_hoh,
  bar_fills = bar_fills,
  ymin = 0, ymax = 100,
  ytitle = "Headship Rate",
  legend = TRUE,
  title = "Headship Rate by Age Group and Year",
  show_labels = FALSE, 
  axis_percent = TRUE 
)

figXX

# ----- Step 4: Save plots ----- #
ggsave(
  "output/figures/fine-grained/figXX-headship-age-year.png",
  plot = figXX,
  width = 3000, height = 2000, units = "px", dpi = 300
)