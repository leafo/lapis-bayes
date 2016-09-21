
db = require "lapis.db"
import Model from require "lapis.bayes.model"

delete_and_return = =>
  res = db.query "
    delete from #{db.escape_identifier @@table_name!}
    where #{db.encode_clause @_primary_cond!}
    returning *
  "

  if res.affected_rows and res.affected_rows > 0
    @@load unpack res
  else
    false

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE lapis_bayes_word_classifications (
--   category_id integer NOT NULL,
--   word text NOT NULL,
--   count integer DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE ONLY lapis_bayes_word_classifications
--   ADD CONSTRAINT lapis_bayes_word_classifications_pkey PRIMARY KEY (category_id, word);
--
class WordClassifications extends Model
  @primary_key: {"category_id", "word"}

  @relations: {
    {"category", belongs_to: "Categories"}
  }

  @find_or_create: (opts={}) =>
    @find(opts) or @create(opts)

  @purge_word: (word, categories) =>
    import Categories from require "lapis.bayes.models"

    categories = { categories } unless type(categories) == "table"
    original_count = #categories
    assert original_count > 0, "missing categories"
    categories = Categories\find_all categories, key: "name"
    assert #categories == original_count, "failed to find all categories specified"

    wcs = @select "where word = ? and category_id in ?",
      word, db.list [c.id for c in *categories]

    count = 0
    for wc in *wcs
      if wc\delete!
        count += 1

    count > 0, count

  delete: =>
    if deleted = delete_and_return @
      import Categories from require "lapis.bayes.models"
      db.update Categories\table_name!, {
        total_count: db.raw db.interpolate_query " total_count - ?", deleted.count
      }, {
        id: @category_id
      }
      true


  increment: (amount) =>
    amount = assert tonumber(amount), "expecting number"
    @update {
      count: db.raw "count + #{amount}"
    }


