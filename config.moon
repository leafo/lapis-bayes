config = require "lapis.config"

config {"development", "test"}, ->
  postgres {
    database: "lapis_bayes"
  }

