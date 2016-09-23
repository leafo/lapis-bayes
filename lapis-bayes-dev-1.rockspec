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
    ["lapis.bayes.classifiers.base"] = "lapis/bayes/classifiers/base.lua",
    ["lapis.bayes.classifiers.bayes"] = "lapis/bayes/classifiers/bayes.lua",
    ["lapis.bayes.classifiers.bayes_mod"] = "lapis/bayes/classifiers/bayes_mod.lua",
    ["lapis.bayes.classifiers.default"] = "lapis/bayes/classifiers/default.lua",
    ["lapis.bayes.classifiers.fisher"] = "lapis/bayes/classifiers/fisher.lua",
    ["lapis.bayes.classifiers.test"] = "lapis/bayes/classifiers/test.lua",
    ["lapis.bayes.classifiers.weighted"] = "lapis/bayes/classifiers/weighted.lua",
    ["lapis.bayes.migrations"] = "lapis/bayes/migrations.lua",
    ["lapis.bayes.model"] = "lapis/bayes/model.lua",
    ["lapis.bayes.models"] = "lapis/bayes/models.lua",
    ["lapis.bayes.models.categories"] = "lapis/bayes/models/categories.lua",
    ["lapis.bayes.models.word_classifications"] = "lapis/bayes/models/word_classifications.lua",
    ["lapis.bayes.schema"] = "lapis/bayes/schema.lua",
    ["lapis.bayes.tokenizer"] = "lapis/bayes/tokenizer.lua",
    ["lapis.bayes.tokenizers.postgres_text"] = "lapis/bayes/tokenizers/postgres_text.lua",
    ["lapis.bayes.tokenizers.url_domains"] = "lapis/bayes/tokenizers/url_domains.lua",
  }
}

