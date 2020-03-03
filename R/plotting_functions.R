col1 <- "#E69F00"
col2 <- "#56B4E9"
col3 <- "#009E73"
col4 <- "#F0E442"
col5 <- "#0072B2"
col6 <- "#D55E00"
col7 <- "#CC79A7"

master_plot <- function(data_in, 
                        startIntCFR,
                        startIntCD, 
                        legendPosition,
                        delay_dist)
{

  dev.off()
  #layout(matrix(c(1,
  #                 2,
  #                 3
  # ),
  # nrow=3, byrow=TRUE))
  
  layout(matrix(c(1, 2,
                  3, 3,
                  4, 4,
                  5, 5),
                nrow=4, byrow=TRUE))  
  
  par(oma = c(1,1,1,1) + 0.5,
      mar = c(0,0,1,1) + 0.1)

  
  cCFRTimeSeriesOutput <- computecCFRTimeSeries(data_in, delay_dist)
  
  IFRFigures <-  cCFRTimeSeriesOutput[,-1]*301/619
  cIFRTimeSeriesOutput <- data.frame(date = cCFRTimeSeriesOutput$date)
  cIFRTimeSeriesOutput <- cbind(cIFRTimeSeriesOutput, IFRFigures)

  plotDelays()
  subPlt1 <- plotCFRTimeSeries(cIFRTimeSeriesOutput, cCFRTimeSeriesOutput, startIntCFR, legendPosition)
  subPlt2 <- plotCaseIncidence(data_in, startIntCD)
  subPlt3 <- plotDeathIncidence(data_in, startIntCD)
  
  
  #outputEstimates <- cbind(tail(nCFRTimeSeriesOutput, n = 1), tail(cCFRTimeSeriesOutput, n = 1))
  
}

plotDelays <- function()
{
  
  par(mar=c(3,4,1,1),mgp=c(2,0.6,0))
  xSamplesDays <- seq(0,40, 1)
  xSamplesCurve <- seq(0,40, 0.1)
  samplingFromDelayDistDays <- onset_to_death(xSamplesDays)
  samplingFromDelayDistCurve <- onset_to_death(xSamplesCurve)
  plot(xSamplesDays, samplingFromDelayDistDays, 
       xlab = "Days after confirmation",
       pch = 19, 
       ylab = "P(death on a given day | death)",
       cex.lab = 2,
       cex.axis = 1.5)
  lines(xSamplesCurve, samplingFromDelayDistCurve)
  mtext(LETTERS[1], adj = 0, line = 1, cex = 1.5) 
  
  par(mar = c(3,4,1,1),mgp = c(2,0.6,0))
  xSamplesDays <- seq(0,40, 1)
  xSamplesCurve <- seq(0,40, 0.1)
  samplingFromDelayDistDays <- onset_to_death_truncated(xSamplesDays)
  samplingFromDelayDistCurve <- onset_to_death_truncated(xSamplesCurve)
  plot(xSamplesDays, samplingFromDelayDistDays, 
       xlab = "Days after confirmation",
       pch = 19, 
       ylab = "",
       cex.lab = 2,
       cex.axis = 1.5)
  lines(xSamplesCurve, samplingFromDelayDistCurve)
  mtext(LETTERS[2], adj = 0, line = 1, cex = 1.5) 
  
}


