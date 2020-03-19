# tidy raw norming demographics/ratings - combine samples and anonymize ids

# The data were collected in three runs for two different samples of words (v1 - v3). The 2 sets of
# data files for v2 are because we ran a second sample of participants to balanced out the gender.

library(tidyverse)
library(here)


DEMOPATH1 <- here("data/raw/gender_norms/v1/demographics.csv")
DEMOPATH2 <- here("data/raw/gender_norms/v2/demographics2.csv")
DEMOPATH3 <- here("data/raw/gender_norms/v3/demographics3.csv")


DEMO_OUT <- here("data/processed/words/gender_ratings_demographics.csv")

demo1 <- read_csv(DEMOPATH1) %>%
  select(-X1)  %>%
  mutate_at(vars(question_name, response_str), tolower) %>%
  mutate(run = "run1")

demo2 <- read_csv(DEMOPATH2) %>%
  select(-X1) %>%
  rename(education = "degree") %>%
  gather("question_name", "response_str", -subjCode) %>%
  rename(subj_id = subjCode) %>%
  mutate_at(vars(question_name, response_str), tolower) %>%
  mutate(run = "run2")

demo3 <- read_csv(DEMOPATH3) %>%
  select(-X1) %>%
  rename(education = "degree") %>%
  gather("question_name", "response_str", -subjCode) %>%
  rename(subj_id = subjCode) %>%
  mutate_at(vars(question_name, response_str), tolower) %>%
  mutate(run = "run3")


demo <- bind_rows(demo1, demo2)  %>%
  bind_rows(demo3) %>%
  mutate(response_str = as.character(response_str),
         response_str = case_when((question_name == "gender" & response_str == "1") ~ "male",
                                  (question_name == "gender" & response_str == "2") ~ "female",
                                  (question_name == "gender" & response_str == "3") ~"other",
                                  TRUE ~ response_str))

anon_ids <- demo %>%
  distinct(subj_id) %>%
  mutate(subj_id_anon = paste0("P", 1:n()))

anon_demo <- demo  %>%
  left_join(anon_ids) %>%
  select(-subj_id) %>%
  rename(subj_id = subj_id_anon) %>%
  select(3,4, 1,2) %>%
  mutate_all(as.factor)

write_csv(anon_demo, DEMO_OUT)

RATINGPATH1 <- here("data/raw/gender_norms/v1/ratings.csv")
RATINGPATH2 <- here("data/raw/gender_norms/v2/ratings2.csv")
RATINGPATH3 <- here("data/raw/gender_norms/v3/ratings3.csv")

RATINGS_OUT <- here("data/processed/words/gender_ratings.csv")

# ratings
ratings1 <- read_csv(RATINGPATH1) 
ratings2 <- read_csv(RATINGPATH2)  %>% #there are two trials for which NA was recorded; not sure why this happened
  rename(subj_id = subjCode) %>%
  filter(!is.na(resp))
ratings3 <- read_csv(RATINGPATH3)  %>%
  rename(subj_id = subjCode) 

ratings_anon <- bind_rows(ratings1, ratings2) %>%
  bind_rows(ratings3) %>%
  left_join(anon_ids) %>%
  filter(!is.na(subj_id_anon)) %>% # we don't have demo data for one person
  select(-subj_id) %>%
  rename(subj_id = subj_id_anon,
         rating = resp)  %>%
  select(subj_id, word, rating) 

write_csv(ratings_anon, RATINGS_OUT)


