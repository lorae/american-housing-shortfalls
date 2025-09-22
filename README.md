# American Housing Shortfalls

This repository provides full replication code for analyzing the extent to which American household sizes have changed over time, and by sociodemographic dimension. Detailed instructions for running the code follow.

TODO: consolidate the .env (SLURM setup) and .Rproject instructions into one config section of this document

# Project setup

To run this project, the user should have a working familiarity with R and git.
   
### 1. Clone the repo to your local computer

Open a terminal on your computer. Navigate to the directory you would like to be the parent directory of the repo, then clone the repo.

On Windows:
```bash
cd your\path\to\parent\directory
```
```bash
git clone https://github.com/lorae/american-housing-shortfalls american-housing-shortfalls
```

macOS/Linux:
```cmd
cd your/path/to/parent/directory
```
```cmd
git clone https://github.com/lorae/american-housing-shortfalls american-housing-shortfalls
```

### 2. Open R project

Open `american-housing-shortfalls.Rproj` using your preferred IDE for R. (During development of this code, R Studio was used).

### 3. Initialize R environment

This step installs all the dependencies (packages) needed to make the code run on your computer. Depending on your installed packages, this setup step may take from a few minutes to over an hour to run.

Make sure the `renv` package is already installed and attached. Run the following in your R console:
```r
install.packages("renv")
```
```r
library("renv")
```

Then initialize the project:
```r
renv::init()
```

You'll be told that this project already has a lockfile. Select option `1: Restore the project from the lockfile`. 

# `data` directory
If you have cloned this repository from GitHub, it will include a `data` directory which contains an empty `ipums_microdata` directory. Because of the large file size, this data is not stored on GitHub. Either request the file directly from the authors or follow these instructions to download the data from IPUMS directly:

## API Setup: Census Data Access

Some scripts in this repository (e.g., for the McClure-Schwartz replication) use the `tidycensus` package, which requires a Census API key. To set this up:

1. **Request a free Census API key**  
   https://api.census.gov/data/key_signup.html

2. **Copy the file** `sample.Renviron` to a new file named `.Renviron` in the project root directory.

    On macOS/Linux:
    ```bash
    cp sample.Renviron .Renviron
    ```
    
    Windows:
    ```cmd
    copy sample.Renviron .Renviron
    ```
3. **Open `.Renviron`** and replace `your_api_key` with your actual key.  Do not include quotation marks. R will automatically load `.Renviron` when you start a new session. This keeps your API key private and separate from the codebase.

    🛑 Important: `.Renviron` is listed in `.gitignore`, so it will not be tracked or uploaded to GitHub — but `sample.Renviron` is tracked, so do not put your actual API key in the sample file.

## Download from IPUMS USA

