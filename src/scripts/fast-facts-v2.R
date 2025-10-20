# The purpose of this script is to provide replicable code which backs the 
# in-line "fast facts" fast facts provided in the manuscript
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
# Page 6
# "Average household size is largest at youngest ages and changed relatively little
# over time for people under age 20. People live, on average, in slightly smaller
# households throughout their 20s, then see an increase in household size in their 
# 30s. The size of a household that the average American lives in declines 
# monotonically from age 40 onwards."
#-------------------------------------------------------------------------------

hhsize_age <- read.csv("output/figure-data/accessory-fig06-hhsize-age-2per-line.csv")

# household size changed relatively little for those under 20 (<1% from 2000 - 2019)
hhsize_age |> filter(subgroup < "20-24")

# Remainder of the fact is best checked by viewing the contours of the lines in
# output/figures/accessory-fig06-hhsize-age-2per-line.jpeg

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

#-------------------------------------------------------------------------------
# FAST FACT: Headship rates in 2000 and 2019 by age
# Page 6
# "Headship rates were lower in 2019 than they were in 2000 at all ages. This effect, 
# though, is particularly pronounced in early and late adulthood. For example, only 
# 20% of people aged 20–24 were household heads in 2019, down from 28% at the 
# turn of the millennium. For people between the ages of 30 and 74, reductions in 
# headship rates over time were relatively small (3 percentage points or less), but these 
# drops were larger for individuals aged 75 and above (at least 6 percentage points lower)."
#-------------------------------------------------------------------------------

headship_age <- read.csv("output/figure-data/fig02-headship-age-year-bars.csv")

# "Headship rates were lower in 2019 than they were in 2000 at all ages"
headship_age <- headship_age |>
  mutate(
    diff = headship_rate_2019 - headship_rate_2000
  )
headship_age

# For people between the ages of 30 and 74, reductions in headship rates over time 
# were relatively small (3 percentage points or less)
headship_age |> filter(subgroup >= "30-34" & subgroup < "75-79")

# ..but these drops were lower for individuals aged 75 and above (at least 6 percentage
# points lower).
headship_age |> filter(subgroup >= "75-79")

#-------------------------------------------------------------------------------
# FAST FACT: Average household size by state
# Page 7
# "Average household size (left panel of Figure 3) in 2000 varied from 3.075 people 
# in Maine to 4.161 people in Utah. Across the 50 states and the District of Columbia 
# (DC), average household size fell between 2000 and 2019 in all but four states 
# (Oklahoma, Alaska, Kentucky, and Tennessee). In 18 states and DC, the drop was larger 
# than the national average (a reduction of 0.093 people per household). Louisiana, 
# DC, New Mexico, California, and Illinois all saw drops in average household size of 
# more than 0.2 people."
#-------------------------------------------------------------------------------
hhsize_state <- read.csv("output/figure-data/fig03-household-size-state.csv")

hhsize_state |> filter(household_size_2000 == min(household_size_2000)) # Maine: min avg hhsize 2000
hhsize_state |> filter(household_size_2000 == max(household_size_2000)) # Utah: max avg hhsize 2000

# Average household size fell between 2000 and 2019 in all but four states
hhsize_state <- hhsize_state |> 
  mutate(diff = household_size_2019 - household_size_2000) 
hhsize_state |> filter(diff >= 0)

# In 18 states and DC, the drop was larger than the national average (a reduction of
# 0.093 people per household).
natl_hhsize_diff <- (hhsize_agg |> pull(hhsize_2019)) - (hhsize_agg |> pull(hhsize_2000)) 
natl_hhsize_diff

hhsize_state |> filter(diff < natl_hhsize_diff )

# Louisiana, DC, New Mexico, California, and Illinois all saw drops in average household size of 
# more than 0.2 people.
hhsize_state |> filter(diff < -0.2)

#-------------------------------------------------------------------------------
# FAST FACT: Average headship rate by state
# Page 7
# "In the right panel of Figure 3, we see similar variation in headship rates. In 2000, 
# headship rates ran from a low of 32.00% in Utah to a high of 46.28% in DC. Headship 
# rates fell over time in 25 states and DC, with the largest decline in Florida (40.71% 
# in 2000 to 37.80% in 2019). Rates rose in the other 25 states, with the largest increases 
# recorded in Maine, Michigan, Wisconsin, North Dakota, and Vermont."
#-------------------------------------------------------------------------------
headship_state <- read.csv("output/figure-data/fig03-headship-rate-state.csv")

headship_state |> filter(headship_rate_2000 == min(headship_rate_2000)) # Utah: min avg HR 2000
headship_state |> filter(headship_rate_2000 == max(headship_rate_2000)) # DC: max avg HR 2000

