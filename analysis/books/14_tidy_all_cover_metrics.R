# get tidy cover data by book
library(tidyverse)
library(here)

SV_PATH <- here("data/processed/books/cover_sv.csv")
H_PATH <- here("data/processed/books/cover_hue_1.csv")
EDGE_PATH <- here("data/processed/books/cover_edge.csv")
EDGE_THRESH <- .01
OUTFILE <- here("data/processed/books/tidy_cover_data_1.csv")

# hue
h_data <- read_csv(H_PATH) %>%
  rename(hue_n = n) 

h_entropy <- h_data %>% # add entropy measure
  select(-min_s, -min_v) %>%
  group_by(book_id) %>%
  right_join(expand(h_data, book_id, color)) %>%
  mutate(hue_n = replace_na(hue_n, 0)) %>%
  summarize(hue_H = entropy::entropy(hue_n))

h_data_tidy <- h_data %>%
  select(-min_s, -min_v) %>%
  mutate(hue_n = hue_n) %>%
  spread("color", "hue_n", fill = 0) %>%
  mutate_if(is.numeric, ~.x + 1) %>% # deal with zero counts
  mutate_if(is.numeric, log) %>% # take log of proportions
  left_join(h_entropy)

# sv
sv_data <- read_csv(SV_PATH)

sv_data_tidy <- sv_data %>%
  unite(metric, channel, metric) %>%
  spread("metric", "value") %>%
  janitor::clean_names()


# edge
edge_data <- read_csv(EDGE_PATH) 

prop_pixels <- edge_data  %>%
  group_by(book_id) %>%
  mutate(edge = ifelse(value > EDGE_THRESH, 0, 1)) %>%
  summarize(prop_pixels = mean(edge))

intensity_entropy <- edge_data %>%
  group_by(book_id) %>%
  summarize(intensity_H = entropy::entropy(value))

## I THINK I NEED TO SCALE ALL THE BOOKS...
filtered_edge_entropy_x <- edge_data %>% 
  group_by(book_id) %>%
  mutate(max_x = max(x),
         edge = ifelse(value > EDGE_THRESH, 0, 1)) %>%
  filter(edge == 1) %>%
  count(book_id, x) %>%
  #right_join(expand(edge_data, book_id, x)) %>%
 # mutate(x = replace_na(x, 0)) %>%
  group_by(book_id) %>%
  summarize(edge_x_H = entropy::entropy(n))

filtered_edge_entropy_y <- edge_data %>% 
  mutate(edge = ifelse(value > EDGE_THRESH, 0, 1))%>%
  filter(edge == 1) %>%
  count(book_id, y) %>%
 # right_join(expand(edge_data, book_id, y)) %>%
 # mutate(y = replace_na(y, 0)) %>%
  group_by(book_id) %>%
  summarize(edge_y_H = entropy::entropy(n))

filtered_edge_entropy <- filtered_edge_entropy_x %>%
  left_join(filtered_edge_entropy_y) %>%
  rowwise() %>%
  mutate(edge_H = mean(c(edge_y_H, edge_x_H, na.rm = T)))
  
all_metrics <- full_join(h_data_tidy, sv_data_tidy) %>%
  full_join(filtered_edge_entropy) %>%
  full_join(prop_pixels) %>%
  full_join(intensity_entropy)

write_csv(all_metrics, OUTFILE)
  