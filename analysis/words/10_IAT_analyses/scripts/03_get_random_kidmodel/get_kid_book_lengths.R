library(tidyverse)
library(tidytext)

INFILE1 <- "../data/100Books.txt"
INFILE2 <- "../data/cdtc_lcnl_corpus_by_book"
OUTFILE <- "../data/montag_word_counts.csv"

# read in two sets of corpora
d_raw1 <- read_lines(INFILE1)  %>%
  as.data.frame() %>%
  rename("text" = ".") 

raw_files <- list.files(INFILE2, full = T)
all_books <- map(raw_files, readLines, encoding = "latin1") %>%
  unlist() 

d_raw2 <- all_books %>%
  as.data.frame() %>%
  rename("text" = ".") 

d_raw = bind_rows(d_raw1, d_raw2)

# get counts
book_titles <- d_raw %>%
  filter(str_detect(text, regex("^Title", ignore_case = TRUE))) %>%
  rename(title = text) %>%
  mutate(book_id = 1:n(),
         title = str_replace(title, "Title: ", "")) %>%
  select(book_id, title)

author_names <- d_raw %>%
  filter(str_detect(text, regex("^Author", ignore_case = TRUE))) %>%
  rename(author = text) %>%
  mutate(book_id = 1:n(),
         author = str_replace(author, "Author: ", "")) %>%
  select(book_id, author)

d_clean <- d_raw %>%
  mutate(book_id = cumsum(str_detect(text, regex("^Title",
                                                 ignore_case = TRUE)))) %>%
  left_join(book_titles) %>%
  left_join(author_names) %>%
  filter(!str_detect(text, regex("^Title",
                                 ignore_case = TRUE)),
         !str_detect(text, regex("^Author",
                                 ignore_case = TRUE)),
         text != "") %>%
  group_by(book_id) %>%
  mutate(line_number = row_number(),
         text = as.character(text)) %>%
  ungroup() %>%
  select(book_id, title, author, line_number, text)

book_word_counts <- d_clean %>%
  unnest_tokens(word, text) %>%
  count(book_id, title, author) 

write_csv(book_word_counts, OUTFILE)
