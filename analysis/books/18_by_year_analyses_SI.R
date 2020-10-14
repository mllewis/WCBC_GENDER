# by year analyses for SI (see exploratory_analysis/gender_bias_publication_year.Rmd for rendered version )
# saves three things: year scatter plot, linear model parameters, and year character mosaic plot

library(tidyverse)
library(broom)
library(here)
library(ggrepel)
library(glue)
library(ggmosaic)

theme_set(theme_classic())

source(here("writeups/paper/paper_helpers.R"))

YEAR_DATA <- here("data/raw/other/isbn_year_by_book.csv")
GENDER_SCORES <- here("data/processed/books/gender_token_type_by_book.csv")
AUDIENCE_GENDER <- here("data/processed/other/tidy_amazon_gender_scores.csv")
CHARACTER_GENDER <- here("data/raw/other/character_gender_by_book.csv")
MODEL_OUTFILE <- here("data/processed/other/year_interaction_model.csv")
YEAR_ALL_PLOT <- here("data/processed/other/year_all_plot.jpeg")
YEAR_CHAR_PLOT <- here("data/processed/other/year_char_plot.jpeg")


character_gender <- read_csv(CHARACTER_GENDER) %>%
  select(book_id, char_main_gender, char_second_gender)

year_data <- read_csv(YEAR_DATA) %>%
  select(book_id, title, earliest_publication)

gender_scores <- read_csv(GENDER_SCORES) %>%
  select(book_id, corpus_type, token_gender_mean) %>%
  pivot_wider(names_from = corpus_type, values_from = token_gender_mean)

audience_gender_scores <- read_csv(AUDIENCE_GENDER) %>%
  select(book_id, addressee_gender_score_token)

tidy_df <-  list(gender_scores,
                 year_data,
                 audience_gender_scores,
                 character_gender) %>%
  reduce(left_join) %>%
  filter(!(book_id %in% c("L105", "L112"))) # "Journey" and "Anno's Journey" are pictures books

####### year and gender corrs #######
addressee_cor <- get_tidy_corr_text(tidy_df, "earliest_publication", "addressee_gender_score_token")
all_cor <- get_tidy_corr_text(tidy_df, "earliest_publication", "all")
char_only_cor <- get_tidy_corr_text(tidy_df, "earliest_publication", "char_only")
no_char_cor <- get_tidy_corr_text(tidy_df, "earliest_publication", "no_char")

####### year and all score plot #######
LABELED_BOOKS <- c("M36", "M49", "M45", "M9", "L239", "L142",
                   "M19", "L257", "L128", "L240", "L220", "M41", "L230")

book_labels <- tidy_df %>%
  select(book_id, title) %>%
  filter(book_id %in% LABELED_BOOKS) %>%
  mutate(title_print = str_to_title(title))

year_all_plot <- tidy_df %>%
  left_join(book_labels) %>%
  mutate(point_class = case_when(!is.na(title_print) ~ "l", TRUE ~ "h")) %>%
  ggplot(aes(x = earliest_publication, y  = all)) +
  geom_point(aes(alpha = point_class), size = .5) +
  geom_hline(aes(yintercept = 3), linetype = .8,  size = 9) +
  geom_smooth(method = "lm", size = .8) +
  geom_text_repel(aes(label = title_print), size = 1,
                  min.segment.length = 0) +
  scale_alpha_manual(values = c(.15, .9)) +
  xlab("Earliest Publication Year") +
  ylab("Book Gender Score (female-ness)") +
  ggtitle("Book Gender Bias vs. Publication Year") +
  theme_classic(base_size = 5) +
  theme(axis.line = element_line(size = .3),
        legend.position = "none")

ggsave(YEAR_ALL_PLOT,
       year_all_plot,
       "jpeg",
       dpi = 320,
       width = 2,
       height = 2,
       units = "in")

####### interaction model #####
interaction_model_params <- lm(no_char ~ char_only*earliest_publication, data = tidy_df) %>%
  summary() %>%
  tidy() %>%
  mutate(term = c("(Intercept)", "Character Gender Score",
                  "Publication Year", "Character Gender Score:Publication Year")) %>%
  mutate_if(is.numeric, round, 3)

write_csv(interaction_model_params, MODEL_OUTFILE)

# character plot
char_main_gender_counts_raw <- tidy_df %>%
  mutate(year_bin = cut(earliest_publication,
                        breaks = seq(1900, 2020, 10),
                        labels = seq(1900, 2020, 10)[-13]))

char_main_gender_counts <- char_main_gender_counts_raw %>%
  group_by(year_bin, char_main_gender) %>%
  summarize(n = n()) %>%
  mutate(prop = n/sum(n)) %>%
  filter(!is.na(char_main_gender))

mosaic_plot_data <- char_main_gender_counts %>%
  group_by(year_bin) %>%
  mutate(total = sum(n),
         perc = total/sum(.$n),
         weight = perc * prop)  %>%
  mutate(char_main_gender = as.factor(char_main_gender)) %>%
  mutate(char_main_gender = fct_relevel(char_main_gender, "M", "F", "MIXED", "AND"))

year_char_plot <- ggplot(mosaic_plot_data) +
  geom_mosaic(aes(x = product(char_main_gender, year_bin),
                  fill = char_main_gender,
                  weight = weight)) +
  scale_y_productlist(labels = c("", "", "" ,"")) +
  ylab("Proportion Characters by Gender") +
  xlab("Publication Decade") +
  ggtitle("Main Character Gender vs. Publication Year") +
  theme_classic(base_size = 5) +
  scale_fill_manual(name="Main Character Gender",
                    labels=c("Male", "Female", "Mixed", "Indeterminate"),
                    values = c("lightblue", "pink","palegreen", "lightgoldenrod1"),
                    guide = guide_legend(reverse=TRUE)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        axis.ticks.y = element_blank(),
        legend.key.size = unit(.5,"line"))


ggsave(YEAR_CHAR_PLOT,
       year_char_plot,
       "jpeg",
       dpi = 320,
       width = 4,
       height = 2,
       units = "in")


