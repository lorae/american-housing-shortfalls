# run-all.R
# 
# Runs full replication code for the entire project

# Read in raw data, process to clean data
source("src/scripts/import-ipums.R")
source("src/scripts/process-ipums.R")
source("src/scripts/load-maps.R")

# Analyze
source("src/scripts/fine-grained-counterfactual-regional.R")

# Figures
source("src/figures/fig02-headship-rates-age-year-bars.R")
source("src/figures/fig03-state-headship-arrows.R")
source("src/figures/fig04-observed-counterfactual-bars.R")
source("src/figures/fig05-diff-state-map.R")
source("src/figures/accessory-fig06-hhsize-age-2per-line.R")

# McClure-Schwartz (2024) replication 
source("src/scripts/mcclure-schwartz-replication-state-surplus.R")

# Manuscript statistics
source("src/scripts/inline-statistics.R")