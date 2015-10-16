DefaultClassifier = require "lapis.bayes.classifiers.default"

class NewClassifier extends DefaultClassifier
  text_probabilities: (categories, text) =>
    categories, available_words, words = @count_words categories, text

    unless categories
      return nil, available_words

    default_prob = @opts.default_prob or 0.1

    total_counts = {}
    for c in *categories
      for word, count in pairs c.word_counts
        total_counts[word] or= 0
        total_counts[word] += count

    require("moon").p total_counts

    for c in *categories
      tuples = for word in *available_words
        total_count = total_counts[word]
        cat_count = c.word_counts[word] or 0
        {word, cat_count/total_count}

      print "#{c.name}"
      table.sort tuples, (a,b) ->
        a[2] > b[2]

      import columnize from require "lapis.cmd.util"
      print columnize tuples

      print

      -- by_importance = for t in *tuples
      --   {math.abs t[2] - 0.5, t}

      -- table.sort by_importance, (a,b) ->
      --   a[1] > b[1]

      -- tuples = [i[2] for i in *by_importance]
      -- require("moon").p tuples
      -- error "not yet"
