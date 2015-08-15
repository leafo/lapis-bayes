
import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

db = require "lapis.db"

import Categories, WordClassifications from require "moonscrape.models"

describe "lapis.bayes", ->
  use_test_env!

  it "classifies text", ->


