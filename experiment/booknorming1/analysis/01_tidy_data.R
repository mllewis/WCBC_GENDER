# read in raw corpus and save tidied version
library(tidyverse)
library(tidytext)
library(jsonlite)
library(here)

RAW_DATA_PATH <- here("data/raw/character_norming/exp1/")
BOOK_DATA_PATH <- here("experiment/booknorming1/get_stimuli/data/books_to_norm.csv")

book_data <- read_csv(BOOK_DATA_PATH) %>%
  select(book_id, title, character_name, character_gender, gender_group)

raw_df <- map_df(list.files(RAW_DATA_PATH, full.names = T), read_csv) %>%
  select(trial_type, workerId, responses, question_prompt, question_type, book_id)

tidy_responses <- function(response_string){
  fromJSON(response_string) %>%
    data.frame() %>%
    pivot_longer(names(.),
                 names_to = "question_id",
                 values_to = "response")
}

tidy_df <- raw_df %>%
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
  left_join(book_data, by = c("book_id","character_name")) %>%
  rename(participant_id = workerId)




m = tidy_df %>%
  filter(!(question_type %in% c("familiarity", "participant_gender")))


m %>%
  filter(character_gender == "m", question_type == "activity") %>%
  pull(response)

m %>%
  filter(character_gender == "m", question_type == "description") %>%
  pull(response)



m %>%
  filter(gender_group == "male-biased", question_type == "activity") %>%
  pull(response)

m %>%
  filter(character_gender == "f", question_type == "description") %>%
  pull(response)

tidy_df %>%
  filter(!(question_type %in% c("familiarity", "participant_gender"))) %>%
  count(paricipant_id, question_type, book_id, character_name) %>%
  arrange(paricipant_id, character_name, book_id, question_type)  %>%
  data.frame()


tidy_df %>%
  filter(question_type == "familiarity") %>%
  count(paricipant_id, question_type, book_id, character_name) %>%
  arrange(paricipant_id, character_name, book_id, question_type)  %>%
  data.frame()

tidy_df %>%
  ungroup() %>%
  distinct(book_id, participant_id) %>%
  count(book_id)



