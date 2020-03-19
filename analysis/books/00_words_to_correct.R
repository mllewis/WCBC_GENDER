# get words to manually correct in corpus

library(tidyverse)
library(tidytext)
library(here)

MONTAG_INFILE <- here("data/processed/books/tidy_montag.csv")
LCNL_INFILE <- here("data/processed/books/tidy_lcl.csv")
OUTFILE <- "~/words_to_correct.csv"

corpus_words <- list(MONTAG_INFILE, LCNL_INFILE) %>%
  map_df(read_csv) %>%
  unnest_tokens(word, text)

word_counts <- corpus_words %>%
  count(word) %>%
  mutate(kidbook_freq = log(n)) %>%
  select(word, kidbook_freq)

check_spelling <- word_counts %>%
  mutate(spell_correct = hunspell::hunspell_check(word),
         spell_correct2 = hunspell::hunspell_check(str_to_title(word))) %>%
  filter(!spell_correct & !spell_correct2)

incorrect_words <- corpus_words %>%
  right_join(check_spelling) %>%
  distinct(book_id, title, author, word) %>%
  arrange(book_id)

incorrect_words %>%
  data.frame()
unique(incorrect_words$word)


write_csv(incorrect_words, OUTFILE)
a = read_csv(MONTAG_INFILE)

filter(a, book_id == "M7") %>%
  data.frame() %>%
  unnest_tokens(word, text) %>%
  filter(word == "opend")

m = list(LCNL_INFILE) %>%
  map_df(read_csv) %>%
  unnest_tokens(word, text) %>%
  filter(word == "opend")
