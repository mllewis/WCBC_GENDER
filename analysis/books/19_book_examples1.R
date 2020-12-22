
library(tidyverse)
library(broom)
library(here)
library(glue)

source(here("writeups/paper/paper_helpers.R"))

ALL_GENDER <- here("data/processed/books/tidy_full_corpus_all.csv")

CONTENT_GENDER <- here("data/processed/books/tidy_full_corpus_no_chars.csv")
CHARACTER_GENDER <- here("data/processed/books/tidy_full_corpus_chars_only.csv")
WORD_SCORES <- here("data/processed/words/all_word_measures_tidy.csv")
BOOK_GENDER <- here("data/processed/books/gender_token_type_by_book.csv")

all_score <- read_csv(ALL_GENDER) %>%
  filter(!(book_id %in% c("L105", "L112")))
content_score <- read_csv(CONTENT_GENDER)  %>%
  filter(!(book_id %in% c("L105", "L112")))
character_score <- read_csv(CHARACTER_GENDER) %>%
  filter(!(book_id %in% c("L105", "L112")))
word_scores <- read_csv(WORD_SCORES) %>%
  select(word, gender)

book_gender <- read_csv(BOOK_GENDER) %>%
  filter(corpus_type == "all") %>%
  select(book_id, title, token_gender_mean)

tidy_df <- bind_rows(content_score, character_score) %>%
  left_join(word_scores) %>%
  mutate(corpus_type2 = case_when((corpus_type == "char_only" & gender < 3) ~ "male_char",
                                  (corpus_type == "char_only" & gender >=3 ) ~ "female_char",
                                  TRUE ~ "content"))
book_gender_content <- read_csv(BOOK_GENDER) %>%
  filter(corpus_type == "no_char") %>%
  select(book_id, title, token_gender_mean)

# tile plot
tile_gender <- tidy_df %>%
  mutate(line_tile = ntile(line_number,50)) %>%
  group_by(book_id, title, line_tile, corpus_type) %>%
  summarize(gender_mean = mean(gender, na.rm = T)) %>%
  group_by(corpus_type) %>%
  mutate(gender_mean_scaled = scale(gender_mean, center = 3)) %>%
  ungroup()


tile_gender %>%
  left_join(book_gender) %>%
  filter(token_gender_mean > 3.25 | token_gender_mean < 2.7) %>%
  ggplot(aes(x = line_tile,
                         y =  gender_mean_scaled,
                         group = corpus_type, color = corpus_type)) +
  #geom_line() +
  geom_hline(aes(yintercept = 0)) +
  geom_smooth(span = .5, se = F) +
  facet_wrap(~title) +
  theme_classic()


# line plot

rug_data <- tidy_df %>%
  filter(corpus_type == "char_only") %>%
  group_by(book_id, line_number) %>%
  summarize(mean_gender = mean(gender, na.rm = T)) %>%
  mutate(gender_binary = case_when(mean_gender >3  ~ "F",
                                  mean_gender <= 3 ~ "M",
                                  TRUE ~ NA_character_))

line_gender <- tidy_df %>%
  group_by(book_id, title, line_number, corpus_type) %>%
  summarize(gender_mean = mean(gender, na.rm = T)) %>%
  group_by(corpus_type) %>%
 # mutate(gender_mean_scaled = scale(gender_mean, center = 3)) %>%
  ungroup()

# This is the best one:
line_gender %>%
  left_join(book_gender) %>%
  left_join(rug_data) %>%
  filter(corpus_type == "no_char") %>%
  #filter(token_gender_mean > 3.25 | token_gender_mean < 2.7) %>%
  filter(token_gender_mean < 2.9) %>%
  ggplot(aes(x = line_number)) +
  geom_hline(aes(yintercept = 3)) +
  geom_smooth(aes(y =  gender_mean), span = .3, color = "red", se = F) +
  geom_rug(aes(x = line_number, sides = "b", color = gender_binary),
           length = unit(0.08, "npc")) +
  scale_color_manual(values = c("pink", "lightblue", "white")) +
  facet_wrap(~title, scale = "free_x") +
  theme_classic()

### try heatmap

### misc

find_target_books <- tile_gender %>%
  count(book_id, title, line_tile) %>%
  group_by(book_id, title) %>%
  summarize(prop_both = sum(n == 2)/n()) %>%
  arrange(-prop_both) %>%
  left_join(book_gender) %>%
  #filter(prop_both == 1) %>%
  filter(token_gender_mean > 3.25 | token_gender_mean < 2.7)

#ggplot(find_target_books, aes(x = prop_both, y = token_gender_mean)) +
#  geom_text(aes(label = title))


