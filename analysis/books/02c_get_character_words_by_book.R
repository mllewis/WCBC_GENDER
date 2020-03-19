# get  by-book list of character/person words

library(tidyverse)
library(tidytext)
library(here)


GENDERED_WORDS_PATH <-  here("data/processed/words/gendered_person_words.csv")
CHARACTER_PATH <- here("data/raw/other/character_gender_by_book.csv")
STOP_WORDS_PATH <- here("data/processed/words/stop_words.csv")
TIDYCORPUS_INFILE <- here("data/processed/books/tidytext_kidbook_corpus.csv")

CHARACTER_OUTPATH <- here("data/processed/books/characters_by_book.csv")

# read in character words, gendered person words, and stop words
characters_tidy <- read_csv(CHARACTER_PATH)  %>% # character words
  select(book_id, char_name) %>%
  mutate(char_name = tolower(char_name))

gendered_person_words <- read_csv(GENDERED_WORDS_PATH) %>% # general gendered  words
  pull(gendered_person_word)

stop_words <- read_csv(STOP_WORDS_PATH) %>% # stop words
  pull(word)

# read in tidied corpus
full_tidy_corpus <- read_csv(TIDYCORPUS_INFILE)

character_words_by_book <- full_tidy_corpus %>%
  left_join(characters_tidy) %>%
  mutate(is_char = str_detect(word, char_name), # is the word a character for that book?
         is_gendered = word %in% gendered_person_words, # is the word in the set of gendered person words?
         is_stop_word = word %in% stop_words) %>% # is the word a stop word? (some parts of character words are stop words, e.g., "the")
  filter((is_char | is_gendered) & !is_stop_word)

# get set of person words by book
unique_character_words_by_book <- character_words_by_book %>%
  distinct(book_id, word, .keep_all = T) %>%
  select(book_id, word)

write_csv(unique_character_words_by_book, CHARACTER_OUTPATH)
