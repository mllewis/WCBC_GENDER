# get corr table for SI of by-word embeddings gender correlations

library(tidyverse)
library(here)


BY_WORD_CORR_TABLE_PATH <- here("data/processed/words/by_word_embedding_corr_table.csv")

## Emebedding scores
SCORE_PATH <- here("data/processed/other/iat/by_word_gender_scores.csv")
model_biases <- read_csv(SCORE_PATH, col_names = c("model", "word", "female_target", "male_target", "female_score")) %>%
  mutate(model2 = str_split(model, "_5_count_"),
         corpus = map_chr(model2, ~pluck(.x, 1)),
         # model_id = map_chr(model2, ~pluck(.x, 2)),
         corpus = case_when(model == "wiki" ~ "wiki", TRUE ~ corpus),
         word = tolower(word)) %>%
  select(-model2, -model)

# take average across model runs
model_scores <- model_biases %>%
  group_by(corpus, word) %>%
  summarize(female_score = mean(female_score))

## human scores
GENDER_NORMS <- here("data/processed/words/gender_ratings_mean.csv")

gender_words <- read_csv(GENDER_NORMS)
gender_norms <- gender_words %>%
  mutate(word = map_chr(word, ~unlist(str_split(.x, " "))[[1]]),
         word = tolower(word),
         word = str_remove_all(word, '[:punct:]')) %>%
  distinct(word, .keep_all = T) %>%
  group_by(word) %>%
  summarize(human_gender_rating  = mean(mean, na.rm = T))

# Merge language and human data
all_scores <- gender_norms %>%
  inner_join(model_scores)

# get pairwise correlation
common_words <- count(all_scores, word) %>%
  filter(n == 3) %>%
  pull(word)

human_lang_corrs <- all_scores %>%
  filter(word %in% common_words) %>%
  spread(corpus, female_score)

col_order <- c("Human gender ratings", "Distributed semantics (WCBC)",
               "Distributed semantics (COCA)", "Distributed semantics (Wikipedia)")
corr_df <- cor(human_lang_corrs[,-1]) %>%
  round(2) %>%
  as.matrix()

#upper.tri(corr_df, diag = T) <- ""

corr_output <- corr_df %>%
  data.frame() %>%
  rownames_to_column() %>%
  mutate(rowname = case_when(rowname == "human_gender_rating" ~ "Human gender ratings",
                             rowname == "coca" ~ "Distributed semantics (COCA)",
                             rowname == "kidbook" ~ "Distributed semantics (WCBC)",
                             rowname == "wiki" ~ "Distributed semantics (Wikipedia)")) %>%
  slice(match(col_order, rowname)) %>%
  select(1,2,4,3,5) %>%
  column_to_rownames(var = "rowname") %>%
  as.matrix()


corr_output[upper.tri(corr_output, diag = T)] <- ""

cor_table_tidy <- corr_output %>%
  as.data.frame() %>%
  rownames_to_column("Var2") %>%
  slice(-1) %>% # get rid of empty column/rows due to missing top diag
  select(-5)

names(cor_table_tidy) <- c("-", "Human gender ratings", "Distributed Semantics (WCBC)", "Distributed Semantics (COCA)")

write_csv(cor_table_tidy, BY_WORD_CORR_TABLE_PATH)

