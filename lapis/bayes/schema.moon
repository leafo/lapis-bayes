run_migrations = ->
  m = require "lapis.db.migrations"
  m.run_migrations require("lapis.bayes.migrations"), "lapis_bayes"

{ :run_migrations }
