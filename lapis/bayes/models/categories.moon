
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

  -- NOTE: this was removed since it was tied to a specific tokenizer
  increment_text: (text, opts={}) =>
    error "This method has been removed, use increment_words instead"

  -- increment a single word by count
  increment_word: (word, count) =>
    import WordClassifications from require "lapis.bayes.models"
    w = WordClassifications\find_or_create {
      category_id: @id
      :word
    }
    w\_increment count
    @increment count

  -- issue a single query to increment all WordClassifications for this
  -- category with the list of words
  -- counts: table in the format {word = count, ... word1, word2, ...}
  increment_words: (counts) =>
    return nil, "missing counts" unless counts

    -- combine hash and array words into summed count
    merged_counts = {}
    for k,v in pairs counts
      word, count = if type(k) == "string"
        k, v
      else
        v, 1

      merged_counts[word] or= 0
      merged_counts[word] += count

    total_count = 0
    tuples = for word, count in pairs merged_counts
      total_count += count
      {@id, word, count}

    unless next tuples
      return total_count

    import WordClassifications from require "lapis.bayes.models"
    tbl = db.escape_identifier WordClassifications\table_name!

    db.query "
    INSERT INTO #{tbl} (category_id, word, count) #{encode_tuples tuples}
    ON CONFLICT (category_id, word) DO UPDATE SET count = #{tbl}.count + EXCLUDED.count
    "

    @increment total_count
    total_count

