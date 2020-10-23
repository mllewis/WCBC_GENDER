# get tidy coca corpus of fiction books (years: 2008 - 2017)
library(tidyverse)
library(tidytext)
library(here)

COCA_FICTION_INFILE <- here("data/raw/corpora/coca_fiction/")
COCA_TIDY <- here("data/processed/iat/corpora/tidy_coca_corpus_full.csv")
tidy_coca_slice <- function(path){
  current_year <- str_split(str_split(path, "w_fic_")[[1]], ".txt")[[2]][1]

  coca_raw <- readLines(path, encoding = "latin1") %>%
    unlist() %>%
    as.data.frame() %>%
    rename(text = ".")

  unnested_corpus <- coca_raw %>%
    mutate_all(as.character) %>%
    unnest_tokens(word, text) %>%
    rownames_to_column("word_id") %>%
    mutate(year = current_year)

  unnested_corpus
}

raw_coca_files <- list.files(COCA_FICTION_INFILE, full = T)
coca_raw_unnested <- map_df(raw_coca_files, tidy_coca_slice)

full_tidy_corpus <- coca_raw_unnested %>%
   mutate(word_id = as.numeric(word_id),
          is_book_id = word_id == round(word_id),
          coca_book_id = case_when(is_book_id ~ word, TRUE ~ NA_character_)) %>%
   fill(coca_book_id) %>%
   filter(!is_book_id) %>%
   unite("coca_book_id", c("coca_book_id", "year"), sep = "-") %>%
   group_by(coca_book_id) %>%
   mutate(word_id = 1:n()) %>%
   select(coca_book_id, word_id, word)

write_csv(full_tidy_corpus, COCA_TIDY)
