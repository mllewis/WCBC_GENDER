
library(tidyverse)
library(tidytext)
library(langcog)
library(here)
library(hunspell)

FEMALE_WORDS <- c("daughter", "daughters",  "granddaughter", "granddaughters","niece", "nieces", "grandniece", "grandnieces")
MALE_WORDS <- c("son", "sons", "grandson", "grandsons",  "nephew", "nephews", "grandnephew", "grandnephews")

REVIEW_PATH <- "/Users/mollylewis/Documents/research/Projects/1_in_progress/KIDBOOK_GENDER/data/processed/books/scraped_amazon_reviews.csv"
MISSPELLINGS_PATH <- here("data/raw/other/amazon_review_misspellings.csv")

# amazon reviews
all_reviews <- read_csv(REVIEW_PATH, col_names = c("book_id", "page_num", 
                                                   "review_title", "date", "verified", 
                                                   "review", "rating"))

tidy_reviews <- all_reviews %>% 
  mutate(title_review = paste0(review_title, " ", review ), # combine titles and review
         review_id = 1:n(),
         title_review = tolower(title_review),
         title_review = str_remove_all(title_review, "[:punct:]")) %>%
  select(-review_title, -review, -page_num) %>%
  unnest_tokens(word, title_review) 


fuzzy_match <- tidy_reviews %>%
  distinct(word) %>%
  mutate(real_word = hunspell_check(word)) %>%
  filter(!real_word) %>%
  mutate(possible_words = hunspell_suggest(word))

correct_words <- fuzzy_match %>%
  rowwise() %>%
  mutate(female_word = sum(unlist(possible_words) %in% FEMALE_WORDS) > 0,
         male_word = sum(unlist(possible_words) %in% MALE_WORDS) > 0) %>%
  filter(female_word | male_word) %>%
  arrange(female_word, male_word) %>%
  select(word, female_word, male_word)

write_csv(correct_words, MISSPELLINGS_PATH)
