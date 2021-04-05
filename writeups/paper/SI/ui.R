library(markdown)
library(shinythemes)
library(plotly)
library(ggiraph)
library(DT)

navbarPage("What might books be teaching young children about gender?: Supplemental Information", theme = shinytheme("flatly"),
         #  header = tags$div(`width` = "200px"),
           tabPanel("Word Gender Ratings",

                    HTML( "Mean gender rating for words in gender rating task. Values range from 1 (male associated) to 5 (female associated). See 'Method Details' tab for additional information. <a href='https://github.com/mllewis/WCBC_GENDER/blob/master/data/processed/words/gender_ratings.csv'>Raw data</a> and <a href='https://github.com/mllewis/WCBC_GENDER/blob/master/data/processed/words/gender_ratings_mean.csv'> aggregated data</a>  available in the Github repository."),
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
                          The word level bias estimates reported in the paper reflect the mean estimate across each of the 10 model runs for both corpus types. The Wikipedia model was trained on a full dump of English Wikpeidia (Bojanowski, et al., 2017)"),

                    br(),
                    br(),
                    h2("Language IAT Measure"),
                    withMathJax(includeMarkdown('iat_method.Rmd')),
                    h2("References"),
                    HTML("Bojanowski, P., Grave, E., Joulin, A., & Mikolov, T. (2017). Enriching word vectors with subword information. Transactions of the Association for Computational Linguistics, 5, 135-146."),
                    br(),
                    br(),
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

              tabPanel("Supplemental Results",
                       h2("Study 1a: Word gender and other word properties"),
                       HTML("An important question is whether genderedness (as rated by adults) is related to properties of words potentially relevant to the development of gender stereotypes: <i>valence</i> (degree of pleasantness), <i>arousal</i> (intensity of emotion), <i>concreteness</i> (whether a word refers to something that can be experienced directly or is more abstract), <i>age of acquisition</i> (AoA, an estimate of the age at which a word is learned), and <i>word frequency</i> (how often a word occurs in a language sample). Valence and arousal are implicated in common gender stereotypes (e.g., girls nice, boys aggressive); age of acquisition and word frequency provide evidence about children’s exposure to words with these properties; the concrete-abstract dimension reflects the conceptual complexity of words."),
                       br(),
                       HTML("&emsp;&emsp; We assessed correlations between rated gender and other lexical properties using existing norms. Warriner, Kuperman, and Brysbaert (2013) provide valence ratings on a 1 (happy) to 9 (unhappy) point scale and arousal ratings on a 1 (excited) to 9 (calm) scale. For age of acquisition (Kuperman, Stadthagen-Gonzalez, & Brysbaert, 2012), participants estimated the age in years at which they learned each word. For concreteness, participants rated the extent to which the meaning of a word can be experienced “directly through one of the five senses”, rating each word on a 1 (abstract) to 5 (concrete) scale. Word frequency estimates depend on properties of the language sample that is used. We therefore conducted the correlational analyses using frequencies from three sources: (1) our corpus of children’s books, (2) the cumulative frequency measure from the TASA norms (Zeno, Ivens, Millard, & Duvvuri, 1995) derived from a much larger sample of books from a broad range of reading levels, and (3) a large corpus of movie subtitles (Subtlex-US: Brysbaert & New, 2009). All frequency measures wore log transformed. Because word sense was not disambiguated in these norms, we averaged across words with the same word forms (but different senses) in our dataset for these analyses. Frequency measures from all three sources were available for 1,954 words in the WCBC. The three frequency measures were correlated (TASA-Subtlex: <i>r</i> = 0.84 [0.82, 0.85], <i>p</i> < .001; TASA-WCBC: <i>r</i> = 0.76 [0.74, 0.78], <i>p</i> < .001; WCBC-Subtlex: <i>r</i> = 0.72 [0.69, 0.74], <i>p</i> < .001; all reported ranges indicate 95% confidence intervals), and the magnitudes are similar to ones reported previously (e.g., Zevin & Seidenberg, 2004.) They also yielded very similar correlations with the other lexical measures."),
                       br(),
                       HTML("&emsp;&emsp; Table 1 below shows the pairwise correlation between all word measures, subsetting to those words available for all measures (<i>N</i> = 1,185). Words that were rated as more feminine tended to be more positively valenced (<i>r</i> = 0.36 [0.31, 0.41], <i>p</i> < .001). More feminine words were also associated with lower arousal (<i>r</i> = -0.07 [-0.12, -0.01], <i>p</i> = 0.02), less concrete (<i>r</i> = -0.12 [-0.18, -0.07], <i>p</i> < .001), and learned earlier (<i>r</i> = -0.08 [-0.14, -0.02], <i>p</i> = 0.006). Word frequency in the WCBC corpus was correlated with word gender (<i>r</i> = 0.09 [0.03, 0.14], <i>p</i> = 0.003), but the other frequency measures were not."),
                       br(),
                       br(),
                       h6("Table 1: Relationship between word properties. Values are Pearson's r. Asterisks indicate statistical significance (p < .05; p< .01; p < .001). Word frequency measures are log transformed.
AoA = Age of acquisition; WCBC = Wisconsin Children's Book Corpus; TASA = Zeno et al., 1995 Corpus; SUBLEX-us = Brysbaert & New, 2009 Corpus."),
                       tableOutput('word_properties_table'),
                       br(),
                       HTML("We next fit an additive linear model to estimate the independent variance in gender explained by the other word measures. We fit separate models with each of the three frequency measures, since the frequency measures were highly colinear with each other. All five measures predicted independent variance in gender ratings. The table below shows the model parameters for the three models with different frequency predictors. In the model with the TASA measure of frequency (Table 2) the R2 was 0.17, with valence being the strongest predictor of a word’s gender association (i.e, more positively valenced words tend to be rated as more feminine; <i> β</i> = 0.35, <i>SE</i> = 0.03, <i>Z</i> = 12.88, <i>p</i> <.001). The other models showed similar patterns (Tables 3-4)."),
                       br(),
                       h6("Table 2: Model parameters predicting word gender association with TASA frequency measure. Larger gender values indicate greater association with females. AoA = Age of acquisition."),
                       tableOutput('tasa_model_table'),

                       h6("Table 3: Model parameters predicting word gender association with SUBTLEX-us frequency measure"),
                       tableOutput('subt_model_table'),

                       h6("Table 4: Model parameters predicting word gender association with WCBC frequency measure"),
                       tableOutput('wcbc_model_table'),
                       HTML("In summary, many of the most frequent content-bearing words in children’s books have strong gender associations (54%), according to adult judgments. Words judged as more feminine were associated with more positive valence and lower arousal. More feminine words are also higher in frequency, less concrete, and learned somewhat earlier (i.e., have a lower age of acquisition, holding frequency and the other variables listed in constant)."),

                       h2("Study 1b: Book gender and publication year"),
                       HTML("Are there historical trends in gender bias in books across the corpus? To answer this question, we coded the first year each book was published using <a href='https://www.worldcat.org/'>WorldCat</a>, and examined how publication year related to the measures of gender we
                       report in the Main Text. There was a small positive correlation between publication year and the average gender score
                       of each book based on human judgments of all word tokens in each book (<i>r </i> = 0.15 [0.03, 0.27], <i> p </i> = 0.02; see figure below), suggesting that more
                       recent books have more female associations in them. There was no relationship between publication year
                       and the other gender measures reported in the Main Text (content score: <i> r </i> = 0.06 [-0.06, 0.19], <i> p </i> = 0.32; character score: <i> r </i> = 0.1 [-0.04, 0.24], <i> p </i> = 0.15;
                       audience gender: <i> r </i> = 0.03 [-0.1, 0.15], <i> p </i> = 0.69)."),
                       br(),
                       br(),
                       imageOutput("year_all",  height = "50px", width = "50px", inline = TRUE),
                       br(),
                       br(),
                       HTML("The relationship between overall book gender association and publication year suggests that more recent books have more female associations, but it does not address whether more recent books contain more or less gender stereotypes than older books.
                  To answer this question, we fit a linear model predicting book content gender score with
                  book character gender score and publication year. The model included additive terms
                  for both predictors as well as their interaction. Table 5 shows the model results.
                  Critically, there was no interaction between character gender score and publication year,
                  suggesting that the strength of the relationship between character and content gender scores
                  reported in the Main Text is not related to publication year."),
                       br(),
                       br(),
                       h6("Table 5: Model parameters predicting book content score"),
                       tableOutput('year_model_table'),
                       br(),
                       br(),

                       h2("Study 1c: Models Predicting Word Gender Bias from Book Type"),

                       HTML("In Study 1c, we predicted the gender bias of the activities and descriptions associated with book characters as a function of the
                            book gender bias estimated in Study 1b. In Study 1b, we estimated book gender bias by taking the mean gender bias of all words occurring in a book; In Study 1c, we estimated
                            book gender bias by asking participants to generate words for the activities associated with the book characters and descriptions of the book characters, and then quantified the bias of those words using
                            previously-collected gender norms for words. The key question was whether the two measures were related to each other."),
                       #HTML("The plot below shows the mean and 95% CI of gender bias ratings for the activity (left) and description (right) words, as a function of book type (estimated in Study 1b)."),
                       #plotOutput("character_plot", width = "80%"),
                       #br(),
                       HTML("&emsp;&emsp;  The tables below show the model parameters for two mixed effect models predicting activity word gender biases (Table 6) and description word gender biases (Table 7). Tables 8-9 show analogous models with content scores as a predictor; Tables 10-11 show analogous models with character scores as a predictor.
                            The exact model specification was: <i> lmer(word_gender_bias ~ average_book_gender + (1|participant_id) + (1|book_id), data) </i>. All variables are scaled."),

                       h6("Table 6: Mixed effect model predicting gender bias of character activity word with average book gender"),
                       tableOutput('activity_table'),
                       h6("Table 7: Mixed effect model predicting gender bias of character description word with average book gender"),
                       tableOutput('desc_table'),
                       h6("Table 8: Mixed effect model predicting gender bias of character activity word with content average book gender"),
                       tableOutput('activity_content_table'),
                       h6("Table 9: Mixed effect model predicting gender bias of character description word with content average book gender"),
                       tableOutput('desc_content_table'),
                       h6("Table 10: Mixed effect model predicting gender bias of character activity word with character average book gender"),
                       tableOutput('activity_char_table'),
                       h6("Table 11: Mixed effect model predicting gender bias of character description word with character average book gender"),
                       tableOutput('desc_char_table'),
                       br(),
                       h2("Study 2a: Word gender biases from co-occurrence statistics"),
                       HTML("In Study 2a, we estimated the gender bias of words based on word embedding models trained on three different corpora. Table 12 below shows the correlations between word gender bias estimates derived from the Wisconsin Children’s Book Corpus, COCA (Davies, 2008), and English Wikipedia (Bojanowski et al., 2016). "),
                       h6("Table 12: Relationships between word gender biases based on word co-occurrence statistics. Correlation values are Pearson’s r. All correlations are significant at the p< .001 level. WCBC = model trained on Wisconsin Children’s Book Corpus; COCA = Davies, 2008; Wikipedia = Bojanowski et al., 2016."),
                       tableOutput('embedding_corr_table'),
                       br(),
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

                       h6("Table 13: Predicting audience gender in reviews with Hudson Kam and Matthewson (2017) survey data"),
                       tableOutput('ibdb_table'),
                       br(),
                       h4("Predicting audience gender in reviews with character gender score"),
                       HTML("The plot below shows the relationship between character (left) and content (right) gender scores and proportion female audience. Tables 14-16 below show the corresponding mixed-effect model parameters."),
                       plotOutput("audience_score_plot", width = "80%"),
                       br(),
                       br(),
                       h6("Table 14: Predicting audience gender in reviews with character gender score"),
                       tableOutput('char_table'),
                       h6("Table 15: Predicting audience gender in reviews with content gender score"),
                       tableOutput('content_table'),
                       h6("Table 16: Predicting audience gender in reviews with character and content gender scores"),
                       tableOutput('char_content_table'),
                       br(),
                       br(),
                       h2("References"),
                       HTML("Bojanowski, P., Grave, E., Joulin, A., & Mikolov, T. (2017). Enriching word vectors with subword information. Transactions of the Association for Computational Linguistics, 5, 135-146. "),
                       br(),
                       br(),
                       HTML("Davies, M (2008). The Corpus of Contemporary American English: 450 million words, 1990-present. "),
                       br(),
                       br(),
                       HTML("Hudson Kam, C. L., & Matthewson, L. (2017). Introducing the Infant Bookreading Database (IBDb). Journal of Child Language,44(6), 1289–1308"),
                       br(),
                       br(),
                       HTML("Kuperman, V., Stadthagen-Gonzalez, H., & Brysbaert, M. (2012). Age-of-acquisition ratings for 30,000 English words. Behavior Research Methods, 44 (4), 978–990."),
                       br(),
                       br(),
                       HTML("Warriner, A. B., Kuperman, V., & Brysbaert, M. (2013). Norms of valence, arousal, and
dominance for 13,915 English lemmas. Behavior Research Methods, 45(4), 1191–1207."),
                       br(),
                       br(),
                       HTML("Zeno, S., Ivens, S. H., Millard, R. T., & Duvvuri, R. (1995). The Educator’s Word Frequency Guide. Brewster, NY: Touchstone Applied Science Associates."),
                       br(),
                       br(),
                       HTML("Zevin, J. D., & Seidenberg, M. S. (2004). Age-of-acquisition effects in reading aloud: Tests of cumulative frequency and frequency trajectory. Memory & Cognition, 32(1), 31–38.")
           )
  )



