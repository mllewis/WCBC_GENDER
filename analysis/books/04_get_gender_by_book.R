# get mean gender by book (type and token)

library(tidyverse)
library(langcog)
library(here)

CORPUS_PATHS <- list(here("data/processed/books/tidy_full_corpus_all.csv"),
                     here("data/processed/books/tidy_full_corpus_no_chars.csv"),
                     here("data/processed/books/tidy_full_corpus_chars_only.csv"))
GENDER_DATA <- here("data/processed/words/gender_ratings_mean.csv")
STOP_WORDS_PATH <- here("data/raw/other/stop_words.csv") # stop words come from https://github.com/igorbrigadir/stopwords/blob/master/en/ranksnl_oldgoogle.txt

OUTFILE <- here("data/processed/books/gender_token_type_by_book.csv")

# stop words
stop_words <- read_csv(STOP_WORDS_PATH)

# get by-word gender data
by_word_gender_with_sense <- read_csv(GENDER_DATA)  %>%
  select(word, mean)

mean_rating_no_sense <- by_word_gender_with_sense %>%
  mutate(word = map_chr(word, ~ unlist(str_split(.x, " "))[[1]])) %>%
  group_by(word) %>%
  summarize(gender = mean(mean)) %>%
  mutate(word = tolower(word))

# get corpora and merge in mean ratings
tidy_corpus <- CORPUS_PATHS %>%
  map_df(read_csv) %>%
  left_join(mean_rating_no_sense) %>% # merge in book words
  anti_join(stop_words) # remove list of stop words

# get means by book (token and type)
## tokens
gender_by_book_tokens <- tidy_corpus %>%
  group_by(book_id, corpus_type) %>%
  multi_boot_standard(co = "gender", na.rm = T) %>%
  rename(token_ci_lower = ci_lower,
         token_ci_upper = ci_upper,
         token_gender_mean = mean) %>%
  arrange(corpus_type)

## types
gender_by_book_types <- tidy_corpus %>%
  distinct(book_id, corpus_type, word, .keep_all = T) %>%
  group_by(book_id, corpus_type) %>%
  multi_boot_standard(co = "gender", na.rm = T) %>%
  rename(type_ci_lower = ci_lower,
         type_ci_upper = ci_upper,
         type_gender_mean = mean)

# get prop missing
prop_token_missing <- tidy_corpus %>%
  mutate(present = case_when(is.na(gender) ~ 0,
                             TRUE ~ 1)) %>%
  group_by(book_id, corpus_type) %>%
  summarize(prop_present_token = mean(present))

prop_type_missing <- tidy_corpus %>%
  mutate(present = case_when(is.na(gender) ~ 0,
                             TRUE ~ 1)) %>%
  distinct(book_id, word,corpus_type, .keep_all = T) %>%
  group_by(book_id, corpus_type) %>%
  summarize(prop_present_type = mean(present))

gender_by_book_all <- tidy_corpus %>%
  distinct(book_id,  title, corpus_type) %>%
  full_join(gender_by_book_tokens) %>%
  full_join(gender_by_book_types) %>%
  full_join(prop_token_missing) %>%
  full_join(prop_type_missing)

write_csv(gender_by_book_all, OUTFILE)


