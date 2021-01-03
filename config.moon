config = require "lapis.config"

config {"development", "test"}, ->
  logging false -- hide query logs

  postgres {
    database: "lapis_bayes"

    host: os.getenv "PGHOST"
    user: os.getenv "PGUSER"
    password: os.getenv "PGPASSWORD"
  }

