
db = require "lapis.db"
import Model, encode_tuples from require "lapis.bayes.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE lapis_bayes_categories (
--   id integer NOT NULL,
--   name text NOT NULL,
--   total_count integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY lapis_bayes_categories
--   ADD CONSTRAINT lapis_bayes_categories_pkey PRIMARY KEY (id);
--
class Categories extends Model
  @timestamp: true

  @relations: {
    {"word_classifications", has_many: "WordClassifications"}
  }

  @find_or_create: (name) =>
    @find(:name) or @create(:name)

  delete: =>
    if super!
      import WordClassifications from require "lapis.bayes.models"
      db.delete WordClassifications\table_name!, {
        category_id: @id
      }

  increment: (amount) =>
    amount = assert tonumber(amount), "expecting number"
    @update {
      total_count: db.raw "total_count + #{amount}"
    }

  increment_text: (text, opts={}) =>
    words_by_counts = {}
    total_words = 0

    tokens = switch type(text)
      when "string"
        import tokenize_text from require "lapis.bayes.tokenizer"
        tokenize_text text, opts
      when "table"
        text -- array of tokens
      else
        error "unknown type for text: #{type text}"

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
    w\_increment count
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
    total_count

