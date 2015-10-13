
UrlTokenizer = require "lapis.bayes.tokenizers.url_tokenizer"

describe "lapis.bayes.tokenizer.url_tokenizer", ->
  it "builds grammar", ->
    tokenizer = UrlTokenizer!
    p = tokenizer\build_grammer!
    p\match "https"



