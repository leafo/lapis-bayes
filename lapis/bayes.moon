db = require "lapis.db"

tokenize_text = (text) ->
  res = unpack db.query "select to_tsvector('english', ?)", text
  vector = res.to_tsvector
  [t for t in vector\gmatch "'(.-)'"]

check_text = (text, classifications) ->


classify_text = (text, classification) ->

{:check_text, :classify_text, :tokenize_text}
