# get book text for norming experiment

library(tidyverse)
library(here)
library(jsonlite)

BOOK_GENDER_MEANS <- here("data/processed/books/gender_token_type_by_book.csv")
LCL_TIDY <-  here("experiment/booknorming1/get_stimuli/data/tidy_lcl_text_for_exp.csv")
MONTAG_TIDY <- here("experiment/booknorming1/get_stimuli/data/tidy_montag_text_for_exp.csv")
CHARACTER_DATA <- here("data/raw/other/character_gender_by_book.csv")

JSON_OUTPATH <- here("experiment/booknorming1/get_stimuli/data/json_booktext.json")

character_data <- read_csv(CHARACTER_DATA) %>%
  select(book_id, title, char_main_singular, char_main_gender, char_name)

# get the 25 most male and female biased books
book_gender_means <- read_csv(BOOK_GENDER_MEANS) %>%
  select(book_id, corpus_type, title, token_gender_mean) %>%
  filter(!(book_id %in% c("L102", "L112")))  %>% # hug and journey (no words; 1 word)
  left_join(character_data)  %>%
  filter(!is.na(char_name)) %>%
  filter(char_main_singular == "YES")


target_book_ids <- book_gender_means %>%
  filter(corpus_type == "all") %>%
  arrange(token_gender_mean) %>%
  mutate(gender_order = 1:n(),
         gender_group = case_when(gender_order <= 20 ~ "male-biased",
                                  gender_order >= (n()-19) ~ "female-biased")) %>%
  filter(!is.na(gender_group)) %>%
  select(-gender_order, -corpus_type)


book_text <- map_df(list(LCL_TIDY, MONTAG_TIDY), read_csv)

target_book_text <- book_text %>%
  filter(book_id %in% target_book_ids$book_id)

text_by_book <- target_book_text %>%
  mutate(text = str_replace_all(text, "\\[", "*"),
         text = str_replace_all(text, "\\]", "*"),
         text = str_replace_all(text, "'", "\\\\'"),
         text = str_replace_all(text, "\"", "\\\\\""),
         text = str_replace_all(text, "(\\*\\*).+(\\*\\*)", ""),# get rid of stuff coresponding to pictures
         text = str_squish(text)) %>%
  group_by(book_id) %>%
  summarize(text = reduce(text, paste, sep = "<br>"))

## This is the best I can do re backslashes, then in sublimed manually replaces \\ with \ (correct: \\" and \')
all_data_to_save <- text_by_book %>%
  left_join(character_data) %>%
  select(book_id, text, char_name)

write_json(all_data_to_save, JSON_OUTPATH)
