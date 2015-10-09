
db = require "lapis.db"
import Model, encode_tuples from require "lapis.bayes.model"

class Categories extends Model
  @timestamp: true

  @find_or_create: (name) =>
    @find(:name) or @create(:name)

  increment: (amount) =>
    amount = assert tonumber(amount), "expecting number"
    @update {
      total_count: db.raw "total_count + #{amount}"
    }

  increment_text: (text, opts={}) =>
    import tokenize_text from require "lapis.bayes.tokenizer"

    words_by_counts = {}
    total_words = 0

    tokens = tokenize_text text, opts
    return 0 if #tokens == 0

    for word in *tokens
      words_by_counts[word] or= 0
      words_by_counts[word] += 1
      total_words += 1

    @increment_words words_by_counts
    total_words

  increment_word: (word, count) =>
    import WordClassifications from require "lapis.bayes.models"
    w = WordClassifications\find_or_create {
      category_id: @id
      :word
    }
    w\increment count
    @increment count

  increment_words: (counts) =>
    import WordClassifications from require "lapis.bayes.models"

    category_words = [{@id, word} for word in pairs counts]
    category_words = encode_tuples category_words

    tbl = db.escape_identifier WordClassifications\table_name!

    -- insert
    db.query "
      insert into #{tbl}
      (category_id, word)
      (
        select * from (#{category_words}) foo(category_id, word)
          where not exists(select 1 from #{tbl} as bar
            where bar.word = foo.word and bar.category_id = foo.category_id)
      )
    "

    -- increment
    total_count = 0
    counts =  for word, count in pairs counts
      total_count += count
      {@id, word, count}

    counts = encode_tuples counts

    db.query "
      update #{tbl}
      set count = #{tbl}.count + foo.count
      from (#{counts}) foo(category_id, word, count)
      where foo.category_id = #{tbl}.category_id and foo.word = #{tbl}.word
    "

    @increment total_count
    words

