# Corporatization of NYC Property: Data Analysis 
This repository includes all of the code for the "The Corporatization of NYC Real Estate" data report published by JustFix. 

[VIEW REPORT LIVE](https://medium.com/justfixnyc/corporatization-of-nyc-real-estate-83e2bf191b73)


## Running the analysis

After cloning this repository, follow these steps to run the analysis in full:

### Step 1: Connecting to nycdb PostGreSQL database

In order to run the SQL queries referenced in this analysis, you will need to set up a copy of the [nycdb PostGreSQL database](https://github.com/nycdb/nycdb) on your local computer. You can visit the [nycdb README](https://github.com/nycdb/nycdb/blob/main/src/README.md) for documentation on how to create your own copy of the database locally. Alternatively, if you have access to a remote version of the database, you can just make note of those authentication credentials.

In order to connect to nycdb, make a copy of the [Renviron.sample](https://github.com/JustFixNYC/landlords-over-time/blob/main/Renviron.sample) file and save it as `.Renviron` in the root directory of this R project. In this new `.Renviron` file, add the `HOST`,`USER`,`PASSWORD`,`PORT`, and `DBNAME` credentials from whatever nycdb database you are connecting to, and then save the file. 

### Step 2: Running the analysis

Once all of the nycdb credentials are configured, you should be good to go to run the analysis. Make sure you have [R installed](https://www.r-project.org/) on your computer—or better yet, install [R Studio](https://www.rstudio.com/). Then, just open up [corporatization_of_nyc_property.R](https://github.com/JustFixNYC/landlords-over-time/blob/main/corporatization_of_nyc_property.R) and run the script. If you are using R Studio, make sure your working directory is set to the root directory of this repo. 

## Questions about the data?

For more information about the analysis, please contact the JustFix data team at hello@justfix.nyc.
