install.packages("sunburstR")
library(sunburstR)
#read in the .csv file to a data frame
path_data <- read.csv(
  "/Users/sarahlinalachheb/Downloads/test_technique/bquxjob_3d9765be_185c749b3cc.csv"
  ,header=T
  ,stringsAsFactors = FALSE
)
#create sunburst visualisation
sunburst(path_data,percent=TRUE,count=TRUE)
