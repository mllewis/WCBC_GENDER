# load packages etc
library(tidyverse)
library(data.table)
library(here)
library(reticulate)
library(glue)
source(here("analysis/words/10_IAT_analyses/scripts/cluster_helpers.R"))
gensim <- import("gensim")

# paths
CORPORA_PATH <-   here("data/processed/iat/corpora/kidbook_sampled/sampled_kidbook_")
MODEL_OUT_PATH <- here("data/processed/iat/models/trained_sampled_kidbook/trained_sampled_kidbook_5_count_")
N_SAMPLES <- 10

train_one_corpus <- function(id, corpus_path, model_path){
  full_corpus_path <- glue("{corpus_path}{id}.txt")

  # set params
  MODEL_TYPE <- "gensim" # gensim or WV
  VECTORS <- 300L
  THREADS <- 1L
  ITER <- 50L #1L
  WINDOW <- 20L
  MIN_COUNT <- 5L

  trained_model <- train_the_model(full_corpus_path, VECTORS, THREADS, ITER,
                                   WINDOW, MIN_COUNT, negative = 20, MODEL_TYPE)

  tidy_trained_model <- bind_cols(
           as_tibble(trained_model$wv$index2word) %>% rename(word = value),
           as_tibble(trained_model$wv$syn0))

  full_model_out_path <- glue("{model_path}{id}.csv")
  write_csv(tidy_trained_model, full_model_out_path)
}

walk(1:N_SAMPLES, train_one_corpus, CORPORA_PATH, MODEL_OUT_PATH)
