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

  x_max <- 40
  xSamplesDays <- seq(0,1000, 1)
  xSamplesCurve <- seq(0,1000, 0.01)
  samplingFromDelayDistDays <- hospitalisation_to_death_truncated(xSamplesDays)
  samplingFromDelayDistCurve <- hospitalisation_to_death_truncated(xSamplesCurve)
  plot(xSamplesCurve[0:4000], samplingFromDelayDistCurve[0:4000], 
       xlab = "Days after hospitalisation",
       ylab = "P(death on a given day | death)",
       pch = 19, 
       cex.lab = 1.8,
       cex.axis = 1.5,
       type = "l")
  polygon(xSamplesCurve,samplingFromDelayDistCurve,col='skyblue')
  
    #lines(xSamplesCurve, samplingFromDelayDistCurve, col = col2)
  mtext(LETTERS[1], adj = 0, line = 1, cex = 1.4) 
  # legend("topright", legend=c("Non-truncated", "Truncated"),
  #        col=c(col1, col2), lty = 1:1, cex = 1.2)
  
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

plotDelaysSupplementary <- function()
{
  dev.off()
  par(mar=c(4,4,1,1),
      mgp=c(2,0.6,0))
  
  x_max <- 40
  xSamplesDays <- seq(0,1000, 1)
  xSamplesCurve <- seq(0,1000, 0.01)
  samplingFromDelayDistDays <- hospitalisation_to_death(xSamplesDays)
  samplingFromDelayDistCurve <- hospitalisation_to_death(xSamplesCurve)
  plot(xSamplesCurve[0:4000], samplingFromDelayDistCurve[0:4000], 
       xlab = "Days after hospitalisation",
       ylab = "P(death on a given day | death)",
       pch = 19, 
       cex.lab = 1.3,
       cex.axis = 1.3,
       type = "l")
  polygon(xSamplesCurve,samplingFromDelayDistCurve,col=rgb(0.529,0.808,0.922,0.5))
  
  x_max <- 40
  xSamplesDays <- seq(0,1000, 1)
  xSamplesCurve <- seq(0,1000, 0.01)
  samplingFromDelayDistDays <- hospitalisation_to_death_truncated(xSamplesDays)
  samplingFromDelayDistCurve <- hospitalisation_to_death_truncated(xSamplesCurve)
  lines(xSamplesCurve[0:4000], samplingFromDelayDistCurve[0:4000], 
       xlab = "",
       ylab = "",
       pch = 19, 
       cex.lab = 1.3,
       cex.axis = 1.3,
       type = "l")
  polygon(xSamplesCurve,samplingFromDelayDistCurve,col=rgb(1,0.6,0,0.5))
  
   legend("topright", legend=c("Non-truncated", "Truncated"),
          col=c(rgb(0.529,0.808,0.922,0.5), rgb(1,0.6,0,0.5)), lty = 1:1, cex = 1.2)
  
}


