# get frequent stop words that we didn't norm (snowball list)

library(tidyverse)
library(tidytext)
library(here)

GENDER_DATA <- here("data/processed/words/gender_ratings_mean.csv")
STOP_WORDS_PATH <- here("data/processed/words/stop_words.csv")

# get by-word gender data
by_word_gender_with_sense <- read_csv(GENDER_DATA)  %>%
  select(word, mean)

mean_rating_no_sense <- by_word_gender_with_sense %>%
  mutate(word = map_chr(word, ~ unlist(str_split(.x, " "))[[1]])) %>%
  group_by(word) %>%
  summarize(gender = mean(mean)) %>%
  mutate(word = tolower(word))

stop_people_words <- c("i", "ours", "ourselves", "yourselves", "hers", "theirs", "themselves")

# stop words we didn't norm
snow <- mean_rating_no_sense %>%
  right_join(stop_words %>% filter(lexicon == "snowball")) %>%
  filter(is.na(gender)) %>%
  filter(!str_detect(word, "'")) %>%
  pull(word)

stop_words <- data.frame(word = setdiff(snow, stop_people_words))

write_csv(stop_words, STOP_WORDS_PATH)

