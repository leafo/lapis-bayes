
-- Base interface for trainers. A trainer operates on a collection of
-- categories and, when training an object/text for a specific category within
-- that set, decides which tokens are candidates worth writing.
--
-- Constructor opts:
--   categories: array of category names this trainer operates on (required)
--   classifier: classifier instance used for tokenization and word lookup. If
--               omitted, a DefaultClassifier is constructed with these opts.
--   filter_tokens: optional fn (tokens, opts) -> tokens applied during
--                  normalization.
class BaseTrainer
  new: (@opts={}) =>
    @categories = assert @opts.categories,
      "#{@@__name}: missing categories"

    @classifier = @opts.classifier
    unless @classifier
      DefaultClassifier = require "lapis.bayes.classifiers.default"
      @classifier = DefaultClassifier @opts

  -- Normalize a tokens table into a canonical {word: count} map. Accepts the
  -- same shapes the classifier tokenizer returns (array of words or
  -- {word: count} map) and merges duplicate words. Applies the filter_tokens
  -- hook when configured.
  normalize_tokens: (tokens) =>
    if @opts.filter_tokens
      tokens = @opts.filter_tokens tokens, @opts

    merged = {}
    if tokens
      for k, v in pairs tokens
        word, count = if type(k) == "string"
          k, v
        else
          v, 1

        merged[word] or= 0
        merged[word] += count

    merged

  -- Abstract: given a target category name and a tokens table, return the
  -- candidate tokens to train. Returns (selected, stats) where selected is a
  -- {word: count} map and stats is an opaque, subclass-defined table.
  select_tokens: (target_name, tokens) =>
    error "#{@@__name}: select_tokens: subclass must implement"

  -- Train a document. Tokenizes, selects candidate tokens, and writes the
  -- survivors to the target category. Returns (count_written, stats).
  train_text: (target_name, text) =>
    tokens = @classifier\tokenize_text text
    selected, stats = @select_tokens target_name, tokens

    import Categories from require "lapis.bayes.models"
    target = Categories\find_or_create target_name

    written = if next selected
      target\increment_words selected
    else
      0

    written, stats
