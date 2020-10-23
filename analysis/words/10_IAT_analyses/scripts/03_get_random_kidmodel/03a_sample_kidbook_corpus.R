# get kid corpus with randomized ordering of books (10 samples)

library(tidyverse)
library(here)

KIDBOOK_CORPUS <- here("data/processed/books/tidy_full_corpus_all.csv")
KIDBOOK_CORPUS_FOR_TRAINING_PREFIX <- here("data/processed/iat/corpora/kidbook_sampled/")
N_SAMPLES <- 10

kidbook_corpus <- read_csv(KIDBOOK_CORPUS)

kidbook_corpus_wide <- kidbook_corpus %>%
  group_by(book_id) %>%
  summarize(book_text = paste0(word, collapse = " "))

get_randomized_corpus <- function(sample_id, corpus, outprefix){
  randomized_corpus <- corpus %>%
    sample_frac(1L)

  full_outpath <- paste0(outprefix,"sampled_kidbook_", sample_id, ".txt")
  writeLines(randomized_corpus$book_text, full_outpath)
}

walk(1:N_SAMPLES, get_randomized_corpus,
     kidbook_corpus_wide,
     KIDBOOK_CORPUS_FOR_TRAINING_PREFIX)
