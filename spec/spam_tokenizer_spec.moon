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
      "percent:50"
      "number:50"
      "number_bucket:short"
      "off"
      "caps:off"
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

  it "dedupes tokens by default", ->
    tokenizer = SpamTokenizer!

    tokens = tokenizer\tokenize_text "spam spam SPAM"

    assert.same {
      "spam"
      "caps:spam"
    }, tokens

  it "allows duplicates when dedupe disabled", ->
    tokenizer = SpamTokenizer { dedupe: false }

    tokens = tokenizer\tokenize_text "spam spam"

    assert.same {
      "spam"
      "spam"
    }, tokens

  it "limits tokens with sample_at_most", ->
    tokenizer = SpamTokenizer { sample_at_most: 2, dedupe: false }

    tokens = tokenizer\tokenize_text "alpha beta gamma delta"

    assert.same {
      "alpha"
      "beta"
    }, tokens

  it "limits bigrams with sample_at_most", ->
    tokenizer = SpamTokenizer { sample_at_most: 2, bigram_tokens: true, dedupe: false }

    tokens = tokenizer\tokenize_text "alpha beta gamma"

    assert.same {
      "alpha"
      "beta"
      "alpha beta"
    }, tokens

  it "handles Chinese spam mix", ->
    tokenizer = SpamTokenizer!

    tokens = tokenizer\tokenize_text "点击这里获取 50% 折扣!!! http://spam.cn/deal"

    assert.same {
      "percent:50"
      "number:50"
      "number_bucket:short"
      "punct:!3"
      "url:spam.cn"
      "domain:spam.cn"
      "host_label:spam"
      "host_label:cn"
      "root_domain:spam.cn"
      "tld:cn"
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

  it "supports dedupe with ignored words", ->
    tokenizer = SpamTokenizer {
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
