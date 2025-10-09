-- Multiclass naive Bayes classifier with Laplace-style smoothing
class BayesMultiClassifier extends require "lapis.bayes.classifiers.base"
  @default_options: {
    max_words: 40
    default_prob: 0.1
  }

  candidate_words: (categories, available_words, count) =>
    return available_words unless count and count < #available_words

    tuples = for word in *available_words
      totals = 0
      counts = {}
      for category in *categories
        word_counts = category.word_counts
        c = word_counts and word_counts[word] or 0
        table.insert counts, c
        totals += c

      score = if totals == 0
        0
      else
        mean = totals / #counts
        variance = 0
        for c in *counts
          variance += (c - mean) ^ 2
        variance / #counts

      score += math.random! / 1000

      { word, score }

    table.sort tuples, (a, b) -> a[2] > b[2]
    [t[1] for t in *tuples[,count]]

  word_probabilities: (categories, available_words) =>
    return nil, "at least two categories required" unless #categories >= 2

    available_words = @candidate_words categories, available_words, @opts.max_words
    vocab_size = #available_words

    return nil, "no words to score" unless vocab_size > 0

    smoothing = if @opts.default_prob and @opts.default_prob > 0
      @opts.default_prob
    else
      1e-6

    sum_counts = 0
    for category in *categories
      sum_counts += category.total_count or 0

    prior_smoothing = smoothing * #categories

    local max_log
    log_scores = for category in *categories
      cat_total = math.max (category.total_count or 0), 0
      prior = (cat_total + smoothing) / (sum_counts + prior_smoothing)
      log_score = math.log prior

      denominator = cat_total + (smoothing * vocab_size)
      denominator = smoothing * vocab_size if denominator <= 0

      for word in *available_words
        word_count = category.word_counts and category.word_counts[word] or 0
        log_score += math.log ((word_count + smoothing) / denominator)

      max_log = if max_log
        math.max max_log, log_score
      else
        log_score

      { category, log_score }

    weights = {}
    total_weight = 0
    for {category, log_score} in *log_scores
      weight = math.exp (log_score - max_log)
      total_weight += weight
      table.insert weights, { category.name, weight }

    return nil, "unable to normalise probabilities" unless total_weight > 0

    for tuple in *weights
      tuple[2] /= total_weight

    table.sort weights, (a, b) -> a[2] > b[2]
    weights
