# get samples of coca corpus
library(tidyverse)
library(here)

KIDBOOK_LENGTHS <-  here("data/processed/iat/other/kid_books_lengths.csv")
COCA_TIDY <-  here("data/processed/iat/corpora/tidy_coca_corpus_full.csv")
SAMPLED_OUTPATH <- here("data/processed/iat/corpora/coca_sampled/")
NSAMPLES <- 10

# get target coca books
coca_tidy <- read_csv(COCA_TIDY)

# get kidbook lengths
kidbook_lengths <- read_csv(KIDBOOK_LENGTHS)

# select only those coca books that have at least the max words of a kid book
target_coca_books <- coca_tidy %>%
  count(coca_book_id) %>%
  filter(n >= max(kidbook_lengths$n)) %>%
  pull(coca_book_id)

# nest coca books
nested_coca <- coca_tidy %>%
  filter(coca_book_id %in% target_coca_books) %>%
  group_by(coca_book_id) %>%
  nest()

# sample corpora
get_single_book_sample <- function(book_data, n_words){
  start_i <- sample(1:(nrow(book_data) - n_words), 1)  # get random starting point in the book
  end_i <- start_i + (n_words - 1)
  slice(book_data, start_i:end_i)
}

get_corpus_sample <- function(sample_id, full_nested_corpus, kid_lengths, outpath){

  book_samples <- data.frame(coca_book_id = sample(unique(full_nested_corpus$coca_book_id),
                                                   length(kid_lengths)), # sample books to train on
                             book_lengths = kid_lengths)

  sampled_corpus <- full_nested_corpus %>%
    right_join(book_samples) %>%
    mutate(temp = map2(data, book_lengths, get_single_book_sample)) %>%
    select(-data) %>%
    unnest() %>%
    group_by(coca_book_id) %>%
    summarize(book_text = paste0(word, collapse = " "))

  full_outpath <- paste0(outpath,"sampled_coca_", sample_id, ".txt")
  writeLines(sampled_corpus$book_text, full_outpath)
}

walk(1:NSAMPLES, get_corpus_sample,
     nested_coca,
     kidbook_lengths$n,
     SAMPLED_OUTPATH)
