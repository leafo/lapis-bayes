local DefaultTokenizer = require("lapis.bayes.tokenizers.postgres_text")
local tokenize_text
tokenize_text = function(text, opts)
  if opts and opts.tokenize_text then
    return opts.tokenize_text(text, opts)
  end
  local tokenizer = opts and opts.tokenizer or DefaultTokenizer
  return tokenizer(opts):tokenize_text(text)
end
return {
  tokenize_text = tokenize_text,
  DefaultTokenizer = DefaultTokenizer
}
