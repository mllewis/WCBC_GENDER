# check that IAT words actually present in model

library(tidyverse)
library(here)
library(glue)

KIDBOOK_SAMPLED_PREFIX <-  here("exploratory_analyses/5_IAT_tests/data/models/trained_sampled_kidbook/trained_sampled_kidbook_5_count_")
COCA_SAMPLED_PREFIX <-  here("exploratory_analyses/5_IAT_tests/data/models/trained_sampled_coca/trained_sampled_coca_5_count_")
PROP_PRESENT_OUTPATH <- here("exploratory_analyses/5_IAT_tests/data/other/prop_iat_words_in_models.csv")

# Stimuli
MATH_ARTS_KID  <- list(test_name = "WEAT_7_2",
                       bias_type = "gender-bias-math-arts",
                       category_1 = c("man", "boy", "brother", "he", "him", "son"),
                       category_2 = c("woman", "girl", "sister", "she", "her",  "daughter"),
                       attribute_1 = c("shapes", "count",  "sort",  "size", "numbers", "different"),
                       attribute_2 = c("books", "paint", "draw", "art", "dance", "story"))

MATH_LANGUAGE_KID  <- list(test_name = "WEAT_7_3",  # this has been studied in kids (Cveneck,Greendwald, & Meltzoff, 2011a)
                           bias_type = "gender-bias-math-language",
                           category_1 = c("man", "boy", "brother", "he", "him", "son"),
                           category_2 = c("woman", "girl", "sister", "she", "her",  "daughter"),
                           attribute_1 = c("shapes", "count",  "sort",  "size", "numbers", "different"),
                           attribute_2 = c("books","read", "write","story", "letters", "spell")) # triangle, added, cents


GOOD_BAD_GENDER_KID <- list(test_name = "WEAT_VALENCE_GENDER",  # this has been studied in kids (Cveneck, Greenwald, & Meltzoff, 2011b)
                            bias_type = "gender-bias-good-bad",
                            category_1 = c("man", "boy", "brother", "he", "him", "son"),
                            category_2 = c("woman", "girl", "sister", "she", "her",  "daughter"),
                            attribute_1 = c("bad", "awful", "sick", "trouble", "hurt" ) , # these words are adapted from Rudman and Goodman, 2004 exp 1
                            attribute_2 = c( "good"   ,"happy", "gift" ,  "sunshine",  "heaven"))


# terrible, awful/wonderful, hate/love
CAREER_WORD_LIST_KID <- list(test_name = "WEAT_6_2",
                             bias_type = "gender-bias-career-family2",
                             category_1 = c( "man", "boy", "brother", "he", "him",  "son"),
                             category_2 = c( "woman", "girl", "sister", "she", "her",  "daughter"),
                             attribute_1 = c("desk",  "work",  "money",
                                             "office", "business", "job"),
                             attribute_2 = c("home", "parents", "children", "family", "cousins",
                                             "wedding")) #career - job; salary- money; executive - desk; professional - work
test_list <- list(MATH_ARTS_KID,
                  MATH_LANGUAGE_KID,
                  CAREER_WORD_LIST_KID,
                  GOOD_BAD_GENDER_KID)


all_target_words <- test_list %>%
  map_df(~ data.frame(bias_type = pluck(., "bias_type"),
                      word = c(pluck(., "category_1"),
                               pluck(., "category_2"),
                               pluck(., "attribute_1"),
                               pluck(., "attribute_2")))) %>%
  mutate(word = tolower(word))


## kidbook sampled
kidbook_sampled_models <- map(1:10, ~glue("{KIDBOOK_SAMPLED_PREFIX}{.x}.csv"))
coca_sampled_models <- map(1:10, ~glue("{COCA_SAMPLED_PREFIX}{.x}.csv"))

all_models <- c(kidbook_sampled_models, coca_sampled_models)


get_prop_present_in_model <- function(model_path, word_list){
  model <- read_csv(model_path)
  model_name <- str_remove(str_split(model_path, "trained_sampled_")[[1]][3], ".csv")

  prop_words_present <- word_list %>%
    left_join(model)  %>%
    select(bias_type, word, V1) %>%
    group_by(bias_type) %>%
    summarize(prop_present = sum(!is.na(V1))/n())  %>%
    mutate(model_name  = model_name)
}

prop_present_df <- map_df(all_models, get_prop_present_in_model, all_target_words)

write_csv(prop_present_df, PROP_PRESENT_OUTPATH)
