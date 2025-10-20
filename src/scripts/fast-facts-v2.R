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
# FAST FACT: Unexplained household size differences by state
# Page 9
# "It is important to note that most of the seven states that experienced this pattern 
# had larger-than-average household sizes in 2000. For example, California’s average 
# household size was 3.997 people per household in 2000, third-highest in the nation. 
# It experienced the second-largest decline in average household size between 2000 
# and 2019 (behind only Illinois), though its 2019 average household size was still 
# larger than national average (3.770 vs. a national average of 3.374). 
#-------------------------------------------------------------------------------
# TODO: Do this way upstream! Maybe in process-ipums
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
  mutate(diff = hhsize_2019 - hhsize_2000) |>
  arrange(State)

# California’s average household size was 3.997 people per household in 2000, third-highest 
# in the nation.
state_hhsize |> slice_max(order_by = hhsize_2000, n = 3)
state_hhsize |> filter(State == "California") |> pull(hhsize_2000)

# It experienced the second-largest decline in average household size between 2000 
# and 2019 (behind only Illinois)
state_hhsize |> slice_max(order_by = -diff, n = 2)

# Though its 2019 average household size was still larger than national average 
# (3.770 vs. a national average of 3.374). 
state_hhsize |> filter(State == "California") |> pull(hhsize_2019)
hhsize_agg |> pull(hhsize_2019)

#-------------------------------------------------------------------------------
# FAST FACT: Unexplained headship differences by state
# Page 9
# "Compared to the mixed findings when analyzing average household size, results 
# using headship rates are consistent: observed headship rates in 2019 fell below 
# expectations in all 50 states and DC (Figure 5, bottom panel). The smallest difference 
# was in Nebraska, where headship increased from 40.11% in 2000 to 40.77% in 2019, 
# still 1.09 percentage points less than the increase to 41.86% predicted under the 
# counterfactual. The five places with the largest gaps between observed values and 
# expectations were DC, Florida, Alabama, New Mexico, and California. With the exception 
# of New Mexico, each of these sites saw a decline in headship rates over time, 
# whereas the counterfactual prediction was of a large increase.
#-------------------------------------------------------------------------------

headship_state_cf <- read_csv("output/figure-data/fig05b-headship-diff-state-map.csv") |> 
  mutate(diff_obs = observed_2019 - observed_2000) 

# The smallest difference was in Nebraska,
headship_state_cf |> slice_max(diff, n = 1)

# where headship increased from 40.11% in 2000 to 40.77% in 2019, still 1.09 percentage 
# points less than the increase to 41.86% predicted under the counterfactual.
headship_state_cf |> filter(State == "Nebraska") |> pull(observed_2000)
headship_state_cf |> filter(State == "Nebraska") |> pull(observed_2019)
headship_state_cf |> filter(State == "Nebraska") |> pull(diff)
headship_state_cf |> filter(State == "Nebraska") |> pull(expected_2019)

# The five places with the largest gaps between observed values and expectations 
# were DC, Florida, Alabama, New Mexico, and California. With the exception of New 
# Mexico, each of these sites saw a decline in headship rates over time, whereas 
# the counterfactual prediction was of a large increase.
headship_state_cf |> slice_max(-diff, n = 5)
# TODO: diff in this table should actaully be 2000 - 2019, not 2019 - 2000 (which it currently is)

#-------------------------------------------------------------------------------
# FAST FACT: Household size household shortfall calculation at CPUMA level
# Page 10-11
# "Using our measure of average household size, we estimate that 754 of the nation’s 
# 1,078 cPUMAs (69.9%) would need to increase their number of households in 2019 
# to reduce average household size to match counterfactual levels. Across these 754 
# cPUMAs, at least 1.923 million more households would be necessary to match 2000 
# patterns. By contrast, average household size has fallen below the counterfactual 
# estimate in the other 324 cPUMAs, signaling that fewer households are needed to 
# match 2000 levels.
#-------------------------------------------------------------------------------

hhsize_cf_cpuma <- readRDS("throughput/fine-grained-hhsize-diff-cpuma.rds")

