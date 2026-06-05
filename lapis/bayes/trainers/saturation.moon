
-- Selective trainer for a binary classifier. Decides per-token whether a
-- training write would add information given the token's current distribution
-- in the corpus, and writes only the survivors.
--
-- Construct one trainer per binary category pair; the same instance handles
-- training in either direction (it derives the contrast from the target name).
--
-- Constructor opts:
--   categories: array of exactly 2 category names, e.g. {"spam", "ham"} (required)
--   saturation_threshold: number in (0.5, 1]. A token is "saturated" in a
--                         direction when its current p in that direction is
--                         >= this value (default 0.95).
--   min_observations: tokens with fewer total observations across both
--                     categories are always trained (default 30).
--   train_novel: train tokens with no prior observations (default true).
--   train_opposite: train tokens currently saturated in the OPPOSITE direction
--                   from the document's label (default true). These are the
--                   "model is wrong about this token" cases.
--   classifier: classifier instance used for tokenization and word lookup. If
--               omitted, a DefaultClassifier is constructed with these opts.
--   tokenize_text / tokenizer / etc.: forwarded to the default classifier
--                                     when no classifier is provided.
BaseTrainer = require "lapis.bayes.trainers.base"

class SaturationTrainer extends BaseTrainer
  new: (opts) =>
    super opts
    assert #@categories == 2,
      "SaturationTrainer: categories must be a list of exactly 2 names"

    @saturation_threshold = @opts.saturation_threshold or 0.95
    @min_observations = @opts.min_observations or 30
    @train_novel = if @opts.train_novel != nil then @opts.train_novel else true
    @train_opposite = if @opts.train_opposite != nil then @opts.train_opposite else true

  get_contrast: (target_name) =>
    a, b = unpack @categories
    if target_name == a
      b
    elseif target_name == b
      a
    else
      error "SaturationTrainer: target '#{target_name}' is not in configured categories {#{a}, #{b}}"

  -- Pure gating decision. Given current counts for a token in both target and
  -- contrast categories, return true if the token should be written.
  should_train_token: (target_count, contrast_count) =>
    n = target_count + contrast_count

    if n == 0
      return @train_novel

    if n < @min_observations
      return true

    p_target = target_count / n

    if p_target >= @saturation_threshold
      false
    elseif p_target <= (1 - @saturation_threshold)
      @train_opposite
    else
      true

  -- Apply gating to a tokens table without writing. Accepts the same shapes
  -- the classifier tokenizer returns (array of words or {word: count} map).
  -- Returns (selected, stats) where selected is a {word: count} map of the
  -- tokens train_text would write.
  select_tokens: (target_name, tokens) =>
    contrast_name = @get_contrast target_name

    merged = @normalize_tokens tokens

    stats = {
      total: 0
      kept: 0
      skipped_saturated: 0
      skipped_novel: 0
      kept_novel: 0
      kept_opposite: 0
      kept_uncertain: 0
      kept_low_obs: 0
    }

    selected = {}

    unless next merged
      return selected, stats

    import Categories from require "lapis.bayes.models"
    target = Categories\find name: target_name
    contrast = Categories\find name: contrast_name

    target_counts = {}
    contrast_counts = {}

    if target and contrast
      words = [w for w in pairs merged]
      wcs = @classifier\find_word_classifications words, {target.id, contrast.id}
      for wc in *wcs
        if wc.category_id == target.id
          target_counts[wc.word] = wc.count
        elseif wc.category_id == contrast.id
          contrast_counts[wc.word] = wc.count

    for word, count in pairs merged
      stats.total += 1

      t = target_counts[word] or 0
      c = contrast_counts[word] or 0
      n = t + c

      bucket = if n == 0
        @train_novel and "kept_novel" or "skipped_novel"
      elseif n < @min_observations
        "kept_low_obs"
      else
        p_target = t / n
        if p_target >= @saturation_threshold
          "skipped_saturated"
        elseif p_target <= (1 - @saturation_threshold)
          @train_opposite and "kept_opposite" or "skipped_saturated"
        else
          "kept_uncertain"

      stats[bucket] += 1

      if bucket\match "^kept_"
        selected[word] = count
        stats.kept += 1

    selected, stats
