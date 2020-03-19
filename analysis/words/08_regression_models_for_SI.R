# get models parameters for different regressions predicting gender with different measures of frequency

library(tidyverse)
library(tidytext)
library(here)


ALL_WORD_MEASURES <- here("data/processed/words/all_word_measures_tidy.csv")
MODEL_OUTFILE <- here("data/processed/words/gender_regression_models.csv")


all_words_with_norms <- read_csv(ALL_WORD_MEASURES)

all_words_with_norms_no_na <- all_words_with_norms %>%
  drop_na() %>%
  mutate_if(is.numeric, base::scale)

# models
model_tasa <- lm(gender ~ log_tasa_freq + valence + arousal  + concreteness + adult_aoa,
     data = all_words_with_norms_no_na)

model_kidbook <- lm(gender ~ log_kidbook_freq + valence + arousal  + concreteness + adult_aoa,
                 data = all_words_with_norms_no_na)

model_subt <- lm(gender ~ log_subt_freq + valence + arousal  + concreteness + adult_aoa,
                    data = all_words_with_norms_no_na)

make_model_pretty <- function(md, type) {

  pretty_model <- md %>%
    tidy() %>%
    rename(Beta = estimate, SE = std.error, Z = statistic, p = p.value) %>%
    mutate(p = case_when(p < .001 ~  "<.001",
                          TRUE ~ as.character(round(p, 3)))) %>%
    mutate_if(is.numeric, ~ round(.,2)) %>%
    select(-term) %>%
    mutate(Term = c("(Intercept)",
                    "Log Frequency",
                    "Valence",
                    "Arousal",
                    "Concreteness",
                    "AoA")) %>%
    select(Term, everything())

  pretty_model_reordered <- pretty_model[c(1,4,3,5,6,2),] %>%
    mutate(p = ifelse(p == "1", ">.99", p),
           model_type = type)

  pretty_model_reordered

}

model_params <- map2_df(list(model_tasa, model_kidbook, model_subt),
        list("TASA", "CB", "SUBTLEX-us"),
        make_model_pretty)

write_csv(model_params, MODEL_OUTFILE)


#```{r, results = "asis"}
#apa_table(pretty_model_reordered, caption ="Parameters of additive linear model predicting gender (feminine-ness) as a function of five word meaning attributes:  arousal, valence, concretenesss, age of acquisition (AoA), and log word frequency (TASA). ",
#         col.names = c("Term", "Std. Beta", "SE", "Z", "p"))
