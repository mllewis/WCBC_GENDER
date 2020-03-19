# get gender bias score for each word using same method used in Caliskan

library(tidyverse)
library(data.table)
library(here)

MALE_WORDS = c("man", "boy", "brother", "he", "him", "son")
FEMALE_WORDS = c("woman", "girl", "sister", "she", "her",  "daughter")

MODEL_PATHS_COCA <- here("exploratory_analyses/5_IAT_tests/data/models/trained_sampled_coca/")
MODEL_PATHS_KIDBOOK <- here("exploratory_analyses/5_IAT_tests/data/models/trained_sampled_kidbook/")
WIKI_PATH <- "/Users/mollylewis/Documents/research/Projects/1_in_progress/VOCAB_SEEDS/exploratory_analyses/0_exploration/wiki.en.vec"
SCORE_OUTPATH <- here("exploratory_analyses/5_IAT_tests/data/other/by_word_gender_scores.csv")

all_models <- c(WIKI_PATH, list.files(MODEL_PATHS_COCA, full.names = T),
                list.files(MODEL_PATHS_KIDBOOK, full.names = T))

 get_gender_score_for_one_model <- function(model_path, mw, fw, outpath, targ_words){
  print(model_path)
  model <- fread(
    model_path,
    header = FALSE,
    skip = 1,
    quote = "",
    encoding = "UTF-8",
    data.table = TRUE,
    col.names = c("word",
                  unlist(lapply(2:301, function(x) paste0("V", x))))) %>%
    filter(word %in% targ_words)

  word_word_dists <- coop::cosine(t(as.matrix(model[,-1])))

  wide_word_word_dists <- word_word_dists %>%
    as.data.frame()  %>%
    mutate(word1 = model$word) %>%
    select(word1,  everything())

  names(wide_word_word_dists)  = c("word1",  model$word)

  long_word_word_dists <- gather(wide_word_word_dists, "word2", "cos_dist", -word1, ) %>%
    select(word1, word2, everything())

  relevant_words <- long_word_word_dists %>%
    filter(word1 %in% c(mw, fw)) %>%
    mutate(gender_type = case_when(word1 %in% mw ~ "male", TRUE ~ "female"))

  if (str_detect(model_path, "wiki")){
    model_name <- "wiki"
  } else {
    model_name <- str_remove(str_split(model_path, "trained_sampled_")[[1]][3], ".csv")
  }

  crit_dists_df <- relevant_words %>%
      group_by(word2, gender_type)%>%
      summarize(mean_cos_dist = mean(cos_dist)) %>%
      spread(gender_type, mean_cos_dist)  %>%
      mutate(female_score = female - male,
             model = model_name) %>%
      rename(female_target = female,
             male_target = male,
             word = word2) %>%
      select(model, word, everything())

  write_csv(crit_dists_df, outpath, append = T)

}

# get kidbook words
targ_words <- read_csv(all_models[[21]]) %>%
            pull(word)

walk(all_models, get_gender_score_for_one_model, MALE_WORDS, FEMALE_WORDS, SCORE_OUTPATH, targ_words)

