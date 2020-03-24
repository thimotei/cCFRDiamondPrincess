zMean <- 13
zMeanLowerLim <- 8.7
zMeanUpperLim <- 20.9
zSD <- 12.7
zMedian <- 9.1
zMedianLowerLim <- 6.7
zMedianUpperLim <- 13.7
propSymptomatic <- 619/309
propOver70Cases <- 124/619
propOver70Deaths <- 7/7


# Lognormal CDF parameterised according to the hospitalisation-to-death 
# distributions in Linton et al. (2020)
delayFun <- function(x, mean, median)
{
  mu <- log(median)
  sigma <- sqrt(2*(log(mean) - mu))
  dlnorm(x, mu, sigma)
}

delayFunCum <- function(x, mean, median)
{
  mu <- log(median)
  sigma <- sqrt(2*(log(mean) - mu))
  plnorm(x, mu, sigma)
}

# all combinations of the hospitalisation-to-death distibution - 
# used to calculate the minimum and maximum CIs. First is the PDF, the rest are CDFs
hospitalisationToDeathTruncatedPDF  <- function(x) delayFun(x, zMean, zMedian)
hospitalisationToDeathTruncated     <- function(x) delayFunCum(x, zMean, zMedian)
hospitalisationToDeathTruncatedLow  <- function(x) delayFunCum(x, zMeanLowerLim, zMedianLowerLim)
hospitalisationToDeathTruncatedMid1 <- function(x) delayFunCum(x, zMeanLowerLim, zMedianUpperLim)
hospitalisationToDeathTruncatedMid2 <- function(x) delayFunCum(x, zMeanUpperLim, zMedianLowerLim)
hospitalisationToDeathTruncatedHigh <- function(x) delayFunCum(x, zMeanUpperLim, zMedianUpperLim)

# Function to work out corrected CFR
scale_cfr <- function(data_1_in, delay_fun){
  case_incidence <- data_1_in$new_cases
  death_incidence <- data_1_in$new_deaths
  cumulative_known_t <- 0 # cumulative cases with known outcome at time tt
  # calculating CDF between each of the days to determine the probability of death on each day

  for(ii in 1:nrow(data_1_in)){
    known_i <- 0 # number of cases with known outcome at time ii
    for(jj in 0:(ii - 1)){
      known_jj <- case_incidence[ii - jj]*(delay_fun(jj) - delay_fun(jj - 1))
      known_i <- known_i + known_jj
    }
    cumulative_known_t <- cumulative_known_t + known_i # Tally cumulative known
  }
  # naive CFR value
  b_tt <- sum(death_incidence)/sum(case_incidence) 
  # corrected CFR estimator
  p_tt <- sum(death_incidence)/cumulative_known_t
  data.frame(nCFR = b_tt, cIFR = p_tt, total_deaths = sum(death_incidence), 
             cum_known_t = round(cumulative_known_t), total_cases = sum(case_incidence))
}


# Get data
allDat <- NCoVUtils::get_ecdc_cases()
allDatDesc <- allDat %>% 
  dplyr::arrange(country, date) %>% 
  dplyr::mutate(date = lubridate::ymd(date)) %>% 
  dplyr::rename(new_cases = cases, new_deaths = deaths) %>%
  dplyr::select(date, country, new_cases, new_deaths) %>%
  dplyr::filter(country == "Cases_on_an_international_conveyance_Japan") %>%
  dplyr::filter(date <= "2020-03-05" & date >= "2020-02-05")
  
ageCorrectedDat <- allDatDesc %>% 
  dplyr::mutate(new_cases = round(new_cases*propOver70Cases),
                new_deaths = new_deaths*propOver70Deaths)

IFREstimateFun <- function(data, delay_dist){
  data %>%
  padr::pad() %>%
  dplyr::mutate(cum_deaths = sum(new_deaths)) %>%
  dplyr::filter(cum_deaths > 0) %>%
  dplyr::select(-cum_deaths) %>%
  dplyr::do(scale_cfr(., delay_fun = delay_dist)) %>% 
  dplyr::filter(cum_known_t > 0 & cum_known_t >= total_deaths)  %>%
  dplyr::mutate(nCFRLowerCI = binom.test(total_deaths, total_cases)$conf.int[1],
                nCFRupperCI = binom.test(total_deaths, total_cases)$conf.int[2],
                cIFRLowerCI = binom.test(total_deaths, cum_known_t)$conf.int[1],
                cIFRUpperCI = binom.test(total_deaths, cum_known_t)$conf.int[2]) %>%
  dplyr::select(cIFR, cIFRLowerCI, cIFRUpperCI)
}



#  all-age estimates
medianEstimate <- IFREstimateFun(allDatDesc,hospitalisationToDeathTruncated)
lowEstimate    <- IFREstimateFun(allDatDesc,hospitalisationToDeathTruncatedLow) 
midEstimate    <- IFREstimateFun(allDatDesc,hospitalisationToDeathTruncatedMid2)
highEstimate   <- IFREstimateFun(allDatDesc,hospitalisationToDeathTruncatedHigh)

allIFREstimates <- dplyr::bind_rows(medianEstimate, lowEstimate, midEstimate, highEstimate) %>% 
  dplyr::tibble()

allIFREstimates <-  allIFREstimates$.
allIFREstimatesPrecise <-  signif((allIFREstimates)* 100, 2)

allCFREstimates <- signif(allIFREstimates*propSymptomatic*100,2) %>% dplyr::tibble()
allCFREstimates <- allCFREstimates$. %>% dplyr::rename(cCFR = cIFR, cCFRLowerCI = cIFRLowerCI, cCFRUpperCI = cIFRUpperCI)

reportedIFREstimates <- dplyr::tibble(cIFR = allIFREstimatesPrecise[1,1], cIFRLowerCI = min(allIFREstimatesPrecise$cIFRLowerCI), cIFRUpperCI = max(allIFREstimatesPrecise$cIFRUpperCI))
reportedCFREstimates <- dplyr::tibble(cCFR = allCFREstimates[1,1], cCFRLowerCI = min(allCFREstimates$cCFRLowerCI), cCFRUpperCI = max(allCFREstimates$cCFRUpperCI))
   
# age-corrected estimates
above70cIFR <- IFREstimateFun(ageCorrectedDat, hospitalisationToDeathTruncated)
above70cIFRPrecise <-  signif((above70cIFR)*100, 2)

above70cCFR <-  signif((above70cIFR)*propSymptomatic*100, 2)

## make plot 
source("R/plotting_functions.R")
plot(1)
master_plot(allDatDesc, delay_dist = hospitalisationToDeathTruncatedPDF)
