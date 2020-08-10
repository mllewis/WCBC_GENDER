# read in raw corpus and save tidied version
library(tidyverse)
library(textclean)
library(tidytext)
library(here)

MONTAG_INFILE <- here("data/raw/corpora/100Books.txt")
BOOKID_KEY <- here("data/raw/corpora/key_book_id.csv")
CONTRACTION_LIST <- here("data/processed/words/contractions_complete.csv")
MONTAG_OUTPATH <- here("experiment/booknorming1/get_stimuli/data/tidy_montag_text_for_exp.csv")


contraction_list <- read_csv(CONTRACTION_LIST)
book_key <- read_csv(BOOKID_KEY)

# read in raw corpus
montag_raw <- read_lines(MONTAG_INFILE)  %>%
  as.data.frame() %>%
  rename("text" = ".")

# tidy titles
montag_titles <- montag_raw %>%
  filter(str_detect(text, regex("^Title", ignore_case = TRUE))) %>%
  rename(title = text) %>%
  mutate(title = str_trim(toupper(str_replace(title, "Title: ", "")))) %>%
  left_join(book_key) %>%
  select(book_id, title, author)

# tidy corpus with titles and line numbers
montag_tidy <- montag_raw %>%
  filter(!str_detect(text, regex("^Author",
                                 ignore_case = TRUE)),
         text != "") %>%
  mutate(row_one = case_when(str_detect(text, regex("^Title",
                                                    ignore_case = TRUE)) ~ 1, TRUE ~ 0),
         title = case_when(row_one == 1 ~ toupper(str_trim(str_replace(text, "Title: ", ""))),
                           TRUE ~ NA_character_)) %>%
  left_join(book_key %>% select(-author)) %>%
  fill(book_id) %>%
  mutate(book_id = as.factor(book_id)) %>%
  filter(row_one == 0) %>%
  select(-row_one, -title) %>%
  group_by(book_id) %>%
  mutate(line_number = row_number()) %>%
  ungroup() %>%
  left_join(montag_titles) %>%
  select(book_id, title, author, line_number, text)

# tidy corpus with cleaned text

montag_tidy_clean <- montag_tidy %>%
  mutate(text = str_replace_all(text, "’", "'"),
         text = str_replace_all(text, "\"", ""),
         text = str_trim(text))
        # text = replace_contraction(text, contraction.key = contraction_list), # replace contractions with uncontrated forms (do this before lowercasing)
        # text = str_replace_all(text, "'s", ""),  # for characters (e.g. "George's") - this is important for our character score
        # text = gsub('[[:punct:] ]+',' ',text), # get rid of punctuation
        # text = tolower(text))

write_csv(montag_tidy_clean, MONTAG_OUTPATH)