# "we estimate that 754 of the nation’s  1,078 cPUMAs (69.9%) would need to increase 
# their number of households in 2019 to reduce average household size to match counterfactual 
# levels."
hhsize_cf_cpuma |> filter(diff > 0) |> nrow()
hhsize_cf_cpuma |> nrow()
(hhsize_cf_cpuma |> filter(diff > 0) |> nrow()) / (hhsize_cf_cpuma |> nrow())

# Across these 754 cPUMAs, at least 1.923 million more households would be necessary 
# to match 2000 patterns.
hhsize_cf_cpuma |>
  filter(diff > 0) |>
  mutate(
    p_over_s_2019 = pop_2019 / observed_2019,
    p_over_s_cf = pop_2019 / expected_2019,
    minimum_surfeit = p_over_s_cf - p_over_s_2019
  ) |>
  pull(minimum_surfeit) |>
  sum()

# By contrast, average household size has fallen below the counterfactual estimate 
# in the other 324 cPUMAs
hhsize_cf_cpuma |> filter(diff < 0) |> nrow()

#-------------------------------------------------------------------------------
# FAST FACT: Headship household shortfall calculation at CPUMA level
# Page 11
# "To match counterfactual levels, headship rates would need to increase in 1054 cPUMAs 
# (97.8%). Cumulatively, 8.439 million additional households would be necessary to 
# achieve this effect.
#-------------------------------------------------------------------------------
headship_cf_cpuma <- readRDS("throughput/fine-grained-headship-diff-cpuma.rds")

# To match counterfactual levels, headship rates would need to increase in 1054 cPUMAs 
# (97.8%).
headship_cf_cpuma |> filter(diff < 0) |> nrow()
headship_cf_cpuma |> nrow()
(headship_cf_cpuma |> filter(diff < 0) |> nrow()) / (headship_cf_cpuma |> nrow())

# Cumulatively, 8.439 million additional households would be necessary to achieve 
# this effect.
headship_cf_cpuma |>
  filter(diff < 0) |>
  mutate(
    surfeit = diff * pop_2019
  ) |>
  pull(surfeit) |>
  sum()


#-------------------------------------------------------------------------------
# FAST FACT: Additional households to match white household sizes
# Page 11
# "Considerably more households would be necessary to allow for further declines in 
# average household size. For example, for the full U.S. population in 2019 to experience 
# patterns on par with what is typical for white Americans, the nation would need 
# between 8.358 million additional households (minimum based on average household 
# size) and 13.032 million additional households (based on headship rates)
#-------------------------------------------------------------------------------

# Pull the average number of people in a white person's home in 2019
white_hhsize_2019 <- crosstab_mean(
  data = ipums_db |> filter(GQ %in% c(0,1,2)),
  value = "NUMPREC",
  wt_col = "PERWT",
  group_by = c("RACE_ETH_bucket", "YEAR")
) |>
  filter(RACE_ETH_bucket == "White", YEAR == 2019) |>
  pull(weighted_mean)

# Use this value on all CPUMAs
hhsize_cf_cpuma |>
  mutate(
    white_hhsize_2019 = white_hhsize_2019,
    white_diff = white_hhsize_2019 - observed_2000
    ) |>
  filter(white_diff < 0) |>
  mutate(
    p_over_s_2019 = pop_2019 / observed_2019,
    p_over_s_white_cf = pop_2019 / white_hhsize_2019,
    minimum_surfeit = p_over_s_white_cf - p_over_s_2019
  ) |>
  pull(minimum_surfeit) |>
  sum()


# Pull the average headship rate among white people in 2019
white_headship_2019 <- crosstab_mean(
  data = ipums_db |> filter(GQ %in% c(0,1,2)),
  value = "is_hoh",
  wt_col = "PERWT",
  group_by = c("RACE_ETH_bucket", "YEAR")
) |>
  filter(RACE_ETH_bucket == "White", YEAR == 2019) |>
  pull(weighted_mean)

# Use this value on all CPUMAs
headship_cf_cpuma |>
  mutate(
    white_headship_2019 = white_headship_2019,
    white_diff = white_headship_2019 - observed_2000
    ) |>
  filter(white_diff > 0) |>
  mutate(
    surfeit = white_diff * pop_2019
  ) |>
  pull(surfeit) |>
  sum()

