local prefix = "lapis_bayes_"
local Model
Model = require("lapis.db.model").Model
return {
  Model = Model:scoped_model(prefix, "lapis.bayes.models"),
  prefix_table = function(name)
    return tostring(prefix) .. tostring(name)
  end
}
