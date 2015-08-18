
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

  increment_text: (text) =>
    import tokenize_text from require "lapis.bayes"

    words_by_counts = {}
    total_words = 0

    for word in *tokenize_text text
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



