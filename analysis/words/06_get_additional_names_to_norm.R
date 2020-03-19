# We have already normed a set of words that contain high-frequency propernames
# but there are a set of main character proper names that are not included in this list.
# this script identifies those words/
library(tidyverse)
library(here)
library(tidytext)

NORMED_PATH <- here("data/processed/words/gender_ratings_mean.csv")
CHARACTER_PATH <- here("data/raw/other/character_gender_by_book.csv")
NEW_CHAR_PATH <- here("data/processed/words/char_words.csv")
current_words <- read_csv(NORMED_PATH) %>%
  mutate(word = tolower(word),
         word = map_chr(word, ~unlist(str_split(.x, " "))[[1]]))  %>%
  select(word, mean)

characters <- read_csv(CHARACTER_PATH) %>%
  select(title, char_name) %>%
  filter(!is.na(char_name)) %>%
  mutate(char_name = tolower(char_name),
         char_name = case_when(title == "TIKKI TIKKI TEMBO"~ "tikki tikki tembo",
                               TRUE ~ char_name)) %>%
  unnest_tokens(char_word, char_name)
  

target_words <- characters %>%
  left_join(current_words, by = c("char_word" = "word")) %>%
  filter(is.na(mean)) %>%
  distinct(char_word) %>%
  arrange(char_word) %>%
  mutate(char_word = str_to_title(char_word)) %>%
  filter(!(char_word %in% c("The", "Gruffalo's", "T", "Mr")))

write_csv(target_words, NEW_CHAR_PATH)
  