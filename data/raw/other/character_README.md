## OVERVIEW
In order to analyze the gender of characters in our child-directed
text corpus, we sifted through all our texts and determined whether
each text had a main or secondary character or characters, and if they
did what their gender composition was. Additionally, we recovered the
name of the main character if there was a singular main character.
The coded data can be found in the file:  

character_gender_by_book.xlsx

## Variables

* char_main_singular
     * This variable codes for whether or not there is a singular
     main character in the book, and takes two values:
     * YES indicates that there is a singular main character
     * NO indicates that there is not a singular main character,
     in which case there can either be several main characters
     or no characters at all.
* char_main_gender
     * This variable codes for the gender of the main character,
     taking several different values:
     * M indicates male
     * F indicates female
     * AND indicates androgynous
     * MIXED indicates that there is more than one main character
     and their genders are some mixture of male and female
     * NA indicates that the gender of the main character is not
     specified.
* char_second_singular
     * This variable codes whether or not there is a singular secondary
     character, taking two values:
     * YES indicates that there is a singular secondary character
     * NO indicates that there is not a singular secondary character,
     in which case there can either be several secondary characters
     or no characters at all.
* char_second_gender
     * This variable codes for the gender of the secondary character,
      taking the same values as described for char_second_gender.
* char_name
     * The name of the singular main character if there is one.
* notes
     * Notes about the coding for a given book if applicable.
