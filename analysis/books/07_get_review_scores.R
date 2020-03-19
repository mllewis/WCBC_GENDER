# Process Amazon reviews. Saves file by book gender ratings, and by-book meta-data (e.g. num reviews).
library(tidyverse)
library(tidytext)
library(langcog)
library(here)

FEMALE_WORDS <- c("daughter", "daughters",  "granddaughter", "granddaughters","niece", "nieces", "grandniece", "grandnieces")
MALE_WORDS <- c("son", "sons", "grandson", "grandsons",  "nephew", "nephews", "grandnephew", "grandnephews")

REVIEW_PATH <- "/Users/mollylewis/Documents/research/Projects/1_in_progress/KIDBOOK_GENDER/data/processed/books/scraped_amazon_reviews.csv"
BOOK_KEY <- here("data/raw/corpora/key_book_id.csv")
MISSPELLINGS_PATH <- here("data/raw/other/amazon_review_misspellings.csv")
AMAZON_SCORES_OUT <- here("data/processed/other/amazon_gender_scores.csv")

book_key <- read_csv(BOOK_KEY) %>%
  select(book_id)

# raw amazon reviews
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

# total number of reviews and mean ratings
all_review_data <- tidy_reviews %>%
  distinct(book_id, review_id, .keep_all = T) %>%
  group_by(book_id) %>%
  summarize(mean_rating = mean(rating),
            n_reviews_total = n())

# get mean gender rating by book
misspellings <- read_csv(MISSPELLINGS_PATH) %>% # I manually removed poor guesses (e.g. "jon" for "son)
  gather("word_type", "kind", -1)  %>%
  filter(kind) %>%
  select(-kind)

all_female_words <- c(misspellings %>% filter(word_type == "female_word") %>% pull(word), 
                      FEMALE_WORDS)
all_male_words <- c(misspellings %>% filter(word_type == "male_word") %>% pull(word), 
                    MALE_WORDS)

# reviews with gender words only
reviews_with_gender <- tidy_reviews %>%
  rowwise() %>%
  mutate(female_word = word %in% all_female_words,
         male_word = word %in% all_male_words) %>%
  filter(female_word | male_word) %>%
  ungroup()

# n reviews with gender words
gender_reviews_data <- reviews_with_gender %>%
  distinct(book_id, review_id) %>%
  count(book_id, name = "n_reviews_gendered")

# by review mean gender
by_review_gender_token <- reviews_with_gender %>%
  group_by(book_id, review_id) %>%
  summarize(n_female_token = sum(female_word),
            n_male_token = sum(male_word)) 

by_review_tidy <- by_review_gender_token %>%
  full_join(book_key) %>% # merge in book info
  left_join(all_review_data) %>%
  left_join(gender_reviews_data) %>% 
  mutate(prop_review_gendered = n_reviews_gendered/n_reviews_total) %>%
  select(book_id, review_id,n_female_token, n_male_token,  n_reviews_total, n_reviews_gendered, prop_review_gendered,
         mean_rating)

write_csv(by_review_tidy, AMAZON_SCORES_OUT)
