# get edges using method described here:  # see https://cran.r-project.org/web/packages/imager/vignettes/gettingstarted.html
library(imager)
library(tidyverse)
library(here)

IMAGE_PATH <- "data/raw/corpora/covers/"
BOOKKEY <- here("data/raw/corpora/key_book_id.csv")
EDGE_OUTFILE <- here("data/processed/books/cover_edge.csv")


book_key <- read_csv(BOOKKEY) %>%
  pull(book_id)

# load image data for each book
get_image_edges <- function(id, path){
  full_path = here(paste0(path, id, ".jpg"))
  edges <- load.image(full_path) %>%
    grayscale() %>%
    imgradient(.,"xy") %>% 
    enorm() %>%
    as.data.frame() %>%
    mutate(book_id = id) %>%
    select(book_id, everything())
  
  edges
}


long_form_edge_data <- map_df(book_key, 
                                   get_image_edges, 
                                   IMAGE_PATH)

write_csv(long_form_edge_data, EDGE_OUTFILE)

