import unescape from require "lapis.util"
import strip_zero_width_string from require "lapis.bayes.text.utf8"

-- strip out 0 width characters, return nil if remaining text is empty
sanitize_token = (token) ->
  return unless token
  token = strip_zero_width_string token
  return if token == ""
  token

-- sanitize the list of tokens by stripping 0 width chars, and removing empty tokens
sanitize_tokens = (tokens) ->
  return {} unless tokens
  return for token in *tokens
    token = sanitize_token token
    continue unless token
    token

normalize_url_text = (text) ->
  return text unless text
  strip_zero_width_string(unescape text) or text

{
  :normalize_url_text
  :sanitize_token
  :sanitize_tokens
}
