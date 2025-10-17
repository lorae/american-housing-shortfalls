# The purpose of this script is to provide replicable code which backs the 
# in-line "fast facts" we calculate in the manuscript
#
# Last modified October 2025
#
# TODO: When manuscript is released, add page numbers.
# 
# ----- Step 0: Load required packages ----- #
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

# ----- Step 1: Source helper functions ----- #

devtools::load_all("../demographr")
source("src/utils/aggregation-tools.R") # tabulate_summary and tabulate_summary_2yr

# ----- Step 2: Import and wrangle data ----- #

con <- dbConnect(duckdb::duckdb(), "data/db/ipums.duckdb")
ipums_db <- tbl(con, "ipums_processed")

#-------------------------------------------------------------------------------
# FAST FACT: percent of the population living in institutions in 2000 and 2019
# Page 3
# "We exclude individuals living in institutional settings, such as prisons
# and nursing homes; this leads us to remove 2.8% of the population in 2000 and 
# 2.5% in the 2015-2019 data"
#-------------------------------------------------------------------------------
# Summarize GQ status for 2000 survey
gq_2000 <- weighted_mean(
  data = ipums_db |> filter(YEAR == 2000),
  value_column = "NUMPREC",
  weight_column = "PERWT",
  group_by_columns = c("GQ")
) |> collect() |>
  mutate(pct_of_pop = sum_weights / sum(sum_weights))

# Proportion in GQ in 2000
gq_2000 |> 
  filter(GQ %in% c(3, 4, 5)) |>
  summarize(sum_pct = sum(pct_of_pop)) |>
  pull(sum_pct)

# Summarize GQ status for 2019 survey
gq_2019 <- weighted_mean(
  data = ipums_db |> filter(YEAR == 2019),
  value_column = "NUMPREC",
  weight_column = "PERWT",
  group_by_columns = c("GQ")
) |> collect() |>
  mutate(pct_of_pop = sum_weights / sum(sum_weights))

# Proportion in GQ in 2000
gq_2019 |> 
  filter(GQ %in% c(3, 4, 5)) |>
  summarize(sum_pct = sum(pct_of_pop)) |>
  pull(sum_pct)

#-------------------------------------------------------------------------------
# FAST FACT: Aggregate household size in 2000 and 2019
# Page 6
# "In 2000, Americans lived, on average, in households of 3.467 people; by 2019 
# that had fallen to 3.374 people, a drop of 2.7%."
#-------------------------------------------------------------------------------
hhsize_agg <- tabulate_summary_2year(data = ipums_db, years = c(2000,2019), group_by = c())

hhsize_agg |> pull(hhsize_2000) # 2000 household size
hhsize_agg |> pull(hhsize_2019) # 2019 household size
hhsize_agg |> pull(hhsize_pctchg_2000_2019) # Percentage change

#-------------------------------------------------------------------------------
# FAST FACT: Household size by age in 2000 and 2019
# Page X
# "Average household size is largest at youngest ages and changed relatively little
# over time for people under age 20. People live, on average, in slightly smaller
# households throughout their 20s, then see an increase in household size in their 
# 30s. The size of a household that the average American lives in declines 
# monotonically from age 40 onwards."
#-------------------------------------------------------------------------------

hhsize_age <- read.csv("output/figure-data/accessory-fig06-hhsize-age-2per-line.csv")

# household size changed relatively little for those under 20 (<1% from 2000 - 2019)
hhsize_age |> filter(subgroup < "20-24")

# Remainder of the fact is best checked by viewing accessory-fig06 in output/figures

#-------------------------------------------------------------------------------
# FAST FACT: Aggregate headship rate in 2000 and 2019
# Page 6
# "Headship rates fell over the same period as well, from 38.58% to 38.15%."
#-------------------------------------------------------------------------------

headship_agg <- crosstab_percent(
  data = ipums_db |> filter(GQ %in% c(0,1,2)),
  wt_col = "PERWT",
  group_by = c("YEAR", "PERNUM"),
  percent_group_by = c("YEAR")
) |>
  filter(PERNUM == 1)

headship_agg |> filter(YEAR == 2000) |> pull(percent) # 2000 headship rate
headship_agg |> filter(YEAR == 2019) |> pull(percent) # 2019 headship rate



# what is this? vvv


## Table of household sizes in 2000 and 2019 by age group
age_bucket_summary |> filter(RACE_ETH_bucket == "All")

## Age buckets with the largest household sizes
age_bucket_summary |> filter(RACE_ETH_bucket == "All") |> slice_max(hhsize_2000, n = 1)
age_bucket_summary |> filter(RACE_ETH_bucket == "All") |> slice_max(hhsize_2019, n = 1)

