# Tidy (1) old (Montag) and (2) new corpus - characters only
# gendered words from 02_get_character_words.R + book-specific words
# Note: main character names are not included if they contain multiple words

library(tidyverse)
library(tidytext)
library(here)

TIDY_CORPUS <- here("data/processed/books/tidytext_kidbook_corpus.csv")
CHARACTER_BY_BOOK <- here("data/processed/books/characters_by_book.csv")

OUTFILE <- here("data/processed/books/tidy_full_corpus_chars_only.csv")

# characters by each book
characters_tidy <- read_csv(CHARACTER_BY_BOOK)

# read in corpus
full_tidy_corpus <- read_csv(TIDY_CORPUS)

full_tidy_chars_only <- full_tidy_corpus %>%
  right_join(characters_tidy) %>%
  mutate(corpus_type = "char_only")

write_csv(full_tidy_chars_only, OUTFILE)
