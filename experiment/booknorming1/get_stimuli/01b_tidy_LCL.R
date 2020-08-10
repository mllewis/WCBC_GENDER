# read in raw corpus and save tidied version
library(tidyverse)
library(tidytext)
library(textclean) # for contraction cleaning
library(here)

LCNL_INFILE <- here("data/raw/corpora/cdtc_lcnl_corpus_by_book/")
BOOKID_KEY <- here("data/raw/corpora/key_book_id.csv")
LCL_OUTPATH <-  here("experiment/booknorming1/get_stimuli/data/tidy_lcl_text_for_exp.csv")

clean_titles_from_transcription <- function(text) {
  text %>%
    str_replace_all("â\u0080\u0099", "'") %>%
    str_replace_all( "\u0092", "'")
}


clean_text_from_transcription <- function(text) {
  text %>%
    str_replace_all( "â\u0080\u009c", "\"") %>%
    str_replace_all( "â\u0080\u009d", "\"") %>%
    str_replace_all("â\u0080\u0098", "'") %>%
    str_replace_all("â\u0080\u0099", "'") %>%
    str_replace_all("â\u0080\u0093", "-") %>%
    str_replace_all("â\u0080\u0094", "-") %>%
    str_replace_all("â\u0092", "'") %>%
    str_replace_all("\u0092", "'") %>%
    str_replace_all("\u0097", "-") %>%
    str_replace_all( "\u0085", "...") %>%
    str_replace_all( "\u0093", "'") %>%
    str_replace_all( "\u0094", "'") %>%
    str_replace_all( "â\u0080", "...") %>%
    str_replace_all("", "\u00e0")
    str_replace_all( "â\u0085", "...")
}

contraction_list <- read_csv(CONTRACTION_LIST)
book_key <- read_csv(BOOKID_KEY)

# read in raw corpus
raw_lcnl_files <- list.files(LCNL_INFILE, full = T)[146]
lcnl_raw <- map(raw_lcnl_files, readLines, encoding = "latin1") %>%
  unlist()  %>%
  as.data.frame() %>%
  rename(text = ".")

# tidy titles
lcnl_titles <- lcnl_raw %>%
  filter(str_detect(text, regex("^Title", ignore_case = TRUE)))  %>%
  rename(title = text) %>%
  mutate(title = str_trim(str_replace(title, "Title: ", "")),
         title = map_chr(title, clean_titles_from_transcription),
         title = toupper(title)) %>%
  left_join(book_key) %>%
  select(book_id, title, author)

# tidy corpus with titles and line numbers
lcnl_tidy <- lcnl_raw %>%
  filter(!str_detect(text, regex("^Author",
                                 ignore_case = TRUE)),
         text != "") %>%
  mutate(row_one = case_when(str_detect(text, regex("^Title",
                                                    ignore_case = TRUE)) ~ 1, TRUE ~ 0),
         title = case_when(row_one == 1 ~ str_trim(str_replace(text, "Title: ", "")),
                           TRUE ~ NA_character_),
         title = map_chr(title, clean_titles_from_transcription),
         title = toupper(title)) %>%
  left_join(book_key %>% select(-author)) %>%
  fill(book_id) %>%
  filter(row_one == 0) %>%
  select(-row_one, -title) %>%
  group_by(book_id) %>%
  mutate(line_number = row_number()) %>%
  ungroup() %>%
  left_join(lcnl_titles) %>%
  select(book_id, title, author, line_number, text)

# tidy corpus with cleaned text
lcnl_tidy_clean <- lcnl_tidy %>%
    mutate(text = map_chr(text, clean_text_from_transcription))

write_csv(lcnl_tidy_clean, LCL_OUTPATH)


#test <-  lcnl_tidy_clean %>% filter(book_id == "L130") %>%
#  select(text)

#test
