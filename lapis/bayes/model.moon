
prefix = "lapis_bayes_"

{
  Model: require("lapis.db.model")\scoped_model prefix, "lapis.bayes.models"
  prefix_table: (name) =>
    "#{prefix}#{name}"
}
