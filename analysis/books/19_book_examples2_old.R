# GOAL: figure with N most frequent (content) words for example pink, blue and
# neutral books along with plot description

library(tidyverse)
library(broom)
library(here)
library(glue)

source(here("writeups/paper/paper_helpers.R"))

ALL_GENDER <- here("data/processed/books/tidy_full_corpus_all.csv")

all_words <-  read_csv(ALL_GENDER) 
  
  
CONTENT_GENDER <- here("data/processed/books/tidy_full_corpus_no_chars.csv")
CHARACTER_GENDER <- here("data/processed/books/tidy_full_corpus_chars_only.csv")
WORD_SCORES <- here("data/processed/words/all_word_measures_tidy.csv")
BOOK_GENDER <- here("data/processed/books/gender_token_type_by_book.csv")

BOOK_MEANS_PATH <- here("data/processed/books/gender_token_type_by_book.csv")
gender_rating_by_book_mean_only <- read_csv(BOOK_MEANS_PATH)
overall_token_mean <- mean(gender_rating_by_book_mean_only$token_gender_mean)

CHARACTER_PATH <- here("data/raw/other/character_gender_by_book.csv")
characters <- read_csv(CHARACTER_PATH)

book_means <- gender_rating_by_book_mean_only %>%
  left_join(characters %>% select(book_id,char_main_gender,
                                  char_second_gender)) %>%
  filter(!(book_id %in% c("L105", "L112"))) # "Journey" and "Anno's Journey" are pictures books

all_book_means <- book_means %>%
  filter(corpus_type == "all") %>%
  mutate(char_main_gender = case_when(is.na(char_main_gender) ~ "none",
                                      TRUE ~ char_main_gender),
         char_main_gender = fct_recode(char_main_gender,
                                       female = "F",
                                       male = "M",
                                       "indeterminate" = "AND",
                                       mixed = "MIXED"),
         char_main_gender = fct_relevel(char_main_gender,
                                        "female", "male", "indeterminate", "mixed", "none"))  %>%
  arrange(token_gender_mean) %>%
  mutate(gender_order = 1:n(),
         gender_group = case_when(gender_order <= 20 ~ "male-biased",
                                  gender_order >= 109 &  gender_order <= 128 ~ "neutral",
                                  gender_order >= 228 ~ "female-biased"),
         gender_group = fct_relevel(gender_group, "female-biased", "neutral"),
         title = str_to_title(title))%>%
  filter(!is.na(gender_group))

all_score <- read_csv(ALL_GENDER) %>%
  filter(!(book_id %in% c("L105", "L112")))
content_score <- read_csv(CONTENT_GENDER)  %>%
  filter(!(book_id %in% c("L105", "L112")))
character_score <- read_csv(CHARACTER_GENDER) %>%
  filter(!(book_id %in% c("L105", "L112")))
word_scores <- read_csv(WORD_SCORES) %>%
  select(word, gender)

book_gender <- read_csv(BOOK_GENDER) %>%
  filter(corpus_type == "all") %>%
  select(book_id, title, token_gender_mean)

tidy_df <- bind_rows(content_score, character_score) %>%
  left_join(word_scores) %>%
  mutate(corpus_type2 = case_when((corpus_type == "char_only" & gender < 3) ~ "male_char",
                                  (corpus_type == "char_only" & gender >=3 ) ~ "female_char",
                                  TRUE ~ "content"))
book_gender_content <- read_csv(BOOK_GENDER) %>%
  filter(corpus_type == "no_char") %>%
  select(book_id, title, token_gender_mean)


