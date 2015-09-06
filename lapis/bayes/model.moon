
prefix = "lapis_bayes_"

import Model from require "lapis.db.model"

db = require "lapis.db"

-- all tuples should be same size
encode_tuples = (tuples) ->
  buffer = { "VALUES" }

  {insert: i} = table
  n_tuples = #tuples
  for t_idx=1,n_tuples
    tuple = tuples[t_idx]
    i buffer, " ("
    k = #tuple
    for idx=1,k
      i buffer, db.escape_literal tuple[idx]
      unless idx == k
        i buffer, ", "

    if t_idx == n_tuples
      i buffer, ")"
    else
      i buffer, "), "

  table.concat buffer

{
  Model: Model\scoped_model prefix, "lapis.bayes.models"
  prefix_table: (name) -> "#{prefix}#{name}"
  :encode_tuples
}
