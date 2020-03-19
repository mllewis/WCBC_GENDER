# get text file corpus for training models where each book is on new line
library(tidyverse)
library(here)

INFILE <- here("data/processed/books/tidy_full_corpus_all.csv")
OUTFILE <- here("exploratory_analyses/5_IAT_tests/corpora/kidbook_training_corpus.txt")

raw_data <- read_csv(INFILE)

corpus_data <- raw_data %>%
  select(book_id, word) %>%
  group_by(book_id) %>%
  summarize(book_text = paste0(word, collapse = " "))

write_lines(corpus_data$book_text, OUTFILE)


