library(markdown)
library(shinythemes)
library(plotly)
library(ggiraph)
library(DT)

navbarPage("Gender in Children's Book Corpus SI", theme = shinytheme("flatly"),

           tabPanel("Word Gender Ratings",
                    HTML( "Mean gender rating for words in gender rating task. Values range from 1 (male associated) to 5 (female associated). See 'Method Details' tab for additional information."),
                    br(),
                    br(),
                    dataTableOutput("wordratingtable")
           ),
           tabPanel("Word Gender Semantics",
                    HTML( "Words are clustered based on the Wikipedia English embeddings Bojanowski et al. (2016).
                    Red indicates clusters that are significantly female biased based on the adult word ratings in a one-sample t-test relative to the overall mean;
                    Blue indicates male-biased clusters. Circle size corresponds to number of words in the cluster."),
                    br(),
                    br(),
                    HTML("Descriptive labels are provided for each cluster where possible (empty labels indicate clusters lacks coherence). Hover over a cluster to see effect size (ES),
                       and actual words included in the cluster. Effect size is Cohen's <i> d </i> from one sampled t-test with bootstrapped 95% confidence intervals. Larger effect sizes indicate larger degree of female bias."),
                    br(),
                    br(),
                    plotlyOutput("bubbleplot", height = "1000px", width = "1000px")
           ),

           tabPanel("Overall Book Gender",
           HTML("The plot below shows the overall gender ratings based on the words in the text.
                       Y-axis shows each book in our corpus; X-axis shows female bias of book on a 5 pt scale. Toggle the Measure selector to change which words are used to calculate the gender score.
                       Toggle the Order and Point Color selectors to change how the data are displayed.
                       Hover over a point to see the score value."),
           br(),
           br(),
           fluidRow(),
           sidebarLayout(
             sidebarPanel(width = 2,
                          radioButtons("plotmeasure", "Measure",
                                       c("All words" = "all",
                                         "Content" = "content",
                                         "Characters" = "chars")),
                          radioButtons("plotorder", "Order",
                                       c("By mean rating" = "token_gender_mean",
                                         "Alphabetical" = "title")),
                          radioButtons("plotcolor", "Point color",
                                       c("Primary character gender" = "char_main_gender",
                                         "Secondary character gender" = "char_second_gender"))),
             #"Prop. words included" = "prop_present_token"
             mainPanel(
               ggiraphOutput("forestplot", height = "10000px", width = "10000px")

             )
           )
           ),
           tabPanel("Method Details",
                    h2("Word Norming Instructions"),
                    HTML( "Below is the exact instructions for the word norming task:"),
                    br(),
                    br(),
                    HTML('<i> You will be asked to rate the "genderness" of about 100 common English words.<br>
                      Some words have "natural" gender, e.g. "he" and "brother" generally refer to men.<br>
                      Other words have no "natural" gender, but may be associated with a gender.<br>
                      For example, you may think that "flowers" are a relatively feminine word. <br>
                      Please use your intuitions to rate each word you see.  Any words that refer to people\'s names will be capitalized.
                      The meaning of words with ambiguous meanings will be clarified. Use the keys 1-5 to respond.
                      Please try to use the entire scale, from "Very masculine" to "Very feminine"</i> '),
                    br(),
                    br(),
                    HTML("After collecting ratings for 2280 words, we realized that we were missing many proper names that occurred in the books
                        and so conducted another round of rating to collect addditonal ratings for 93 proper names.
                        The data reported in the main manuscript already includes these words.
                        We slightly modified the instructions to inform participants that the words in this list were dominated by proper names."),
                    br(),
                    br(),

                    HTML('<i> You will be asked to rate the gender (masculine/feminine) of 100 English words.<br>
                        Most of the words are first names. Some are last names. And a few are regular English words.<br>
                        Please use your intuition to rate each word from very masculine to very feminine using the 1-5 keys.<br>
                        Try to use the entire scale. It\'s ok to go with your first impression for each word, but please do not rush.</i> '),
                    br(),
                    br(),
                    h2("Book Gender and Child Gender"),
                    HTML( "A gender score was calculate for each review for each book on Amazon based on the number of gender relational terms included in the review. The 16 terms are listed below:"),
                    br(),
                    br(),
                    HTML('<b>Female </b>: "daughter", "daughters",  "granddaughter", "granddaughters","niece", "nieces", "grandniece", "grandnieces"<br>'),
                    HTML('<b>Male </b>: "son", "sons", "grandson", "grandsons",  "nephew", "nephews", "grandnephew", "grandnephews"'),
                    br(),
                    br(),
                    h2("Word Embedding models"),
                    HTML("We used the gensim implementation (Řehůřek & Sojka, 2011) of word2vec (skip-gram; Miklov, et al., 2013) on our corpus of children's books. The text of each book was entered as a new line in the corpus.
                          The vector size was 300, the window size was 20, and the minimum word count was 5. We trained 10 seperate models where we randomized
                          the order of the books across corpora. Similiarly, for the adult fiction corpus (CoCA; Davies, 2008), we trained 10 models  on 10 corpora constructed by sampling fiction text from the CoCA corpus dating  from 1990 to 2017. Each training corpus
                          included a sample from a book in CoCA matched for length to one from the Children's Book Corpus. The starting point for the text from the adult fiction book was randomly determined.
                          The word level bias estimates reported in the paper reflect the mean estimate across each of the 10 model runs for both corpus types." ),

                    br(),
                    br(),
                    h2("Language IAT Measure"),

                    h2("References"),
                    HTML("Davies, M (2008). The Corpus of Contemporary American English: 450 million words, 1990-present."),
                    br(),
                    HTML("Mikolov T, Chen K, Corrado G, Dean J (2013). Efficient estimation of word representations in vector space."),
                    br(),
                    HTML("Řehůřek, R., & Sojka, P. (2010). Software Framework for Topic Modelling with Large Corpora.
                         In Proceedings of the LREC 2010 Workshop on New Challenges for NLPFrameworks (pp. 45–50). Valletta, Malta: ELRA")
           ),

              tabPanel("Supplemental Models",
                       h2("Models Predicting Word Gender"),
                       HTML( "In the Main Text, we present analyses that include estimates of word frequency from the TASA corpus (Zeno, Ivens, Millard, & Duvvuri, 1995). This frequency measure was used because  it relies on a corpus of child-directed text, but is larger
              than the WCBC corpus. Here we present our analyses with two other frequency measures for comparsion: Frequency as estimated from the WCBC and frequency as measured from movie subtitles (SUBTLEX-us norms; Brysbaert & New, 2009). The SUBTLEX-us
              norms provide a benchmark for estimates from a much larger corpus of text."),
                       br(),
                       br(),

                       h3("Pairwise correlation between all measures"),
                       tableOutput('pairwise_corr_table'),
                       h5("Values are Pearson's r. Asterisks indicate statistical significance (p < .05: *;  p < .01: **;  p < .001: ***). Word frequency measures are log transformed.
AoA = Age of acquisition; WCBC = Wisconsin Children's Book Corpus; TASA = Zeno et al., 1995 Corpus; SUBLEX-us = Brysbaert & New, 2009 Corpus."),
                       br(),

                       h3("Models parameters predicting word gender association"),
                       h5("Larger values indicate stronger association with females."),
                       br(),
                       h4("Model with WCBC frequency:"),
                       tableOutput('cbc_freq_model'),

                       br(),

                       h4("Model with SUBTLEX-us frequency:"),
                       tableOutput('subtlex_freq_model'),

                       br(),

                       h4("Model with TASA frequency (as in Main Text):"),
                       tableOutput('tasa_freq_model'),

                       br(),
                       br(),

                       h2("Models Predicting Audience Gender"),

                       HTML( "In the Main Text, we present analyses  predicting the gender of a book's audience based on counts of gendered kinship terms (e.g., 'daughter', 'son', etc.) in online book reviews.
                             The  Main Text reports analyses predicting the  proportion of female kinship terms (tokens) present relative to all target kinship word for each book. Here we
                             present mixed-effect logistic regression models predicting the raw counts of gendered kinship terms at the review level with a random intercept for each book. The results of the mixed effect logistic models
                             are qualitatively the same as the simpler, correlational analyses presented in the Main Text."),
                       br(),
                       br(),

                       h4("Predicting audience gender in reviews with Kam and Matthewson (2017) survey data"),
                       tableOutput('ibdb_table'),
                       br(),
                       h4("Predicting audience gender in reviews with character gender score"),
                       tableOutput('char_table'),
                       br(),
                       h4("Predicting audience gender in reviews with content gender score"),
                       tableOutput('content_table'),
                       br(),
                       h4("Predicting audience gender in reviews with charcter and content gender scores"),
                       tableOutput('char_content_table')


                    )

#

           # Additional stuff for SI:
           # Description of gender character coding [Matt]
           # Advert age
           # book bias over time
)

