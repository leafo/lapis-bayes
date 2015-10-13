
UrlDomainsTokenizer = require "lapis.bayes.tokenizers.url_domains"

describe "lapis.bayes.tokenizer.url_tokenizer", ->
  it "builds grammar", ->
    tokenizer = UrlDomainsTokenizer!
    p = tokenizer\build_grammer!
    p\match "https"

  describe "with grammar", ->
    local grammar

    before_each ->
      grammar = UrlDomainsTokenizer!\build_grammer!

    it "detects some urls", ->
      assert.same {
        "http://leafo.net& "
        "http://google.com/p8sslord"
        "www.leafodad.com"
      }, grammar\match "href='http://leafo.net&amp; ' http://google.com/p8sslord please help the good one www.leafodad.com yeah what the freak"

  describe "with tonenizer", ->
    local tokenize_text
    before_each ->
      tokenize_text = UrlDomainsTokenizer!\tokenize_text

