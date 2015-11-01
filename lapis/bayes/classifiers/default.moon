-- implements naive bayes with assumed probability

class DefaultClassifier
  new: (@opts={}) =>

  confidence: (result) =>
    hit, miss = unpack result
    (hit[2] - miss[2]) / hit[2]

  candidate_tokens: (categories, available_words, count) =>
    return available_words if #available_words <= count

    assert #categories == 2, "can only do two categories"

    a,b = unpack categories
    -- calculate conflict words
    tuples = for word in *available_words
      a_count = a.word_counts and a.word_counts[word] or 0
      b_count = b.word_counts and b.word_counts[word] or 0

      {
        word
        math.random! / 100 + math.abs (a_count - b_count) / math.sqrt a_count + b_count
        a_count
        b_count
      }

    table.sort tuples, (a,b) ->
      a[2] > b[2]

    [t[1] for t in *tuples[,count]]

  count_words: (categories, text) =>
    db = require "lapis.db"
    import Categories, WordClassifications from require "lapis.bayes.models"

    num_categories = #categories

    categories_by_name = {c.name, c for c in *Categories\find_all categories, key: "name" }
    categories = [categories_by_name[name] for name in *categories when categories_by_name[name]]

    return nil, "missing categories" unless #categories == num_categories

    import tokenize_text from require "lapis.bayes.tokenizer"

    words = tokenize_text text, @opts
    return nil, "failed to generate tokens" unless words and next words

    categories_by_id = {c.id, c for c in *categories}

    wcs = WordClassifications\find_all words, {
      key: "word"
      where: {
        category_id: db.list [c.id for c in *categories]
      }
    }

    available_words = [word for word in pairs {wc.word, true for wc in *wcs}]

    if #available_words == 0
      return nil, "no words in text are classifyable"

    for wc in *wcs
      category = categories_by_id[wc.category_id]
      category.word_counts or= {}
      category.word_counts[wc.word] = wc.count

    categories, available_words, words

  text_probabilities: (...) =>
    categories, available_words, words = @count_words ...
    unless categories
      return nil, available_words

    assert #categories == 2, "only works with two categories"

    token_ratio = #available_words / #words

    a, b = unpack categories

    sum_counts = 0
    for c in *categories
      sum_counts += c.total_count

    available_words = @candidate_tokens categories, available_words, 40
    available_words_count = #available_words

    default_prob = (@opts.default_prob or 0.1) / sum_counts

    default_a = default_prob * a.total_count
    default_b = default_prob * b.total_count

    prob = if false -- @opts.log
      -- fast?
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
      -- slow?
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

    table.sort tuples, (a, b) ->
      a[2] > b[2]

    for {c, p} in *tuples
      tuples[c] = p

    tuples, token_ratio

