# GOAL: figure with N most frequent (content) words for example pink, blue and
# neutral books along with plot description

library(tidyverse)
library(broom)
library(here)
library(glue)

source(here("writeups/paper/paper_helpers.R"))
paste2 <- function(x, y, sep = ", ") paste(x, y, sep = sep)


ALL_GENDER <- here("data/processed/books/tidy_full_corpus_all.csv")
WORD_SCORES <- here("data/processed/words/all_word_measures_tidy.csv")
POS_PATH <- "/Users/mollylewis/Documents/research/Projects/1_in_progress/sense-adjectives/data/SUBTLEX-US\ frequency\ list\ with\ PoS\ information\ text\ version.txt"


pos <- read_tsv(POS_PATH) %>%
  janitor::clean_names() %>%
  select(word, dom_po_s_subtlex)

all_book_words <- read_csv(ALL_GENDER)

book_lengths <- all_book_words %>%
  count(book_id)

book_means <- read_csv(BOOK_MEANS_PATH)  %>%
  filter(!(book_id %in% c("L105", "L112")))

# books in forest plot
all_book_means <- book_means %>%
  select(book_id, title, corpus_type, token_gender_mean) %>%
  left_join(book_lengths) %>%
  filter(corpus_type == "all") %>%
  arrange(token_gender_mean) %>%
  mutate(gender_order = 1:n(),
         gender_group = case_when(gender_order <= 20 ~ "male-biased",
                                  gender_order >= 109 &  gender_order <= 128 ~ "neutral",
                                  gender_order >= 228 ~ "female-biased"),
         gender_group = fct_relevel(gender_group, "female-biased", "neutral"),
         title = str_to_title(title))%>%
  filter(!is.na(gender_group))

# merge in word gender cluser info
WORDS_WITH_CLUSTERS <- here("data/processed/words/gender_word_tsne_coordinates.csv")
CLUSTER_GENDERS <- here("data/processed/words/gender_centroids_tsne_coordinates.csv")

cluster_genders <- read_csv(CLUSTER_GENDERS) %>%
  select(cluster_id, gender_bias)

words_with_clusters <- read_csv(WORDS_WITH_CLUSTERS) %>%
  select(word, cluster_id) %>%
  left_join(cluster_genders) %>%
  mutate(gender_bias = case_when(gender_bias == "male" ~ "(m)",
                                 gender_bias == "female" ~ "(f)",
                                 gender_bias == "neither" ~ ""))

# merge in word gender info
GENDER_RATINGS_CI_PATH <- here("data/processed/words/gender_ratings_mean.csv")
gender_ratings_with_ci <- read_csv(GENDER_RATINGS_CI_PATH) %>%
  mutate(gender_bias = case_when(gender_bias == "m" ~ " (m)",
                                 gender_bias == "f" ~ " (f)",
                                 gender_bias == "neither" ~ ""),
         word = map_chr(word, ~unlist(str_split(.x, " "))[[1]])) %>%
  distinct(word, .keep_all = T)



TARGET_BOOKS <- c("M39", "M24", "M7")
#TARGET_BOOKS <- c("M39", "M24", "L108")

word_scores <- read_csv(WORD_SCORES)

target_words <- all_book_words %>%
  filter(book_id %in% TARGET_BOOKS) %>%
  left_join(word_scores %>% select(word, gender)) %>%
  filter(!is.na(gender)) %>% # filter to only words we normed
  left_join(gender_ratings_with_ci) %>%
  left_join(pos) %>%
  filter(dom_po_s_subtlex %in% c("Noun", "Verb")) %>% #, "Adverb", "Adjective" # nouns and verbs only
  filter(!(word %in% c("am", "had","were", "got", "have"))) %>% # get rid of light words
  mutate(word = glue("{word}{gender_bias}")) %>%
  count(book_id, word) %>%
  arrange(book_id, -n) %>%
  group_by(book_id) %>%
  slice(1:25) %>%
  data.frame()


target_words %>%
  group_by(book_id) %>%
  summarize(temp = reduce(word, paste2)) %>%
  data.frame()
