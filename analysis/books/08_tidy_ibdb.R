# tidy imbdb data
library(tidyverse)
library(here)

HUDSONKAM_PATH <- here("data/raw/other_norms/IBDb.csv")
IBDB_LNCLKEY <- here("data/raw/other/ibdb_lcnl_key.csv")
IBDB_TIDY_PATH <- here("data/processed/other/ibdb_tidy.csv")
MIN_NUM_RESPONSES_PER_BOOK <- 5

imdb <- read_csv(HUDSONKAM_PATH) %>%
  janitor::clean_names() %>%
  select(c_age, c_sex,  p_gend , p_age, book1, book2, book3, book4, book5) %>%
  gather("x", "title", -1:-4) %>%
  select(-x)

key_ibdb <- read_csv(IBDB_LNCLKEY) %>%
  select(book_id, ibdb_title) %>%
  filter(!is.na(ibdb_title))

imdb_means <- imdb %>%
  group_by(title) %>%
  summarise(child_gender = mean(c_sex, na.rm = T),
            parent_gender = mean(p_gend, na.rm = T),
            parent_age = mean(p_age, na.rm = T),
            child_age= mean(c_age, na.rm = T),
            n_ibdb = n()) %>%
  mutate(title = tolower(title)) %>%
  right_join(key_ibdb, by = c("title" = "ibdb_title" )) %>%
  select(book_id, everything()) %>%
  select(-title) %>%
  filter(n_ibdb >= MIN_NUM_RESPONSES_PER_BOOK)

write_csv(imdb_means, IBDB_TIDY_PATH)