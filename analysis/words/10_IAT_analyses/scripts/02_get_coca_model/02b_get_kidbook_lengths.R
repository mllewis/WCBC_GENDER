# get length of each kid book in words (for sampling brown corpus)

library(tidyverse)
library(here)

KIDBOOK_CORPUS <- here("data/processed/books/tidy_full_corpus_all.csv")
KIDBOOK_LENGTHS <-  here("data/processed/iat/other/kid_books_lengths.csv")

kidbook_corpus <- read_csv(KIDBOOK_CORPUS)
book_counts <- kidbook_corpus %>%
  count(book_id) %>%
  filter(!(book_id %in% c("L105", "L112")))
  #mutate(n = ifelse(n > 3000, 3000, n))

write_csv(book_counts, KIDBOOK_LENGTHS)
