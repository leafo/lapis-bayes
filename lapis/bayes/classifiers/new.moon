DefaultClassifier = require "lapis.bayes.classifiers.default"

average = (nums) ->
  sum = 0
  for n in *nums
    sum += n

  return sum / #nums

weighted_avg = (tuples) ->
  num_tuples = #tuples
  sum = 0
  sum_weight = 0

  for {num, weight} in *tuples
    sum += num
    sum_weight += weight

  avg_weight = sum_weight/num_tuples

  avg = 0
  for {num, weight} in *tuples
    avg += (num/num_tuples) * (weight/avg_weight)

  avg

class NewClassifier extends DefaultClassifier
  text_probabilities: (categories, text) =>
    categories, available_words, words = @count_words categories, text

    unless categories
      return nil, available_words

    total_counts = {}
    for c in *categories
      continue unless c.word_counts
      for word, count in pairs c.word_counts
        total_counts[word] or= 0
        total_counts[word] += count

    probs = for c in *categories
      tuples = for word in *available_words
        total_count = total_counts[word]
        cat_count = c.word_counts and c.word_counts[word] or 0
        {cat_count/total_count, total_count}

      {c.name, weighted_avg tuples}

    table.sort probs, (a,b) ->
      a[2] > b[2]

    -- also make probs available in hash
    for {c, p} in *probs
      probs[c] = p

    probs, #available_words / #words


