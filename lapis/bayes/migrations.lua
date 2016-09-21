local schema = require("lapis.db.schema")
local add_column, create_index, drop_index, drop_column, create_table
add_column, create_index, drop_index, drop_column, create_table = schema.add_column, schema.create_index, schema.drop_index, schema.drop_column, schema.create_table
local serial, boolean, varchar, integer, text, foreign_key, double, time, numeric, enum
do
  local _obj_0 = schema.types
  serial, boolean, varchar, integer, text, foreign_key, double, time, numeric, enum = _obj_0.serial, _obj_0.boolean, _obj_0.varchar, _obj_0.integer, _obj_0.text, _obj_0.foreign_key, _obj_0.double, _obj_0.time, _obj_0.numeric, _obj_0.enum
end
local prefix_table
prefix_table = require("lapis.bayes.model").prefix_table
return {
  [1439610038] = function(self)
    create_table(prefix_table("categories"), {
      {
        "id",
        serial
      },
      {
        "name",
        text
      },
      {
        "total_count",
        integer
      },
      {
        "created_at",
        time
      },
      {
        "updated_at",
        time
      },
      "PRIMARY KEY (id)"
    })
    return create_table(prefix_table("word_classifications"), {
      {
        "category_id",
        foreign_key
      },
      {
        "word",
        text
      },
      {
        "count",
        integer
      },
      "PRIMARY KEY (category_id, word)"
    })
  end,
  [1474434614] = function(self)
    return create_index(prefix_table("categories"), "name")
  end
}
