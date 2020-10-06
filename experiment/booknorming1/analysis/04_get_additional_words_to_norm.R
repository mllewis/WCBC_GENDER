# get additional words to norm

CLEANED_RESPONSES_DF <- here("data/processed/character_norming/exp1/exp1_response_data.csv")
cleaned_responses_with_norms <- read_csv(CLEANED_RESPONSES_DF) %>%
  mutate(gender_group = fct_relevel(gender_group, "male-biased", "neutral"))

WORDS_TO_NORM_DF <- here("data/processed/character_norming/exp1/words_to_norm.csv")

# remove words that are the wrong pos or are too long
cleaned_responses_with_norms_filtered <- cleaned_responses_with_norms %>%
  filter(correct_pos %in% c("action", "description"))  %>%
  mutate(nchar = nchar(raw_response)) %>%
  filter(nchar < 35) # remove responses 35 chars or more (tend to be full sentences)

# responses that occur 1 or more times for either activity or description that are unnormed
unnormed_responses <- cleaned_responses_with_norms_filtered %>%
  filter(is.na(human_gender_estimate_us)) %>%
  count(word_tidy_lemma) %>%
  arrange(-n) %>%
  filter(n > 1)

write_csv(unnormed_responses, WORDS_TO_NORM_DF)
