# get number of turkers excluded based on attention checks;
# this is from Gary.
library(tidyverse)
library(here)

EXCLUDED_TURKERS_PATH <- here("data/raw/gender_norms/excluded_turkers/")
OUTFILE <- here("data/processed/words/n_participants_attention_excluded.csv")

num_excluded_attention_check <-
  list.files(path = EXCLUDED_TURKERS_PATH, 
             pattern = "*attention*",
             full.names = TRUE) %>% 
  map_df(~read_csv(.)) %>%
  nrow() 

num_excluded_midpoint <- 
  list.files(path = EXCLUDED_TURKERS_PATH, 
             pattern = "*midpoint*",
             full.names = TRUE) %>% 
  map_df(~read_csv(.) %>% mutate_all(as.character)) %>%
  nrow() 

exclusion_df <- data.frame(num_excluded_attention_check = num_excluded_attention_check,
           num_excluded_midpoint = num_excluded_midpoint)

write_csv(exclusion_df, OUTFILE)