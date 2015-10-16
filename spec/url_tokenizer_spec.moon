
UrlDomainsTokenizer = require "lapis.bayes.tokenizers.url_domains"

describe "lapis.bayes.tokenizer.url_tokenizer", ->
  it "builds grammar", ->
    tokenizer = UrlDomainsTokenizer!
    p = tokenizer\build_grammar!
    p\match "https"

  describe "with grammar", ->
    local grammar

    before_each ->
      grammar = UrlDomainsTokenizer!\build_grammar!

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

    it "extracts tokens from string", ->
      assert.same {
        "leafo.net&"
        "google.com"
        "leafodad.com"
      }, tokenize_text "href='http://leafo.net&amp; ' http://google.com/p8sslord/da?what please help the good one www.leafodad.com yeah what the freak"

    it "ignore domains", ->
      tokens = UrlDomainsTokenizer({
        ignore_domains: {
          "leafo.net": true
          "*.google.com": true
        }
      })\tokenize_text [[
        http://leafo.net
        http://good.leafo.net
        http://google.com
        http://butt.google.com
        http://plus.good.google.com
      ]]

      assert.same {"good.leafo.net", "google.com"}, tokens
