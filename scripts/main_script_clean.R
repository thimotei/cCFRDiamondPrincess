# parameters for the truncated distribution - used for the estimates in the main text

zMean <- 13
zMeanLowerLim <- 8.7
zMeanUpperLim <- 20.9
zSD <- 12.7
zMedian <- 9.1
zMedianLowerLim <- 6.7
zMedianUpperLim <- 13.7

# parameters for the truncated distribution - used for the estimates in the main text

zMeanNonT <- 8.6
zMeanNonTLowerLim <- 6.8
zMeanNonTUpperLim <- 10.8
zSDNonT <- 6.7
zMedianNonT <- 6.7
zMedianNonTLowerLim <- 5.3
zMedianNonTUpperLim <- 8.3


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

hospitalisationToDeath     <- function(x) delayFunCum(x, zMeanNonT, zMedianNonT)
hospitalisationToDeathLow  <- function(x) delayFunCum(x, zMeanNonTLowerLim, zMedianNonTLowerLim)
hospitalisationToDeathMid1 <- function(x) delayFunCum(x, zMeanNonTLowerLim, zMedianNonTUpperLim)
hospitalisationToDeathMid2 <- function(x) delayFunCum(x, zMeanNonTUpperLim, zMedianNonTLowerLim)
hospitalisationToDeathHigh <- function(x) delayFunCum(x, zMeanNonTUpperLim, zMedianNonTUpperLim)


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


# Get data - DEPRACTED
allDat <- NCoVUtils::get_ecdc_cases()
allDatDesc <- allDat %>% 
  dplyr::arrange(country, date) %>% 
  dplyr::mutate(date = lubridate::ymd(date)) %>% 
  dplyr::rename(new_cases = cases, new_deaths = deaths) %>%
  dplyr::select(date, country, new_cases, new_deaths) %>%
  dplyr::filter(country == "Cases_on_an_international_conveyance_Japan") %>%
  dplyr::filter(date <= "2020-03-05" & date >= "2020-02-05")

# age correction on old data - DEPRACTED 
ageCorrectedDat <- allDatDesc %>% 
  dplyr::mutate(new_cases = round(new_cases*propOver70Cases),
                new_deaths = new_deaths*propOver70Deaths)


# updated data - CURRENT
newData <- read.csv("data/up_to_date.csv")
newData$date <- as.Date(newData$date)
newData <- subset(newData,date <= "2020-03-05" & date >= "2020-02-05")

# age correction on updated data - CURRENT
ageCorrectedDatNew <- newData %>% 
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

# analysis for the main text - up to the 5th March and corrected for
IFREstimateFun(newData, hospitalisationToDeathTruncated)

#  all-age estimates
medianEstimateNew <- IFREstimateFun(newData,hospitalisationToDeathTruncated)
lowEstimateNew    <- IFREstimateFun(newData,hospitalisationToDeathTruncatedLow) 
midEstimateNew    <- IFREstimateFun(newData,hospitalisationToDeathTruncatedMid2)
highEstimateNew   <- IFREstimateFun(newData,hospitalisationToDeathTruncatedHigh)

allIFREstimatesNew <- dplyr::bind_rows(medianEstimateNew, lowEstimateNew, midEstimateNew, highEstimateNew) %>% 
  dplyr::tibble()

allIFREstimatesNew <-  allIFREstimatesNew$.
allIFREstimatesNewPrecise <-  signif((allIFREstimates)*100, 2)

allCFREstimatesNew <- signif(allIFREstimatesNew*propSymptomatic*100,2) %>% dplyr::tibble()
allCFREstimatesNew <- allCFREstimatesNew$. %>% dplyr::rename(cCFR = cIFR, cCFRLowerCI = cIFRLowerCI, cCFRUpperCI = cIFRUpperCI)

reportedIFREstimatesNew <- dplyr::tibble(cIFR = allIFREstimatesNewPrecise[1,1], cIFRLowerCI = min(allIFREstimatesNewPrecise$cIFRLowerCI), cIFRUpperCI = max(allIFREstimatesNewPrecise$cIFRUpperCI))
reportedCFREstimatesNew <- dplyr::tibble(cCFR = allCFREstimatesNew[1,1], cCFRLowerCI = min(allCFREstimatesNew$cCFRLowerCI), cCFRUpperCI = max(allCFREstimatesNew$cCFRUpperCI))

# age-corrected estimates
above70cIFRNew <- IFREstimateFun(ageCorrectedDatNew, hospitalisationToDeathTruncated)
above70cIFRNew <-  signif((above70cIFRNew)*100, 2)

reportedcIFREstimatesAgeNew <-  dplyr::tibble(cIFR = above70cIFRNew[1,1], 
                                          cIFRLowerCI = above70cIFRNew[1,2],
                                          cIFRUpperCI = above70cIFRNew[1,3])

reportedcCFREstimatesAgeNew <-  signif(dplyr::tibble(cIFR = above70cIFRNew[1,1]*propSymptomatic, 
                                          cIFRLowerCI = above70cIFRNew[1,2]*propSymptomatic,
                                          cIFRUpperCI = above70cIFRNew[1,3]*propSymptomatic),2)

