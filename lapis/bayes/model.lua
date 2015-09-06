local prefix = "lapis_bayes_"
local Model
Model = require("lapis.db.model").Model
local db = require("lapis.db")
local encode_tuples
encode_tuples = function(tuples)
  local buffer = {
    "VALUES"
  }
  local i
  i = table.insert
  local n_tuples = #tuples
  for t_idx = 1, n_tuples do
    local tuple = tuples[t_idx]
    i(buffer, " (")
    local k = #tuple
    for idx = 1, k do
      i(buffer, db.escape_literal(tuple[idx]))
      if not (idx == k) then
        i(buffer, ", ")
      end
    end
    if t_idx == n_tuples then
      i(buffer, ")")
    else
      i(buffer, "), ")
    end
  end
  return table.concat(buffer)
end
return {
  Model = Model:scoped_model(prefix, "lapis.bayes.models"),
  prefix_table = function(name)
    return tostring(prefix) .. tostring(name)
  end,
  encode_tuples = encode_tuples
}
