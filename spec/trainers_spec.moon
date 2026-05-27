
import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Categories, WordClassifications from require "lapis.bayes.models"
SaturationTrainer = require "lapis.bayes.trainers.saturation"

-- identity tokenizer used in integration tests so we can target specific
-- tokens without going through stemming / stopword filtering
identity_tokenizer = (str, opts) -> [t for t in str\gmatch "%S+"]

describe "lapis.bayes.trainers.saturation", ->
  describe "construction", ->
    it "requires categories opt", ->
      assert.has_error -> SaturationTrainer!
      assert.has_error -> SaturationTrainer {}

    it "requires exactly two categories", ->
      assert.has_error -> SaturationTrainer categories: {"only_one"}
      assert.has_error -> SaturationTrainer categories: {"a", "b", "c"}

    it "constructs with a category pair", ->
      t = SaturationTrainer categories: {"spam", "ham"}
      assert.same {"spam", "ham"}, t.categories
      assert.same 0.95, t.saturation_threshold
      assert.same 30, t.min_observations
      assert.true t.train_novel
      assert.true t.train_opposite

    it "accepts threshold overrides", ->
      t = SaturationTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.8
        min_observations: 5
        train_novel: false
        train_opposite: false
      }
      assert.same 0.8, t.saturation_threshold
      assert.same 5, t.min_observations
      assert.false t.train_novel
      assert.false t.train_opposite

  describe "get_contrast", ->
    local trainer
    before_each ->
      trainer = SaturationTrainer categories: {"spam", "ham"}

    it "returns the other category", ->
      assert.same "ham", trainer\get_contrast "spam"
      assert.same "spam", trainer\get_contrast "ham"

    it "errors on unknown target", ->
      assert.has_error -> trainer\get_contrast "wat"

  describe "should_train_token", ->
    it "trains novel tokens by default", ->
      t = SaturationTrainer categories: {"a", "b"}
      assert.true t\should_train_token 0, 0

    it "skips novel tokens when train_novel is false", ->
      t = SaturationTrainer {
        categories: {"a", "b"}
        train_novel: false
      }
      assert.false t\should_train_token 0, 0

    it "always trains low-observation tokens regardless of rate", ->
      t = SaturationTrainer {
        categories: {"a", "b"}
        min_observations: 30
      }
      -- 5/0 = 100% target rate but n < min_obs
      assert.true t\should_train_token 5, 0

    it "skips tokens saturated in target direction", ->
      t = SaturationTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.95
        min_observations: 10
      }
      assert.false t\should_train_token 100, 0

    it "trains tokens saturated in opposite direction by default", ->
      t = SaturationTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.95
        min_observations: 10
      }
      assert.true t\should_train_token 0, 100

    it "skips opposite-direction tokens when train_opposite is false", ->
      t = SaturationTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.95
        min_observations: 10
        train_opposite: false
      }
      assert.false t\should_train_token 0, 100

    it "trains uncertain mid-range tokens", ->
      t = SaturationTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.95
        min_observations: 10
      }
      assert.true t\should_train_token 60, 40
      assert.true t\should_train_token 55, 45

  describe "select_tokens", ->
    use_test_env!

    local trainer

    before_each ->
      truncate_tables Categories, WordClassifications

      trainer = SaturationTrainer {
        categories: {"spam", "ham"}
        saturation_threshold: 0.95
        min_observations: 10
      }

    it "gates survivors against the corpus without mutating it", ->
      spam = Categories\find_or_create "spam"
      ham = Categories\find_or_create "ham"

      -- "metabol" saturated in spam (skipped),
      -- "but" saturated in ham (kept opposite),
      -- "novel" unseen (kept novel)
      spam\increment_words { metabol: 100 }
      ham\increment_words { but: 100 }

      selected, stats = trainer\select_tokens "spam", {
        metabol: 1
        novel: 1
        but: 1
      }

      assert.same { novel: 1, but: 1 }, selected
      assert.same 3, stats.total
      assert.same 2, stats.kept
      assert.same 1, stats.skipped_saturated
      assert.same 1, stats.kept_novel
      assert.same 1, stats.kept_opposite

      spam_counts = {wc.word, wc.count for wc in *WordClassifications\select "where category_id = ?", spam.id}
      assert.same { metabol: 100 }, spam_counts

    it "accepts an array-of-words token list and merges duplicates", ->
      selected, stats = trainer\select_tokens "spam", {"alpha", "beta", "alpha"}

      assert.same { alpha: 2, beta: 1 }, selected
      assert.same 2, stats.total
      assert.same 2, stats.kept_novel

    it "does not create the target category", ->
      trainer\select_tokens "spam", {"alpha"}
      assert.nil Categories\find name: "spam"

    it "treats every token as novel when contrast category does not exist", ->
      -- target has prior counts but with no contrast there's no saturation to
      -- measure against, so the DB lookup is skipped and tokens look novel
      spam = Categories\find_or_create "spam"
      spam\increment_words { alpha: 100 }

      selected, stats = trainer\select_tokens "spam", {"alpha", "beta"}

      assert.same { alpha: 1, beta: 1 }, selected
      assert.same 2, stats.kept_novel

    it "respects train_novel = false", ->
      trainer = SaturationTrainer {
        categories: {"spam", "ham"}
        train_novel: false
        min_observations: 5
      }

      ham = Categories\find_or_create "ham"
      ham\increment_words { other: 10 }

      selected, stats = trainer\select_tokens "spam", {"wholly", "novel", "words"}

      assert.same {}, selected
      assert.same 3, stats.skipped_novel

    it "errors when target is not in configured categories", ->
      assert.has_error -> trainer\select_tokens "other", {"some", "words"}

  describe "train_text", ->
    use_test_env!

    before_each ->
      truncate_tables Categories, WordClassifications

    it "tokenizes, gates, and writes selected tokens to the target", ->
      trainer = SaturationTrainer {
        categories: {"spam", "ham"}
        saturation_threshold: 0.95
        min_observations: 10
        tokenize_text: identity_tokenizer
      }

      spam = Categories\find_or_create "spam"
      ham = Categories\find_or_create "ham"

      spam\increment_words { metabol: 100 }
      ham\increment_words { but: 100 }

      count, stats = trainer\train_text "spam", "metabol novel but"

      assert.same 2, count
      assert.same 3, stats.total
      assert.same 2, stats.kept
      assert.same 1, stats.skipped_saturated
      assert.same 1, stats.kept_novel
      assert.same 1, stats.kept_opposite

      spam_counts = {wc.word, wc.count for wc in *WordClassifications\select "where category_id = ?", spam.id}
      assert.same { metabol: 100, novel: 1, but: 1 }, spam_counts
