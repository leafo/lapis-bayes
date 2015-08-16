db = require "lapis.db"
schema = require "lapis.db.schema"

import add_column, create_index, drop_index, drop_column, create_table from schema

{
  :serial, :boolean, :varchar, :integer, :text, :foreign_key, :double, :time,
  :numeric, :enum
} = schema.types

import prefix_table from require "lapis.bayes.model"

{
  [1439610038]: =>
    create_table prefix_table("categories"), {
      {"id", serial}
      {"name", text}

      {"total_count", integer}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_table prefix_table("word_classifications"), {
      {"category_id", foreign_key}
      {"word", text}
      {"count", integer}

      "PRIMARY KEY (category_id, word)"
    }

}