plotCFRTimeSeries <- function(ncfr_data_in, 
                              ccfr_data_in, 
                              startIntCFR, 
                              legendPosition,
                              extraSubLabelSpace)
{

  endInt   <- length(ncfr_data_in$date)
  
  if(min(ncfr_data_in$ci_low, ccfr_data_in$ci_low)!= 0)
  {
    ylimMin <- min(ncfr_data_in$ci_low, ccfr_data_in$ci_low) 
  }
  else
  {
    ylimMin <- 0
  }
  
  ylimMax  <- max(ncfr_data_in$ci_high[startIntCFR:endInt], ccfr_data_in$ci_high[startIntCFR:endInt])
            + 0.1 * max(ncfr_data_in$ci_high[startIntCFR:endInt], ccfr_data_in$ci_high[startIntCFR:endInt])
  
  #par(oma = c(4, 4, 0, 0)) # make room (i.e. the 4's) for the overall x and y axis titles
  #par(mar = c(2, 2, 1, 1)) # make the plots be closer together
  par(mar=c(3,4,1,1),mgp=c(2,0.6,0))
  par(xpd=FALSE)
    plotCI(x = ncfr_data_in$date[startIntCFR:endInt],
         y = ncfr_data_in$ci_mid[startIntCFR:endInt],
         li = ncfr_data_in$ci_low[startIntCFR:endInt],
         ui = ncfr_data_in$ci_high[startIntCFR:endInt],
         xlab = "", 
         ylab = "",
         ylim = c(ylimMin,ylimMax),
         cex.lab = 2,
         cex.axis = 1.8)
  lines(x = ncfr_data_in$date[startIntCFR:endInt], 
        ncfr_data_in$ci_mid[startIntCFR:endInt],
        col = col2)
  grid(ny = NULL, nx = 0, col = rgb(0.9,0.9,0.9), lty = "solid")
  par(xpd=TRUE)
  #text(ncfr_data_in$date[startInt] + 0.6 , 3.8, "A", cex = 1.5)
  
  par(new=T)
  
  par(xpd=FALSE)
  #par(oma = c(4, 4, 0, 0)) # make room (i.e. the 4's) for the overall x and y axis titles
  #par(mar = c(2, 2, 1, 1)) # make the plots be closer together
  par(mar = c(3,4,1,1),mgp = c(2,0.6,0))
  plotCI(x = ccfr_data_in$date[startIntCFR:endInt],
         y = ccfr_data_in$ci_mid[startIntCFR:endInt],
         li = ccfr_data_in$ci_low[startIntCFR:endInt],
         ui = ccfr_data_in$ci_high[startIntCFR:endInt], 
         xlab = "",
         ylab = "CFR (%)",
         ylim = c(ylimMin,ylimMax),
         cex.lab = 2,
         cex.axis = 1.8)
  lines(x = ccfr_data_in$date[startIntCFR:endInt], 
        ccfr_data_in$ci_mid[startIntCFR:endInt], col = col3)
  legend(legendPosition, legend=c("corrected IFR", "corrected CFR"),
         col=c(col2, col3), lty = 1:1, cex = 1.5)
  mtext(LETTERS[3], adj = 0, line = 1, cex = 1.5) 
}


plotCaseIncidence <- function(data_in_raw, startIntCD)
{
  endInt <- length(data_in_raw$date)
  par(xpd=FALSE)
  plot(x = data_in_raw$date[startIntCD:endInt],
       data_in_raw$new_cases[startIntCD:endInt],
       xlab = "",
       ylab = "Daily confirmed cases",
       cex.lab = 2,
       cex.axis = 1.8)
  lines(x = data_in_raw$date[startIntCD:endInt], data_in_raw$new_cases[startIntCD:endInt], col = col5)
  par(mar=c(3,4,1,1),mgp=c(2,0.6,0))
  #par(oma = c(4, 4, 0, 0)) # make room (i.e. the 4's) for the overall x and y axis titles
  #par(mar = c(2, 2, 1, 1)) # make the plots be closer together
  grid(ny = NULL, nx = 0, col = rgb(0.9,0.9,0.9), lty = "solid")
  par(xpd=TRUE)
  mtext(LETTERS[4], adj = 0, line = 1, cex = 1.5) 
  #text(data_in_raw$date[1] + 1 , 115, "C", cex = 1.5)
  
}

plotDeathIncidence <- function(data_in_raw, startIntCD)
{
  endInt <- length(data_in_raw$date)
  par(xpd=FALSE)
  plot(x = data_in_raw$date[startIntCD:endInt], 
       data_in_raw$new_deaths[startIntCD:endInt],
       xlab = "Date",
       ylab = "Daily deaths",
       cex.lab = 2,
       cex.axis = 1.8,
       yaxp = c(0, 2, 2), 
       tick.ratio = 2)
  lines(x = data_in_raw$date[startIntCD:endInt], data_in_raw$new_deaths[startIntCD:endInt], col = col6)
  par(xpd=TRUE)
  mtext(LETTERS[5], adj = 0, line = 1, cex = 1.5) 
  #text(data_in_raw$date[1] + 1 , 1.95, "D", cex = 1.5)
  
}

