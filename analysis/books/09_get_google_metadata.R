# get book metadata from google api (book cover url plus additional data)

library(tidyverse)
library(XML)
library(RCurl)
library(jsonlite)
library(here)


INFILE <- here("data/raw/other/isbn_year_by_book.csv") 
# Note: this was done through an iterative procedure where ISBN were manually searched
# to find the one google books uses
OUTFILE <- here("data/processed/other/google_books_metadata3.csv")

isbn_df <- read_csv(INFILE) %>%
    select(title, isbn_updated) %>%
    mutate(isbn_seperated = str_split(isbn_updated, " ")) %>%
    select(-isbn_updated) %>%
    unnest() %>%
    mutate(isbn_seperated = str_replace_all(isbn_seperated, "\r|-", "")) 
  
get_book_meta_data <- function(current_isbn, outfile){
  url_path <- paste0("https://www.googleapis.com/books/v1/volumes?q=isbn:", current_isbn)
  json_result <- getURL(url_path,ssl.verifyhost=F,ssl.verifypeer=F,followlocation=T)
  rs <- fromJSON(json_result)$items
  
  print(rs$volumeInfo$title)
  print(current_isbn)
  if (!is.null(rs)) {
    # get data we want
    out_data <- data.frame(isbn = current_isbn,
               title = ifelse(!is.null(rs$volumeInfo$title), rs$volumeInfo$title, NA),
               publisher = ifelse(!is.null(rs$volumeInfo$publisher), rs$volumeInfo$publisher, NA),
               published_date = ifelse(!is.null(rs$volumeInfo$publishedDate), rs$volumeInfo$publishedDate, NA),
               publisher_desription = ifelse(!is.null(rs$volumeInfo$description), rs$volumeInfo$description, NA),
               n_pages = ifelse(!is.null(rs$volumeInfo$pageCount), rs$volumeInfo$pageCount, NA),
               category = ifelse(!is.null(rs$volumeInfo$categories[[1]]), rs$volumeInfo$categories[[1]], NA),
               mean_rating = ifelse(!is.null(rs$volumeInfo$averageRating), rs$volumeInfo$averageRating, NA),
               num_ratings = ifelse(!is.null(rs$volumeInfo$ratingsCount), rs$volumeInfo$ratingsCount, NA),
               sale_country = ifelse(!is.null(rs$saleInfo$country), rs$saleInfo$country, NA),
               access_country = ifelse(!is.null(rs$accessInfo$country), rs$accessInfo$country, NA),
               cover_thubnail_url = ifelse(!is.null(rs$volumeInfo$imageLinks$thumbnail), rs$volumeInfo$imageLinks$thumbnail, NA),
               preview_url = ifelse(!is.null(rs$volumeInfo$previewLink), rs$volumeInfo$previewLink, NA))
  } else {
    out_data <- data.frame(isbn = current_isbn,
                           title = NA,
                           publisher = NA,
                           published_date = NA,
                           publisher_desription = NA,
                           n_pages = NA,
                           category = NA,
                           mean_rating = NA,
                           num_ratings = NA,
                           sale_country = NA,
                           access_country = NA,
                           cover_thubnail_url = NA,
                           preview_url = NA)
    
  }
  
  write_csv(out_data, outfile, append = T)
  Sys.sleep(3)
}


walk("0060586532",get_book_meta_data, OUTFILE)




