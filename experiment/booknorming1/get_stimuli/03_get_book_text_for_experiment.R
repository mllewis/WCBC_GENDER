# get book text for norming experiment

library(tidyverse)
library(here)
library(jsonlite)

LCL_TIDY <-  here("experiment/booknorming1/get_stimuli/data/tidy_lcl_text_for_exp.csv")
MONTAG_TIDY <- here("experiment/booknorming1/get_stimuli/data/tidy_montag_text_for_exp.csv")
BOOKS_TO_NORM <- here("experiment/booknorming1/get_stimuli/data/books_to_norm.csv")
JSON_OUTPATH <- here("experiment/booknorming1/get_stimuli/data/json_booktext.json")

books_to_norm <- read_csv(BOOKS_TO_NORM)

target_book_text <- map_df(list(LCL_TIDY, MONTAG_TIDY), read_csv) %>%
  filter(book_id %in% unique(books_to_norm$book_id))

text_by_book <- target_book_text %>%
  mutate(text = str_replace_all(text, "\\[", "*"),
         text = str_replace_all(text, "\\]", "*"),
         text = str_replace_all(text, "'", "\\\\'"),
         text = str_replace_all(text, "\"", "\\\\\""),
         #text = str_replace_all(text, "(\\*\\*).+(\\*\\*)", ""),# get rid of stuff coresponding to pictures
         text = str_squish(text),
         title = str_replace_all(title, "'", "\\\\'"),
         title = str_replace_all(title, "\"", "\\\\\"")) %>%
  group_by(book_id, title) %>%
  summarize(text = reduce(text, paste, sep = "<br>"))

## This is the best I can do re backslashes, then in sublimed manually replaces \\ with \ (correct: \\" and \')
char_data_to_save <- books_to_norm %>%
  mutate(char_name = str_replace_all(character_name, "'", "\\\\'")) %>%
  select(book_id, char_name) %>%
  group_by(book_id) %>%
  summarize(char_name = list(char_name))

all_data_to_save <- text_by_book %>%
  left_join(char_data_to_save) %>%
  select(book_id, title, char_name, text)

write_json(all_data_to_save, JSON_OUTPATH)
