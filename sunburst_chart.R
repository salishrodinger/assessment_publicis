install.packages("sunburstR")
library(sunburstR)
#lecture du fichier csv
path_data <- read.csv(
  "bquxjob_3d9765be_185c749b3cc.csv"
  ,header=T
  ,stringsAsFactors = FALSE
)
# création du sunburst
sunburst(path_data,percent=TRUE,count=TRUE)
