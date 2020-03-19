# Tidy (1) old (Montag) and (2) new corpus - no characters
# gendered words from 02_get_character_words.R + book-specific words
# Note: we have to do this at the corpus level because some of the character names have multiple words

library(tidyverse)
library(tidytext)
library(here)

TIDY_CORPUS <- here("data/processed/books/tidytext_kidbook_corpus.csv")
CHARACTER_BY_BOOK <- here("data/processed/books/characters_by_book.csv")
OUTFILE <- here("data/processed/books/tidy_full_corpus_no_chars.csv")

# characters by each book
characters_tidy <- read_csv(CHARACTER_BY_BOOK)

# read in corpus
full_tidy_corpus <- read_csv(TIDY_CORPUS)

full_tidy_no_chars <- full_tidy_corpus %>%
  anti_join(characters_tidy) %>%
  mutate(corpus_type = "no_char")

write_csv(full_tidy_no_chars, OUTFILE)
