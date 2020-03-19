# read in raw corpus (Montag and LCNL) and save tidied version
library(tidyverse)
library(tidytext)
library(here)

MONTAG_INFILE <- here("data/processed/books/tidy_montag.csv")
LCNL_INFILE <- here("data/processed/books/tidy_lcl.csv")
TIDY_OUTFILE <- here("data/processed/books/tidytext_kidbook_corpus.csv")

# read in tidied corpus
full_tidy_corpus <- list(MONTAG_INFILE, LCNL_INFILE) %>%
  map_df(read_csv)

tidytext_full_corpus <- full_tidy_corpus %>%
  unnest_tokens(word, text) %>%
  mutate(word = str_replace_all(word, "[[:digit:]]", "")) %>% # remove all numbers
  filter(nchar(word) > 1 | word %in% c("a", "i")) # and single letters


write_csv(tidytext_full_corpus, TIDY_OUTFILE)
