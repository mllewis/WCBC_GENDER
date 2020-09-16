# get book text for norming experiment
# Final selection criteria:
# - main character is gendered and named, or there is no main character
# - not many secondary characters (e.g. Mr. Fish)
# - 150- 900 words


library(tidyverse)
library(tidytext)
library(here)
library(googlesheets4)

SHEET_KEY <- "1NrnRFZ-14VlMoXftB12b9CMVNS6HWfVI7WG65o_oI9w"
BOOK_GENDER_MEANS <- here("data/processed/books/gender_token_type_by_book.csv")
LCL_TIDY <-  here("experiment/booknorming1/get_stimuli/data/tidy_lcl_text_for_exp.csv")
MONTAG_TIDY <- here("experiment/booknorming1/get_stimuli/data/tidy_montag_text_for_exp.csv")
CHARACTER_DATA <- here("data/raw/other/character_gender_by_book.csv")
BOOKS_TO_NORM_OUTPATH <- here("experiment/booknorming1/get_stimuli/data/books_to_norm.csv")

character_data <- read_csv(CHARACTER_DATA) %>%
  select(book_id, title, char_main_singular, char_main_gender, char_name)

character_data <- read_csv(CHARACTER_DATA)

# get the 25 most male and female biased books
book_gender_means <- read_csv(BOOK_GENDER_MEANS) %>%
  select(book_id, corpus_type, title, type_gender_mean) %>%
  left_join(character_data)
book_text <- map_df(list(LCL_TIDY, MONTAG_TIDY), read_csv)

# get books with in range of target number of words
MAX_WORDS <- 1000
MIN_WORDS <- 150
books_with_counts <- book_text %>%
  unnest_tokens(word, text) %>%
  count(book_id)

coded_data <- read_sheet(SHEET_KEY) # "book character coding for norming"

target_books <- coded_data %>%
  left_join(books_with_counts) %>%
  filter(!(character_name %in% c("no_named_character", "no_main_character", "no_gendered_character"))) %>%
  filter(is.na(exclude)) %>%
  filter(n < 900)

# downsample to 15 per group
final_target_book_ids <- distinct(target_books, book_id, .keep_all = T) %>%
  arrange(type_gender_mean) %>%
  group_by(gender_group) %>%
  slice(1:15)

final_target_book_character_data <- target_books %>%
  filter(book_id %in% final_target_book_ids$book_id) %>%
  mutate(character_name = toupper(character_name))

write_csv(final_target_book_character_data, BOOKS_TO_NORM_OUTPATH)
