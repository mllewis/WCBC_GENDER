# get word frequency across kidbook corpus

library(tidyverse)
library(tidytext)
library(here)

TIDY_CORPUS <- here("data/processed/books/tidy_full_corpus_all.csv")
OUTFILE <- here("data/processed/books/all_corpus_word_frequency.csv")

tidy_corpus <- read_csv(TIDY_CORPUS)

word_counts <- tidy_corpus %>%
  count(word) %>%
  mutate(log_kidbook_freq = log(n)) %>%
  select(word, log_kidbook_freq)


write_csv(word_counts, OUTFILE)