1. Navigate to the [IPUMS USA login page](https://uma.pop.umn.edu/usa/authentication/login). If you do not already have user credentials, you will need to set them up before proceeding. Log into the portal.

2. Request a data extract with the following information:

  **Sample** (count: 2)
  -   2000 5%
  -   2019 ACS 5yr
  
  **Variables** (count: 110)
  - [YEAR](https://usa.ipums.org/usa-action/variables/YEAR)
  - [MULTYEAR](https://usa.ipums.org/usa-action/variables/MULTYEAR)
  - TODO: fill out the rest

# Running the code

The code for this project is stored in the `src` folder. Code is divided into two main directories: `scripts` and `utils`. The `scripts` directory contains executable code which runs the analyses. The `utils` foler contains necessary accessory modules, typically in the form of functions, that are sourced when certain scripts run. These functions are separated due to their complexity. Code underlying them can be inspected more directly when they are isolated, and they are subject to a battery of unit tests.

We'll now explain each of the `scripts` files in turn, which walk the researcher through data ingestion, throughput generation, and generation of output and figures.

**The scripts should be run in the following order**:
1. `import-ipums.R`
2. `process-ipums.R`

## `import-ipums.R`

This script serves two purposes:
1. Read in the IPUMS USA microdata from its raw, brittle format in the source `.dat.gz` file into a DuckDB database, which can be more agilely manipulated and analyzed.

2. Read IPUMS USA pull metadata and saved clean files into the `docs/` folder that help with later data reconciliation and labelling.

This script leverages the `ipumsr` package for this purpose. Due to the relatively large size of the source data (2 GB as of June 2025), it requires about 5 minutes to run when using 15 cores, 1000 GB memory, R version 4.4.2.

**Inputs**:
- `data/ipums-microdata/usa_0020.xml`
- `data/ipums-microdata/usa_0020.dat.gz`

**Outputs**:
- `data/db/ipums.duckdb`
- `docs/ipums_value_labels.RData`
- `docs/ipums-data-dictionary.html` (currently deprecated and no longer generated)

The `db/ipums.duckdb` file contains the primary data used in the remainder of the project. The other outputs in the `docs` directory are used downstream for graph labelling, re-attaching labels after KOB regressions are done, and more. 
TODO: specify more here.

## `process-ipums.R`
The purpose of this script is to attach essential accessory columns to the raw microdata for downstream analysis. It reads from the `ipums` table in `data/db/ipums-raw.duckdb` and writes processed data to the `ipums_bucketed` table in `data/db/ipums-processed.duckdb`. For example, data are bucketed from their raw format (e.g. `INCTOT`) to a processed, discrete format like `INCTOT_cpiu_2010_bucket`. Here is an up-to-date list on which variables are created, and how, as of June 2025:

- `pers_id`: generated by concatenating the `SAMPLE`, `SERIAL`, and `PERNUM` columns, separating using an underscore. This is the IPUMS-recommended way to [uniquely identify each person](https://usa.ipums.org/usa-action/variables/PERNUM#description_section).
- `hh_id`: generated by contatenating the `SAMPLE` and `SERIAL` columns, separating using an underscore. This is the IPUMS-recommended way to [uniquely identify each household](https://usa.ipums.org/usa-action/variables/SERIAL#description_section).
- `AGE_bucket`: generated by applying the `lookup_tables/age/age_buckets01.csv` lookup table to the `AGE` column to create discrete buckets [TODO: of what.....?]
- `HHINCOME_bucket`: a deprecated column, no longer used, in favor of `INCTOT_cpiu_2010_bucket`. Generated by applying the `lookup_tables/hhincome/hhincome_buckets03.csv` lookup table to the `HHINCOME` column. (TODO: delete this, after refactoring INCTOT_cpiu_2010_bucket to use the same logic rather than its current clunky hard-coded format.)
- `HISPAN_bucket`: a throughput column that is generated by applying the `"lookup_tables/hhincome/hhincome_buckets03.csv` lookup table to the `HISPAN` column to create [a boolean? what? TODO: of what.....?]
- `RACE_bucket`: a througput column that is generated by applying the `lookup_tables/race/race_buckets00.csv` lookup table to the `RACE` column to create [TODO what?]
- `EDUC_bucket` a throughput column that is generated by applying the `lookup_tables/educ/educ_buckets00.csv` lookup table to the `EDUC` column to create [TODO: what?????]
- `RACE_ETH_bucket`: a column that is created by combining entries in `HISPAN_bucket` and `RACE_bucket`. Used to create exclusive race/ethnicity labels. The code writing the SQL query to generate these labels can be found in the `dataduck` package (TODO: move it or make it simpler to access)
- `cpiu`: a throughput column that is generated by importing a BLS data series with annual CPI-U values
- `cpiu_2010_value`: a throughput column that contains the CPI-U value in 2010.
- `cpiu_2010_deflator`: a throughput column derived by dividing the current `YEAR`'s `cpiu` value by the `cpiu_2010_value`
- `INCTOT_cpiu_2010`: a throughput column derived dividing the `INCTOT` column by the `cpiu_2010_deflator` column, along with two hard-coded exceptions (NA and `AGE` < 15)
- `INCTOT_cpiu_2010_bucket`: a column created by bucketing `INCTOT_cpiu_2010` in 7 groups, ranging from negative values to over $200,000.
- `us_born`: a boolean column that is `TRUE` when the `BPL` (birthplace) variable is less than 120 (see [documentation](https://usa.ipums.org/usa-action/variables/BPL#codes_section) for BPL codes)
- `persons_per_bedroom`: a numeric column derived by dividing `NUMPREC` by `BEDROOMS`. Note that we filter out individuals living in group quarters from our analysis, so edge cases for those individuals do not affect `NUMPREC`-related results (TODO: expand more upon that here. BEDROOMS is always NA when GQ !in 0,1,2; right? And isn't NUMPREC NA? Doesn't matter anyway since they're filtered away but a best practice mgiht be to manually set these entries as NA)
- `tenure`: equals "homeowner" or "renter"
- `gender`: equals "male" or "female"
- `cpuma`: a character-encoded (rather than numeric) version of the [CPUMA0010 variable](https://usa.ipums.org/usa-action/variables/CPUMA0010)

**Inputs**:
- needs `dataduck` package
- `data/db/ipums.duckdb`: `ipums` table

**Outputs**:
- `data/db/ipums.duckdb`: `ipums_processed` table

Outputs are used downstream for all subsequent analysis.

# Running SLURM jobs with environment variables
To keep sensitive or system-specific values (like an email address or scratch directory path) outside of version control, we use a `.env` file to define environment variables, and reference them in the job scripts.

1. **Create a .env file**
    This repository includes a tracked example.env file which you can copy and fill with your information. To use it:
  
    ```bash
    cp example.env .env
    ```
  
    Then open `.env` in your preferred IDE / text editor and fill in your information. For example:
  
    ```bash
    SLURM_MAIL_USER=me@nowhere.com
    PROJECT_WORKDIR=your/file/path/to/household-size-demographics
    ```
    Do not commit your `.env` file. It should be automatically ignored, as it is listed in `.gitignore.` 

2. **Source the environment before submitting jobs**
    Before running a job, load the environment variables into your shell:
    
    ```bash
    source .env
    ```
    
    Then submit the SLURM job as usual. You can run this test script to confirm your `.env` is configured correctly. Assuming it is, logs should show up in the `slurm-logs` directory:
    
    ```bash
    sbatch your/file/path/to/household-size-demographics/jobs/test-env.sh
    ```
    
    The job script references your environment variables, ensuring your email address and file paths are never hardcoded into the script itself.

----
# KOB decompsition
See details here: https://lorae.github.io/household-size-demographics/kob-decomposition.html


----
# File structure


----
# Additional notes / Conventions
copy info about _db or _tb suffix on varnames

In general, varnames that are gneerated in this project are all lowercase. varnames from original ipums are uppercase. TODO: formalize this across the code.

---
# TODOS / musings

TODO: transfer over lookup tables!!!

TODO: add instructions on setting up the environment for the first time and installing all the packages using the renv.lock file. Note that the last time I installed `duckdb` on Della, it took 1 hour 4 minutes, so give the user a fair warning about that.

TODO: should the detailed headers on these scripts be fully supplanted by the contents of this README?

TODO: I'm going to have to write more on dataduck, potentially rename the package and come up with a mroe strategic vision for it and how it can be used in conjunction with these 3(!) related projects.
