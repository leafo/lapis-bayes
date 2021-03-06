-- implements naive bayes with assumed probability
class BayesClassifier extends require "lapis.bayes.classifiers.base"
  @default_options: {
    max_words: 40
    default_prob: 0.1
    log: false
  }

  word_probabilities: (categories, available_words) =>
    return nil, "only two categories supported at once" unless #categories == 2

    a, b = unpack categories

    sum_counts = 0
    for c in *categories
      sum_counts += c.total_count

    available_words = @candidate_words categories, available_words, @opts.max_words
    available_words_count = #available_words

    default_prob = @opts.default_prob / sum_counts

    default_a = default_prob * a.total_count
    default_b = default_prob * b.total_count

    prob = if @opts.log
      -- TODO: test if the log approach has any advantages
      ai_log_sum = 0
      bi_log_sum = 0

      for word in *available_words
        ai_log_sum += math.log (a.word_counts and a.word_counts[word] or 0) + default_a
        bi_log_sum += math.log (b.word_counts and b.word_counts[word] or 0) + default_b

      ai_log_sum -= math.log (default_a + a.total_count) * available_words_count
      bi_log_sum -= math.log (default_b + b.total_count) * available_words_count

      ai_log_sum += math.log a.total_count
      bi_log_sum += math.log b.total_count

      ai_prob = math.exp ai_log_sum
      bi_prob = math.exp bi_log_sum

      ai_prob / (ai_prob + bi_prob)
    else
      local ai_mul, bi_mul

      for word in *available_words
        ai_count = (a.word_counts and a.word_counts[word] or 0) + default_a
        bi_count = (b.word_counts and b.word_counts[word] or 0) + default_b

        if ai_mul
          ai_mul *= ai_count
        else
          ai_mul = ai_count

        if bi_mul
          bi_mul *= bi_count
        else
          bi_mul = bi_count

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

