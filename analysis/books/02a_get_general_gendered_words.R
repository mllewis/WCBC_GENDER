# get non book-specific gendered person words
# three kinds of words from the coropra: (1) pronouns;
# (2) person names ("mother", "mister") and (3) proper people names in our normed words.


library(tidyverse)
library(here)

NORMED_WORDS <- here("data/processed/words/gender_ratings_mean.csv")
GENDERED_PERSON_WORDS <- here("data/processed/words/gendered_person_words.csv")

# all target words
PRONOUNS_WORDS <- c("she", "he", "her", "him", "hers", "his", "herself", "himself")
PERSON_WORDS <- c("mother", "mommy", "mom", "father", "daddy", "dad", "brother", "boy",
                  "sister", "girl", "grandma", "grandmother", "grandpa", "grandfather", 
                  "aunt", "uncle", "ma", "pa", "madame", "mister", "man", "woman", "lady", 
                  "gentleman", "mr.", "mrs.")

BAD_PROPER <- c("Dr.", "March (month)", "Miss (title of person)", "Monday", "Mr.", "Mrs.",
                "November", "Paris", "Thursday", "Wednesday", "Tuesday", "California", "York",
                "Mars", "French", "France", "Japan", "London", "Hippopotomus", 
                "April", "Blaze", "Grouchy", "Moose", "Rocky", "Rocket", "Triangle")

person_proper <- read_csv(NORMED_WORDS) %>%
  filter(str_detect(word, "^[[:upper:]]")) %>%
  mutate(word = case_when(word == "Rocky (name)" ~ "Rocky",
                          word == "Spike (name)" ~ "Spike",
                          TRUE ~ word)) %>%
  filter(!(word %in% BAD_PROPER)) %>%
  pull(word) %>%
  tolower()

all_gendered_person_words <- data.frame(gendered_person_word = 
                                          c(PRONOUNS_WORDS, PERSON_WORDS, person_proper)) 

write_csv(all_gendered_person_words, GENDERED_PERSON_WORDS)