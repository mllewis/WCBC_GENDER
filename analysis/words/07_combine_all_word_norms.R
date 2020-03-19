# merge all word norms together

library(tidyverse)
library(here)
library(janitor)

OUTFILE <- here("data/processed/words/all_word_measures_tidy.csv")
TASA_PATH <- here("data/raw/other_norms/TASA formatted.txt")
KIDBOOK_FREQ_PATH <- here("data/processed/books/all_corpus_word_frequency.csv")
SUBTLEXUS_PATH <- here("data/raw/other_norms/SUBTLEXus_corpus.txt")
EMOT_PATH <- here("data/raw/other_norms/BRM-emot-submit.csv")
CONC_PATH <- here("data/raw/other_norms/brysbaert_corpus.csv")
AOA_PATH <- here("data/raw/other_norms/AoA_ratings_Kuperman_et_al_BRM.csv")

## frequency
# tasa norms
tasa_norms <- read_tsv(TASA_PATH) %>%
  clean_names()

tasa_norms_tidy <- tasa_norms %>%
  mutate(log_tasa_freq = log(all)) %>%
  select(word, log_tasa_freq)

# kidbook freq
kidbook_freq <- read_csv(KIDBOOK_FREQ_PATH)

# subtlexus
subtlexus_norms <- read_tsv(SUBTLEXUS_PATH) %>%
  clean_names()  %>%
  select(word, lg10wf) %>%
  rename(log_subt_freq = lg10wf)

## valence and arousal norms
emot_norms <- read_csv(EMOT_PATH) %>%
  clean_names()
emot_norms_tidy <- emot_norms %>%
  select(word, v_mean_sum, a_mean_sum) %>%
  rename(valence = v_mean_sum,
         arousal = a_mean_sum)

## conc norms
conc_norms <- read_csv(CONC_PATH) %>%
  clean_names()
conc_norms_tidy <- conc_norms %>%
  select(word, conc_m) %>%
  rename(concreteness  = conc_m)

## aoa norms
aoa_norms <- read_csv(AOA_PATH) %>%
  clean_names()

aoa_norms_tidy <- aoa_norms %>%
  select(word, rating_mean) %>%
  rename(adult_aoa = rating_mean)

all_words_with_norms <- list(mean_rating_no_sense %>% select(word, gender),
                             tasa_norms_tidy,
                             subtlexus_norms,
                             kidbook_freq,
                             emot_norms_tidy,
                             conc_norms_tidy,
                             aoa_norms_tidy) %>%
  reduce(left_join, by = "word")

write_csv(all_words_with_norms, OUTFILE)
