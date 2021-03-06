# predict reviews with other measures using glmer; make plots for SI
library(tidyverse)
library(lme4)
library(here)
library(broom.mixed)

REVIEWS_DATA_PATH <- here("data/processed/other/amazon_gender_scores.csv")
IBDB_TIDY_PATH <- here("data/processed/other/ibdb_tidy.csv")
BOOK_MEANS_PATH <- here("data/processed/books/gender_token_type_by_book.csv")
MODEL_OUTFILE <- here("data/processed/other/audience_mixed_effect_models.csv")
PLOT_DATA_OUTFILE <- here("data/processed/other/audience_plot_data.csv")

# our measures of book gender
book_means <- read_csv(BOOK_MEANS_PATH)

book_content_measures <- book_means %>%
  select(book_id, corpus_type, token_gender_mean) %>%
  spread("corpus_type", "token_gender_mean")


ibdb_data <- read_csv(IBDB_TIDY_PATH)

review_data <- read_csv(REVIEWS_DATA_PATH)  %>%
  left_join(book_content_measures) %>%
  left_join(ibdb_data) %>%
  filter(!(book_id %in% c("L105", "L112"))) # "Journey" and "Anno's Journey" are pictures books

make_model_pretty <- function(md, type) {

  pretty_model <- md %>%
    tidy() %>%
    rename(Beta = estimate, SE = std.error, Z = statistic, p = p.value) %>%
    mutate(p = case_when(p < .001 ~  "<.001",
                         TRUE ~ as.character(round(p, 3)))) %>%
    mutate_if(is.numeric, ~ round(.,2)) %>%
    select(term, everything()) %>%
    select(-group)%>%
    slice(-(n()))

  pretty_model_reordered <- pretty_model%>%
    mutate(p = ifelse(p == "1", ">.99", p),
           model_type = type)

  pretty_model_reordered

}


ibdb_amazon_model <- glmer(cbind(n_female_token, n_male_token) ~
                             child_gender + (1|book_id),
                           family = binomial(link ='logit'),
                           data = review_data)

adressee_char_model <- glmer(cbind(n_female_token, n_male_token) ~
                               char_only + (1|book_id),
                             family = binomial(link = 'logit'),
                             control = glmerControl(optimizer = "bobyqa"),
                             data = review_data)

adressee_content_model <- glmer(cbind(n_female_token, n_male_token) ~
                                  no_char + (1|book_id),
                                family = binomial(link = 'logit'),
                                control = glmerControl(optimizer = "bobyqa"),
                                data = review_data)


additive_adressee_model <- glmer(cbind(n_female_token, n_male_token) ~
                                   char_only + no_char + (1|book_id),
                                 family = binomial(link ='logit'),
                                 data = review_data)


model_params <- map2_df(list(ibdb_amazon_model,  adressee_char_model, adressee_content_model, additive_adressee_model),
                        list("ibdb", "char", "content", "char_content"),
                        make_model_pretty)

model_params_tidy <- model_params %>%
  mutate(term = case_when(term == "child_gender" ~ "prop. female, Hudson Kam and Matthewson (2017)",
                          term == "char_only" ~ "character score",
                          term == "no_char" ~ "content score",
                          TRUE ~ term))

write_csv(model_params_tidy, MODEL_OUTFILE)

# plot data
by_book_review_data <- review_data %>%
  group_by(book_id, n_reviews_total, n_reviews_gendered,
           prop_review_gendered, char_only, no_char, child_gender)  %>%
  summarize(addressee_gender_score_token =
              sum(n_female_token)/(sum(n_female_token) +
                                     sum(n_male_token)))


write_csv(by_book_review_data, PLOT_DATA_OUTFILE)
