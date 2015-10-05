
import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Categories, WordClassifications from require "lapis.bayes.models"

describe "lapis.bayes", ->
  use_test_env!

  setup ->
    -- remove the version that caches
    Categories.find_or_create = (name) =>
      @find(:name) or @create(:name)

  describe "WordClassifications", ->
    before_each ->
      truncate_tables Categories, WordClassifications

    it "deletes word from category", ->
      c1 = Categories\find_or_create "hello"

      c1\increment_words {
        alpha: 17
        beta: 19
      }
      c1_count = c1.total_count

      c2 = Categories\find_or_create "world"

      c2\increment_words {
        beta: 22
        triple: 27
      }
      c2_count = c2.total_count

      wc = assert WordClassifications\find category_id: c1.id, word: "beta"
      wc\delete!

      c1\refresh!
      c2\refresh!

      assert.same 19, c1_count - c1.total_count
      assert.same 0, c2_count - c2.total_count

  describe "Categories", ->
    before_each ->
      truncate_tables Categories, WordClassifications

    it "finds or creates category", ->
      c = Categories\find_or_create "hello"
      c2 = Categories\find_or_create "hello"
      assert.same c.id, c2.id

    it "increments words", ->
      c = Categories\find_or_create "hello"

      WordClassifications\create {
        word: "color"
        category_id: c.id
        count: 2
      }

      c\increment_words {
        color: 55
        height: 12
        green: 8
      }

      wc_by_name = {wc.word, wc for wc in *WordClassifications\select!}

      assert.same 57, wc_by_name.color.count
      assert.same 12, wc_by_name.height.count
      assert.same 8, wc_by_name.green.count

  describe "tokenize_text", ->
    import tokenize_text from require "lapis.bayes"

    it "gets tokens for empty string", ->
      assert.same {}, tokenize_text ""

    it "gets tokens for basic string", ->
      assert.same {"hello", "world"}, tokenize_text "hello world"

    it "gets tokens with stems and no stop words", ->
      assert.same {"eat", "burger"}, tokenize_text "i am eating burgers"

    it "gets tokens keeping dupes", ->
      assert.same {"burger", "burger"}, tokenize_text "burgers are burgers"

  describe "train_text", ->
    import train_text from require "lapis.bayes"

    before_each ->
      truncate_tables Categories, WordClassifications

    it "classifies a single string", ->
      train_text "spam", "hello this is spam, I love spam"
      assert.same 1, Categories\count!
      c = unpack Categories\select!
      assert.same "spam", c.name
      assert.same 3, WordClassifications\count!
      words = WordClassifications\select!
      table.sort words, (a, b) ->
        a.word < b.word

      assert.same {
        { category_id: c.id, count: 1, word: "hello" }
        { category_id: c.id, count: 1, word: "love" }
        { category_id: c.id, count: 2, word: "spam" }
      }, words


    it "classifies multiple strings", ->
      train_text "spam", "hello this is spam, I love spam"
      train_text "ham", "there is ham here"
      train_text "spam", "eating spamming the regular stuff"
      train_text "ham","pigs create too much jam"

  describe "text_probabilities", ->
    import text_probabilities from require "lapis.bayes"

    before_each ->
      truncate_tables Categories, WordClassifications

    it "works when there is no data", ->
      Categories\create name: "spam"
      Categories\create name: "ham"

      assert.same {
        nil, "no words in text are classifyable"
      }, {
        text_probabilities {"spam", "ham"}, "hello world"
      }

    it "works when there is some data", ->
      spam = Categories\create name: "spam"
      spam\increment_text "hello world"

      ham = Categories\create name: "ham"
      ham\increment_text "butt world"

      probs, rate = text_probabilities {"spam", "ham"}, "butt zone"
      assert.same 0.5, rate
      -- normalize probs for easy specs
      for p in *probs
        p[2] = math.floor p[2] * 100 + 0.5

      assert.same {
        {"ham", -134}
        {"spam", -438}
      }, probs

  describe "classify_text", ->
    import train_text, classify_text, text_probabilities, tokenize_text from require "lapis.bayes"

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

