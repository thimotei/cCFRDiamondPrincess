# setting up colours to be used in the plots

col1 <- "#E69F00"
col2 <- "#56B4E9"
col3 <- "#009E73"
col4 <- "#F0E442"
col5 <- "#0072B2"
col6 <- "#D55E00"
col7 <- "#CC79A7"

# master function which when run makes Figure 1

master_plot <- function(data_in, 
                        startIntCFR,
                        startIntCD, 
                        legendPosition,
                        delay_dist)
{

  dev.off()
  layout(matrix(c(1,
                  2,
                  3),
                nrow=3, byrow=TRUE))  
  
  par(oma = c(1,1,1,1) + 0.5,
      mar = c(0,0,1,1) + 0.1)

  plotDelays()

  subPlt2 <- plotCaseIncidence(data_in, startIntCD)
  subPlt3 <- plotDeathIncidence(data_in, startIntCD)
  
  
}


#plotting function to plot the delay distributions
plotDelays <- function()
{
  
  par(mar=c(4,4,1,1),
      mgp=c(2,0.6,0))
  xSamplesDays <- seq(0,40, 1)
  xSamplesCurve <- seq(0,40, 0.1)
  samplingFromDelayDistDays <- hospitalisation_to_death(xSamplesDays)
  samplingFromDelayDistCurve <- hospitalisation_to_death(xSamplesCurve)
  plot(xSamplesDays, samplingFromDelayDistDays, 
       xlab = "Days after hospitalisation",
       pch = 19, 
       ylab = "P(death on a given day | death)",
       cex.lab = 1.8,
       cex.axis = 1.5)
  lines(xSamplesCurve, samplingFromDelayDistCurve, col = col1)

  xSamplesDays <- seq(0,40, 1)
  xSamplesCurve <- seq(0,40, 0.1)
  samplingFromDelayDistDays <- hospitalisation_to_death_truncated(xSamplesDays)
  samplingFromDelayDistCurve <- hospitalisation_to_death_truncated(xSamplesCurve)
  points(xSamplesDays, samplingFromDelayDistDays, 
       xlab = "Days after hospitalisation",
       pch = 19, 
       ylab = "",
       cex.lab = 1.8,
       cex.axis = 1.5)
  lines(xSamplesCurve, samplingFromDelayDistCurve, col = col2)
  mtext(LETTERS[1], adj = 0, line = 1, cex = 1.4) 
  legend("topright", legend=c("Non-truncated", "Truncated"),
         col=c(col1, col2), lty = 1:1, cex = 1.2)
  
}

# plotting function to plot the case epicurve
plotCaseIncidence <- function(data_in_raw, startIntCD)
{

  par(mar = c(4,4,1,1))
  barplot(cruise_ship_by_confirmation$new_cases,
          names.arg=cruise_ship_by_confirmation$date,
          col = col5, 
          ylim = c(0,max(cruise_ship_by_confirmation$new_cases)),
          xlab = "Date",
          ylab = "Daily confirmed cases",
          cex.lab = 1.8,
          cex.axis = 1.5,
          las = 1)
  mtext(LETTERS[2], adj = 0, line = 1, cex = 1.4) 
  
}

# plotting function to plot the death epicurve
plotDeathIncidence <- function(data_in_raw, startIntCD)
{

  par(mar = c(4,4,1,1))
  barplot(cruise_ship_by_confirmation$new_deaths,
          names.arg=cruise_ship_by_confirmation$date,
          col = col6,
          ylim = c(0,max(cruise_ship_by_confirmation$new_deaths)),
          xlab = "Date",
          ylab = "Daily deaths",
          yaxt = 'n',
          cex.lab = 1.8,
          cex.axis = 1.5)
          at1 <- seq(0, 2, 1)
          axis(side =2, at1, labels = T, las = 1, cex.lab = 1.8, cex.axis = 1.5)
  mtext(LETTERS[3], adj = 0, line = 1, cex = 1.4) 
  
}
