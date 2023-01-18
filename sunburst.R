install.packages("sunburstR")
library(sunburstR)
#read in the .csv file to a data frame
path_data <- read.csv(
  "/Users/sarahlinalachheb/Downloads/test_technique/bquxjob_7089cc7e_185c5e08138.csv"
  ,header=T
  ,stringsAsFactors = FALSE
)

#select the 2 columns needed for the visualisation
df <- path_data[c('full_journey','nb_parcours')]

#create sunburst visualisation
sunburst(df,width='100%', height=600, legend = F)