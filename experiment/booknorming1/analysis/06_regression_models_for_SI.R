# get models parameters for different regressions predicting description and activity gender bias; save file of means for plotting

library(tidyverse)
library(here)


CLEANED_RESPONSES_DF <- here("data/processed/character_norming/exp1/exp1_response_data.csv")
MODEL_OUTFILE <- here("data/processed/books/character_mixed_effect_models.csv")
MEANS_OUTFILE <- here("data/processed/books/character_gender_means.csv")


cleaned_responses_with_norms <- read_csv(CLEANED_RESPONSES_DF) %>%
  mutate(gender_group = fct_relevel(gender_group, "male-biased", "neutral"))

cleaned_responses_with_norms_filtered <- cleaned_responses_with_norms %>%
  filter(correct_pos %in% c("action", "description"))  %>%
  mutate(nchar = nchar(raw_response)) %>%
  filter(nchar < 35) # remove responses 35 chars or more (tend to be full sentences)

cleaned_responses_with_norms_filtered_scaled <- cleaned_responses_with_norms_filtered %>%
  mutate(human_gender_estimate_us_scaled = scale(human_gender_estimate_us))

activity_model <- lmer(human_gender_estimate_us_scaled ~  gender_group + (1|book_id) + (1|participant_id),
                       data = cleaned_responses_with_norms_filtered_scaled %>% filter(question_type == "activity"))

description_model <- lmer(human_gender_estimate_us_scaled ~  gender_group + (1|book_id) + (1|participant_id),
     data = cleaned_responses_with_norms_filtered_scaled %>% filter(question_type == "description"))

make_model_pretty <- function(md, type) {

  pretty_model <- md %>%
    tidy() %>%
    filter(group == "fixed") %>%
    rename(Beta = estimate, SE = std.error, Z = statistic) %>%
    mutate_if(is.numeric, ~ round(.,2))  %>%
    select(-group) %>%
    mutate(term = case_when(term == "gender_groupneutral" ~ "neutral",
                            term == "gender_groupfemale-biased" ~ "female-biased",
                            TRUE ~ term)) %>%
    mutate(model_type = type)

  pretty_model

}

model_params <- map2_df(list(activity_model, description_model),
        list("activity", "description"),
        make_model_pretty)

write_csv(model_params, MODEL_OUTFILE)

by_group_means <-  cleaned_responses_with_norms_filtered %>%
  mutate(gender_group = fct_relevel(gender_group, "male-biased", "neutral")) %>%
  filter(!is.na(human_gender_estimate_us)) %>%
  group_by(book_id, gender_group, question_type, participant_id) %>%
  summarize(mean_gender = mean(human_gender_estimate_us)) %>%
  group_by(book_id, gender_group, question_type) %>%
  summarize(mean_gender = mean(mean_gender)) %>%
  group_by(gender_group, question_type) %>%
  langcog::multi_boot_standard(col = "mean_gender")

write_csv(by_group_means, MEANS_OUTFILE)


