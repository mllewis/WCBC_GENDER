# tidy raw norming demographics/ratings for description/action word norming
# note that for some reason a few old words were normed, these are excluded

library(tidyverse)
library(here)

DEMOPATH <- here("data/raw/gender_norms/v4_description_action_words/demographics4.csv")
DEMO_OUT <- here("data/processed/words/gender_ratings_demographics_desc_act.csv")

target_words <- read_csv(TARGET_WORDS)
demo <- read_csv(DEMOPATH) %>%
  select(-X1) %>%
  rename(education = "degree") %>%
  gather("question_name", "response_str", -subjCode) %>%
  rename(subj_id = subjCode) %>%
  mutate_at(vars(question_name, response_str), tolower) %>%
  mutate(run = "run4") %>%
  mutate(response_str = as.character(response_str),
         response_str = case_when((question_name == "gender" & response_str == "1") ~ "male",
                                  (question_name == "gender" & response_str == "2") ~ "female",
                                  (question_name == "gender" & response_str == "3") ~"other",
                                  TRUE ~ response_str))

anon_ids <- demo %>%
  distinct(subj_id) %>%
  mutate(subj_id_anon = paste0("P_da_", 1:n()))

anon_demo <- demo  %>%
  left_join(anon_ids) %>%
  select(-subj_id) %>%
  rename(subj_id = subj_id_anon) %>%
  select(3,4, 1,2) %>%
  mutate_all(as.factor)

write_csv(anon_demo, DEMO_OUT)

RATINGPATH4 <- here("data/raw/gender_norms/v4_description_action_words/ratings4.csv")
RATINGS_OUT <- here("data/processed/words/gender_ratings_desc_ac.csv")

# ratings
ratings <- read_csv(RATINGPATH4)  %>%
  rename(subj_id = subjCode)

ratings_anon <- ratings %>%
  left_join(anon_ids) %>%
  filter(!is.na(subj_id_anon)) %>% # we don't have demo data for one person
  select(-subj_id) %>%
  rename(subj_id = subj_id_anon,
         rating = resp)  %>%
  select(subj_id, word, rating)

write_csv(ratings_anon, RATINGS_OUT)


