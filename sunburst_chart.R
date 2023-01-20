install.packages("sunburstR")
library(sunburstR)
# Lecture du fichier csv
path_data <- read.csv(
  "bquxjob_3d9765be_185c749b3cc.csv",
  header = TRUE,
  stringsAsFactors = FALSE)

# Cleaning des libellés des légendes
path_data$full_journey <- gsub("_", " ", path_data$full_journey)
path_data$full_journey <- toupper(path_data$full_journey)

# Création du sunburst
sunburst(path_data, percent = TRUE, count = TRUE)