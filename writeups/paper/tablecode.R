
```{r}
simple_corr <- psych::corr.test(all_words_with_norms[,-1], adjust = "none")$r %>%
  as_tibble(rownames = "rowname") %>%
  gather("var2", "simple_r", -rowname)

simple_corr_p <- psych::corr.test(all_words_with_norms[,-1], adjust = "none")$p %>%
  as_tibble(rownames = "rowname") %>%
  gather("var2", "simple_p", -rowname)

tidy_corrs <- simple_corr %>%
  left_join(simple_corr_p) 

text_tidy_corrs <- tidy_corrs %>%
  filter(rowname != var2) %>%
  mutate_at(vars(simple_r, simple_p), ~ round(.,2)) %>%
  rowwise() %>%
  mutate(r_equality_sign = case_when(simple_p < .01 ~ ", _p_ < .01", 
                                     TRUE ~ paste0(", _p_ = ", simple_p)),
         r_print_text = paste0("_r_ = ", simple_r , r_equality_sign)) 

print_tidy_corrs <- tidy_corrs %>%
  filter(rowname != var2) %>%
  mutate(simple_p  =  case_when(
    simple_p < .01 ~ "**", simple_p < .05 ~ "*",  TRUE ~ "")) %>%
  mutate(simple_r = round(simple_r,2),
         r_print = paste0(simple_r, simple_p)) %>%
  select(rowname, var2, r_print)

tidy_corrs_to_print <- print_tidy_corrs %>%
  spread(var2, r_print)  %>%
  mutate_all(funs(replace_na(., ""))) %>%
  select(1,6,3,8,5,4,2,7) 
```

```{r}
tidy_corrs_to_print_reordered <- tidy_corrs_to_print[c(5,2,7,4,3,1,6),] %>%
  mutate(" " = c("Gender (female-ness)", "Arousal", "Valence", "Dominance", "Concreteness", "AoA","Frequency (log)")) %>%
  select(" ", everything()) %>%
  select(-rowname)

kable(tidy_corrs_to_print_reordered,
      format = "latex",
      booktabs = T, 
      escape = F,
      caption = "Pairwise correlation (Pearson's r) between all word norms.  Single astericks indicate p < .05 and double astericks indicate p < .01.",
      align = "lrrrrrrr",
      col.names = c(" ", "Gender (female-ness)", "Arousal", "Valence", "Dominance", "Concreteness", "AoA","Frequency (log)")) %>%
  column_spec(2:8, width = "1.4cm") %>%
  kable_styling(bootstrap_options = "condensed", 
                full_width = F,  font_size = 4)
```
