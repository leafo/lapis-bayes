SpamTokenizer = require "lapis.bayes.tokenizers.spam"

describe "lapis.bayes.tokenizers.spam", ->
  it "tokenizes spam-like text", ->
    tokenizer = SpamTokenizer!

    tokens = tokenizer\tokenize_text [[Cheap Rolex Watches for $199.99!!! Visit http://Dealz.EXAMPLE.com now or email SALES@EXAMPLE.com for 50% OFF!!!]]

    assert.same {
      "cheap"
      "rolex"
      "watches"
      "for"
      "currency:$"
      "number:199.99"
      "number_bucket:long"
      "punct:!3"
      "visit"
      "url:dealz.example.com"
      "domain:dealz.example.com"
      "host_label:dealz"
      "host_label:example"
      "host_label:com"
      "root_domain:example.com"
      "tld:com"
      "now"
      "or"
      "email"
      "email:sales@example.com"
      "email_user:sales"
      "domain:example.com"
      "host_label:example"
      "host_label:com"
      "root_domain:example.com"
      "tld:com"
      "for"
      "percent:50"
      "number:50"
      "number_bucket:short"
      "off"
      "caps:off"
      "punct:!3"
    }, tokens

  it "adds bigrams when enabled", ->
    tokenizer = SpamTokenizer { bigram_tokens: true }

    tokens = tokenizer\tokenize_text "Buy Cheap meds now"

    assert.same {
      "buy"
      "cheap"
      "meds"
      "now"
      "buy cheap"
      "cheap meds"
      "meds now"
    }, tokens

  it "strips html content", ->
    tokenizer = SpamTokenizer!

    tokens = tokenizer\tokenize_text [[<div><p>Limited <strong>Offer</strong> <a href="http://example.com">Click</a> now!</p></div>]]

    assert.same {
      "limited"
      "offer"
      "click"
      "now"
      "url:example.com"
      "domain:example.com"
      "host_label:example"
      "host_label:com"
      "root_domain:example.com"
      "tld:com"
    }, tokens

  it "supports dedupe and ignored words", ->
    tokenizer = SpamTokenizer {
      dedupe: true
      ignore_words: {
        deal: true
      }
    }

    tokens = tokenizer\tokenize_text "Deal DEAL!!! Limited deal now NOW 10% NOW!!!"

    assert.same {
      "punct:!3"
      "limited"
      "now"
      "caps:now"
      "percent:10"
      "number:10"
      "number_bucket:short"
    }, tokens
