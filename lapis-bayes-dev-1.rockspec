package = "lapis-bayes"
version = "dev-1"

source = {
  url = "git://github.com/leafo/lapis-bayes.git"
}

description = {
  summary = "Naive Bayes classifier for use in Lua",
  license = "MIT",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
}

dependencies = {
  "lua == 5.1",
  "lapis"
}

build = {
  type = "builtin",
  modules = {
    ["lapis.bayes"] = "lapis/bayes.lua",
    ["lapis.bayes.migrations"] = "lapis/bayes/migrations.lua",
    ["lapis.bayes.model"] = "lapis/bayes/model.lua",
    ["lapis.bayes.models"] = "lapis/bayes/models.lua",
    ["lapis.bayes.models.categories"] = "lapis/bayes/models/categories.lua",
    ["lapis.bayes.models.word_classifications"] = "lapis/bayes/models/word_classifications.lua",
    ["lapis.bayes.schema"] = "lapis/bayes/schema.lua",
  }
}

