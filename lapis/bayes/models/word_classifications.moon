
db = require "lapis.db"
import Model from require "lapis.bayes.model"

class WordClassifications extends Model
  @primary_key: {"category_id", "word"}

  @find_or_create: (category_id, word) =>
    opts = { :category_id, :word }
    @find(opts) or @create(opts)

  increment: (amount) =>
    amount = assert tonumber(amount), "expecting number"
    @update {
      count: db.raw "count + #{amount}"
    }


