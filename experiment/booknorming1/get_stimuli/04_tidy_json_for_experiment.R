# add js to book data

library(tidyverse)
library(here)


JSON_OUTPATH <- here("experiment/booknorming1/get_stimuli/data/json_booktext.json")
JS_OUTPATH <-here("experiment/booknorming1/exp_code/data.js")

raw_text <- read_lines(JSON_OUTPATH)
new_text<- paste0('var text = \'', raw_text, "\'")

write_lines(new_text, JS_OUTPATH)

#NEXT: in sublime, manually replace slashes in data.js (correct: \\" and \')

#Run these lines in terminal:
sed -i '' 's/\\"/\"/g' /Users/mollylewis/Documents/research/Projects/1_in_progress/WCBC_GENDER/experiment/booknorming1/exp_code/data.js
sed -i "" "s/\\\'/'/g" /Users/mollylewis/Documents/research/Projects/1_in_progress/WCBC_GENDER/experiment/booknorming1/exp_code/data.js
