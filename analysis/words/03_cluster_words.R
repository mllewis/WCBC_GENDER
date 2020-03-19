### Clustering gender words based on wiki semantics, and identifiying gendered clusters
library(tidyverse)
library(data.table)
library(here)
library(broom)

INFILE <- here("data/processed/words/gender_ratings_mean.csv")
MODELPATH <- "/Users/mollylewis/Documents/research/Projects/1_in_progress/VOCAB_SEEDS/analyses/0_exploration/wiki.en.vec"
N_CLUSTERS <- 100
OUTFILE_WORDS <- here("data/processed/words/gender_word_tsne_coordinates.csv")
OUTFILE_CENTROIDS <- here("data/processed/words/gender_centroids_tsne_coordinates.csv")

# read in gender ratings
gender_words <- read_csv(INFILE)
mean_rating_no_sense <- gender_words %>%
  mutate(word = map_chr(word, ~unlist(str_split(.x, " "))[[1]]),
         word = tolower(word),
         word = str_remove_all(word, '[:punct:]')) %>%
  distinct(word, .keep_all = T) %>%
  group_by(word) %>%
  summarize(gender = mean(mean))

# read in model
model <- fread(
  MODELPATH,
  header = FALSE,
  skip = 1,
  quote = "",
  encoding = "UTF-8",
  data.table = TRUE,
  col.names = c("word",
                unlist(lapply(2:301, function(x) paste0("V", x))))) %>%
  mutate(word = tolower(word))

# merge model and gender ratings
words_with_embeddings <- model %>% # 2321
  right_join(mean_rating_no_sense)  %>%
  filter(!is.na(V2))

raw_tsne = Rtsne::Rtsne(words_with_embeddings[,2:301])
word_df <- raw_tsne$Y %>%
  as.data.frame() %>%
  rename(tsne_X = V1,
         tsne_Y = V2)  %>%
  mutate(word = words_with_embeddings$word,
         gender = words_with_embeddings$gender)

# get clusters
clustersF <- kmeans(scale(word_df[-3:-4]), N_CLUSTERS)
word_df$cluster_id = factor(clustersF$cluster)

write_csv(word_df, OUTFILE_WORDS)

