library(bbmle)
library(plotrix)
library(fitdistrplus)
library(padr)

source("R/cCFR_calculation.R")


#importing case and death data
cruise_ship_by_confirmation <- read.csv("data/cruise_ship_diamond_princess_by_confirmation.csv")

# importing the age-stratified scale factors
cruise_ship_SFs <- read.csv("data/age_scale_factors.csv")
sfIFR <- cruise_ship_SFs$ifrSF

cruise_ship_by_confirmation$date <- as.Date(cruise_ship_by_confirmation$date)

# age distribution of cruise ship individuals 
cruise_ship_ages <- c(16,23,347, 428,334,398,923,1015,216,11)


# Reproducing the distribution from onset-to-death
# Linton et al. (https://doi.org/10.3390/jcm9020538)

zmean <- 14.5
zsd <- 6.7
zmedian <- 13.2
muOD <- log(zmedian)
sigmaOD <- sqrt( 2*(log(zmean) - muOD) )

onset_to_death <- function(x)
{
  dlnorm(x, muOD, sigmaOD)
}

zmean <- 20.2
zsd <- 11.6
zmedian <- 17.1
muODT <- log(zmedian)
sigmaODT <- sqrt( 2*(log(zmean) - muODT) )

onset_to_death_truncated <- function(x)
{
  dlnorm(x, muODT, sigmaODT)
}


# Estimating distribution from hospitalisation-to-death
# Linton et al. (https://doi.org/10.3390/jcm9020538)

zmean <- 8.6
zsd <- 6.7
zmedian <- 6.7
muHD <- log(zmedian)
sigmaHD <- sqrt( 2*(log(zmean) - muHD) )

hospitalisation_to_death <- function(x)
{
  dlnorm(x, muHD, sigmaHD)
}

zmean <- 13
zsd <- 12.7
zmedian <- 9.1
muHDT <- log(zmedian)
sigmaHDT <- sqrt( 2*(log(zmean) - muHDT) )

hospitalisation_to_death_truncated <- function(x)
{
  dlnorm(x, muHDT, sigmaHDT)
}


source("R/plotting_functions.R")

# running the script for plotting Figure 1 in the main text
master_plot(cruise_ship_by_confirmation, 1, 1, "topright", hospitalisation_to_death_truncated)




# running the code to produce the IFR and CFR estimates quoted in the manuscript
cCFREstimate <- computecCFRTimeSeries(cruise_ship_by_confirmation, hospitalisation_to_death)
cIFREstimate <- data.frame(date = cCFREstimate$date, ci_mid = cCFREstimate$ci_mid*sfIFR[1], ci_low = cCFREstimate$ci_low*sfIFR[1], ci_high = cCFREstimate$ci_high*sfIFR[1])

cases_scaled_by_age <- scale_by_age_distribution_cases(cruise_ship_by_confirmation, cruise_ship_SFs)
deaths_scaled_by_age <- scale_by_age_distribution_deaths(cruise_ship_by_confirmation, cruise_ship_SFs)

ageGroupStratified <- data.frame(date = cruise_ship_by_confirmation$date, new_cases = round(cases_scaled_by_age[,9]), new_deaths = round(deaths_scaled_by_age[,9]))

cCFRAgeGroupStratified <- computecCFRTimeSeries(ageGroupStratified, hospitalisation_to_death)
cCFRTAgeGroupStratified <- computecCFRTimeSeries(ageGroupStratified, hospitalisation_to_death_truncated)

cIFRAgeGroupStratified <- data.frame(date = cCFRAgeGroupStratified$date, ci_mid = cCFRAgeGroupStratified$ci_mid*sfIFR[1], ci_low = cCFRAgeGroupStratified$ci_low*sfIFR[1], ci_high = cCFRAgeGroupStratified$ci_high*sfIFR[1])
cIFRTAgeGroupStratified <- data.frame(date = cCFRTAgeGroupStratified$date, ci_mid = cCFRTAgeGroupStratified$ci_mid*sfIFR[1], ci_low = cCFRTAgeGroupStratified$ci_low*sfIFR[1], ci_high = cCFRTAgeGroupStratified$ci_high*sfIFR[1])



