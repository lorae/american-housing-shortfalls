# run-all.R
# 
# Runs full replication code for the entire project

# Read in raw data, process to clean data
source("src/scripts/import-ipums.R")
source("src/scripts/process-ipums.R")


# Figures
source("src/figures/accessory-fig06-hhsize-age-2per-line.R")
# TODO: other figures here

# McClure-Schwartz (YYYY) replication
# TODO: replace placeholder with actual year
source("src/scripts/mcclure-schwartz-replication-state-surplus.R")

# Fast facts
source("src/scripts/fast-facts-v2.R")