### Identifiy gendered clusters using t-test, with effect size [CI]
library(tidyverse)
library(here)
library(broom)
library(rstatix)

INFILE_WORDS <- here("data/processed/words/gender_word_tsne_coordinates.csv")
OUTFILE_CENTROIDS <- here("data/processed/words/gender_centroids_tsne_coordinates.csv")

word_df <- read_csv(INFILE_WORDS)
CRIT_VALUE <- .05

# test whether cluster is significantly male or female biased
overall_gender_mean <- mean(word_df$gender, na.rm = TRUE)

get_t_test <- function(df, H0_value){
  t_test_data <- t.test(x = unlist(df$gender, use.names = F),
         mu = H0_value) %>%
    tidy()  %>%
    select(statistic, estimate, p.value)


  effect_size_data <- if (length(df$gender) > 5){ # can't bootstrap for small clusters
      df %>%
        cohens_d(gender ~ 1, mu = H0_value, ci = T) %>%
        select(effsize, conf.low, conf.high, n)
  } else {
    df %>%
      cohens_d(gender ~ 1, mu = H0_value, ci = F) %>%
      mutate(conf.low = NA,
             conf.high = NA) %>%
      select(effsize, conf.low, conf.high, n)
  }

  bind_cols(t_test_data, effect_size_data) %>%
    rename(t_statistic = statistic,
           mean_gender = estimate,
           effect_size = effsize,
           eff_conf_low = conf.low,
           eff_conf_high = conf.high)
}

cluster_gender_t_tests <- word_df %>%
  select(cluster_id, gender) %>%
  group_by(cluster_id) %>%
  nest() %>%
  mutate(fit = map(data, get_t_test, overall_gender_mean)) %>%
  select(-data) %>%
  unnest()  %>%
  mutate(is_gendered = p.value < CRIT_VALUE,
         gender_bias = case_when(is_gendered & t_statistic < 0 ~ "male",
                                 is_gendered & t_statistic > 0 ~ "female",
                                 TRUE ~ "neither")) %>%
  select(cluster_id, n, effect_size, eff_conf_low, eff_conf_high,
         is_gendered, gender_bias, t_statistic, mean_gender)

# add in x and y values
all_cluster_df <- word_df %>%
  group_by(cluster_id) %>%
  summarize(tsne_X = mean(tsne_X),
            tsne_Y = mean(tsne_Y)) %>%
  left_join(cluster_gender_t_tests)

write_csv(all_cluster_df, OUTFILE_CENTROIDS)


