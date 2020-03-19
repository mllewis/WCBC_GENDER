# get pos of normed words

library(tidyverse)
library(here)
library(janitor)

NORMED_WORDS <- here("data/processed/words/gender_ratings_mean.csv")
POS <- here("data/raw/other_norms/SUBTLEX-US\ frequency\ list\ with\ PoS\ information.csv")
NORMED_WORDS_WITH_POS <- here("data/processed/words/normed_words_pos_to_code.csv")

normed_words <- read_csv(NORMED_WORDS) %>%
  select(word) %>%
  mutate(word = tolower(word))

pos <- read_csv(POS) %>%
  clean_names() %>%
  select(word, dom_po_s_subtlex)


normed_words_with_pos <- normed_words %>%
  left_join(pos) %>%
  arrange(dom_po_s_subtlex)

write_csv(normed_words_with_pos, NORMED_WORDS_WITH_POS)
