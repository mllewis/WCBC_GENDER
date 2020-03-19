# get sv data by book cover
library(tidyverse)
library(here)
library(imager)

SV_OUTPATH <- here("data/processed/books/cover_sv.csv")
IMAGE_PATH <- "data/raw/corpora/covers/"
BOOKKEY <- here("data/raw/corpora/key_book_id.csv")
book_key <- read_csv(BOOKKEY) %>%
  pull(book_id)

# load image data for each book
get_image_data <- function(id, path){
  full_path = here(paste0(path, id, ".jpg"))
  
  full_path %>%
    load.image() %>%
    RGBtoHSV() %>%
    as.data.frame() %>%
    mutate(channel = factor(cc, labels = c('H','S','V')),
           book_id = id) %>%
    select(book_id, x, y, channel, value) 
}

raw_long_form_cover_data <- map_df(book_key, 
                                   get_image_data, 
                                   IMAGE_PATH)

# get s-v data 
get_sv_data <- function(image_data){
  sv_values <- image_data %>%
    filter(channel %in% c("S", "V")) %>%
    mutate(x_bin = cut(x, 100, labels = F),  # divide color into 100 x 100 grid
           y_bin = cut(y, 100, labels = F)) %>%
    group_by(x_bin, y_bin, channel) %>%
    summarize(mean = mean(value)) %>%
    group_by(channel) %>%
    summarize(mean = mean(mean)) %>%
    gather("metric", "value", -channel)
 
  sv_values
}

sv_data <- raw_long_form_cover_data %>%
    group_by(book_id) %>%
    nest() %>%
    mutate(temp = map(data, get_sv_data)) %>%
    select(-data) %>%
    unnest()

write_csv(sv_data, SV_OUTPATH)
