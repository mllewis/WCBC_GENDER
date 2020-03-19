# get hue data by book cover
library(tidyverse)
library(here)
library(imager)
library(data.table)

H_OUTPATH <- here("data/processed/books/cover_hue_1.csv")
IMAGE_PATH <- "data/raw/corpora/covers/"
BOOKKEY <- here("data/raw/corpora/key_book_id.csv")
BOUNDARY_FILE <- here("data/processed/books/hue_boundaries_1.csv")

MIN_S <- .05 #.05
MIN_V <- .5 #.5

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
  
  
# get hue data for each book
hue_boundaries <- read_csv(BOUNDARY_FILE) %>%
  select(-hue_mean) %>%
  gather("measure", "value", -colorname) %>%
  data.table()

get_h_data <- function(image_data, min_s, min_v, hb){
  h_values <- image_data %>%
    filter(channel == "H") %>%
    left_join(image_data %>% filter(channel == "S") %>% select(-channel) %>%
                rename(value_s = value)) %>%
    left_join(image_data %>% filter(channel == "V") %>% select(-channel) %>%
                rename(value_v = value)) %>%
    filter(value_s > min_s, value_v > min_v) %>% # remove dark and light colors (see 12_color_distribtion)
    mutate(x_bin = cut(x, 100, labels = F),  # divide color into 100 x 100 grid
           y_bin = cut(y, 100, labels = F)) %>%
    group_by(x_bin, y_bin) %>%
    summarize(mean_h = mean(value)) %>%
    ungroup() 
  
  h_values_counts <-  h_values %>%
    #mutate(h_bin = cut(mean_h, breaks = seq(0, 360, 20), include.lowest = T)) %>% # cut hue space into 36 intervals
    mutate(blue = case_when(mean_h >= hb[colorname == "blue" & measure == "lower_bound"]$value &
                              mean_h <= hb[colorname == "blue" & measure == "upper_bound"]$value ~ 1, TRUE ~ 0),
           green = case_when(mean_h >= hb[colorname == "green" & measure == "lower_bound"]$value &
                              mean_h <= hb[colorname == "green" & measure == "upper_bound"]$value ~ 1, TRUE ~ 0),
           orange = case_when(mean_h >= hb[colorname == "orange" & measure == "lower_bound"]$value &
                     mean_h <= hb[colorname == "orange" & measure == "upper_bound"]$value ~ 1, TRUE ~ 0),
           pink = case_when(mean_h >= hb[colorname == "pink" & measure == "lower_bound"]$value &
                             mean_h <= hb[colorname == "pink" & measure == "upper_bound"]$value ~ 1, TRUE ~ 0),
           purple = case_when(mean_h >= hb[colorname == "purple" & measure == "lower_bound"]$value &
                              mean_h <= hb[colorname == "purple" & measure == "upper_bound"]$value ~ 1, TRUE ~ 0),
           yellow = case_when(mean_h >= hb[colorname == "yellow" & measure == "lower_bound"]$value &
                             mean_h <= hb[colorname == "yellow" & measure == "upper_bound"]$value ~ 1, TRUE ~ 0),
           red = case_when((mean_h >= hb[colorname == "red" & measure == "lower_bound"]$value[1] &
                                mean_h <= hb[colorname == "red" & measure == "upper_bound"]$value[1])|
                             (mean_h >= hb[colorname == "red" & measure == "lower_bound"]$value[2] &
                                mean_h <= hb[colorname == "red" & measure == "upper_bound"]$value[2])
                             ~ 1, TRUE ~ 0)) %>%
    mutate(bin_id = 1:n()) %>%
    select(-x_bin, -y_bin, -mean_h) %>%
    gather("color", "value", -bin_id) %>%
    filter(value == 1) %>%
    count(color) %>%
    mutate(min_s = min_s,
           min_v = min_v)  # normalize prop in each hue space 

  h_values_counts
}


hue_data <- raw_long_form_cover_data %>%
    group_by(book_id) %>%
    nest() %>%
    mutate(temp = map(data, get_h_data, MIN_S, MIN_V, hue_boundaries)) %>%
    select(-data) %>%
    unnest()

write_csv(hue_data, H_OUTPATH)
