
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

class WordClassifications extends Model
  @primary_key: {"category_id", "word"}

  @relations: {
    {"category", belongs_to: "Categories"}
  }

  @find_or_create: (opts={}) =>
    @find(opts) or @create(opts)

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


