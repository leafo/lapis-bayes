-- implements naive bayes with assumed probability
class BayesClassifier extends require "lapis.bayes.classifiers.base"
  @default_options: {
    max_words: 40
    default_prob: 0.1
    log: false
    token_weight_patterns: nil
    uncertainty_weight: 1.0
    normalize_doc_count: false
  }

  -- Compares per-document word rates so a category with more training
  -- documents doesn't win every shared word. The prior is uniform since the
  -- training balance is usually a sampling artifact, not the real base rate.
  doc_log_rate_ratio: (a, b, word) =>
    -- one smoothing floor shared by both categories so it favors neither
    default_rate = @opts.default_prob / (a.doc_count + b.doc_count)

    a_rate = (a.word_counts and a.word_counts[word] or 0) / a.doc_count + default_rate
    b_rate = (b.word_counts and b.word_counts[word] or 0) / b.doc_count + default_rate
    math.log(a_rate) - math.log(b_rate)

  -- keeps the words that move the normalized score the most. chi-squared
  -- selection can't be used here since word counts may exceed doc_count
  doc_normalized_candidate_words: (a, b, available_words, count) =>
    return available_words if #available_words <= count

    tuples = for word in *available_words
      {word, math.abs @doc_log_rate_ratio a, b, word}

    table.sort tuples, (x, y) ->
      if x[2] == y[2]
        return x[1] < y[1]
      x[2] > y[2]

    [t[1] for t in *tuples[,count]]

  doc_normalized_probability: (a, b, available_words, token_weights) =>
    log_ratio = 0
    for word in *available_words
      log_ratio += token_weights[word] * @doc_log_rate_ratio a, b, word

    1 / (1 + math.exp -log_ratio)

  get_token_weight: (word) =>
    return 1.0 unless @opts.token_weight_patterns

    for pattern, weight in pairs @opts.token_weight_patterns
      if word\match pattern
        return weight

    1.0

  word_probabilities: (categories, available_words, opts={}) =>
    opts or= {}
    return nil, "only two categories supported at once" unless #categories == 2

    a, b = unpack categories

    if @opts.normalize_doc_count
      unless (a.doc_count or 0) > 0 and (b.doc_count or 0) > 0
        return nil, "normalize_doc_count requires doc_count on both categories"

    sum_counts = 0
    for c in *categories
      sum_counts += c.total_count

    available_words = if @opts.normalize_doc_count
      @doc_normalized_candidate_words a, b, available_words, @opts.max_words
    else
      @candidate_words categories, available_words, @opts.max_words
    available_words_count = #available_words

    unclassified_counts = opts.unclassified_counts or @opts.unclassified_counts
    uncertainty_weight = if opts.uncertainty_weight != nil
      opts.uncertainty_weight
    else
      @opts.uncertainty_weight or 1.0
    uncertainty_weight = math.max uncertainty_weight, 0

    token_weights = {}
    for word in *available_words
      weight = @get_token_weight word

      if unclassified_counts
        unc = unclassified_counts[word]
        if unc and unc > 0
          classified_total = 0
          classified_total += (a.word_counts and a.word_counts[word]) or 0
          classified_total += (b.word_counts and b.word_counts[word]) or 0

          total = classified_total + unc
          if total > 0 and uncertainty_weight != 0
            confidence = classified_total / total
            weight *= confidence ^ uncertainty_weight

      token_weights[word] = weight

    default_prob = @opts.default_prob / sum_counts

    default_a = default_prob * a.total_count
    default_b = default_prob * b.total_count

    -- NOTE: you should use log mode if you have a large number of tokens
    -- because the numbers get really small
    prob = if @opts.normalize_doc_count
      @doc_normalized_probability a, b, available_words, token_weights
    elseif @opts.log
      ai_log_sum = 0
      bi_log_sum = 0

      for word in *available_words
        ai_count = (a.word_counts and a.word_counts[word] or 0) + default_a
        bi_count = (b.word_counts and b.word_counts[word] or 0) + default_b

        weight = token_weights[word] or @get_token_weight word

        ai_log_sum += weight * math.log ai_count
        bi_log_sum += weight * math.log bi_count

      ai_log_sum += math.log a.total_count
      bi_log_sum += math.log b.total_count

      ai_log_sum -= math.log (default_a + a.total_count)
      bi_log_sum -= math.log (default_b + b.total_count)

      ai_log_sum -= math.log available_words_count
      bi_log_sum -= math.log available_words_count

      max_log_sum = math.max ai_log_sum, bi_log_sum

      ai_prob = math.exp(ai_log_sum - max_log_sum)
      bi_prob = math.exp(bi_log_sum - max_log_sum)

      ai_prob / (ai_prob + bi_prob)
    else
      local ai_mul, bi_mul

      for word in *available_words
        ai_count = (a.word_counts and a.word_counts[word] or 0) + default_a
        bi_count = (b.word_counts and b.word_counts[word] or 0) + default_b

        weight = token_weights[word] or @get_token_weight word

        if ai_mul
          ai_mul *= ai_count ^ weight
        else
          ai_mul = ai_count ^ weight

        if bi_mul
          bi_mul *= bi_count ^ weight
        else
          bi_mul = bi_count ^ weight

      ai_prob = a.total_count * ai_mul / ((a.total_count + default_a) * available_words_count)
      bi_prob = b.total_count * bi_mul / ((b.total_count + default_b) * available_words_count)

      ai_prob = 0 if ai_prob != ai_prob
      bi_prob = 0 if bi_prob != bi_prob

      ai_prob / (ai_prob + bi_prob)

    if prob != prob
      return nil, "Got nan when calculating prob"

    if prob == math.huge or prob == -math.huge
      return nil, "Got inf when calculating prob"

    tuples = {
      { a.name, prob }
      { b.name, 1 - prob }
    }

    table.sort tuples, (a, b) -> a[2] > b[2]
    tuples
