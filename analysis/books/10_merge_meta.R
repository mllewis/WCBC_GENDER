# tidy google data

library(tidyverse)
library(here)


INFILE <- here("data/processed/other/google_books_metadata.csv")
BOOKKEY <- here("data/raw/corpora/key_book_id.csv")
OUTFILE <- here("data/processed/other/tidy_google_metadata.csv")

raw_google <- read_csv(INFILE) %>%
  mutate(title_us = toupper(title_us)) %>%
  mutate(cover_thumbnail_url = as.factor(cover_thumbnail_url))
book_key <- read_csv(BOOKKEY)

google_with_book_id <- raw_google %>%
  full_join(book_key, by = c("title_us" = "title")) %>%
  mutate_if(is.character, as.factor) %>%
  mutate(isbn = as.factor(isbn)) 

google_tidy <- google_with_book_id %>%
  select(book_id, title_us, publisher,
         publisher_desription, n_pages, mean_rating,
         num_ratings, cover_thumbnail_url, preview_url) %>%
  rename(google_mean_rating = mean_rating,
         google_num_ratings = num_ratings,
         title = title_us) %>%
  filter(!is.na(book_id)) 

write_csv(google_tidy, OUTFILE)
