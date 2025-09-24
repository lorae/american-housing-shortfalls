# src/scripts/get-ipums-data.R
# 
# The purpose of this script is to download the IPUMS data extract directly from
# the IPUMS API.

library(ipumsr)

if (!file.exists(".Renviron")) {
  stop(".Renviron file needed for this code to run. Please follow Step B in the project README.")
} 

# Read API key from environment (set in .Renviron)
api_key <- Sys.getenv("IPUMS_API_KEY")

if (api_key == "your_ipums_api_key") {
  stop(".Renviron file exists, but IPUMS API key has not been added. Please follow step B in the project README to add it.")
}
