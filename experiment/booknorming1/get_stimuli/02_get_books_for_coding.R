# get book text for norming experiment

library(tidyverse)
library(here)
library(jsonlite)
library(tidytext)

BOOK_GENDER_MEANS <- here("data/processed/books/gender_token_type_by_book.csv")
LCL_TIDY <-  here("experiment/booknorming1/get_stimuli/data/tidy_lcl_text_for_exp.csv")
MONTAG_TIDY <- here("experiment/booknorming1/get_stimuli/data/tidy_montag_text_for_exp.csv")
CHARACTER_DATA <- here("data/raw/other/character_gender_by_book.csv")

BOOKS_TO_CODE_OUTPATH <- here("experiment/booknorming1/get_stimuli/data/books_to_code.csv")

character_data <- read_csv(CHARACTER_DATA) %>%
  select(book_id, title, char_main_singular, char_main_gender, char_name)character_data <- read_csv(CHARACTER_DATA)

# get the 25 most male and female biased books
book_gender_means <- read_csv(BOOK_GENDER_MEANS) %>%
  filter(corpus_type == "all") %>%
  arrange(-token_gender_mean) %>%
  select(book_id, corpus_type, title, token_gender_mean) %>%
  left_join(character_data)

book_text <- map_df(list(LCL_TIDY, MONTAG_TIDY), read_csv)

# get books with in range of target number of words
MAX_WORDS <- 1000
MIN_WORDS <- 150
books_with_counts <- book_text %>%
  unnest_tokens(word, text) %>%
  count(book_id)

short_books <- books_with_counts %>%
  filter(n <= MAX_WORDS,
         n >= MIN_WORDS) %>%
  pull(book_id)

# get 1, 3, and 5 quintiles of gender bias
target_book_ids <- book_gender_means %>%
  filter(book_id %in% short_books) %>%
  arrange(token_gender_mean) %>%
  mutate(gender_tile = ntile(token_gender_mean, 5),
         gender_group = case_when(gender_tile == 1 ~ "male-biased",
                                  gender_tile == 3 ~ "neutral",
                                  gender_tile >= 5 ~ "female-biased")) %>%
  filter(!is.na(gender_group)) %>%
  left_join(distinct(book_text, book_id, author)) %>%
  select(book_id, title, author, token_gender_mean, gender_group, char_main_singular, char_main_gender, char_name) %>%
  left_join(books_with_counts)

write_csv(target_book_ids, BOOKS_TO_CODE_OUTPATH)
