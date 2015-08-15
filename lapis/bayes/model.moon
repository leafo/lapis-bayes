
prefix = "lapis_bayes_"

import Model from require "lapis.db.model"

{
  Model: Model\scoped_model prefix, "lapis.bayes.models"
  prefix_table: (name) -> "#{prefix}#{name}"
}
