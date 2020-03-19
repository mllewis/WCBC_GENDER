# cluster coefficient helpers

# wrapper function
write_overlap_coefficient <- function(nvectors, nthreads, 
                                      niter, windowsize, 
                                      mincount, nrandom, 
                                      nclosestwords, corpus_path,
                                      outputpath, 
                                      word_pairs,
                                      model_type){
  
  print ("")
  print("== training the model ==")
  current_model <- train_the_model(corpus_path, nvectors, nthreads, niter, windowsize, mincount, negative = 5, model_type)
  
  # get count of how many of pair words are actually in the models
  pair_counts <- get_target_pair_counts(word_pairs, current_model)
  
  print ("== calculating coefficients ==")
  # make random word pair list for baselin
  all_words <- ifelse(model_type == "gensim", list(current_model$wv$index2word), list(rownames(current_model))) # diff for gensim, WV
  random_word_pairs <- data.frame(word1 = sample(unlist(all_words), nrandom),
                                  word2 = sample(unlist(all_words), nrandom),
                                  word_type = "random")
  
  full_word_pairs <- bind_rows(word_pairs, random_word_pairs)
  
  # get_coefficient for each word pairs
  all_word_pairs <- pmap_df(list(full_word_pairs$word1, full_word_pairs$word2, full_word_pairs$word_type),
                            get_clustering_wrapper, 
                            nclosestwords, 
                            current_model) 
  
  # get meeran coefficient across word types and label stuff      
  coeffs <- all_word_pairs %>%
    group_by(word_type) %>%
    langcog::multi_boot_standard(col = "cluster_coefficient", na.rm = T)  %>%
    rename(overlap_coefficient = mean) %>%
    mutate(n_random = nrandom,
           n_closest_words = nclosestwords,
           n_vectors = nvectors, 
           n_threads = nthreads,
           n_iter = niter,
           windowsize = windowsize,
           min_count = mincount,
           model_type = model_type,
           corpus = corpus_path)   %>%
    left_join(pair_counts)
  
  write_csv(coeffs, outputpath, append = T)
}

# get target list count wrapper
get_target_pair_counts <- function(wordpairs, model){
  if (class(model) != "VectorSpaceModel"){
    words_in_model = model$wv$index2word
  } else {
    words_in_model = rownames(model) 
  }  
  counts <- pmap_df(list(wordpairs$word1, wordpairs$word2, wordpairs$word_type), 
            get_counts_of_target_words_in_model, words_in_model) %>%
      filter(in_model) %>%
      count(word_type) 
  
  counts
  # write_csv(counts %>% select(-in_model), "../data/good_bats_word_list.csv")

}

# not all words in target list are actually in the model - count them
get_counts_of_target_words_in_model <- function(w1, w2, type, words_in_model){
  
  word_check <- ((w1 %in% words_in_model) & (w2 %in% words_in_model))
  
  data.frame(word1 = w1, 
             word2 = w2, 
             word_type = type,
             in_model = word_check)
}

# train the model with set of params
train_the_model <- function(corpus_path, nvectors, nthreads, niter, windowsize, mincount, negative, type){
  
  if (type == "gensim"){ # gensim
    corpus <- read_lines(corpus_path)   %>%
      str_split(" ")
    
    the_model <- gensim$models$Word2Vec(
      min_count = mincount,
      window =  windowsize,
      iter = niter,
      workers = nthreads,
      size = nvectors,
      negative = negative, 
      sg = 1 # use skip-gram (better for rare words)
    )
    
    the_model$build_vocab(sentences = corpus)
    the_model$train(
      sentences = corpus,
      epochs = the_model$iter, 
      total_examples = the_model$corpus_count)
    
  } else if (type == "WV") { # wordVectors
    the_model <- wordVectors::train_word2vec(corpus_path,
                                        "../data/childers_book_vectors_uni.bin", 
                                        vectors = nvectors, threads = nthreads, iter = niter, 
                                        negative_samples = negative, force = T , cbow = 0, # default skipgram
                                        window = windowsize,  min_count = mincount)
  } 
  
  the_model
}

