
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

    total_count = 0
    tuples = for word, count in pairs counts
      total_count += count
      {@id, word, count}

    unless next tuples
      return total_count

    tbl = db.escape_identifier WordClassifications\table_name!

    res = db.query "
    insert into #{tbl} (category_id, word, count) #{encode_tuples tuples}
    on conflict (category_id, word) do update set count = #{tbl}.count + EXCLUDED.count
    "

    @increment total_count
    total_count

