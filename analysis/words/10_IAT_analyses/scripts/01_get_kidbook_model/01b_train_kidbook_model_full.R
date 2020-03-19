### get model for full kid corpus

# load packages etc
library(tidyverse)
library(data.table)
library(here)
library(reticulate)
source(here("exploratory_analyses/5_IAT_tests/scripts/cluster_helpers.R"))
use_python("/usr/local/bin/python") # reticulate stuff - only necessary for gensim
gensim <- import("gensim")

# paths
CORPUS_PATH_kid <-  here("exploratory_analyses/5_IAT_tests/data/corpora/kidbook_training_corpus.txt")
KIDOUT <- here("exploratory_analyses/5_IAT_tests/data/models/trained_kid_model_5_count.csv")

# (3) Train the model on kid and adult data
# set params
MODEL_TYPE <- "gensim" # gensim or WV
VECTORS <- 300L
THREADS <- 1L
ITER <- 50L #1L
WINDOW <- 20L
MIN_COUNT <- 5L

kid_trained_model <- train_the_model(CORPUS_PATH_kid, VECTORS, THREADS, ITER,
                                 WINDOW, MIN_COUNT, negative = 20, MODEL_TYPE)

tidy_kid_model <- bind_cols(
         as_tibble(kid_trained_model$wv$index2word) %>% rename(word = value),
          as_tibble(kid_trained_model$wv$syn0))


write_csv(tidy_kid_model, KIDOUT)
