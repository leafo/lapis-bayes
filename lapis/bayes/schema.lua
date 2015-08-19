local run_migrations
run_migrations = function()
  local m = require("lapis.db.migrations")
  return m.run_migrations(require("lapis.bayes.migrations"), "lapis_bayes")
end
return {
  run_migrations = run_migrations
}
