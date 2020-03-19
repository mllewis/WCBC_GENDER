
get_tidy_corr_text <- function(df, var1, var2) {

    cor.test(pull(df, var1), pull(df, var2)) %>%
    tidy() %>%
    mutate(pval2 = case_when((p.value > .01) ~ round(p.value, 2),
                             TRUE ~ round(p.value, 3)),
           r_p_value = case_when(p.value < .001 ~ " _p_ < .001",
                                 TRUE ~ paste0(" _p_ = ", pval2))) %>%
    mutate(corr_print = glue("_r_ = {round(estimate,2)} [{round(conf.low,2)}, {round(conf.high,2)}], {r_p_value}")) %>%
    pull(corr_print)


}

get_tidy_one_sample_t_test_text <- function(x_value, mu_value){
  tidy_t <- t.test(x = x_value, 
         mu = mu_value) %>%
    tidy()  

  tidy_effect_size <- rstatix::cohens_d(data.frame(x_value = x_value), 
                         x_value ~ 1, mu = mu_value, 
                         ci = T) %>%
                select(effsize, conf.low, conf.high) %>%
                rename(conf_low_d = conf.low,
                       conf_high_d = conf.high) %>%
                mutate_all(round, 2)
  
  bind_cols(tidy_t, tidy_effect_size) %>%
    mutate(pval2 = case_when((p.value > .01) ~ round(p.value, 2),
                             TRUE ~ round(p.value, 3)),
           t_p_value = case_when(p.value < .001 ~ " _p_ < .001",
                                 TRUE ~ paste0(" _p_ = ", pval2))) %>%
    mutate(t_print = glue("_t_({parameter}) = {round(statistic,2)}, {t_p_value}; _d_ = {effsize} [{conf_low_d}, {conf_high_d}]")) %>%
    pull(t_print)
  
}
