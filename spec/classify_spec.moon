import truncate_tables from require "lapis.spec.db"

import Categories, WordClassifications from require "lapis.bayes.models"

describe "lapis.bayes", ->

  describe "BaseClassifier", ->
    local classifier
    before_each ->
      truncate_tables Categories, WordClassifications
      BaseClassifier = require "lapis.bayes.classifiers.base"
      classifier = BaseClassifier!

    describe "find_categories", ->
      it "handles invalid categories", ->
        assert.same {
          nil, "find_categories: missing categories (first, second)"
        }, {
          classifier\find_categories {"first", "second"}
        }

      it "handles one invalid category", ->
        Categories\find_or_create "first"
        assert.same {
          nil, "find_categories: missing categories (second)"
        }, {
          classifier\find_categories {"first", "second"}
        }

      it "finds categories in the correct order", ->
        first = Categories\find_or_create "first"
        second = Categories\find_or_create "second"
        third = Categories\find_or_create "third"

        results = classifier\find_categories {"first", "second"}
        assert.same 2, #results, "should find two categories"

        -- confirm the result objects are in correct order
        assert.same first.id, results[1].id, "correct category order"
        assert.same second.id, results[2].id, "correct category order"

    describe "find_word_classifications", ->
      it "finds empty set", ->
        first = Categories\find_or_create "first"
        second = Categories\find_or_create "second"

        assert.same {}, classifier\find_word_classifications {"myword"}, {first.id, second.id}

      it "finds partial results", ->
        first = Categories\find_or_create "first"
        second = Categories\find_or_create "second"

        WordClassifications\create {
          category_id: first.id
          word: "hello"
          count: 2
        }

        WordClassifications\create {
          category_id: second.id
          word: "hello"
          count: 8
        }

        WordClassifications\create {
          category_id: second.id
          word: "zone"
          count: 4
        }

        WordClassifications\create {
          category_id: second.id
          word: "yum"
          count: 3
        }

        res = classifier\find_word_classifications {"hello", "zone"}, {first.id, second.id}

        results = ["#{r.category_id}:#{r.word}:#{r.count}" for r in *res]
        table.sort results

        expected = {
          "#{first.id}:hello:2"
          "#{second.id}:hello:8"
          "#{second.id}:zone:4"
        }

        table.sort expected
        assert.same expected, results

  describe "classify_text", ->
    import train_text, classify_text, text_probabilities from require "lapis.bayes"
    import tokenize_text from require "lapis.bayes.tokenizer"

    setup ->
      truncate_tables Categories, WordClassifications
      for {c, text} in *{
        {"spam", [[Replica Patek menn klokker : kopi Patek Philippe klokker, replicapatekonline.com]] }
        {"spam", [[Links of London Necklaces 6 - $88.00 : links of london, linksoflondonoutlete.net]] }
        {"spam", [[Robes de mariée 2015, robes de bal 2015, robes de soirée 2015 au prix de gros.]] }
        {"spam", [[Cheap Pandora Charms US Online:Offer the best Pandora jewellery at great prices.]] }
        {"spam", [[Wedding Dresses | Bridesmaid Dresses | Prom &amp; Evening Dresses | Sundo Bridal]] }
        {"spam", [[Christian Louboutin Illat : Christian Louboutin Outlet Sale Kanssa Iso alennus !]] }
        {"spam", [[Links of London Dome Amethyst Charm - $47.20 : links of london, randjjewelry.org]] }
        {"spam", [[Christian Louboutin Illat : Christian Louboutin Outlet Sale Kanssa Iso alennus !]] }
        {"spam", [[New Balance 574 Chaussures Online Store, New Balance 574 chaussures Vente chaude]] }
        {"spam", [[Audemars Piguet Replica Watches - Wholesale Audemars Piguet Watches Online Store]] }
        {"spam", [[Billige Beach Brudekjoler 2013 Affordable Beach Brudekjoler Online: TDbridal.com]] }
        {"spam", [[Hourglass Underwire - $125.00 : Professional swimwear stores, coolbikinishop.com]] }
        {"spam", [[G script charm flap french wallet - $120.00 : Gucci outlet stores, gucci-me.com]] }
        {"spam", [[Constellation Brushed Chronometer  - $212.00 : Zen Cart!, The Art of E-commerce]] }
        {"spam", [[Women New Balance 1400,Women New Balance 1400 For Sale : newbalancefanatics.com]] }
        {"spam", [[Longines Evidenza - urmager Tradition - Ure - Longines Swiss Urmager siden 1832]] }
        {"spam", [[Constellation Brushed Chronometer  - $211.00 : Zen Cart!, The Art of E-commerce]] }
        {"spam", [[Links of London Necklaces 2 - $80.00 : links of london, linksoflondondublin.com]] }
        {"spam", [[Cheap Prom Dresses 2014 - Buy discount Prom Dress on sale at Weddinggownyes.com]] }
        {"spam", [[Older Models Rolex Watches - View Large Selection of Rolex Older Models Watches]] }

        {"ham", [[The "I don't know what to call these games but I liked how the look" Collection]] }
        {"ham", [[Interesting, experimental, alternative. A.K.A favorite stuff here ever]] }
        {"ham", [[Cool stuff from friends and buddies - mainly german / berlin dev scene]] }
        {"ham", [[an old game i found on my old itch.io account whose password i forgot]] }
        {"ham", [[Collection of things I liked that were free so I can find them later]] }
        {"ham", [[Bla bla bla: Text Adventures, Visual Novels and Twine Games]] }
        {"ham", [[Lo que he encontrado en este maravilloso lugar llamado Itch]] }
        {"ham", [[Inspirational Titles  ::  Idea-Crafting  ::  Case Studies.]] }
        {"ham", [[i love mlg!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!]] }
        {"ham", [[Things I need to pay for when I get my credit card back]] }
        {"ham", [[∀∀∀∀∀∀∀∀∀∀∀∀∀∀∀∀∀∀]] }
        {"ham", [[games i particularly like for some reason or another]] }
        {"ham", [[http://itch.io/c/9098/myajoufi33gmailcoms-collection]] }
        {"ham", [[I didn't make them, but in no order I recommend them]] }
        {"ham", [[Homebrew: Original Games for Obsolete Game Hardware]] }
        {"ham", [[Games I've downloaded so I remember them and stuff]] }
        {"ham", [[Secret Tunnel's Collection of Rad Games That I Dig]] }
        {"ham", [[[GameBlast] Jogos gratuitos recomendados da semana]] }
        {"ham", [[Point 'n Click/"Walking Sims"/Stories/Exploration]] }
        {"ham", [[Shubshub's List of Cool Games that Shubshub Likes]] }
      }
        train_text c, text


    classifiers = {
      "lapis.bayes.classifiers.test"
      "lapis.bayes.classifiers.bayes"
      "lapis.bayes.classifiers.bayes_mod"
      "lapis.bayes.classifiers.fisher"
    }

    for cmod in *classifiers
      it "classifies with #{cmod}", ->
        C = require cmod
        res = assert C!\text_probabilities {"spam", "ham"},
          "good game zone love them game at the beach"

        assert.same "ham", res[1][1]

    for classification, texts in pairs {
      spam: {
        [[prom rolex watches for cheap sale]]
        [[older replica outlet sale]]
        [[dresses]]
      }
      ham: {
        [[i love games and rember these as being good]]
        [[this collection is great text adventures and experimental stuff]]
        [[games]]
      }
    }
      for text in *texts
        categories = {"spam", "ham"}

        it "classifies '#{text}' as '#{classification}'", ->
          got = classify_text categories, text
          unless got == classification
            tokens = tokenize_text text
            error {
              "got #{got}, expected #{classification}"
              categories: Categories\find_all categories, "name"
              words: WordClassifications\find_all tokens, "word"
              tokens: tokens
              probs: text_probabilities {"spam", "ham"}, text
            }


