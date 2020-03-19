# Tidy version fo full corpus
# includes all words

library(tidyverse)
library(tidytext)
library(here)

TIDY_CORPUS <- here("data/processed/books/tidytext_kidbook_corpus.csv")
OUTFILE <- here("data/processed/books/tidy_full_corpus_all.csv")

full_tidy_corpus <-read_csv(TIDY_CORPUS) %>%
  select(book_id, title, author, line_number, word)  %>%
  mutate(corpus_type = "all")

write_csv(full_tidy_corpus, OUTFILE)
