DefaultTokenizer = require "lapis.bayes.tokenizers.postgres_text"

-- {
--   tokenize_text: function -- custom tokenize function
-- 
-- }
tokenize_text = (text, opts) ->
  if opts and opts.tokenize_text
    return opts.tokenize_text text, opts

  tokenizer = opts and opts.tokenizer or DefaultTokenizer
  tokenizer(opts)\tokenize_text text

{ :tokenize_text, :DefaultTokenizer }
