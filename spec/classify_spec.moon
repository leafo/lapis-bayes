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

        do
          results = classifier\find_categories {"first", "second"}
          assert.same 2, #results, "should find two categories"

          -- confirm the result objects are in correct order
          assert.same first.id, results[1].id, "correct category order"
          assert.same second.id, results[2].id, "correct category order"

        do
          results = classifier\find_categories {"third", "first"}
          assert.same 2, #results, "should find two categories"

          -- confirm the result objects are in correct order
          assert.same third.id, results[1].id, "correct category order"
          assert.same first.id, results[2].id, "correct category order"

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
      "lapis.bayes.classifiers.bayes_multi"
      "lapis.bayes.classifiers.fisher"
    }

    for cmod in *classifiers
      it "classifies with #{cmod}", ->
        C = require cmod
        res = assert C!\text_probabilities {"spam", "ham"},
          "good game zone love them game at the beach"

        assert.same "ham", res[1][1]

    it "classifies with lapis.bayes.classifiers.bayes (log)", ->
      C = require "lapis.bayes.classifiers.bayes"
      classifier = C { log: true }

      res = assert classifier\text_probabilities {"spam", "ham"},
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
          got_default = classify_text categories, text
          unless got_default == classification
            BaseClassifier = require "lapis.bayes.classifiers.base"
            tokens = BaseClassifier!\tokenize_text text

            error {
              "got #{got_default}, expected #{classification}"
              categories: Categories\find_all categories, "name"
              words: WordClassifications\find_all tokens, "word"
              tokens: tokens
              probs: text_probabilities {"spam", "ham"}, text
            }

          got_log = classify_text categories, text, { log: true }
          unless got_log == classification
            BaseClassifier = require "lapis.bayes.classifiers.base"
            tokens = BaseClassifier!\tokenize_text text

            error {
              "log mode got #{got_log}, expected #{classification}"
              categories: Categories\find_all categories, "name"
              words: WordClassifications\find_all tokens, "word"
              tokens: tokens
              probs: text_probabilities {"spam", "ham"}, text, { log: true }
              opts: { log: true }
            }

  describe "BayesMultiClassifier", ->
    import train_text from require "lapis.bayes"

    before_each ->
      truncate_tables Categories, WordClassifications
      for {label, tokens} in *{
        {"cats", {"cat", "kitten", "purr", "whisker", "nap"}}
        {"cats", {"feline", "cat", "purr"}}
        {"dogs", {"dog", "puppy", "bark", "bone", "wag"}}
        {"dogs", {"dog", "fetch", "leash", "bark"}}
        {"birds", {"bird", "wing", "feather", "chirp"}}
        {"birds", {"bird", "soar", "sky", "chirp"}}
      }
        train_text label, tokens

    it "classifies across multiple categories", ->
      classifier = require "lapis.bayes.classifiers.bayes_multi"
      probs = assert classifier!\text_probabilities {"cats", "dogs", "birds"},
        {"kitten", "purr", "whisker"}

      assert.same "cats", probs[1][1]
      assert probs["cats"] > probs["dogs"], "cats should outrank dogs"
      assert probs["cats"] > probs["birds"], "cats should outrank birds"

    it "generates a normalised probability distribution", ->
      classifier = require "lapis.bayes.classifiers.bayes_multi"
      probs = assert classifier!\text_probabilities {"cats", "dogs", "birds"},
        {"bark", "bone", "dog"}

      total = 0
      for {_, p} in *probs
        total += p

      assert math.abs(total - 1) < 1e-6, "probabilities should sum to ~1"

  describe "NgramTokenizer with BayesMultiClassifier for language detection", ->
    NgramTokenizer = require "lapis.bayes.tokenizers.ngram"
    BayesMultiClassifier = require "lapis.bayes.classifiers.bayes_multi"
    import train_text from require "lapis.bayes"

    local classifier

    before_each ->
      truncate_tables Categories, WordClassifications

      -- Use bigrams (n=2) for language detection - captures character patterns
      tokenizer = NgramTokenizer { n: 2 }
      classifier = BayesMultiClassifier { tokenizer: tokenizer }

      -- Train on sample sentences in different languages with more data per language
      training_data = {
        -- English - distinctive patterns: "th", "he", "er", "an", "in", "on"
        {"english", "The quick brown fox jumps over the lazy dog and runs around"}
        {"english", "Hello world this is a test of the system in English language"}
        {"english", "Programming and software development with modern technology"}
        {"english", "Machine learning models for natural language understanding"}
        {"english", "Welcome to the website where you can find information"}
        {"english", "These are common English words and phrases that we use"}

        -- Spanish - distinctive: "ción", "que", "es", "os", "as", "ñ"
        {"spanish", "El rápido zorro marrón que salta sobre el perro perezoso"}
        {"spanish", "Hola mundo esta es una prueba del sistema de transmisión"}
        {"spanish", "Los lenguajes de programación son herramientas importantes"}
        {"spanish", "Buenos días cómo estás espero que tengas un buen día"}
        {"spanish", "Bienvenido a nuestro sitio web donde puedes encontrar información"}
        {"spanish", "Estas son palabras y frases comunes que usamos en español"}

        -- French - distinctive: "le", "de", "tion", "ent", "que", accents
        {"french", "Le rapide renard brun qui saute pardessus le chien paresseux"}
        {"french", "Bonjour le monde ceci est un test du système de diffusion"}
        {"french", "Les langages de programmation sont des outils importants"}
        {"french", "Comment allezvous aujourdhui jespère que vous passez une bonne journée"}
        {"french", "Bienvenue sur notre site web où vous pouvez trouver des informations"}
        {"french", "Ce sont des mots et phrases courants que nous utilisons en français"}

        -- German - distinctive: "ch", "sch", "en", "er", "un", umlauts
        {"german", "Der schnelle braune Fuchs der über den faulen Hund springt"}
        {"german", "Hallo Welt dies ist ein Test des Notfallübertragungssystems"}
        {"german", "Programmiersprachen sind wichtige Werkzeuge für die Entwicklung"}
        {"german", "Guten Morgen wie geht es Ihnen ich hoffe Sie haben einen schönen Tag"}
        {"german", "Willkommen auf unserer Website wo Sie Informationen finden können"}
        {"german", "Dies sind häufige Wörter und Phrasen die wir auf Deutsch verwenden"}

        -- Chinese - distinctive: Chinese characters, different byte patterns
        {"chinese", "敏捷的棕色狐狸跳过懒狗并且到处跑"}
        {"chinese", "你好世界这是一个紧急广播系统的测试"}
        {"chinese", "编程语言是表达算法的重要工具"}
        {"chinese", "早上好你好吗我希望你有美好的一天"}
        {"chinese", "欢迎来到我们的网站在这里你可以找到信息"}
        {"chinese", "这些是我们在中文中使用的常用词和短语"}
      }

      for {lang, text} in *training_data
        train_text lang, text, { tokenizer: tokenizer }

    it "detects English text", ->
      probs = assert classifier\text_probabilities {
        "english", "spanish", "french", "german", "chinese"
      }, "Welcome to the website where you can find information and content"

      assert.same "english", probs[1][1], "should detect English"
      assert probs["english"] > 0.3, "English should have reasonable probability"

    it "detects Spanish text", ->
      probs = assert classifier\text_probabilities {
        "english", "spanish", "french", "german", "chinese"
      }, "Bienvenido estas son palabras en español que usamos"

      assert.same "spanish", probs[1][1], "should detect Spanish"
      assert probs["spanish"] > probs["english"], "Spanish should outrank English"

    it "detects French text", ->
      probs = assert classifier\text_probabilities {
        "english", "spanish", "french", "german", "chinese"
      }, "Bienvenue ce sont des mots en français que nous utilisons"

      assert.same "french", probs[1][1], "should detect French"
      assert probs["french"] > probs["english"], "French should outrank English"

    it "detects German text", ->
      probs = assert classifier\text_probabilities {
        "english", "spanish", "french", "german", "chinese"
      }, "Willkommen dies sind Wörter auf Deutsch die wir verwenden"

      assert.same "german", probs[1][1], "should detect German"
      assert probs["german"] > probs["english"], "German should outrank English"

    it "detects Chinese text", ->
      probs = assert classifier\text_probabilities {
        "english", "spanish", "french", "german", "chinese"
      }, "欢迎这些是我们使用的中文词语"

      assert.same "chinese", probs[1][1], "should detect Chinese"
      assert probs["chinese"] > probs["english"], "Chinese should outrank English"

    it "probabilities sum to 1", ->
      probs = assert classifier\text_probabilities {
        "english", "spanish", "french", "german", "chinese"
      }, "This is a test sentence in English"

      total = 0
      for {_, p} in *probs
        total += p

      assert math.abs(total - 1) < 1e-6, "probabilities should sum to ~1"

    it "returns all languages ranked", ->
      probs = assert classifier\text_probabilities {
        "english", "spanish", "french", "german", "chinese"
      }, "Testing language detection with character ngrams"

      assert.same 5, #probs, "should return probabilities for all 5 languages"
      assert.same "english", probs[1][1], "English should be first"

      -- Verify probabilities are in descending order
      for i = 2, #probs
        assert probs[i-1][2] >= probs[i][2], "probabilities should be sorted descending"

  describe "BayesClassifier with token_weight_patterns", ->
    import train_text from require "lapis.bayes"
    BayesClassifier = require "lapis.bayes.classifiers.bayes"

    before_each ->
      truncate_tables Categories, WordClassifications

      -- Train with specific tokens to test weighting
      -- Category "good" has certain tokens
      train_text "good", {"hello", "world", "nice", "great", "domain:trusted"}
      train_text "good", {"hello", "nice", "domain:trusted"}
      train_text "good", {"world", "great"}

      -- Category "bad" has different tokens
      train_text "bad", {"spam", "junk", "domain:untrusted"}
      train_text "bad", {"spam", "domain:untrusted"}
      train_text "bad", {"junk", "evil"}

    it "classifies without weights (baseline)", ->
      classifier = BayesClassifier!
      probs = assert classifier\text_probabilities {"good", "bad"},
        {"hello", "world", "domain:trusted"}

      assert.same "good", probs[1][1], "should classify as good"

    it "boosts tokens matching pattern with weight > 1", ->
      -- Without weights, classify text with domain token
      classifier_no_weight = BayesClassifier!
      probs_no_weight = assert classifier_no_weight\text_probabilities {"good", "bad"},
        {"domain:trusted"}

      baseline_prob = probs_no_weight["good"]

      -- With weights, boost domain tokens
      classifier_with_weight = BayesClassifier {
        token_weight_patterns: {["^domain:"]: 2.0}
      }
      probs_with_weight = assert classifier_with_weight\text_probabilities {"good", "bad"},
        {"domain:trusted"}

      boosted_prob = probs_with_weight["good"]

      -- Boosted probability should be higher (more confident)
      assert boosted_prob > baseline_prob, "weighted token should increase confidence"

    it "dampens tokens matching pattern with weight < 1", ->
      -- Without weights
      classifier_no_weight = BayesClassifier!
      probs_no_weight = assert classifier_no_weight\text_probabilities {"good", "bad"}, {
        "hello"
        "domain:trusted"
      }

      baseline_prob = probs_no_weight["good"]

      -- With dampening weight
      classifier_with_weight = BayesClassifier {
        token_weight_patterns: {
          "^domain:": 0.5
        }
      }

      probs_with_weight = assert classifier_with_weight\text_probabilities {"good", "bad"}, {
        "hello"
        "domain:trusted"
      }

      dampened_prob = probs_with_weight["good"]

      -- Dampened probability should be lower (less confident)
      assert dampened_prob < baseline_prob, "dampened token should decrease confidence"

    it "handles tokens that don't match any pattern", ->
      classifier = BayesClassifier {
        token_weight_patterns: {
          "^domain:": 2.0
        }
      }

      probs = assert classifier\text_probabilities {"good", "bad"}, {
        "hello"
        "world"
      }

      assert.same "good", probs[1][1], "should still classify correctly"

    it "handles multiple patterns", ->
      classifier = BayesClassifier {
        token_weight_patterns: {
          "^domain:": 2.0
          "^url:": 1.5
          "trusted$": 3.0
        }
      }

      probs = assert classifier\text_probabilities {"good", "bad"}, {
        "domain:trusted"
        "hello"
      }

      assert.same "good", probs[1][1], "should classify with multiple patterns"

    it "works in log mode", ->
      classifier_log = BayesClassifier {
        log: true
        token_weight_patterns: {["^domain:"]: 2.0}
      }

      probs_log = assert classifier_log\text_probabilities {"good", "bad"},
        {"domain:trusted"}

      assert.same "good", probs_log[1][1], "should work in log mode"
      assert probs_log["good"] > 0.5, "should have high confidence for good category"

    it "works in regular mode", ->
      classifier_regular = BayesClassifier {
        log: false
        token_weight_patterns: {
          "^domain:": 2.0
        }
      }

      probs_regular = assert classifier_regular\text_probabilities {"good", "bad"}, {
        "domain:trusted"
      }

      assert.same "good", probs_regular[1][1], "should work in regular mode"
      assert probs_regular["good"] > 0.5, "should have high confidence for good category"

    it "handles weight of 1.0 (no effect)", ->
      classifier_no_weight = BayesClassifier!
      probs_no_weight = assert classifier_no_weight\text_probabilities {"good", "bad"}, {
        "hello", "domain:trusted"
      }

      classifier_weight_1 = BayesClassifier {
        token_weight_patterns: {
          "^domain:": 1.0
        }
      }

      probs_weight_1 = assert classifier_weight_1\text_probabilities {"good", "bad"}, {
        "hello", "domain:trusted"
      }

      -- Should produce very similar results (allowing for floating point differences)
      assert math.abs(probs_no_weight["good"] - probs_weight_1["good"]) < 0.01,
        "weight of 1.0 should have minimal effect"

    it "can flip classification with strong weight", ->
      -- "weak" category has many tokens
      train_text "weak", {"common", "common", "common", "common", "marker:weak"}

      -- "strong" category has fewer tokens but marked token
      train_text "strong", {"marker:strong"}

      -- Without weights, common words dominate
      classifier_no_weight = BayesClassifier!
      probs_no_weight = assert classifier_no_weight\text_probabilities {"weak", "strong"}, {
        "common"
        "marker:strong"
      }

      -- With strong weight on marker, it should flip
      classifier_with_weight = BayesClassifier {
        token_weight_patterns: {
          "^marker:": 5.0
        }
      }

      probs_with_weight = assert classifier_with_weight\text_probabilities {"weak", "strong"}, {
        "common", "marker:strong"
      }

      -- The weighted marker should increase confidence in "strong"
      assert probs_with_weight["strong"] > probs_no_weight["strong"],
        "strong weight should boost target category"

    it "handles empty pattern list", ->
      classifier = BayesClassifier {
        token_weight_patterns: {}
      }

      probs = assert classifier\text_probabilities {"good", "bad"}, {
        "hello"
        "domain:trusted"
      }

      assert.same "good", probs[1][1], "should work with empty pattern list"

