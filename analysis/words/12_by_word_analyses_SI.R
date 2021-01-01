# make csv of relationship between word variables for SI
library(tidyverse)
library(broom)
library(glue)
library(knitr)
library(here)

CORR_OUTFILE <- here("data/processed/words/word_properties_corrs.csv")
TASA_OUTFILE <- here("data/processed/words/TASA_word_properties_model.csv")
SUBT_OUTFILE <- here("data/processed/words/SUBTLEXUS_word_properties_model.csv")
CB_OUTFILE <- here("data/processed/words/WCBC_word_properties_model.csv")
ALL_WORD_MEASURES <- here("data/processed/words/all_word_measures_tidy.csv")
all_words_with_norms <- read_csv(ALL_WORD_MEASURES)


############# COR TABLE #############
get_pairwise_tidy_corr <- function(v1, v2, df) {
  cor.test(pull(df, v1), pull(df,v2)) %>%
    tidy()
}

all_words_with_norms_no_na <- all_words_with_norms %>%
  drop_na()

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
VAR_ORDER_LABS <-  c("Gender (fem.)", "Arousal", "Valence", "Concreteness", "AoA", "Frequency (WCBC)", "Frequency (TASA)")
VAR_ORDER_LABS2 <-  c("Gender (fem.)", "Arousal", "Valence", "Concreteness", "AoA", "Frequency (WCBC)", "Frequency (TASA)", "Frequency (SUBTLEX-us)")

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

colnames(cor_table_tidy) <- c("-", VAR_ORDER_LABS)
write_csv(cor_table_tidy, CORR_OUTFILE)

############# MODELS #############
all_words_with_norms_no_na <- all_words_with_norms %>%
  drop_na() %>%
  mutate_if(is.numeric, base::scale)

# models
model_tasa <- lm(gender ~ log_tasa_freq + valence + arousal  + concreteness + adult_aoa,
                 data = all_words_with_norms_no_na)

model_kidbook <- lm(gender ~ log_kidbook_freq + valence + arousal  + concreteness + adult_aoa,
                    data = all_words_with_norms_no_na)

model_subt <- lm(gender ~ log_subt_freq + valence + arousal  + concreteness + adult_aoa,
                 data = all_words_with_norms_no_na)

make_model_pretty <- function(md, type) {

  pretty_model <- md %>%
    tidy() %>%
    rename(Beta = estimate, SE = std.error, Z = statistic, p = p.value) %>%
    mutate(p = case_when(p < .001 ~  "<.001",
                         TRUE ~ as.character(round(p, 3)))) %>%
    mutate_if(is.numeric, ~ round(.,2)) %>%
    select(-term) %>%
    mutate(Term = c("(Intercept)",
                    "Log Frequency",
                    "Valence",
                    "Arousal",
                    "Concreteness",
                    "AoA")) %>%
    select(Term, everything())

  pretty_model_reordered <- pretty_model[c(1,4,3,5,6,2),] %>%
    mutate(p = ifelse(p == "1", ">.99", p),
           model_type = type)

  pretty_model_reordered

}

model_params <- map2_df(list(model_tasa, model_kidbook, model_subt),
                        list("TASA", "CB", "SUBTLEX-us"),
                        make_model_pretty)


tasa_model <- model_params %>%
  filter(model_type == "TASA") %>%
  select(-model_type)

write_csv(tasa_model, TASA_OUTFILE)


subt_model <- model_params %>%
  filter(model_type == "SUBTLEX-us") %>%
  select(-model_type)

write_csv(subt_model, SUBT_OUTFILE)


CB_model <- model_params %>%
  filter( model_type == "CB") %>%
  select(-model_type)

write_csv(CB_model, CB_OUTFILE)

