# get cover thumbnails from google links 

library(magick)
library(tidyverse)
library(here)

INPATH <- here("data/processed/other/tidy_google_metadata.csv")

all_meta  = read_csv(INPATH) 

save_cover_image <- function(book_id, path){
  print(path)
  current_image <- image_read(path) 
  outpath <- here(paste0("data/raw/corpora/covers/", book_id, ".jpg"))
  image_write(current_image, path = outpath, format = 'jpg')
}

walk2(all_meta$book_id, all_meta$cover_thumbnail_url, save_cover_image)


