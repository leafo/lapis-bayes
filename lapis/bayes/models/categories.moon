
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
    w = WordClassifications\find_or_create {
      category_id: @id
      :word
    }
    w\increment count
    @increment count


  increment_words: (counts) =>
    words = [{:word, :count} for word, count in pairs counts]
    import WordClassifications from require "lapis.bayes.models"

    WordClassifications\include_in words, "word", {
      flip: true
      local_key: "word"
      where: {
        category_id: @id
      }
    }

    for word in *words
      word.word_classification or= WordClassifications\create {
        word: word.word
        category_id: @id
      }

      word.word_classification\increment word.count

    words