# Headship rates fell over time in 25 states and DC
headship_state <- headship_state |> 
  mutate(diff = headship_rate_2019 - headship_rate_2000) 
headship_state |> filter(diff <= 0)

# ...with the largest decline in Florida (40.71% in 2000 to 37.80% in 2019)
headship_state |> arrange(diff) |> slice_head(n = 1)

# Rates rose in the other 25 states
headship_state |> filter(diff > 0) 

# ... with the largest increases recorded in Maine, Michigan, Wisconsin, North Dakota, 
# and Vermont
headship_state |> arrange(-diff) |> slice_head(n = 5)

#-------------------------------------------------------------------------------
# FAST FACT: Headship vs. change in headship
# Page 7
# "There is no consistent pattern linking headship rates in 2000 to changes over 
# the subsequent 20 years: rates rose and fell in states with high baseline rates 
# as well as in states with low baseline rates."
#-------------------------------------------------------------------------------

# This graph should be sufficiently convincing of the point
ggplot(headship_state, aes(x = headship_rate_2000, y = diff)) +
  geom_point() +
  labs(
    x = "Headship rate, 2000",
    y = "Change in headship rate, 2000–2019"
  )

#-------------------------------------------------------------------------------
# FAST FACT: Observed vs expected aggregate change
# Page 8
# "The actual drop in average household size (0.093 people) amounts to 73.9% of the 
# expected decline based on changes in population structure."
# "...Notably, in this case the observed change [in headship rate] (a decrease of 
# 0.43 percentage points) is in the opposite direction as the counterfactual (an 
# expected increase of 2.23 percentage points)."
#-------------------------------------------------------------------------------
actual_cf <- read.csv("output/figure-data/fig04-observed-counterfactual-bars.csv")

# "The actual drop in average household size (0.093 people) amounts to 73.9% of the 
# expected decline based on changes in population structure."
actual_hhsize_2000 <- actual_cf |> filter(var == "household_size") |> pull(observed_2000)
expected_hhsize_2019 <- actual_cf |> filter(var == "household_size") |> pull(expected_2019)
(natl_hhsize_diff) / (expected_hhsize_2019 - actual_hhsize_2000)

# Observed change in headship rate is -0.43 pp
actual_hr_2000 <- actual_cf |> filter(var == "headship_rate") |> pull(observed_2000)
actual_hr_2019 <- actual_cf |> filter(var == "headship_rate") |> pull(observed_2019)
actual_hr_2019 - actual_hr_2000

# Counterfactual expected change in headship rate was +2.23 pp
expected_hr_2019 <- actual_cf |> filter(var == "headship_rate") |> pull(expected_2019)
expected_hr_2019 - actual_hr_2000

#-------------------------------------------------------------------------------
# FAST FACT: Unexplained differences by state
# Page 9
# "It is important to note that most of the seven states that experienced this pattern 
# had larger-than-average household sizes in 2000. For example, California’s average 
# household size was 3.997 people per household in 2000, third-highest in the nation. 
# It experienced the second-largest decline in average household size between 2000 
# and 2019 (behind only Illinois), though its 2019 average household size was still 
# larger than national average (3.770 vs. a national average of 3.374). 
#-------------------------------------------------------------------------------
# TODO: Do this way upstream!
# Copy the small lookup table to DuckDB
cpuma_state_cross <- readRDS("data/helpers/cpuma-state-cross.rds") # Crosswalks CPUMA0010 to state
copy_to(con, cpuma_state_cross, "cpuma_state_cross", temporary = TRUE, overwrite = TRUE)

# Now join inside DuckDB
temp <- ipums_db |>
  left_join(tbl(con, "cpuma_state_cross"), by = "CPUMA0010")

state_hhsize <- crosstab_mean(
  data = temp |> filter(GQ %in% c(0,1,2)),
  value = "NUMPREC",
  wt_col = "PERWT",
  group_by = c("YEAR", "State")
) |>
  select(State, YEAR, weighted_mean) %>%
  pivot_wider(
    names_from = YEAR,
    values_from = weighted_mean,
    names_prefix = "hhsize_"
  ) |>
  mutate(diff = hhsize_2000 - hhsize_2019) |>
  arrange(State)

# California’s average household size was 3.997 people per household in 2000, third-highest 
# in the nation.
state_hhsize_2000 |> filter(YEAR == 2000) |> slice_max(order_by = weighted_mean, n = 3)
state_hhsize_2000 |> filter(State == "California") |> pull(weighted_mean)

# It experienced the second-largest decline in average household size between 2000 
# and 2019 (behind only Illinois)


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