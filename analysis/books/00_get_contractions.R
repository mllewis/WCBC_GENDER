# get list of contractions to replace (for some reason the default lists are missing a few)

library(lexicon)
library(tidyverse)
library(here)

CONTRACTION_OUTFILE <- here("data/processed/words/contractions_complete.csv")


contractions <- key_contractions %>%
  add_row(contraction = "haven't", expanded = "have not") %>%
  add_row(contraction = "hadn't", expanded = "had not")  %>%
  arrange(contraction)

write_csv(contractions, CONTRACTION_OUTFILE)
