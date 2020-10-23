library(tidyverse)
library(rlang)
library(plotly)
library(ggiraph)

function(input, output, session) {


  WORDS_PATH <- "data/gender_ratings_mean.csv"
  words <- read_csv(WORDS_PATH) %>%
    select(word, mean, ci_lower, ci_upper, n) %>%
    arrange(-mean) %>%
    mutate_if(is.numeric, round, 2) %>%
    rename("mean gender rating" = mean,
           "lower 95 CI" = ci_lower,
           "upper 95 CI" = ci_upper,
           "n raters" = n)

  output$wordratingtable = DT::renderDataTable({
    words
  })

  CHARACTER_PATH <- "data/character_gender_by_book.csv"
  characters <- read_csv(CHARACTER_PATH)

  character_tidy <- characters %>%
    mutate(char_main_gender = case_when(is.na(char_main_gender) ~ "none",
                                        TRUE ~ char_main_gender),
           char_main_gender = fct_recode(char_main_gender,
                                         female = "F",
                                         male = "M",
                                         "indeterminate" = "AND",
                                         mixed = "MIXED"),
           char_main_gender = fct_relevel(char_main_gender,
                                          "female", "male", "indeterminate", "mixed", "none"),
           char_second_gender = case_when(is.na(char_second_gender) ~ "none",
                                        TRUE ~ char_second_gender),
           char_second_gender = fct_recode(char_second_gender,
                                         female = "F",
                                         male = "M",
                                         "indeterminate" = "AND",
                                         mixed = "MIXED"),
           char_second_gender = fct_relevel(char_second_gender,
                                          "female", "male", "indeterminate", "mixed", "none"))
  # overall b0ok means data
  BOOK_MEANS_PATH <- "data/gender_token_type_by_book.csv"
  gender_rating_by_book_mean <- read_csv(BOOK_MEANS_PATH) %>%
    select(corpus_type, book_id, token_gender_mean, token_ci_lower, token_ci_upper, prop_present_token)  %>%
    left_join(character_tidy) %>%
    left_join(characters %>% select(book_id, author)) %>%
    mutate(title = str_remove_all(str_to_title(str_squish(title)), "'"),
           author = str_remove_all(author, "'"),
           tooltip_string = paste0("Title: ",
                                   str_to_title(title),
                                   "\n Author: ",
                                   str_to_title(author),
                                   "\n Gender Score: ",
                                   as.character(round(token_gender_mean, 2)))) %>%
    filter(!(book_id %in% c("L105", "L112"))) # "Journey" and "Anno's Journey" are pictures books

  all_book_means <- list("all" = gender_rating_by_book_mean %>% filter(corpus_type == "all"),
                         "content" = gender_rating_by_book_mean %>% filter(corpus_type == "no_char"),
                         "chars" = gender_rating_by_book_mean %>% filter(corpus_type == "char_only"))


  get_forest_plot <- function(){

    current_df <- all_book_means[input$plotmeasure][[1]]

    current_title <- case_when(input$plotmeasure == "all" ~ "Mean Gender Rating by Book\n(all words)\n",
                               input$plotmeasure == "content" ~ "Mean Gender Rating by Book\n(content words only)\n",
                               input$plotmeasure == "chars" ~ "Mean Gender Rating by Book\n(character words only)\n")

    if (input$plotorder == "token_gender_mean"){
      current_df_sorted <- current_df %>%
        mutate(title = fct_reorder(title, token_gender_mean))
    }  else {
      current_df_sorted <- current_df %>%
        mutate(title = fct_rev(title))
    }

    overall_token_mean <- mean(current_df$token_gender_mean, na.rm = T)

    forest_plot <- ggplot(current_df_sorted, aes(x = title,
                                                 y = token_gender_mean,
                                                 tooltip = tooltip_string,
                                                 data_id = title)) +
      coord_flip() +
      geom_linerange(aes(ymin = token_ci_lower, ymax = token_ci_upper), alpha = .3, size = 2) +
      xlab("Book Title") +
      ylab("Book Gender Score (female-ness)") +
      ggtitle(current_title) +
      geom_point_interactive(aes_string(color = input$plotcolor), size = 5) +
      #theme_classic(base_size = 24) +
      theme_minimal(base_size = 24) +
      theme(axis.text.y = element_text(size = 12),
            legend.box.background = element_rect(colour =  "grey", size = 5),
            legend.position = 'bottom',
            text=element_text(family="helvetica"))

    # format color
    if (input$plotcolor == "char_main_gender"){
      forest_plot <- forest_plot +
        scale_color_manual(
              values = c("pink"," lightblue", "lightgoldenrod1",
                         "palegreen","lightgrey"),
              name = "Primary character gender") +
        guides(col = guide_legend(ncol = 2, size = 8))

    } else if(input$plotcolor == "char_second_gender"){
      forest_plot <- forest_plot +
        scale_color_manual(
          values = c("pink"," lightblue", "lightgoldenrod1",
                     "palegreen", "lightgrey"),
          name = "Secondary character gender") +
        guides(col = guide_legend(ncol = 2, size = 8))

    } else if(input$plotcolor == "prop_present_token"){
      forest_plot <- forest_plot +
        scale_color_gradient(low = "white", high = "navy", name = "Prop. Tokens Normed") +
        theme(legend.position = 'top')
    }

    #girafe_options(forest_plot, opts_tooltip(use_fill = TRUE) )

    ggiraph(code = print(forest_plot),
            height_svg = 50,
            width_svg = 15,
            hover_css = "fill:black;",
            selection_type = "single",
            selected_css = "fill:black;",
            zoom_max = 1)
  }

  get_bubble_plot <- function(){

    WORD_DATA <- "data/gender_word_tsne_coordinates.csv"
    word_df <- read_csv(WORD_DATA) %>%
     select(word, cluster_id) %>%
     group_by(cluster_id) %>%
     nest()  %>%
     mutate(word_string = purrr::map(data, ~reduce(.$word, paste, sep = "\n"))) %>%
     select(-data) %>%
     unnest()


    LABEL_DATA <- "data/cluster_labels.csv"
    cluster_labels <- read_csv(LABEL_DATA)  %>%
      select(-examples) %>%
      mutate(cluster_label_tidy = str_replace_all(cluster_label, "/", "/ "),
             cluster_label_tidy = str_replace_all(cluster_label_tidy, " ", " \n"),
             cluster_label_tidy = str_replace_all(cluster_label_tidy, "\\*", ""))


    TNSE_DATA <- "data/gender_centroids_tsne_coordinates.csv"
    centroid_df <- read_csv(TNSE_DATA)  %>%
      left_join(cluster_labels) %>%
      left_join(word_df) %>%
      mutate_if(is.numeric, round, 2) %>%
      mutate(word_string_with_es = paste0("ES: ",effect_size, " [", eff_conf_low, ",", eff_conf_high, "] \n\n", word_string))



    bubble_plot <- centroid_df %>%
      arrange(is_gendered) %>%
      ggplot(
        aes(text = word_string_with_es)
        ) +
      geom_point(aes(size = n,
                     y = tsne_X,
                     x = -tsne_Y,
                     fill = gender_bias),
                 color = "grey",
                 alpha = .9,
                 shape = 21) +
      scale_fill_manual(values = c("pink", "lightblue", "white"),
                        name = "Gender Bias") +
      geom_text(aes(y = tsne_X,
                    x = -tsne_Y,
                    label = cluster_label_tidy,
                    color = is_gendered),
                               size = 1.9,
                               lineheight = .8) +
      scale_color_manual(values = c("grey", "black"), guide = F) +
      scale_size_area(max_size = 20, guide = F) +
      theme_void() +
      theme(legend.position = "top",
            legend.box.background = element_rect(colour = "black"),
            plot.margin = margin(8, 8, 8, 8),
            legend.margin = margin(4, 4, 4, 10)) +
      guides(fill = guide_legend(override.aes = list(size = 5))) +
      theme(legend.position = 'none')

    ax <- list(
      title = "",
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE,
      showgrid = FALSE
    )

    ggplotly(bubble_plot, tooltip = "text")   %>%
      layout(xaxis = ax, yaxis = ax)

  }

  output$forestplot <- renderggiraph(get_forest_plot())
  output$bubbleplot <- renderPlotly(get_bubble_plot())


  AUDIENCE_MODEL_PARAM_PATH <-  "data/audience_mixed_effect_models.csv"
  audience_data <- read_csv(AUDIENCE_MODEL_PARAM_PATH)
  output$ibdb_table <- renderTable({filter(audience_data, model_type == "ibdb") %>% select(-model_type)},  striped = TRUE, bordered = TRUE)
  output$char_table <- renderTable({filter(audience_data, model_type == "char") %>% select(-model_type)},  striped = TRUE, bordered = TRUE)
  output$content_table <- renderTable({filter(audience_data, model_type == "content") %>% select(-model_type)},  striped = TRUE, bordered = TRUE)
  output$char_content_table <- renderTable({filter(audience_data, model_type == "char_content") %>% select(-model_type)},  striped = TRUE, bordered = TRUE)

  YEAR_SCATTER_PLOT_PATH <- "data/year_all_plot.jpeg"
  output$year_all <- renderImage({
    filename <- normalizePath(YEAR_SCATTER_PLOT_PATH)
    list(src = filename)

  }, deleteFile = FALSE)

  YEAR_INTERACTION_MODEL_PARAM_PATH <-  "data/year_interaction_model.csv"
  year_model_data <- read_csv(YEAR_INTERACTION_MODEL_PARAM_PATH)
  output$year_model_table <- renderTable(year_model_data,  striped = TRUE, bordered = TRUE)

  YEAR_CHAR_PLOT_PATH <- "data/year_char_plot.jpeg"
  output$year_char <- renderImage({
    filename <- normalizePath(YEAR_CHAR_PLOT_PATH)
    list(src = filename)

  }, deleteFile = FALSE)


}