## Average household size among children age 0-19
ipums_db_age_v1 <- ipums_db |>
  # Add columns for whether an individual is under 20 or over 65
  mutate(
    under20 = (AGE < 20), # excludes 20 year-olds
    over65 = (AGE >= 65), # includes 65 year-olds
    from20to64 = (AGE >= 20 & AGE < 65) # includes 20 yos, excludes 65 yos
  )

ipums_db_age_v2 <- ipums_db_age_v1 |>
  # Add a column for whether a household contains an individual under 20
  group_by(SAMPLE, SERIAL, YEAR) |> # uniquely IDs HHs
  mutate(
    contains_under20 = any(under20),
    count_under20 = sum(as.integer(under20))
    ) |>
  ungroup()

ipums_db_age_v3 <- ipums_db_age_v2 |>
  # Add a column for whether an individual is an adult over 20 living in a hh with an under-20 yo
  # Also add a column for the number of over 20 adults in a household with children
  mutate(
    cohabit_under20 = (contains_under20 & under20 == FALSE),
    n_cohabit_under20 = NUMPREC - count_under20
  )

# # Visually inspect a few entries to ensure logic works properly
# # Running this line will take 1-2 minutes
# x <- ipums_db_age_v3 |> head(100) |> collect() |>
#   select(SERIAL, NUMPREC, PERNUM, AGE, under20, from20to64, over65, contains_under20, count_under20, cohabit_under20, n_cohabit_under20)
# View(x) # logic appears consistent with intention

# Note: I needed 12 cores to make this step work. 5 cores, and the session crashes.
tabulate_summary_2year(data = ipums_db_age_v3, years = c(2000,2019), group_by = "under20")
tabulate_summary_2year(data = ipums_db_age_v3, years = c(2000,2019), group_by = "from20to64")
tabulate_summary_2year(data = ipums_db_age_v3, years = c(2000,2019), group_by = "over65")

## Average number of adults (age 20+) per household that contains at least one child (age <20)
# ... in 2019
crosstab_mean(
  data = ipums_db_age_v3 |> filter(YEAR == 2019) |> filter(GQ %in% c(0,1,2)) |> filter(contains_under20 == TRUE),
  value = "n_cohabit_under20",
  wt_col = "PERWT",
  group_by = c()
)
# ... in 2000
crosstab_mean(
  data = ipums_db_age_v3 |> filter(YEAR == 2000) |> filter(GQ %in% c(0,1,2)) |> filter(contains_under20 == TRUE),
  value = "n_cohabit_under20",
  wt_col = "PERWT",
  group_by = c()
)

##############################################
# Fast fact: household size by cPUMA
##############################################
## Average hhsize by CPUMA0010 in 2000 and 2019
cpuma_hhsize <- tabulate_summary_2year(data = ipums_db, years = c(2000,2019), group_by = "CPUMA0010")
cpuma_hhsize

## Household size in the median CPUMA in 2000
median(cpuma_hhsize$hhsize_2000)

## Minimum household size in a CPUMA in 2000
min(cpuma_hhsize$hhsize_2000)

## Maximum household size in a CPUMA in 2000
max(cpuma_hhsize$hhsize_2000)

## Average household size increased/decreased in X% of CPUMAs from 2000 - 2019
cpuma_hhsize <- cpuma_hhsize |>
  mutate(
    hhsize_decreased = (hhsize_pctchg_2000_2019 < 0)
  )
sum(cpuma_hhsize$hhsize_decreased) # number of CPUMAs where HH size decreased
nrow(cpuma_hhsize) # total number of CPUMAs

sum(cpuma_hhsize$hhsize_decreased) / nrow(cpuma_hhsize) # Proportion of CPUMAs where HH size decreased

## Household size in the median CPUMA in 2019
median(cpuma_hhsize$hhsize_2019)

## Change in range in CPUMA-level HH size from 2000 to 2019
# 2000 min, max, range
min_2000 <- min(cpuma_hhsize$hhsize_2000)
max_2000 <- max(cpuma_hhsize$hhsize_2000)

min_2000
max_2000
max_2000 - min_2000

# 2019 min, max, range
min_2019 <- min(cpuma_hhsize$hhsize_2019)
max_2019 <- max(cpuma_hhsize$hhsize_2019)

min_2019
max_2019
max_2019 - min_2019

##############################################
# Fast fact: number of additional housing units needed
##############################################
source("src/utils/counterfactual-tools.R") # Includes function for counterfactual calculation

ipums_db <- tbl(con, "ipums_processed")

# Calculate CPUMA-level fully-controlled diffs
hhsize_contributions <- calculate_counterfactual(
  cf_categories = c("RACE_ETH_bucket", "AGE_bucket", "gender", "us_born", "EDUC_bucket", "INCTOT_cpiu_2010_bucket", "CPUMA0010", "tenure"),
  p0 = 2000,
  p1 = 2019,
  p0_data = ipums_db |> filter(YEAR == 2000, GQ %in% c(0,1,2)), 
  p1_data = ipums_db |> filter(YEAR == 2019, GQ %in% c(0,1,2)),
  outcome = "NUMPREC"
)$contributions  

