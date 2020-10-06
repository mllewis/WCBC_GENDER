# get gender bias score for each word using same method used in Caliskan
# in english, using both corpora (sub or wiki)

library(tidyverse)
library(data.table)
library(here)

MALE_WORDS <- c("son", "his","him","he", "brother","boy", "man")
FEMALE_WORDS <- c("daughter", "hers", "her", "she",  "sister", "girl", "woman")
CLEANED_RESPONSES_DF <- here("data/processed/character_norming/exp1/exp1_response_data.csv")
MODEL_PATH <- "/Users/mollylewis/Documents/research/Projects/1_in_progress/VOCAB_SEEDS/exploratory_analyses/0_exploration/wiki.en.vec"
OUTFILE <- here("data/processed/character_norming/exp1/response_embedding_gender_scores.csv")

cleaned_responses_with_norms <- read_csv(CLEANED_RESPONSES_DF) %>%
  mutate(gender_group = fct_relevel(gender_group, "male-biased", "neutral"))

cleaned_responses_with_norms_filtered <- cleaned_responses_with_norms %>%
  filter(correct_pos %in% c("action", "description"))  %>%
  mutate(nchar = nchar(raw_response)) %>%
  filter(nchar < 35) %>% # remove responses 35 chars or more (tend to be full sentences) %>%
  distinct(word_tidy_lemma) %>%
  rename(word = word_tidy_lemma)


MODEL_SOURCE <- "wiki" # sub or wiki

model <- fread(
  MODEL_PATH,
  header = FALSE,
  skip = 1,
  quote = "",
  encoding = "UTF-8",
  data.table = TRUE,
  col.names = c("word",
                unlist(lapply(2:301, function(x) paste0("V", x)))))

target_word_coordinates <-  cleaned_responses_with_norms_filtered %>%
  left_join(model)  %>%
  mutate(type = "target_response",
         gender = NA)


gender_word_coordinates <- model %>%
  filter(word %in% c(MALE_WORDS, FEMALE_WORDS)) %>%
  mutate(type = "gender_word",
         gender = ifelse(word %in% MALE_WORDS, "male", "female"))

rm(model)

all_words <- bind_rows(target_word_coordinates, gender_word_coordinates)  %>%
  select(word, type, gender, everything())

get_gender_score <- function(this_word, all_words_df){
  print(this_word)
  mat <- all_words_df %>%
    filter((word == this_word & type == "target_response") | type == "gender_word")

  word_word_dists <- coop::cosine(t(as.matrix(mat[,c(-1, -2, -3)])))

  wide_word_word_dists <- word_word_dists %>%
    as.data.frame()  %>%
    mutate(word1 =  mat$word,
           gender = mat$gender) %>%
    select(word1, gender, everything())

  long_word_word_dists <- wide_word_word_dists %>%
    filter(word1 != this_word) %>%
    select(word1, gender, V1) %>%
    rename(cos_dist = V1)

  try({
    long_word_word_dists %>%
      group_by(gender)%>%
      summarize(mean_cos_dist = mean(cos_dist)) %>%
      spread(gender, mean_cos_dist)  %>%
      mutate(male_score = male - female,
             word = this_word) %>%
      rename(female_target = female,
             male_target = male) %>%
      select(word, everything())
  })
}

# this is slow....
crit_dists <- map(target_word_coordinates$word,
                     get_gender_score,
                     all_words)

crit_dists_df <- keep(crit_dists, ~length(.) > 1) %>%
  bind_rows()

write_csv(crit_dists_df, OUTFILE)

