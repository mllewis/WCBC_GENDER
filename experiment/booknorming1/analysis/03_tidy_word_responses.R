# clean word responses, get pos, and fix spelling
library(tidyverse)
library(tidytext)
library(janitor)
library(hunspell)
library(here)

TIDY_FULL_DF <-  here("data/processed/character_norming/exp1/exp1_tidy_unprocessed_data.csv")
POS_INFO <- here("data/raw/other_norms/SUBTLEX-US\ frequency\ list\ with\ PoS\ information.csv")
CLEANED_RESPONSES_DF <- here("data/processed/character_norming/exp1/exp1_response_data.csv")

tidy_responses_df <- read_csv(TIDY_FULL_DF)

####  tidy df of responses on critical trials ####
pos_info <- read_csv(POS_INFO) %>% # get pos from subtlex
  clean_names() %>%
  select(word, dom_po_s_subtlex, all_po_s_subtlex)

# merge in POS info
tidy_responses_df_with_pos <- tidy_responses_df %>%
  filter(question_type %in% c("activity", "description")) %>%
  mutate(word = tolower(response),
         word = str_trim(word),
         word = str_replace_all(word, "[[:punct:]]", ""), # strip punctuation
         word = map_chr(word, ~strsplit(., " ")[[1]][1])) %>% # if contains multiple words, take first word
  left_join(pos_info) %>%
  mutate(present_subtlexus = !is.na(dom_po_s_subtlex))

# correct spelling mistakes
spelling_errors <- tidy_responses_df_with_pos %>%
  mutate(spell_correct = case_when(!present_subtlexus ~ hunspell_check(word),
                                   present_subtlexus ~ TRUE),
         hunspell_corrected_spelling = case_when(!spell_correct ~ map_chr(word, ~hunspell_suggest(.)[[1]][1]),
                                                 TRUE ~ word)) %>%
  filter(!spell_correct) %>%
  select(question_type, word, hunspell_corrected_spelling)
# do some manual spell checking here

# get correct pos based on subtlexus
cleaned_responses <-  tidy_responses_df_with_pos %>%
  left_join(spelling_errors) %>%
  select(-contains("subtlex")) %>%
  mutate(word_tidy = case_when(is.na(hunspell_corrected_spelling) ~ word,
                               TRUE ~ hunspell_corrected_spelling),
         word_tidy = map_chr(word_tidy, ~strsplit(., " ")[[1]][1])) %>% # if contains multiple words, take first word
  left_join(pos_info, by = c("word_tidy" = "word")) %>% # merge back in pos after correcting spelling
  mutate(correct_pos = case_when(str_detect(all_po_s_subtlex, "Verb") & question_type == "activity" ~ "action",
                                 str_detect(all_po_s_subtlex, "Noun|Adjective|Adverb") & question_type == "description" ~ "description",
                                 TRUE ~ NA_character_)) %>%
  rename(raw_response = response) %>%
  select(participant_id, trial_index, book_id, title,  gender_group, question_type, character_name,
         character_type, character_gender, question_id, raw_response, word_tidy, correct_pos)

write_csv(cleaned_responses, CLEANED_RESPONSES_DF)

#count(m, question_type, word_tidy, gender_group) %>%
 # filter(!(word_tidy %in% c("play", "run", "eat", "pretty", "loud", "clever"))) %>%
#  arrange(gender_group, -n) %>%
 # group_by(question_type, gender_group) %>%
  #slice(1:10) %>%
  #data.frame()
