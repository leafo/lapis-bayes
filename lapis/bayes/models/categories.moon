
db = require "lapis.db"
import Model from require "lapis.bayes.model"

class Categories extends Model
  @timestamps: true

  @find_or_create: (name) =>
    @create name: name

  increment: (amount) =>
    amount = assert tonumber(amount), "expecting number"
    @update {
      count: db.raw "count + #{amount}"
    }

