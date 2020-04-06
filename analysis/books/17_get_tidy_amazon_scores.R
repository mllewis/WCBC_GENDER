# tidy gender scores
library(here)
library(tidyverse)

REVIEWS_DATA_PATH <- here("data/processed/other/amazon_gender_scores.csv")
OUTPATH <- here("data/processed/other/tidy_amazon_gender_scores.csv")

review_data <- read_csv(REVIEWS_DATA_PATH)

by_book_review_data <- review_data %>%
  group_by(book_id, n_reviews_total, n_reviews_gendered,
           prop_review_gendered)  %>%
  summarize(addressee_gender_score_token =
              sum(n_female_token)/(sum(n_female_token) +
                                     sum(n_male_token)))

write_csv(by_book_review_data, OUTPATH)
