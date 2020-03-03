library(bbmle)
library(plotrix)
library(fitdistrplus)

source("R/cCFR_calculation.R")


#importing case and death data
cruise_ship_by_confmation <- read.csv("data/cruise_ship_data/cruise_ship_diamond_princess_by_confirmation.csv")

# importing the age-stratified scale factors
cruise_ship_SFs <- read.csv("data/cruise_ship_data/age_scale_factors.csv")

cruise_ship_by_confmation$date <- as.Date(cruise_ship_by_confmation$date)

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
master_plot(cruise_ship_by_confmation, 1, 16, "topright", hospitalisation_to_death_truncated)




