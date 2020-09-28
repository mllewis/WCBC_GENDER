# read in raw jspych output and get responses out of nested json, merge in book metadata
library(tidyverse)
library(tidytext)
library(jsonlite)
library(here)

RAW_DATA_PATH <- here("data/raw/character_norming/exp1/")
BOOK_DATA_PATH <- here("experiment/booknorming1/get_stimuli/data/books_to_norm.csv")
TIDY_FULL_DF <- here("data/processed/character_norming/exp1/exp1_tidy_unprocessed_data.csv")

book_data <- read_csv(BOOK_DATA_PATH) %>%
  select(book_id, title, character_name, character_type,
         character_gender, gender_group,)

raw_df <- map_df(list.files(RAW_DATA_PATH, full.names = T), read_csv) %>%
  select(trial_type, trial_index, workerId, responses,
         question_prompt, question_type, book_id,
         time_elapsed) %>%
  rename(participant_id = workerId)

tidy_responses <- function(response_string){
  fromJSON(response_string) %>%
    data.frame() %>%
    pivot_longer(names(.),
                 names_to = "question_id",
                 values_to = "response")
}

tidy_responses_df <- raw_df %>%
  filter(str_detect(trial_type, "survey")) %>%
  select(-trial_type) %>%
  mutate(question_type = case_when(str_detect(responses, "book_1") ~ "familiarity",
                                   str_detect(question_prompt, "gender?") ~ "participant_gender",
                                   TRUE ~ question_type),
         activity_character = str_extract(question_prompt, "activities\\s*(.*?)\\s*does"), # extract character name
         activity_character =  sub(".*activities *(.*?) *does*", "\\1", activity_character),
         description_character = str_extract(question_prompt, "describe\\s*(.*?)\\s*in"),
         description_character =  sub(".*describe *(.*?) *in*", "\\1", description_character),
         character_name = case_when(is.na(activity_character) ~ description_character,
                               TRUE ~ activity_character)) %>%
  select(-activity_character, -description_character, -question_prompt) %>%
  mutate(data = map(responses, tidy_responses)) %>%
  select(-responses) %>%
  unnest(data) %>%
  filter(response != "") %>%
  left_join(book_data, by = c("book_id","character_name")) # merge in book meta data

write_csv(tidy_responses_df, TIDY_FULL_DF)
