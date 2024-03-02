import uniquify from require "lapis.util"

class BaseClassifier
  new: (@opts={}) =>
    if @@default_options
      @opts = setmetatable {k,v for k,v in pairs @opts}, __index: @@default_options

  classify: (...) =>
    probs, err = @text_probabilities ...
    error "not yet"

  -- categories: a lua array of categories names
  -- text: string of text to classify, or an array of tokens to classify
  text_probabilities: (category_names, text) =>
    categories, err = @find_categories category_names

    unless categories
      return nil, err

    words = if type(text) == "string"
      import tokenize_text from require "lapis.bayes.tokenizer"
      tokenize_text text, @opts
    else
      text

    unless words and next words
      return nil, "failed to generate tokens for text"

    available_words, err = @count_words categories, words

    unless available_words
      return nil, err

    available_words_set = {word, true for word in *available_words}
    count = 0
    for word in *words
      count +=1 if available_words_set[word]

    token_ratio = count / #words

    probs, err = @word_probabilities categories, available_words
    unless probs
      return nil, err

    -- put probs in hash table part of result
    for {c, p} in *probs
      probs[c] = p

    probs, token_ratio

  -- query the category objects by category name
  -- returns an array of category records in the same order as the input
  find_categories: (category_names) =>
    import Categories from require "lapis.bayes.models"
    db = Categories.db

    categories = Categories\select "where name in ?", db.list category_names
    by_name = {c.name, c for c in *categories}

    local missing

    result = for name in *category_names
      c = by_name[name]

      unless c
        missing or= {}
        table.insert missing, name
        continue

      c

    if missing and next missing
      return nil, "find_categories: missing categories (#{table.concat missing, ", "})"

    result

  -- reduce the set of available words by looking for polarizing words
  -- categories: array of category objects
  -- available_words: array of available words
  -- count: the max length of returned words array
  candidate_words: (categories, available_words, count) =>
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

  -- load the categories with the counts from the words text, return the list
  -- of words that appear in at least one category
  --
  -- categories: array of categories
  -- words: array of tokens
  count_words: (categories, words) =>
    db = require "lapis.db"
    import WordClassifications from require "lapis.bayes.models"

    categories_by_id = {c.id, c for c in *categories}

    words = uniquify words

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

    available_words

