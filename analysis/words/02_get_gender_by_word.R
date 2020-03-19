# get mean rating by word; exclude non-native speakr ratings
library(tidyverse)
library(here)
library(langcog)

RATING_RATINGS_PATH <- here("data/processed/words/gender_ratings.csv")
DEMO_PATH <- here("data/processed/words/gender_ratings_demographics.csv")

OUTFILE <- here("data/processed/words/gender_ratings_mean.csv")

# exclude non-native speakers
rating_demos <- read_csv(DEMO_PATH)

non_native_participants <- rating_demos %>%
  filter(question_name == "native_english" | question_name == "native") %>%
  filter(response_str == 0) %>%
  pull(subj_id)

rating_demos_ex <- rating_demos %>%
  filter(!(subj_id %in% non_native_participants))

by_word_ns <- count(ratings, word)

by_word_means <- ratings %>%
  group_by(word) %>%
  multi_boot_standard(col = "rating") %>%
  left_join(by_word_ns)

by_word_means_with_bias <- by_word_means %>%
  mutate(gender_bias = case_when(ci_lower > mean(gender_ratings_with_ci$mean) ~ "f",
                                 ci_upper < mean(gender_ratings_with_ci$mean) ~ "m",
                                 TRUE ~ "neither"))


write_csv(by_word_means_with_bias, OUTFILE)
