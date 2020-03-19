# scrape amazon reviews

library(tidyverse)
library(rvest)
library(here)

N_PAGES <- 200
REVIEW_FUNCTION <- here("analysis/books/scrape_reviews_function.R")
REVIEW_PATH <- here("data/raw/other/amazon_links_by_book.csv")
OUTPATH <- here("data/processed/books/scraped_amazon_reviews.csv")

source(REVIEW_FUNCTION)

get_review_for_1_page <- function(book_id, current_url, outfile){
  
  print(book_id)
  current_page_num = str_split(current_url, "pageNumber=")[[1]][2]
  node <- read_html(current_url) %>% 
    html_nodes("div[id*=customer_review]")
  print(current_page_num)
  
  reviews <- lapply(node, get_reviews) %>% 
    bind_rows() %>%
    rename(review_title = title) %>%
    mutate(book_id = book_id,
          page_num = current_page_num) %>%
    select(book_id, page_num, review_title, date, ver.purchase, comments, stars)
  
  write_csv(reviews, outfile, append = T)
}


get_review_for_1_page_safely <- safely(get_review_for_1_page)


#### DO THE THING ####
review_raw <- read_csv(REVIEW_PATH) 

review_tidy <- review_raw %>%
  rowwise() %>%
  mutate(path_tidy = str_split(review_url, "/ref=")[1][[1]][1],
         path_tidy = paste0(path_tidy, "/ref=cm_cr_arp_d_viewopt_srt?ie=UTF8&reviewerType=all_reviews&sortBy=recent&pageNumber="))

full_paths <- cross_df(list(path_tidy = review_tidy$path_tidy, y = 1:N_PAGES)) %>%
  rowwise() %>%
  mutate(path_with_page = paste0(path_tidy, y)) %>%
  left_join(review_tidy %>% select(book_id, path_tidy)) %>%
  select(book_id, path_with_page) 

walk2(full_paths$book_id, 
      full_paths$path_with_page, 
      get_review_for_1_page_safely, OUTPATH)

#get_review_for_1_page_safely(full_paths$book_id[1], 
#                             full_paths$path_with_page[1],OUTPATH)

