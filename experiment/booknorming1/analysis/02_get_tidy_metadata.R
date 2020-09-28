# get time, gender, and familiarity data
library(tidyverse)
library(here)
library(gendercodeR)


TIDY_FULL_DF <- here("data/processed/character_norming/exp1/exp1_tidy_unprocessed_data.csv")
METADATA_DF <- here("data/processed/character_norming/exp1/exp1_meta_data.csv")
FAMILIARITY_DF <- here("data/processed/character_norming/exp1/exp1_familiarity_data.csv")


tidy_responses_df <- read_csv(TIDY_FULL_DF, col_type = c("dcccdccccccc"))

#### tidy df of participant meta-data ####
total_time <- tidy_responses_df %>%
  filter(question_type == "participant_gender") %>% # participant gender is the last trial
  mutate(total_time_min = time_elapsed/60000) %>% # convert ms to min
  select(participant_id, total_time_min)

gender <-  tidy_responses_df %>%
  filter(question_id == "gender") %>%
  mutate(gender = recode_gender(gender = response,
                                dictionary = broad),
         gender = case_when(response == "women" ~ "female",
                            TRUE ~ gender)) %>%
  select(participant_id, gender)

meta_data_df <- left_join(gender, total_time)
write_csv(meta_data_df, METADATA_DF)

####  familiarity df ####
familiarity_df <- tidy_responses_df %>%
  group_by(participant_id) %>%
  distinct(participant_id, trial_index, title) %>%
  filter(!is.na(title)) %>%
  arrange(participant_id, trial_index) %>%
  distinct(participant_id, title) %>%
  group_by(participant_id) %>%
  mutate(question_id = 1:n(),
         question_id = paste0("book_", question_id)) %>%
  left_join(tidy_responses_df %>%
              filter(question_type == "familiarity")  %>%
              select(participant_id, question_id, response)) %>%
  select(-question_id)

write_csv(familiarity_df, FAMILIARITY_DF)
