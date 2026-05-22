# import-ipums.R
#
# This script processes raw IPUMS data and saves it in a DuckDB file.
#
# ----- Step 0: Configuration ----- #

library("dplyr")
library("duckdb")
library("ipumsr")
library("glue")

# Check for existence of .Renviron file
if (!file.exists(".Renviron")) {
  stop(".Renviron file needed for this code to run. Please refer to Part B of the README file for configuration instructions.")
} 

# Read and validate IPUMS API key from .Renviron
readRenviron(".Renviron")
ipums_api_key <- Sys.getenv("IPUMS_API_KEY")

if (ipums_api_key == "" || ipums_api_key == "your_ipums_api_key") {
  stop(".Renviron file exists, but IPUMS API key has not been added. Please refer to Part B of the README file for configuration instructions.")
}

print(paste0("IPUMS API key: ", ipums_api_key))
set_ipums_api_key(ipums_api_key)

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
    "OWNERSHP", "OWNERSHPD", "HHINCOME",
    # Person-level
    "PERNUM", "PERWT","SEX", "AGE",
    "RACE", "RACED", "HISPAN", "HISPAND",
    "BPL", "BPLD", "CITIZEN",
    "EDUC", "EDUCD", "INCTOT"
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
  api_key = ipums_api_key
)

extract_num <- sprintf("%05d", submitted$number)

ddi_path <- glue("data/ipums-microdata/usa_{extract_num}.xml")
dat_path <- glue("data/ipums-microdata/usa_{extract_num}.dat.gz")

# ----- Step 3: Save to DuckDB ----- #

ddi <- read_ipums_ddi(ddi_path)
ipums_tb <- read_ipums_micro(ddi, var_attrs = c()) 

con <- dbConnect(duckdb::duckdb(), "data/db/ipums.duckdb")
dbWriteTable(con, "ipums", ipums_tb, overwrite = TRUE)
DBI::dbDisconnect(con)

