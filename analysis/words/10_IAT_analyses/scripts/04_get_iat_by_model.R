# get IAT for each model

# load packages etc
library(tidyverse)
library(here)
library(data.table)
library(glue)

source(here("analysis/words/10_IAT_analyses/scripts/IAT_utils.R"))

# Outfile
ES_OUTFILE <- here("data/processed/iat/other/iat_es_by_model.csv")

# Model paths
KIDBOOK_FULL_PATH <- here("data/processed/iat/models/trained_kid_model_5_count.csv")
KIDBOOK_SAMPLED_PREFIX <- here("data/processed/iat/models/trained_sampled_kidbook/trained_sampled_kidbook_5_count_")
COCA_SAMPLED_PREFIX <-  here("data/processed/iat/models/trained_sampled_coca/trained_sampled_coca_5_count_")
WIKI_PATH <- "/Users/mollylewis/Documents/research/Projects/1_in_progress/VOCAB_SEEDS/exploratory_analyses/0_exploration/wiki.en.vec"

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



### GET THE ES BY MODEL TYPE
## kidbook
kid_model <- read_csv(KIDBOOK_FULL_PATH)
kidbook_full_es <- map_df(test_list, get_ES, kid_model)  %>%
  mutate(corpus = "kidbook")

## kidbook sampled
kidbook_sampled_models <- map(1:10, ~glue("{KIDBOOK_SAMPLED_PREFIX}{.x}.csv"))
kidbook_sampled_es <- cross2(test_list, kidbook_sampled_models)  %>%
 map_df(~get_ES(.x[[1]], read_csv(.x[[2]])) %>%
          mutate(model_id = str_remove(str_remove(.x[[2]],
                                                  KIDBOOK_SAMPLED_PREFIX), ".csv"))) %>%
 mutate(corpus = "kidbook_sampled")

# sampled coca
coca_sampled_models <- map(1:10, ~glue("{COCA_SAMPLED_PREFIX}{.x}.csv"))
coca_sampled_es <- cross2(test_list, coca_sampled_models)  %>%
    map_df(~get_ES(.x[[1]], read_csv(.x[[2]])) %>%
                   mutate(model_id = str_remove(str_remove(.x[[2]],
                                                           COCA_SAMPLED_PREFIX), ".csv"))) %>%
    mutate(corpus = "coca_sampled")

# wiki
wiki_model <- fread(
  WIKI_PATH,
  header = FALSE,
  skip = 1,
  quote = "",
  encoding = "UTF-8",
  data.table = TRUE,
  col.names = c("word",
                unlist(lapply(2:301, function(x) paste0("V", x)))))

wiki_es <- map_df(test_list, get_ES, wiki_model) %>%
  mutate(corpus = "wiki")


### Bind ES together
all_es <- list(kidbook_full_es,
               kidbook_sampled_es,
               coca_sampled_es,
               wiki_es)  %>%
            reduce(bind_rows)

# write to csv
write_csv(all_es, ES_OUTFILE)


