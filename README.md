# 🏡 American Housing Shortfalls: Replication Package

This repository contains the full replication code for *Changes in Average Household Size and Headship Rates as Indicators of Housing Shortfalls*
by Peter Hepburn and Lorae Stojanovic (forthcoming). We explain in detail how to replicate the analysis on your personal work environment.

## ⚡ Quick Start
For experienced users who just want to get the project running right away. If you
have trouble following these steps, please follow the **Detailed Start** guide below.

1. Navigate to the directory where you want the project to be saved and clone both required repos side by side

    ```bash
    cd your/path/to/parent/directory
    ```

    ```bash
    git clone https://github.com/lorae/american-housing-shortfalls american-housing-shortfalls
    git clone https://github.com/lorae/demographr demographr
    ```

2. Enter the main project

    ```bash
    cd american-housing-shortfalls
    ```

3. Copy the environment file and edit it with your own [IPUMS API key](https://account.ipums.org/api_keys)

    ```bash
    cp example.Renviron .Renviron
    # (Windows PowerShell: Copy-Item example.Renviron .Renviron)
    # IMPORTANT: open .Renviron and replace "your_ipums_api_key" with your actual key
    ```

4. Restore dependencies and run the analysis

    Open `american-housing-shortfalls.Rproj` in your preferred IDE, then in the R console:
    
    ```r
    renv::restore()
    source("run-all.R")
    ```
    
## 📎 Detailed Start
Detailed instructions for how to fully install and run this project code on your computer.

###  Part A: Clone the repo and configure the R project

These steps will allow you to install the code on your computer that runs this project and set up the environment so that it mimics the environment on which the code was developed.

1. **Clone the repo**: Open a terminal on your computer. Navigate to the directory you would like to be the parent directory of the repo, then clone the repo.

    MacOS/Linux:
    
    ```cmd
    cd your/path/to/parent/directory
    ```
    ```cmd
    git clone https://github.com/lorae/american-housing-shortfalls american-housing-shortfalls
    ```
    
    Windows:
    
    ```bash
    cd your\path\to\parent\directory
    ```
    ```bash
    git clone https://github.com/lorae/american-housing-shortfalls american-housing-shortfalls
    ```

2. **Open the R project**: Navigate into the directory, now located at `your/path/to/parent/directory/american-housing-shortfalls`.
Open `american-housing-shortfalls.Rproj` using your preferred IDE for R. (We use R Studio.)

    Every subsequent time you work with the project code, you should always open the `american-housing-shortfalls.Rproj` file
    at the beginning of your work session. This will avoid common issues with broken file paths or an incorrect working directory.

3. **Initialize R environment**: Install all the dependencies (packages) needed to make the code run on your computer. 
Depending on which packages you may have already installed on your computer, this setup step may take from a few minutes to over 
an hour.

    First, ensure you have the package manager, `renv`, installed. Run the following in your R console:
    
    ```r
    install.packages("renv") # Safe to run, even if you're not sure if you already have renv
    ```
    ```r
    library("renv")
    ```
    
    Then load all the packages needed for the project:
    
    ```r
    renv::activate()
    renv::restore()
    ```
    
    When it asks if you want to proceed, type `y` for "yes".

### Part B: Download raw data from IPUMS USA

The [IPUMS Terms of Use](https://www.ipums.org/about/terms) precludes us from directly sharing the raw microdata extract, however,
the data used in this analysis is freely available and simple to download after setting up an IPUMS USA account. In this step,
we explain this process and how to "order" a data extract that exactly matches the one used in this study.

4. **Copy the file** `example.Renviron` to a new file named `.Renviron` in the project root directory. 
You can do this manually or use the following terminal commands:

    MacOS/Linux:
    
    ```bash
    cp example.Renviron .Renviron
    ```
    
    Windows:
    
    ```cmd
    copy example.Renviron .Renviron
    ```
    
5. **Set up your IPUMS USA API key**: If you don't already have one, set up a free account on 
[IPUMS USA](https://uma.pop.umn.edu/usa/user/new). Use the new account to login to the 
[IPUMS API Key](https://account.ipums.org/api_keys) webpage. Copy your API key from this webpage.

6. **Open `.Renviron`** and replace `your_ipums_api_key` with your actual key.  Do not include quotation marks. 
R will automatically load `.Renviron` when you start a new session. This keeps your API key private and separate 
from the codebase.

    🛑 Important: `.Renviron` is listed in `.gitignore`, so it will not be tracked or uploaded to GitHub — but `example.Renviron` is tracked, so do not put your actual API key in the example file.


### Part C: Run the analysis scripts

The code for this project is stored in the `src` folder. Code is divided into two main directories: `scripts` and `utils`. The `scripts` directory contains executable code which runs the analyses. The `utils` foler contains necessary accessory modules, typically in the form of functions, that are sourced when certain scripts run. These functions are separated due to their complexity. Code underlying them can be inspected more directly when they are isolated, and they are subject to a battery of unit tests.


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


# Running the code



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
