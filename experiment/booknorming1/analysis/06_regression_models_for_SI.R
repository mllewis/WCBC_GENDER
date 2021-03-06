# get models parameters for different regressions predicting description and activity gender bias; save file of means for plotting

library(tidyverse)
library(here)
library(lme4)
library(broom.mixed)


CLEANED_RESPONSES_DF <- here("data/processed/character_norming/exp1/exp1_response_data.csv")
BOOK_MEANS_PATH <- here("data/processed/books/gender_token_type_by_book.csv")

MODEL_OUTFILE <- here("data/processed/books/character_mixed_effect_models.csv")
MEANS_OUTFILE <- here("data/processed/books/character_gender_means.csv")

study1b_gender_means  <- read_csv(BOOK_MEANS_PATH)


cleaned_responses_with_norms <- read_csv(CLEANED_RESPONSES_DF) %>%
  mutate(gender_group = fct_relevel(gender_group, "male-biased", "neutral"))

cleaned_responses_with_norms_filtered <- cleaned_responses_with_norms %>%
  filter(correct_pos %in% c("action", "description"))  %>%
  mutate(nchar = nchar(raw_response)) %>%
  filter(nchar < 35) # remove responses 35 chars or more (tend to be full sentences)

# all
gender_rating_by_book_mean_only <- study1b_gender_means %>%
  filter(corpus_type == "all") %>%
  select(book_id, token_gender_mean)

# char
gender_rating_by_book_mean_only_char_only <- study1b_gender_means %>%
  filter(corpus_type == "char_only") %>%
  select(book_id, token_gender_mean) %>%
  rename(token_gender_mean_char = token_gender_mean)

# content
gender_rating_by_book_mean_only_no_char <- study1b_gender_means %>%
  filter(corpus_type == "no_char") %>%
  select(book_id, token_gender_mean) %>%
  rename(token_gender_mean_content = token_gender_mean)

cleaned_responses_with_norms_filtered_scaled <- cleaned_responses_with_norms_filtered %>%
  left_join(gender_rating_by_book_mean_only) %>%
  left_join(gender_rating_by_book_mean_only_char_only) %>%
  left_join(gender_rating_by_book_mean_only_no_char) %>%
  group_by(question_type) %>%
  mutate(human_gender_estimate_us_scaled = scale(human_gender_estimate_us),
         token_gender_mean_scaled = scale(token_gender_mean),
         token_gender_mean_char_scaled = scale(token_gender_mean_char),
         token_gender_mean_content_scaled = scale(token_gender_mean_content))

## all models
activity_model <- lmer(human_gender_estimate_us_scaled ~ token_gender_mean_scaled + (1|book_id) + (1|participant_id),
                       data = cleaned_responses_with_norms_filtered_scaled %>% filter(question_type == "activity"))

description_model <- lmer(human_gender_estimate_us_scaled ~  token_gender_mean_scaled + (1|book_id) + (1|participant_id),
                          data = cleaned_responses_with_norms_filtered_scaled %>% filter(question_type == "description"))

## char models
activity_model_char <- lmer(human_gender_estimate_us_scaled ~ token_gender_mean_char_scaled + (1|book_id) + (1|participant_id),
                            data = cleaned_responses_with_norms_filtered_scaled %>% filter(question_type == "activity"))

description_model_char <- lmer(human_gender_estimate_us_scaled ~ token_gender_mean_char_scaled + (1|book_id) + (1|participant_id),
                               data = cleaned_responses_with_norms_filtered_scaled %>% filter(question_type == "description"))

## content models
activity_model_content <- lmer(human_gender_estimate_us_scaled ~ token_gender_mean_content_scaled + (1|book_id) + (1|participant_id),
                               data = cleaned_responses_with_norms_filtered_scaled %>% filter(question_type == "activity"))

description_model_content <- lmer(human_gender_estimate_us_scaled ~ token_gender_mean_content_scaled + (1|book_id) + (1|participant_id),
                                  data = cleaned_responses_with_norms_filtered_scaled %>% filter(question_type == "description"))

make_model_pretty <- function(md, type) {

  pretty_model <- md %>%
    tidy() %>%
  #  filter(effect == "fixed") %>%
    rename(Beta = estimate, SE = std.error, Z = statistic) %>%
    mutate_if(is.numeric, ~ round(.,2))  %>%
    select(-group) %>%
    mutate(term = case_when(str_detect(term,"token_gender_mean") ~ "average_book_gender",
                            TRUE ~ term)) %>%
    mutate(model_type = type)

  pretty_model

}

model_params <- map2_df(list(activity_model, description_model,
                             activity_model_char, description_model_char,
                             activity_model_content, description_model_content),
                        list("activity_model", "description_model",
                             "activity_model_char", "description_model_char",
                             "activity_model_content", "description_model_content"),
        make_model_pretty) %>%
  select(-effect)

write_csv(model_params, MODEL_OUTFILE)
#
# by_group_means <-  cleaned_responses_with_norms_filtered %>%
#   mutate(gender_group = fct_relevel(gender_group, "male-biased", "neutral")) %>%
#   filter(!is.na(human_gender_estimate_us)) %>%
#   group_by(book_id, gender_group, question_type, participant_id) %>%
#   summarize(mean_gender = mean(human_gender_estimate_us)) %>%
#   group_by(book_id, gender_group, question_type) %>%
#   summarize(mean_gender = mean(mean_gender)) %>%
#   group_by(gender_group, question_type) %>%
#   langcog::multi_boot_standard(col = "mean_gender")
#
# write_csv(by_group_means, MEANS_OUTFILE)


