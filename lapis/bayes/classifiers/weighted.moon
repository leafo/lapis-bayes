class WeightedCassifier extends require "lapis.bayes.classifiers.base"
  word_probabilities: (categories, available_words) =>
    return nil, "only two categories supported at once" unless #categories == 2

    a, b = unpack categories

    expected = a.total_count / (a.total_count + b.total_count)

    sum = 0
    tuples = for word in *available_words
      a_count = a.word_counts[word] or 0
      b_count = b.word_counts[word] or 0

      p = a_count / (a_count + b_count)

      diff = math.abs (p - expected) / (p + expected)
      sum += diff
      {p, diff}

    -- now average tuples with weights
    tp = 0
    for {p, diff} in *tuples
      tp += p * (diff/sum)

    out = {
      {a.name, tp}
      {b.name, 1 - tp}
    }

    table.sort out, (a, b) -> a[2] > b[2]
    out
