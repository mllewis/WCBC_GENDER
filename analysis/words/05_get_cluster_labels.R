# get cluster labels
library(here)
library(tidyverse)

INFILE <- here("data/processed/words/gender_word_tsne_coordinates.csv")
LABEL_OUTPATH <- here("data/processed/words/cluster_labels.csv")

words_df <- read_csv(INFILE)

# function to get cluster labels from human
get_cluster_label <- function(current_df){ 
  print(current_df$word)
  user_cluster_label <- readline(prompt = "Enter cluster label: ")
  user_cluster_label
}

cluster_labels <- words_df %>%
  group_by(cluster_id) %>%
  nest() %>%
  mutate(cluster_label = "") %>%
  mutate(cluster_label = map_chr(data, get_cluster_label)) %>%
  select(cluster_id, cluster_label)

#write_csv(cluster_labels, LABEL_OUTPATH)

