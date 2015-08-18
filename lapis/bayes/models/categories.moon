
db = require "lapis.db"
import Model from require "lapis.bayes.model"

class Categories extends Model
  @timestamp: true

  @find_or_create: (name) =>
    @find(:name) or @create(:name)

  increment: (amount) =>
    amount = assert tonumber(amount), "expecting number"
    @update {
      total_count: db.raw "total_count + #{amount}"
    }

  increment_word: (word, count) =>
    import WordClassifications from require "lapis.bayes.models"
    w = WordClassifications\find_or_create @id, word
    w\increment count
    @increment count

