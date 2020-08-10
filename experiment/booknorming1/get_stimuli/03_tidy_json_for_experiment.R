# add js to book data

library(tidyverse)
library(here)


JSON_OUTPATH <- here("experiment/booknorming1/get_stimuli/data/json_booktext.json")
JS_OUTPATH <-here("experiment/booknorming1/data.js")

raw_text <- read_lines(JSON_OUTPATH)
new_text<- paste0('var text = \'', raw_text, "\'")

write_lines(new_text, JS_OUTPATH)

#NEXT: in sublime, manually replace slashes in data.js (correct: \\" and \')