# get cluster wrapper - works slightly differently for gensim/wv
get_clustering_wrapper <- function(word1, word2, word_type, nwords, model){

  # get the closest nwords to each target word
  if (class(model) != "VectorSpaceModel"){ # tests if it's a WV model
    target_words_in_model <- (as.character(word1) %in% model$wv$index2word) & (as.character(word2) %in% model$wv$index2word)
   
     if (target_words_in_model){
       
      crit_words <- map2_df(c(as.character(word1), as.character(word2)), 
                            c("group1", "group2"), 
                            function(x, y, nwords, model){
                                sim_words <- model$wv$most_similar(positive = x, topn = as.integer(nwords))

                                data.frame(group = y, 
                                           target_word = unlist(purrr::transpose(sim_words)[1]))  %>%
                                  filter(target_word != "")
                            }, nwords, model) %>%
        data.table()
    } else {
      crit_words <- NULL
    }
    
  } else { # wordVectors model
    target_words_in_model <- (as.character(word1) %in% rownames(model)) & (as.character(word2) %in% rownames(model))
    
    if (target_words_in_model) {
      crit_words <- map2_df(c(as.character(word1), as.character(word2)), 
                            c("group1", "group2"), 
                            function(x, y, nwords, model){
                              model %>% 
                                wordVectors::closest_to(x, n = nwords + 1, fancy_names = F) %>%
                                slice(-1) %>% # remove target word (x)
                                mutate(group = y) %>%
                                rename(target_word = word) %>%
                                filter(target_word != "")
                            }, nwords, model) %>%
        data.table()
    } else {
      crit_words <- NULL
    }
  }
  
  if (!is.null(crit_words)){
    if (class(model) != "VectorSpaceModel"){
    crit_model  <- model$wv$syn0 %>%
      data.table()  %>%
      cbind(target_word = model$wv$index2word) %>%
      merge(crit_words %>% select(-group), all.y = TRUE)

    } else {

      crit_model  <- model %>%
        as.matrix.data.frame() %>% # this is necessary because there's a bug in vectormode -> df
        data.table()  %>%
        cbind(target_word = rownames(model)) %>%
        merge(crit_words %>% select(-group), all.y = TRUE)
      
      crit_model[,similarity:=NULL]
    }

    dists <- get_pairwise_dist_beween_words(crit_model)
    clustering_coeff <- get_clustering_coefficient(dists, crit_words)

    clustering_coeff %>%
      mutate(word1 = word1, 
             word2 = word2,
             word_type = word_type) %>%
      select(word1, word2, word_type, everything())
  }
}

# get pairwise distances between target words
get_pairwise_dist_beween_words <- function(d){
  model_matrix <- as.matrix(d[,-"target_word"])
  word_df <- data.frame(words = d$target_word,
                        Var =  unlist(map(1:length(d$target_word),~paste0("v", .x))))
  
  word_word_dists_wide <- suppressMessages(
    philentropy::distance(model_matrix, method = "cosine")
    ) # suppress log meassage
  
  word_word_dists_long <- word_word_dists_wide %>%
                reshape2::melt() %>%
                subset(value != 0) %>%
                mutate_if(is.factor, as.character) %>%
                left_join(word_df, by = c("Var1" = "Var")) %>% # merge in words
                rename(w1 = words) %>%
                left_join(word_df, by = c("Var2" = "Var")) %>%
                rename(w2 = words,
                       cos_dist = value) %>%
                select(w1, w2, cos_dist) 
    
  word_word_dists_long
}

# given pairwise distances between words clusters, get clustering coefficient
get_clustering_coefficient <- function(dists, crit_words){

  labeled_dists <- dists %>%
    left_join(crit_words, 
              by = c("w1" = "target_word")) %>%
    rename(group_name1 = group) %>%
    left_join(crit_words, 
              by = c("w2" = "target_word")) %>%
    rename(group_name2 = group) 
  
  # get within 1 
  within_group1_mean <- labeled_dists %>%
    filter(group_name1 == "group1" & group_name2 == "group1") %>%
    summarize(mean_group1 = mean(cos_dist)) %>%
    unlist(use.names = F)
  
  # get within 2
  within_group2_mean <- labeled_dists %>%
    filter(group_name1 == "group2" & group_name2 == "group2") %>%
    summarize(mean_group1 = mean(cos_dist)) %>%
    unlist(use.names = F)
  
  # across mean
  across_mean <- labeled_dists %>%
    filter(group_name1 != group_name2) %>%
    summarize(mean_group1 = mean(cos_dist)) %>%
    unlist(use.names = F)
  
  cluster_coefficient <- across_mean/((within_group1_mean + within_group2_mean)/2)
    data.frame(cluster_coefficient = cluster_coefficient,
                across_mean = across_mean, 
                within_group1_mean = within_group1_mean, 
                within_group2_mean = within_group2_mean)
}