# Counterfactual overall household size in 2019
cf_hhsize_2019_overall <- (hhsize_contributions$weighted_mean_2000 * hhsize_contributions$percent_2019) |> sum() / 100
cf_hhsize_2019_overall

population_aggregates_2019 <- crosstab_mean(
  data = ipums_db |> filter(YEAR == 2019, GQ %in% c(0,1,2)),
  value = "NUMPREC",
  wt_col = "PERWT",
  group_by = c(),
  every_combo = TRUE)

# Actual overall household size in 2019 (excluding those in Group Quarters)
act_hhsize_2019_overall <- population_aggregates_2019 |>
  pull(weighted_mean)
act_hhsize_2019_overall

# Population in 2019 (excluding those in Group Quarters)
population_2019 <- population_aggregates_2019 |>
  pull(weighted_count)
population_2019

## Overall housing unit shortage/surfeit in 2019 (netting out positives and negatives within CPUMAs)
(population_2019/act_hhsize_2019_overall) - (population_2019/cf_hhsize_2019_overall)

##############################################
# Fast fact: number of additional housing units needed, accounting for CPUMA-level surfeit/surplus
##############################################

# Sum the counterfactuals by CPUMA
hhsize_contributions_cpuma <- hhsize_contributions |>
  mutate(
    contribution = weighted_mean_2000 * percent_2019 / 100
  ) |>
  group_by(CPUMA0010) |>
  summarize(
    contribution = sum(contribution, na.rm = TRUE),
    population = sum(weighted_count_2019, na.rm = TRUE),
    percent = sum(percent_2019, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(cf_hhsize = contribution/percent * 100)

# Validity check: ensure the sum of contributions equals cf_hhsize_2019_overall
# Rounded to 5 decimal places due to floating point errors
round((hhsize_contributions_cpuma$contribution |> sum()), 5) == round(cf_hhsize_2019_overall, 5)

# Validity check: sum of `population` column matches population_2019
sum(hhsize_contributions_cpuma$population) == population_2019

# Validity check: cf_hhsize*percent/100 |> sum() = cf_hhsize_2019_overall
round(((hhsize_contributions_cpuma$cf_hhsize*hhsize_contributions_cpuma$percent/100)) |> sum(), 5) == round(cf_hhsize_2019_overall, 5)

cf_by_cpuma <- cpuma_hhsize |>
  rename(CPUMA0010 = subgroup) |>
  left_join(hhsize_contributions_cpuma, by = "CPUMA0010") |>
  mutate(
    housing_surfeit = (population/hhsize_2019) - (population/cf_hhsize)
  )

# Housing shortage and surplus, and number of CPUMAs with a shortage or surplus
cf_by_cpuma_summary <- cf_by_cpuma |> 
  summarize(
    total = sum(housing_surfeit, na.rm = TRUE),
    count_total = sum(!is.na(housing_surfeit)),
    sum_negative = sum(housing_surfeit[housing_surfeit < 0], na.rm = TRUE),
    sum_positive = sum(housing_surfeit[housing_surfeit > 0], na.rm = TRUE),
    count_negative = sum(housing_surfeit < 0, na.rm = TRUE),
    count_positive = sum(housing_surfeit > 0, na.rm = TRUE)
  )
cf_by_cpuma_summary

# Percentage with a shortage
pull(cf_by_cpuma_summary, count_negative) / pull(cf_by_cpuma_summary, count_total)

# Largest surfeit
slice_max(cf_by_cpuma, housing_surfeit) |> View()
# Largest shortage
slice_min(cf_by_cpuma, housing_surfeit) |> View()

# Figure out where the greatest surfeit/surplus is by mapping.
# TODO: Don't just copy and paste this code from counterfactual-regional.R. Create
# a function that can be called to map things.
rot <- function(a) {
  matrix(c(cos(a), sin(a), -sin(a), cos(a)), 2, 2)
}
transform_state <- function(
    df, 
    state_fp, 
    rotation_angle, 
    scale_factor, 
    shift_coords
) {
  state <- df %>% filter(STATEFIP == state_fp)
  state_geom <- st_geometry(state)
  state_centroid <- st_centroid(st_union(state_geom))
  rotated_geom <- (state_geom - state_centroid) * rot(rotation_angle * pi / 180) / scale_factor + state_centroid + shift_coords
  state %>% st_set_geometry(rotated_geom) %>% st_set_crs(st_crs(df))
}
# Load shapefiles. Data is unzipped from WHERE? TODO: document
cpuma_sf <- st_read("data/ipums-cpuma0010-sf/ipums_cpuma0010.shp") |>
  filter(!STATEFIP %in% c('60', '64', '66', '68', '69', '70', '72', '78')) |># Remove excluded states, like Puerto Rico
  st_transform(crs = "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs") |>
  mutate(geometry = st_simplify(geometry, dTolerance =  5000))  # Simplify shapes

# Rotate and move Alaska and Hawaii to fit on map
alaska_cpuma <- transform_state(cpuma_sf, "02", -39, 2.3, c(1000000, -5000000))
hawaii_cpuma <- transform_state(cpuma_sf, "15", -35, 1, c(5200000, -1400000))

# Final map after transforming non-contiguous states
cpuma_sf_final <- cpuma_sf |>
  filter(!STATEFIP %in% c("02", "15")) |>
  bind_rows(alaska_cpuma, hawaii_cpuma)

# Highlight CPUMA 973 in red
cpuma_sf_hhsize <- cpuma_sf_final |>
  mutate(
    fill_color = ifelse(CPUMA0010 == "973", "red", "white")
  )
ggplot(cpuma_sf_hhsize) + 
  geom_sf(aes(geometry = geometry, fill = fill_color), color = "grey50", size = 0.1) +
  scale_fill_identity() + 
  theme_void()


# Highlight CPUMA 550 in red
cpuma_sf_hhsize <- cpuma_sf_final |>
  mutate(
    fill_color = ifelse(CPUMA0010 == "550", "red", "white")
  )
ggplot(cpuma_sf_hhsize) + 
  geom_sf(aes(geometry = geometry, fill = fill_color), color = "grey50", size = 0.1) +
  scale_fill_identity() + 
  theme_void()


##############################################
# Fast fact: number of additional housing units needed, all CPUMAs have average HH size of white americans
##############################################

# Average size of a white household
white_hhsize_2019_overall <- crosstab_mean(
  data = ipums_db |> filter(YEAR == 2019) |> filter(GQ %in% c(0,1,2)),
  value = "NUMPREC",
  wt_col = "PERWT",
  group_by = c("RACE_ETH_bucket")
) |> 
  filter(RACE_ETH_bucket == "White") |>
  pull(weighted_mean)

## Overall housing unit shortage/surfeit in 2019 relative to white household norms (netting out positives and negatives within CPUMAs)
(population_2019/act_hhsize_2019_overall) - (population_2019/white_hhsize_2019_overall) # huge number!

## cPUMA-level household counterfactual, except we replace every cPUMA's cf_hhsize with 3.09 (the value of `white_hhsize_2019_overall`)
hhsize_contributions_cpuma_white <- hhsize_contributions_cpuma |>
  select(-cf_hhsize) |>
  mutate(cf_hhsize_white = white_hhsize_2019_overall)

cf_by_cpuma_white <- cpuma_hhsize |>
  rename(CPUMA0010 = subgroup) |>
  left_join(hhsize_contributions_cpuma_white, by = "CPUMA0010") |>
  mutate(
    housing_surfeit = (population/hhsize_2019) - (population/cf_hhsize_white)
  )

# Housing shortage and surplus, and number of CPUMAs with a shortage or surplus
cf_by_cpuma_summary_white <- cf_by_cpuma_white |> 
  summarize(
    total = sum(housing_surfeit, na.rm = TRUE),
    count_total = sum(!is.na(housing_surfeit)),
    sum_negative = sum(housing_surfeit[housing_surfeit < 0], na.rm = TRUE),
    sum_positive = sum(housing_surfeit[housing_surfeit > 0], na.rm = TRUE),
    count_negative = sum(housing_surfeit < 0, na.rm = TRUE),
    count_positive = sum(housing_surfeit > 0, na.rm = TRUE)
  )
cf_by_cpuma_summary_white

# Percentage with a shortage
pull(cf_by_cpuma_summary_white, count_negative) / pull(cf_by_cpuma_summary_white, count_total)

######### Fast fact: nultiracial percentage
# We define “multiracial” individuals as non-Hispanic persons whose race is encoded 
# as “Two major races” or “Three or more major races” in the Census Bureau’s “RACE” 
# variable. These individuals comprised __% of the non group-quartered population 
# in 2000 and ___% in 2019.
crosstab_percent(
  data = ipums_db |> filter(GQ %in% c(0,1,2)), 
  wt_col = "PERWT", 
  group_by = c("RACE_ETH_bucket", "YEAR"),
  percent_group_by = c("YEAR")
) |> arrange(YEAR)

##### Fast fact: median CPUMA-level hhsize in 2000
tabulate_summary(
  ipums_db,
  year = 2000,
  value = "NUMPREC",
  group_by = "CPUMA0010"
) |> pull(hhsize) |> median()