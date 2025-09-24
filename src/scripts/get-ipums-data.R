# src/scripts/get-ipums-data.R
# 
# The purpose of this script is to download the IPUMS data extract directly from
# the IPUMS API.

# ----- Step 0: Configuration ----- #

library(ipumsr)
library(glue)

if (!file.exists(".Renviron")) {
  stop(".Renviron file needed for this code to run. Please refer to Part B of the README file for configuration instructions.")
} 

# Read API key from project-local .Renviron
readRenviron(".Renviron") # Force a re-read each run
api_key <- Sys.getenv("IPUMS_API_KEY")

if (api_key == "" || api_key == "your_ipums_api_key") {
  stop(".Renviron file exists, but IPUMS API key has not been added. Please refer to Part B of the README file for configuration instructions.")
}

print(paste0("IPUMS API key: ", api_key))
set_ipums_api_key(api_key)

# ----- Step 1: Define, submit, and wait for data extract ----- #

# Define extract
ipums_extract <- define_extract_micro(
  description = "Replication data: Changes in Average Household Size and Headship Rates as Indicators of Housing Shortfalls (Hepburn and Stojanovic, 2025)",
  collection = "usa",
  samples = c(
    "us2000a", # 2000 5% sample
    "us2019c"  # 2015-2019, ACS 5-year sample
    ),
  variables = c(
    # Household-level
    "YEAR", "MULTYEAR", "SAMPLE", "SERIAL", "CBSERIAL", "HHWT",
    "CLUSTER", "STRATA", "GQ", "NUMPREC", "CPUMA0010",
    "OWNERSHP", "OWNERSHPD", "HHINCOME", "ROOMS", 
    "BEDROOMS",
    # Person-level
    "PERNUM", "PERWT","SEX", "AGE",
    "RACE", "RACED", "HISPAN", "HISPAND",
    "BPL", "BPLD", "CITIZEN",
    "EDUC", "EDUCD", "INCTOT"
    # "REPWTP", "UNITSSTR", # Probably not needed, add back in if needed
  )
)

# Submit extract request
submitted <- submit_extract(ipums_extract)

# Poll until extract is ready
wait_for_extract(submitted) 

# ----- Step 2: Download and save extract ----- #

# Once ready, download the extract ZIP
download_extract(
  submitted,
  download_dir = "data/ipums-microdata",
  overwrite = TRUE,
  api_key = api_key
)

extract_num <- sprintf("%05d", submitted$number)

ddi_path <- glue("data/ipums-microdata/usa_{extract_num}.xml")
dat_path <- glue("data/ipums-microdata/usa_{extract_num}.dat.gz")

