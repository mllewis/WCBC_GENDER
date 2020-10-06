# clean word responses, get pos, and fix spelling
library(tidyverse)
library(tidytext)
library(janitor)
library(hunspell)
library(textstem)
library(here)

TIDY_FULL_DF <-  here("data/processed/character_norming/exp1/exp1_tidy_unprocessed_data.csv")
POS_INFO <- here("data/raw/other_norms/SUBTLEX-US\ frequency\ list\ with\ PoS\ information.csv")
GENDER_BIAS_DF <- here("data/processed/words/all_word_measures_tidy.csv")
GLASGOW_GENDER_BIAS_DF <- here("data/raw/other_norms/GlasgowNorms.csv")
CLEANED_RESPONSES_DF <- here("data/processed/character_norming/exp1/exp1_response_data.csv")

tidy_responses_df <- read_csv(TIDY_FULL_DF) %>%
  filter(question_type %in% c("activity", "description")) %>%
  rename(raw_response = response)

#### tidy df of responses on critical trials ####
pos_info <- read_csv(POS_INFO) %>% # get pos from subtlex
  clean_names() %>%
  select(word, dom_po_s_subtlex, all_po_s_subtlex)

# merge in POS info
tidy_responses_df_with_pos <- tidy_responses_df %>%
  mutate(word = tolower(raw_response),
         word = str_trim(word),
         word = str_replace_all(word, "[[:punct:]]", ""), # strip punctuation
         word = map_chr(word, ~strsplit(., " ")[[1]][1])) %>% # if contains multiple words, take first word
  left_join(pos_info) %>%
  mutate(present_subtlexus = !is.na(dom_po_s_subtlex))

# correct spelling mistakes (check spelling for words not in subtlexus)
corrected_spelling_errors <- tidy_responses_df_with_pos %>%
  mutate(spell_correct = case_when(!present_subtlexus ~ hunspell_check(word),
                                   present_subtlexus ~ TRUE),
         hunspell_corrected_spelling = case_when(!spell_correct ~ map_chr(word, ~hunspell_suggest(.)[[1]][1]),
                                                 TRUE ~ word),
         hunspell_corrected_spelling = map_chr(hunspell_corrected_spelling, ~strsplit(., " ")[[1]][1]), # if contains multiple words, take first word (as above)
         hunspell_corrected_spelling = tolower(hunspell_corrected_spelling)) %>%
  filter(!spell_correct) %>%
  select(question_type, word, hunspell_corrected_spelling)

# get correct pos based on subtlexus
cleaned_responses <-  tidy_responses_df_with_pos %>%
  left_join(corrected_spelling_errors) %>% # merge in
  select(-contains("subtlex")) %>%
  mutate(word_tidy = case_when(is.na(hunspell_corrected_spelling) ~ word,
                               TRUE ~ hunspell_corrected_spelling)) %>%
  left_join(pos_info, by = c("word_tidy" = "word")) %>% # merge back in pos after correcting spelling
  mutate(correct_pos = case_when(str_detect(all_po_s_subtlex, "Verb") & question_type == "activity" ~ "action", # define what pos count as corret for each category
                                 str_detect(all_po_s_subtlex, "Noun|Adjective|Adverb") & question_type == "description" ~ "description",
                                 TRUE ~ NA_character_)) %>%
  select(participant_id, trial_index, book_id, title,  gender_group, question_type, character_name,
         character_type, character_gender, question_id, raw_response, word_tidy, correct_pos)

cleaned_responses_lemma <- cleaned_responses %>%
  mutate(word_tidy_lemma = lemmatize_words(word_tidy)) # from textstem package (lemmatize)

# merge in human judgment info
gender_bias_estimates <- read_csv(GENDER_BIAS_DF) %>%
  select(word, gender) %>%
  rename(human_gender_estimate_us = gender)

gender_bias_estimates_glasgow <- read_csv(GLASGOW_GENDER_BIAS_DF) %>%
  clean_names() %>%
  select(word, gend_m) %>%
  rename(human_gender_estimate_glasgow = gend_m)

cleaned_responses_with_norms <- cleaned_responses_lemma %>%
  left_join(gender_bias_estimates, by= c("word_tidy_lemma" = "word")) %>%
  left_join(gender_bias_estimates_glasgow , by= c("word_tidy_lemma" = "word"))

write_csv(cleaned_responses_with_norms, CLEANED_RESPONSES_DF)