reportedcIFREstimatesNew
reportedcCFREstimatesNew
reportedcIFREstimatesAgeNew
reportedcCFREstimatesAgeNew

## make plot 
source("R/plotting_functions.R")
plot(1)
master_plot(newData, delay_dist = hospitalisationToDeathTruncatedPDF)

#  estimates using all of the data - for the SUPPLEMENTARY MATERIAL
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

reportedIFREstimatesSupp <- dplyr::tibble(cIFR = allIFREstimatesPrecise[1,1], cIFRLowerCI = min(allIFREstimatesPrecise$cIFRLowerCI), cIFRUpperCI = max(allIFREstimatesPrecise$cIFRUpperCI))
reportedCFREstimatesSupp <- dplyr::tibble(cCFR = allCFREstimates[1,1], cCFRLowerCI = min(allCFREstimates$cCFRLowerCI), cCFRUpperCI = max(allCFREstimates$cCFRUpperCI))

# age-corrected estimates
above70cIFR <- IFREstimateFun(ageCorrectedDat, hospitalisationToDeathTruncated)
above70cIFRPrecise <-  signif((above70cIFR)*100, 2)


reportedcIFREstimatesSupp <-  signif(dplyr::tibble(cIFR = above70cIFR[1,1]*100, 
                                           cIFRLowerCI = above70cIFR[1,2]*100,
                                           cIFRUpperCI = above70cIFR[1,3]*100),2)

reportedcCFREstimatesSupp <-  signif(dplyr::tibble(cIFR = above70cIFR[1,1]*propSymptomatic*100, 
                                                  cIFRLowerCI = above70cIFR[1,2]*propSymptomatic*100,
                                                  cIFRUpperCI = above70cIFR[1,3]*propSymptomatic*100),2)

reportedIFREstimatesSupp
reportedCFREstimatesSupp
reportedcIFREstimatesSupp
reportedcCFREstimatesSupp

#  estimates using all of the data - non-truncated distribution - for the SUPPLEMENTARY MATERIAL
medianEstimateNonT <- IFREstimateFun(allDatDesc,hospitalisationToDeath)
lowEstimateNonT    <- IFREstimateFun(allDatDesc,hospitalisationToDeathLow) 
midEstimateNonT    <- IFREstimateFun(allDatDesc,hospitalisationToDeathMid2)
highEstimateNonT   <- IFREstimateFun(allDatDesc,hospitalisationToDeathHigh)

allIFREstimatesNonT <- dplyr::bind_rows(medianEstimateNonT, lowEstimateNonT, midEstimateNonT, highEstimateNonT) %>% 
  dplyr::tibble()

allIFREstimatesNonT <-  allIFREstimatesNonT$.
allIFREstimatesPreciseNonT <-  signif((allIFREstimatesNonT)* 100, 2)

allCFREstimatesNonT <- signif(allIFREstimatesNonT*propSymptomatic*100,2) %>% dplyr::tibble()
allCFREstimatesNonT <- allCFREstimatesNonT$. %>% dplyr::rename(cCFR = cIFR, cCFRLowerCI = cIFRLowerCI, cCFRUpperCI = cIFRUpperCI)

reportedIFREstimatesSuppNonT <- dplyr::tibble(cIFR = allIFREstimatesPreciseNonT[1,1], cIFRLowerCI = min(allIFREstimatesPreciseNonT$cIFRLowerCI), cIFRUpperCI = max(allIFREstimatesPreciseNonT$cIFRUpperCI))
reportedCFREstimatesSuppNonT <- dplyr::tibble(cCFR = allCFREstimatesNonT[1,1], cCFRLowerCI = min(allCFREstimatesNonT$cCFRLowerCI), cCFRUpperCI = max(allCFREstimatesNonT$cCFRUpperCI))

# age-corrected estimates
above70cIFRNonT <- IFREstimateFun(ageCorrectedDat, hospitalisationToDeath)
above70cIFRPreciseNonT <-  signif((above70cIFRNonT)*100, 2)


reportedcIFREstimatesSuppNonT <-  signif(dplyr::tibble(cIFR = above70cIFRNonT[1,1]*100, 
                                                   cIFRLowerCI = above70cIFRNonT[1,2]*100,
                                                   cIFRUpperCI = above70cIFRNonT[1,3]*100),2)

reportedcCFREstimatesSuppNonT <-  signif(dplyr::tibble(cIFR = above70cIFRNonT[1,1]*propSymptomatic*100, 
                                                   cIFRLowerCI = above70cIFRNonT[1,2]*propSymptomatic*100,
                                                   cIFRUpperCI = above70cIFRNonT[1,3]*propSymptomatic*100),2)

reportedIFREstimatesSuppNonT
reportedCFREstimatesSuppNonT
reportedcIFREstimatesSuppNonT
reportedcCFREstimatesSuppNonT

