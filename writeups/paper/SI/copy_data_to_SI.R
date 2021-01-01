# In order to deploy the shiny app to shinyapp.io all of the data has to be stored locally,
# in the SI shiny app folder. This means there two copies of the data in the repo, which means
# that when changes are made to processed data in the main analysis scripts these don't get
# automatically updated in the SI app. This script copies the relevant files and writes them
# to the SI directory. Run this script before deploying the app to ensure all data is up to date.

library(here)
library(tidyverse)

data_for_SI <-
  list(
    here("data/raw/other/isbn_year_by_book.csv"),
    here("data/raw/other/advert_age_by_book.csv"),
    here("data/processed/books/gender_token_type_by_book.csv"),
    here("data/raw/other/character_gender_by_book.csv"),
    here("data/processed/words/cluster_labels.csv"),
    here("data/processed/words/gender_centroids_tsne_coordinates.csv"),
    here("data/processed/words/gender_word_tsne_coordinates.csv"),
    here("data/processed/words/gender_ratings_mean.csv"),
    here("data/processed/other/audience_mixed_effect_models.csv"),
    here("data/processed/other/audience_plot_data.csv"),
    here("data/processed/words/word_properties_corrs.csv"),
    here("data/processed/words/TASA_word_properties_model.csv"),
    here("data/processed/words/SUBTLEXUS_word_properties_model.csv"),
    here("data/processed/words/WCBC_word_properties_model.csv"),
    here("data/processed/books/character_mixed_effect_models.csv"),
    here("data/processed/books/character_gender_means.csv"),
    here("data/processed/words/by_word_embedding_corr_table.csv"),
    here("data/processed/other/year_interaction_model.csv"), # year analyses
    here("data/processed/other/year_all_plot.jpeg"),
    here("data/processed/other/year_char_plot.jpeg")

)

copy_to_si_dir <- function(old_filepath) {
  if (str_detect(old_filepath, ".csv")){
    current_file <- read_csv(old_filepath)
    new_file_path <- paste0("writeups/paper/SI/data/", tail(str_split(old_filepath, "/")[[1]],1))
    write_csv(current_file, here(new_file_path))
  } else {
    new_file_path <- here("writeups/paper/SI/data/")
    file.copy(old_filepath, new_file_path)
    }
}

walk(data_for_SI, copy_to_si_dir)
