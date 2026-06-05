
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

    table.sort tuples, (a, b) -> a[2] < b[2]

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

  -- decrement existing words for this category, deleting any that reach zero
  -- counts: table in the format {word = count, ... word1, word2, ...}
  decrement_words: (counts) =>
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

    tuples = for word, count in pairs merged_counts
      {word, count}

    table.sort tuples, (a, b) -> a[1] < b[1]

    unless next tuples
      return 0

    import WordClassifications from require "lapis.bayes.models"
    tbl = db.escape_identifier WordClassifications\table_name!
    cat_tbl = db.escape_identifier @@table_name!
    cat_id = db.escape_literal @id

    -- decrement each matching word and subtract the total removed from the
    -- category count. if a word is over-decremented, the LEAST term clamps the
    -- removed amount to what the word actually had
    res = db.query "
    WITH input (word, amount) AS (#{encode_tuples tuples}),
    upd AS (
      UPDATE #{tbl} wc
      SET count = wc.count - input.amount
      FROM input
      WHERE wc.category_id = #{cat_id} AND wc.word = input.word
      RETURNING LEAST(wc.count + input.amount, input.amount) AS removed
    ),
    cat AS (
      UPDATE #{cat_tbl}
      SET total_count = total_count - (SELECT COALESCE(sum(removed), 0) FROM upd)
      WHERE id = #{cat_id}
      RETURNING 1
    )
    SELECT COALESCE(sum(removed), 0) AS total FROM upd
    "

    -- delete any words that reached zero
    words = table.concat [db.escape_literal t[1] for t in *tuples], ", "
    db.query "
    DELETE FROM #{tbl}
    WHERE category_id = #{cat_id} AND count <= 0 AND word IN (#{words})
    "

    total = res[1] and tonumber(res[1].total) or 0
    @total_count -= total
    total
