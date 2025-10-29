Full-text article: https://www.tandfonline.com/doi/full/10.1080/10511482.2025.2570727

# 🏡 American Housing Shortfalls: Replication Package

This repository contains the full replication code for [*Changes in Average Household Size and Headship Rates as Indicators of Housing Shortfalls*
by Peter Hepburn and Lorae Stojanovic (2025)](https://www.tandfonline.com/doi/full/10.1080/10511482.2025.2570727). We explain in detail how to replicate the analysis on your personal work environment.

## ⚡ Key Findings

Between 2000 and 2019, the average number of people per U.S. household declined modestly—from 3.47 to 3.37, a 3% decrease. At first glance, this seems to contradict claims of a worsening housing shortage: if household sizes are shrinking, doesn't that imply housing is becoming less scarce?

We take a demographic decomposition approach proposed by Galster (2024) and account for the fact that the U.S. is (among other things) older, more educated, and more racially and ethnically diverse than in 2000. The first two shifts tend to drive down household size, while the latter has potentially mixed effects. We find that:

- **Net of demographic change, Americans live in larger households than before.** For example, the average 45-49-year-old lives in a household of 3.14 persons in the year 2000; by 2019, that had increased to 3.33. ([See Accessory Figure 6](https://github.com/lorae/american-housing-shortfalls/blob/main/output/figures/fig06-accessory-hhsize-age-2per-line.jpeg).)

  We estimate these patterns using granular IPUMS microdata that classify each individual by age, gender, tenure, income, race/ehnicity, education, birthplace, and geography (Constant Public Use Microdata Area). 

- **Even after accounting for all these demographic changes, household size fell less than expected.** As shown in Figure 4 below, these measurable characteristics alone would have predicted a 34% *larger* decline in average household size—to 3.342—than what actually occurred.

![Figure 4: Observed vs. Counterfactual Household Size and Headship Rates](https://github.com/lorae/american-housing-shortfalls/blob/main/output/figures/fig04-observed-counterfactual-bars.jpeg?raw=true)

- **Headship rates tell a similar story.**  The *headship rate* is the share of people counted as "household head" or "person one" in the survye- typically the person who pays the rent or mortgage and serves as the household's primary financial support. For example, if one-third of women age 30-34 is counted as the "person one" in the survey data, then the headship rate among this group is 33%.
  
  Based on the same set of sociodemographic correlates, we would have expected headship rates to rise between 2000 and 2019, from 38.6% to 40.8%. Instead, they slightly *declined*, to 38.2%. This implies that, even after adjusting for population changes, Americans today form fewer independent households than in the past.

  
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

3. Copy the environment file and edit it with your own [IPUMS API key](https://account.ipums.org/api_keys) and [Census API key](https://api.census.gov/data/key_signup.html)

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
    

### Part B: Initialize project for download from IPUMS USA and the U.S. Census

The [IPUMS Terms of Use](https://www.ipums.org/about/terms) precludes us from directly sharing the raw microdata extract, however,
the data used in this analysis is freely available and simple to download after setting up your API key.
A section of our manuscript also references results from the McClure-Schwartz analysis. We produced
these numbers in `src/scripts/mcclure-schwartz-replication-state-surplus.R` and they require a Census API key. 


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

6. Set up your [Census API key](https://api.census.gov/data/key_signup.html). Copy your API key from this website

7. **Open `.Renviron`** and replace `your_ipums_api_key` and `your_census_api_key` with your actual keys.  Do not include quotation marks. 
R will automatically load `.Renviron` when you start a new session. This keeps your API key private and separate 
from the codebase.

    🛑 Important: `.Renviron` is listed in `.gitignore`, so it will not be tracked or uploaded to GitHub — but `example.Renviron` is tracked, so do not put your actual API key in the example file.


### Part C: Run the analysis scripts

8. Source `run-all.R`.

    ```r
    source("run-all.R")
    ```

# File structure

TODO

# Additional notes / Conventions

copy info about _db or _tb suffix on varnames

In general, varnames that are gneerated in this project are all lowercase. varnames from original ipums are uppercase. TODO: formalize this across the code.

