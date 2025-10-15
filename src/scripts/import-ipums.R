# import-ipums.R
#
# This script processes raw IPUMS data and saves it in a DuckDB file.
#
# Input:
# -  makes API call to IPUMS USA. Be sure to follow Part B of project set-up
#    in README.md before running - this script reads an environment variable from 
#    .Renviron
#
# Output:
# -  docs/ipums-data-dictionary.html
#    Interactive data dictionary including the items from the IPUMS data pull
# -  docs/ipums_value_labels.RData
#    List containing value labels for every variable in the ipums data pull
# -  the db (what is it called?)
#    TODO

# ----- Step 0: Load packages ----- #
library("dplyr")
library("duckdb")
library(ipumsr)
library(glue)

# These packages are implicitly needed; loading them here purely for renv visibility
library("htmltools")
library("shiny")
library("DT")

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

# ----- Step 3: Save to DuckDB ----- #

ddi <- read_ipums_ddi(ddi_path)
ipums_tb <- read_ipums_micro(ddi, var_attrs = c()) 

con <- dbConnect(duckdb::duckdb(), "data/db/ipums.duckdb")
dbWriteTable(con, "ipums", ipums_tb, overwrite = TRUE)
DBI::dbDisconnect(con)

# ----- Step 3: Save helpful reference documentation ----- #

# Interactive HTML document outlining the variables from the 
# data pull
# Temporarily disabled because I don't want to clutter the repo. If it causes
# downstream issues, re-enable it below.
# ipums_view(ddi, out_file = "docs/ipums-data-dictionary.html", launch = FALSE)

# A list which provides the value labels for every variable
# in the pull. The tibble of value labels for a variable
# VARNAME, for example, can be accessed through  the following
# code:
# `my_tibble <- value_labels_list$VARNAME`

value_labels_list <- lapply(seq_len(nrow(ddi$var_info)), function(i) {
  val_labels <- ddi$var_info$val_labels[[i]]
  if (nrow(val_labels) > 0) {
    return(val_labels)
  } else {
    return(NULL)
  }
})

names(value_labels_list) <- ddi$var_info$var_name

save(value_labels_list, file = "docs/ipums_value_labels.RData")
