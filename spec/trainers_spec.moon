
import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Categories, WordClassifications from require "lapis.bayes.models"
MarginalValueTrainer = require "lapis.bayes.trainers.marginal_value"

-- identity tokenizer used in integration tests so we can target specific
-- tokens without going through stemming / stopword filtering
identity_tokenizer = (str, opts) -> [t for t in str\gmatch "%S+"]

describe "lapis.bayes.trainers.marginal_value", ->
  describe "construction", ->
    it "requires categories opt", ->
      assert.has_error -> MarginalValueTrainer!
      assert.has_error -> MarginalValueTrainer {}

    it "requires exactly two categories", ->
      assert.has_error -> MarginalValueTrainer categories: {"only_one"}
      assert.has_error -> MarginalValueTrainer categories: {"a", "b", "c"}

    it "constructs with a category pair", ->
      t = MarginalValueTrainer categories: {"spam", "ham"}
      assert.same {"spam", "ham"}, t.categories
      assert.same 0.95, t.saturation_threshold
      assert.same 30, t.min_observations
      assert.true t.train_novel
      assert.true t.train_opposite

    it "accepts threshold overrides", ->
      t = MarginalValueTrainer {
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
      trainer = MarginalValueTrainer categories: {"spam", "ham"}

    it "returns the other category", ->
      assert.same "ham", trainer\get_contrast "spam"
      assert.same "spam", trainer\get_contrast "ham"

    it "errors on unknown target", ->
      assert.has_error -> trainer\get_contrast "wat"

  describe "should_train_token", ->
    it "trains novel tokens by default", ->
      t = MarginalValueTrainer categories: {"a", "b"}
      assert.true t\should_train_token 0, 0

    it "skips novel tokens when train_novel is false", ->
      t = MarginalValueTrainer {
        categories: {"a", "b"}
        train_novel: false
      }
      assert.false t\should_train_token 0, 0

    it "always trains low-observation tokens regardless of rate", ->
      t = MarginalValueTrainer {
        categories: {"a", "b"}
        min_observations: 30
      }
      -- 5/0 = 100% target rate but n < min_obs
      assert.true t\should_train_token 5, 0

    it "skips tokens saturated in target direction", ->
      t = MarginalValueTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.95
        min_observations: 10
      }
      assert.false t\should_train_token 100, 0

    it "trains tokens saturated in opposite direction by default", ->
      t = MarginalValueTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.95
        min_observations: 10
      }
      assert.true t\should_train_token 0, 100

    it "skips opposite-direction tokens when train_opposite is false", ->
      t = MarginalValueTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.95
        min_observations: 10
        train_opposite: false
      }
      assert.false t\should_train_token 0, 100

    it "trains uncertain mid-range tokens", ->
      t = MarginalValueTrainer {
        categories: {"a", "b"}
        saturation_threshold: 0.95
        min_observations: 10
      }
      assert.true t\should_train_token 60, 40
      assert.true t\should_train_token 55, 45

  describe "train_text", ->
    use_test_env!

    local trainer

    before_each ->
      truncate_tables Categories, WordClassifications

      trainer = MarginalValueTrainer {
        categories: {"spam", "ham"}
        saturation_threshold: 0.95
        min_observations: 10
        tokenize_text: identity_tokenizer
      }

    it "skips saturated, trains novel, trains opposite", ->
      spam = Categories\find_or_create "spam"
      ham = Categories\find_or_create "ham"

      -- "metabol" is saturated in spam (100/0)
      -- "but" is saturated in ham (0/100)
      -- "novel" is unseen
      spam\increment_words { metabol: 100 }
      ham\increment_words { but: 100 }

      count, stats = trainer\train_text "spam", "metabol novel but"

      assert.same 3, stats.total
      assert.same 2, stats.kept
      assert.same 1, stats.skipped_saturated
      assert.same 1, stats.kept_novel
      assert.same 1, stats.kept_opposite

      spam_counts = {wc.word, wc.count for wc in *WordClassifications\select "where category_id = ?", spam.id}
      assert.same 100, spam_counts.metabol  -- not incremented
      assert.same 1, spam_counts.novel
      assert.same 1, spam_counts.but

    it "leaves spam untouched when every token is saturated in target", ->
      spam = Categories\find_or_create "spam"
      Categories\find_or_create "ham"

      spam\increment_words { foo: 100, bar: 100 }

      count, stats = trainer\train_text "spam", "foo bar"

      assert.same 0, count
      assert.same 2, stats.total
      assert.same 0, stats.kept
      assert.same 2, stats.skipped_saturated

      spam_counts = {wc.word, wc.count for wc in *WordClassifications\select "where category_id = ?", spam.id}
      assert.same 100, spam_counts.foo
      assert.same 100, spam_counts.bar

    it "trains every token when contrast category does not exist yet", ->
      count, stats = trainer\train_text "spam", "alpha beta gamma"

      assert.same 3, stats.total
      assert.same 3, stats.kept
      assert.same 3, stats.kept_novel

      spam = assert Categories\find name: "spam"
      counts = {wc.word, wc.count for wc in *WordClassifications\select "where category_id = ?", spam.id}
      assert.same {alpha: 1, beta: 1, gamma: 1}, counts

    it "respects train_novel = false", ->
      trainer = MarginalValueTrainer {
        categories: {"spam", "ham"}
        train_novel: false
        min_observations: 5
        tokenize_text: identity_tokenizer
      }

      ham = Categories\find_or_create "ham"
      ham\increment_words { other: 10 }

      count, stats = trainer\train_text "spam", "wholly novel words"

      assert.same 3, stats.total
      assert.same 0, stats.kept
      assert.same 3, stats.skipped_novel

      spam = assert Categories\find name: "spam"
      counts = {wc.word, wc.count for wc in *WordClassifications\select "where category_id = ?", spam.id}
      assert.same {}, counts

    it "works symmetrically in the ham direction", ->
      spam = Categories\find_or_create "spam"
      ham = Categories\find_or_create "ham"

      -- "metabol" saturated in spam: training "ham" with it should train
      -- (opposite direction)
      spam\increment_words { metabol: 100 }

      count, stats = trainer\train_text "ham", "metabol"

      assert.same 1, stats.kept_opposite

      ham_counts = {wc.word, wc.count for wc in *WordClassifications\select "where category_id = ?", ham.id}
      assert.same 1, ham_counts.metabol

    it "errors when target is not in configured categories", ->
      assert.has_error -> trainer\train_text "other", "some text"
