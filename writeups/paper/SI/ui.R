library(markdown)
library(shinythemes)
library(plotly)
library(ggiraph)
library(DT)

navbarPage("Gender in Children's Book Corpus SI", theme = shinytheme("flatly"),
         #  header = tags$div(`width` = "200px"),
           tabPanel("Word Gender Ratings",

                    HTML( "Mean gender rating for words in gender rating task. Values range from 1 (male associated) to 5 (female associated). See 'Method Details' tab for additional information. <a href='https://github.com/mllewis/WCBC_GENDER/blob/master/data/processed/words/gender_ratings.csv'>Raw data</a> and <a href='https://github.com/mllewis/WCBC_GENDER/blob/master/data/processed/words/gender_ratings_mean.csv'> aggregated data</a>  available in the Github repository."),
                    br(),
                    br(),
                    dataTableOutput("wordratingtable"),
           ),
         tabPanel("Word Gender and Other Word Measures",

               #   includeMarkdown('word_norms.Rmd')
                  includeHTML('word_norms.html')

         ),


           tabPanel("Word Gender Semantics",
                    HTML( "Words are clustered based on the Wikipedia English embeddings Bojanowski et al. (2016).
                    Red indicates clusters that are significantly female biased based on the adult word ratings in a one-sample t-test relative to the overall mean;
                    Blue indicates male-biased clusters. Circle size corresponds to number of words in the cluster."),
                    br(),
                    br(),
                    p("Descriptive labels are provided for each cluster where possible (empty labels indicate clusters lacks coherence). Hover over a cluster to see effect size (ES),
                       and actual words included in the cluster. Effect size is Cohen's d  from a one sampled t-test with bootstrapped 95% confidence intervals. Larger effect sizes indicate larger degree of female bias."),
                    br(),
                    br(),
                    plotlyOutput("bubbleplot", height = "1000px", width = "1000px")
           ),

           tabPanel("Overall Book Gender",
           HTML("The plot below shows the overall gender ratings based on the words in the text.
                       Y-axis shows each book in our corpus; X-axis shows female bias of book on a 5 pt scale. Toggle the Measure selector to change which words are used to calculate the gender score.
                       Toggle the Order and Point Color selectors to change how the data are displayed.
                       Hover over a point to see an individual book's gender score."),
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
                    HTML("After collecting ratings for 2,280 words, we realized that we were missing many proper names that occurred in the books
                        and so conducted another round of rating to collect additonal ratings for 93 proper names.
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
                    h2("Stop word list"),
                    HTML("We excluded the follow 30 words from our norming procedure: 'I', 'a', 'about', 'an', 'are', 'as', 'at', 'be', 'by',
                    'for', 'from', 'how', 'in', 'is', 'it', 'of', 'on', 'or', 'that', 'the', 'this', 'to', 'was', 'what', 'when', 'where', 'who', 'will',
                    'with', 'the'."),

                    br(),
                    br(),
                    h2("Book Gender and Child Gender"),
                    HTML( "A gender score was calculated for each review for each book on Amazon based on the number of gender relational terms included in the review. The 16 terms are listed below:"),
                    br(),
                    br(),
                    HTML('<b>Female </b>: "daughter", "daughters",  "granddaughter", "granddaughters","niece", "nieces", "grandniece", "grandnieces"<br>'),
                    HTML('<b>Male </b>: "son", "sons", "grandson", "grandsons",  "nephew", "nephews", "grandnephew", "grandnephews"'),
                    br(),
                    br(),
                    h2("Word Embedding models"),
                    HTML("We used the gensim implementation (Řehůřek & Sojka, 2011) of word2vec (skip-gram; Miklov, et al., 2013) on our corpus of children's books. The text of each book was entered as a new line in the corpus.
                          The vector size was 300, the window size was 20, and the minimum word count was 5. We trained 10 separate models where we randomized
                          the order of the books across corpora. Similarly, for the adult fiction corpus (CoCA; Davies, 2008), we trained 10 models  on 10 corpora constructed by sampling fiction text from the CoCA corpus dating  from 1990 to 2017. Each training corpus
                          included a sample from a book in CoCA matched for length to one from the Children's Book Corpus. The starting point for the text from the adult fiction book was randomly determined.
                          The word level bias estimates reported in the paper reflect the mean estimate across each of the 10 model runs for both corpus types." ),

                    br(),
                    br(),
                    h2("Language IAT Measure"),
                    withMathJax(includeMarkdown('iat_method.Rmd')),

                    h2("References"),
                    HTML("Caliskan, A., Bryson, J. J., & Narayanan, A. (2017). Semantics derived automatically from language corpora contain human-like biases. Science, 356(6334), 183-186."),
                    br(),
                    br(),
                    HTML("Davies, M (2008). The Corpus of Contemporary American English: 450 million words, 1990-present."),
                    br(),
                    br(),
                    HTML("Lewis, M., & Lupyan, G. (2019). What are we learning from language? Associations between gender biases and distributional semantics in 25 languages."),
                    br(),
                    br(),
                    HTML("Mikolov T, Chen K, Corrado G, Dean J (2013). Efficient estimation of word representations in vector space."),
                    br(),
                    br(),
                    HTML("Řehůřek, R., & Sojka, P. (2010). Software Framework for Topic Modelling with Large Corpora.
                         In Proceedings of the LREC 2010 Workshop on New Challenges for NLPFrameworks (pp. 45–50). Valletta, Malta: ELRA")
           ),

              tabPanel("Supplemental Models",
                       h2("Study 1c: Models Predicting Word Gender Bias from Book Type"),

                       HTML("In Study 1c, we predicted the gender bias of the activities and descriptions associated with book characters as a function of the
                            book gender bias estimated in Study 1b. In Study 1b, we estimated book gender bias by taking the mean gender bias of all words occurring in a book; In Study 1c, we estimated
                            book gender bias by asking participants to generate words for the activities associated with the book characters and descriptions of the book chararacters, and then quantified the bias of those words using
                            previously-collected gender norms for words. The key question was whether the two measures were related to each other."),
                       br(),
                       br(),
                       HTML("The plot below shows the mean and 95% CI of gender bias ratings for the activity (left) and description (right) words, as a function of book type (estimated in Study 1b)."),
                       plotOutput("character_plot", width = "80%"),
                       br(),
                       HTML("The tables below show the model parameters for two mixed effect models predicting activity word gender biases (top) and description word gender biases (bottom).
                            The exact model specification was: <i> lmer(word_gender_bias ~ book_type + (1|participant_id) + (1|book_id), data) </i>."),

                       h4("Mixed effect model predicting gender bias of character activity word with book type:"),
                       tableOutput('activity_table'),
                       br(),
                       h4("Mixed effect model predicting gender bias of character description word with book type:"),
                       tableOutput('desc_table'),

                       h2("Study 3: Models Predicting Audience Gender"),

                       HTML( "In the Main Text, we present analyses  predicting the gender of a book's audience based on counts of gendered kinship terms (e.g., 'daughter', 'son', etc.) in online book reviews.
                             The  Main Text reports analyses predicting the  proportion of female kinship terms (tokens) present relative to all target kinship word for each book. Here we
                             present mixed-effect logistic regression models predicting the raw counts of gendered kinship terms at the review level with a random intercept for each book.
                             The exact model specification was: <i> glmer(cbind(n_female_token, n_male_token) ~
                             child_gender(or other fixed effect) + (1|book_id), family = binomial(link ='logit'), data = data)</i>.
                             The results of the mixed effect logistic models
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
           ) ,
         tabPanel("Gender Bias and Publication Year",
                  HTML("Are there historical trends in gender bias in books across the corpus? To answer this question, we coded the first year each book was published using <a href='https://www.worldcat.org/'>WorldCat</a>, and examined how publication year related to the measures of gender we
                       report in the Main Text. There was a small positive correlation between publicaiton year and the average gender score
                       of each book based on human judgments of all word tokens in each book (<i>r </i> = 0.15 [0.03, 0.27], <i> p </i> = 0.02; see figure below), suggesting that more
                       recent books have more female associations in them. There was no relationship between publication year
                       and the other gender measures reported in the Main Text (content score: <i> r </i> = 0.06 [-0.06, 0.19], <i> p </i> = 0.32; character score: <i> r </i> = 0.1 [-0.04, 0.24], <i> p </i> = 0.15;
                       audience gender: <i> r </i> = 0.03 [-0.1, 0.15], <i> p </i> = 0.69)."),
                  br(),
                  br(),
                  imageOutput("year_all",  height = "100px", width = "100px", inline = TRUE),
                  br(),
                  br(),
                  HTML("The relationship between overall book gender association and publication year suggests that more recent books have more female associations, but it does not address whether more recent books contain more or less gender stereotypes than older books.
                  To answer this question, we fit a linear model predicting book content gender score with
                  book character gender score and publication year. The model included additive terms
                  for both predictors as well as their interation. The table below shows the model results.
                  Critically, there was no interaction between character gender score and publication year,
                  suggesting that the strength of the relationship between character and content gender scores
                  reported in the Main Text is not related to publication year."),
                  br(),
                  br(),
                  tableOutput('year_model_table'),
                  br(),
                  br(),
                  HTML("Finally, we examined the relationship between the gender of the main characters in each book and the book's publication year.
                       The plot below shows the proportion of books with main characters in each gender category
                       (male, female, mixed and indeterminate) as a function of publication year.
                       The width of the bars corresponds to the number of books in our corpus published in the each decade.
                       The data suggest a trend for more recent books to have proportionally fewer male main characters,
                       and more main characters with indeterminate gender."),
                  br(),
                  br(),
                  imageOutput("year_char",  height = "100px", width = "100px", inline = TRUE),
                  br(),
                  br(),
         )
)


