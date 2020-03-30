# table of pairwise word measure correlations including all three frequency measures (TASA, WCBC, SUBTLEXUS)

library(tidyverse)
library(tidytext)
library(here)
library(glue)

CORR_TABLE_OUTFILE <- here("data/processed/words/gender_pairwise_corrs.csv")
ALL_WORD_MEASURES <- here("data/processed/words/all_word_measures_tidy.csv")

all_words_with_norms <- read_csv(ALL_WORD_MEASURES)
all_words_with_norms_no_na <- all_words_with_norms %>%
  drop_na()

get_pairwise_tidy_corr <- function(v1, v2, df) {
  cor.test(pull(df, v1), pull(df,v2)) %>%
    tidy()
}

tidy_corrs <-  expand.grid(names(all_words_with_norms_no_na[,-1]),
                           names(all_words_with_norms_no_na[,-1]), stringsAsFactors = FALSE) %>%
  filter(Var1 != Var2) %>%
  mutate(temp = map2(Var1, Var2, get_pairwise_tidy_corr, all_words_with_norms_no_na)) %>%
  unnest() %>%
  mutate(sig = case_when(p.value < .001 ~ "***", p.value < .01 ~ "**", p.value < .05 ~ "*",  TRUE ~ "" ),
         estimate_round = case_when(abs(round(estimate, 2)) < .01 ~ "0.00",
                                    TRUE ~ as.character({round(estimate, 2)})),
         estimate_print = as.character(glue("{estimate_round}{sig}")))

VAR_ORDER <-  c("gender", "arousal", "valence", "concreteness", "adult_aoa", "log_kidbook_freq", "log_tasa_freq", "log_subt_freq")
VAR_ORDER_LABS <-  c("Gender\n(fem.)", "Arousal", "Valence", "Concreteness", "AoA", "Frequency\n(WCBC)", "Frequency\n(TASA)")
VAR_ORDER_LABS2 <-  c("Gender (fem.)", "Arousal", "Valence", "Concreteness", "AoA", "Frequency (WCBC)", "Frequency (TASA)", "Frequency  (SUBTLEX-us)")

cor_table <- tidy_corrs %>%
  select(Var1, Var2, estimate_print) %>%
  pivot_wider(names_from = Var1, values_from = estimate_print, values_fill = list(estimate_print = "")) %>%
  select(Var2, VAR_ORDER) %>%
  slice(match(VAR_ORDER, Var2)) %>%
  mutate(Var2 = VAR_ORDER_LABS2)  %>%
  column_to_rownames(var = "Var2") %>%
  as.matrix()

cor_table[upper.tri(cor_table)] <- ""

cor_table_tidy <- cor_table %>%
  as.data.frame() %>%
  rownames_to_column("Var2") %>%
  slice(-1) %>% # get rid of empty column/rows due to missing top diag
  select(-9)

colnames(cor_table_tidy) <- c("", VAR_ORDER_LABS)

write_csv(cor_table_tidy, CORR_TABLE_OUTFILE)
