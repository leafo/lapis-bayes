-- implements a modified bayes that only calculates best option without any
-- probabilities
class BayesModClassifier extends require "lapis.bayes.classifiers.base"

  -- http://blog.datumbox.com/machine-learning-tutorial-the-naive-bayes-text-classifier/
  word_probabilities: (categories, available_words) =>
    sum_counts = 0
    for c in *categories
      sum_counts += c.total_count

    tuples = for cat in *categories
      prob = math.log cat.total_count / sum_counts
      for word in *available_words
        word_count = cat.word_counts and cat.word_counts[word] or 0
        prob += math.log (word_count + 1) / (cat.total_count + sum_counts)

      {cat.name, prob}

    table.sort tuples, (a,b) -> a[2] > b[2]
    tuples

