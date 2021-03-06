# IAT utility functions

# gets cosine distance using a function from fastrtext
get_word_distance_cos = function(model, w1 , w2){

  # embeddings <- fastrtext::get_word_vectors(model, c(w1, w2))
  embeddings <- model %>%
                  filter(word %in% c(w1, w2)) %>%
                  select(-word) %>%
                  as.matrix()
  if (dim(embeddings)[1] == 2){
  (crossprod(embeddings[1, ], embeddings[2, ])/sqrt(crossprod(embeddings[1,
                                                                         ]) * crossprod(embeddings[2, ])))[1]
  } else {
    NA
  }
}


# gets df with each unique pairing of category and attribute
prep_word_list <- function(word_list) {
  if (length(word_list) > 4) {
    word_list <- word_list[-1:-2]
  }
  cross_df(word_list) %>%
    gather(key = "category_type", value = "category_value", category_1:category_2) %>%
    gather(key = "attribute_type", value = "attribute_value", attribute_1:attribute_2) %>%
    distinct(category_value, attribute_value, .keep_all = TRUE)  %>%
    mutate_all(tolower)
}


# function on the top right of Caliskan pg 2
get_swabs <- function(df, model){
df %>%
    rowwise() %>%
    mutate(cosine_sim = get_word_distance_cos(model, category_value, attribute_value)) %>%
    ungroup() %>% # gets rid of rowwise error message
    group_by(category_type, category_value, attribute_type) %>%
    summarize(word_attribute_mean = mean(cosine_sim, na.rm = T)) %>%
    spread(attribute_type, word_attribute_mean) %>%
    mutate(swab = attribute_1 - attribute_2)
}


# effect size function on Caliskan pg 2 (top right)
get_sYXab <- function(df){
  sYXab_denom <- sd(df$swab, na.rm = T)

  df %>%
    group_by(category_type) %>%
    summarize(mean_swab = mean(swab, na.rm = T)) %>%
    spread(category_type, mean_swab) %>%
    summarize(sYXab_num = category_1 - category_2) %>%
    transmute(sYXab = sYXab_num/sYXab_denom) %>%
    unlist(use.names = FALSE)
}

# wrapper for ES function
get_ES <- function(df, model) {
  print(pluck(df, "test_name"))
  swabs <- prep_word_list(df[-1:-2]) %>%
    get_swabs(., model)

  swab_means <- swabs %>%
    group_by(category_type) %>%
    summarize(mean_swab = mean(swab, na.rm = T)) %>%
    spread(category_type, mean_swab)  %>%
    rename(male_swab = category_1,
           female_swab = category_2)

  es <- get_sYXab(swabs)

  data.frame(test = pluck(df, "test_name"),
             bias_type = pluck(df, "bias_type"),
             effect_size = es) %>%
    bind_cols(swab_means)
}
