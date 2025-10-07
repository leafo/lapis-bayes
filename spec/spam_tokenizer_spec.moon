SpamTokenizer = require "lapis.bayes.tokenizers.spam"

it_tokenizes = (label, input, expected_tokens, opts=nil) ->
  it "tokenizes #{label}", ->
    tokenizer = SpamTokenizer opts
    tokens = tokenizer\tokenize_text input
    assert.same expected_tokens, tokens, "Tokens for #{input\sub 1, 80}"

describe "lapis.bayes.tokenizers.spam", ->
  it "tokenizes spam-like text", ->
    tokenizer = SpamTokenizer!

    tokens = tokenizer\tokenize_text [[Cheap Rolex Watches for $199.99!!! Visit http://Dealz.EXAMPLE.com now or email SALES@EXAMPLE.com for 50% OFF!!!]]

    assert.same {
      "cheap"
      "rolex"
      "watches"
      "for"
      "visit"
      "now"
      "or"
      "email"
      "off"
      "currency:$"
      "number:199.99"
      "number_bucket:long"
      "punct:!3"
      "url:dealz.example.com"
      "domain:dealz.example.com"
      "host_label:dealz"
      "host_label:example"
      "host_label:com"
      "root_domain:example.com"
      "tld:com"
      "email:sales@example.com"
      "email_user:sales"
      "domain:example.com"
      "percent:50"
      "number:50"
      "number_bucket:short"
      "caps:off"
    }, tokens

  it_tokenizes "with bigrams", "Buy Cheap meds now", {
    "buy"
    "cheap"
    "meds"
    "now"
    "buy cheap"
    "cheap meds"
    "meds now"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "with default dedupe", "spam spam SPAM", {
    "spam"
    "caps:spam"
  }

  it_tokenizes "wit  duplicates when dedupe disabled", "spam spam", {
    "spam"
    "spam"
  }, {
    dedupe: false
  }

  it_tokenizes "limits tokens with sample_at_most", "alpha beta gamma delta", {
    "alpha"
    "beta"
  }, {
    sample_at_most: 2, dedupe: false
  }

  it_tokenizes "single word with bigrams enabled", "alpha", {
    "alpha"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "limits bigrams with sample_at_most", "alpha beta gamma", {
    "alpha"
    "beta"
    "alpha beta"
    "beta gamma"
  }, {
    sample_at_most: 2, bigram_tokens: true, dedupe: false
  }

  it_tokenizes "chinese with url", "点击这里获取 50% 折扣!!! http://spam.cn/deal", {
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
  }

  it_tokenizes "html content", [[
    <div><p>Limited <strong>Offer</strong> <a href="http://example.com">Click</a> now!</p></div>
  ]], {
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
  }

  it_tokenizes "ignored words", "Deal DEAL!!! Limited deal now NOW 10% NOW!!!", {
    "limited"
    "now"
    "punct:!3"
    "caps:now"
    "percent:10"
    "number:10"
    "number_bucket:short"
  }, {
    ignore_words: {
      deal: true
    }
  }

  it_tokenizes "Esperanto sentence", "Eble ĉiu ĵaŭdo ŝanĝiĝos al pli agrabla tago", {
    "eble"
    "ciu"
    "jaudo"
    "sangigos"
    "al"
    "pli"
    "agrabla"
    "tago"
  }

  it_tokenizes "Spanish sentence", "el juego esta disponible en español?", {
    "el"
    "juego"
    "esta"
    "disponible"
    "en"
    "espanol"
  }

  it_tokenizes "capitalized sentence", "MY GAME NOT WORKING. ERROR: LICENSE NOT FOUND. PLEASE HELP!", {
    "my"
    "game"
    "not"
    "working"
    "error"
    "license"
    "found"
    "please"
    "help"
    "caps:my"
    "caps:game"
    "caps:not"
    "caps:working"
    "caps:error"
    "caps:license"
    "caps:found"
    "caps:please"
    "caps:help"
  }

  describe "bigram dedupe", ->
    it_tokenizes "with bigrams with dupes", "spam spam spam", {
      "spam"
      "spam"
      "spam"
      "spam spam"
      "spam spam"
    }, {
      bigram_tokens: true, dedupe: false
    }


    it_tokenizes "with bigrams without dupes", "spam spam spam", {
      "spam"
      "spam spam"
    }, {
      bigram_tokens: true, dedupe: true
    }

  describe "with stemming", ->
    it_tokenizes "with stems", "running dogs created connections", {
      "run"
      "dog"
      "creat"
      "connect"
    }, {
      stem_words: true
    }

    it_tokenizes "with stems & caps", "RUNNING Dogs", {
      "run"
      "dog"
      "caps:run"
    }, {
      stem_words: true
    }

    it_tokenizes "with stems and bigrams", "running dogs", {
      "run"
      "dog"
      "run dog"
    }, {
      stem_words: true, bigram_tokens: true
    }

    it_tokenizes "with deduped stems", "running runs run", {
      "run"
    }, {
      stem_words: true
    }

    it_tokenizes "with bigrams and matching stems", "running runs run", {
      "run"
      "run run"
    }, {
      stem_words: true, bigram_tokens: true
    }

    it_tokenizes "with bigrams not deduped", "running runs run", {
      "run"
      "run"
      "run"
      "run run"
      "run run"
    }, {
      stem_words: true, bigram_tokens: true, dedupe: false
    }

    it_tokenizes "stemming combined with tagged tokens", "running at http://examples.com with $199.99 for sales@example.com", {
      "run"
      "at"
      "with"
      "for"
      "url:examples.com"
      "domain:examples.com"
      "host_label:examples"
      "host_label:com"
      "root_domain:examples.com"
      "tld:com"
      "currency:$"
      "number:199.99"
      "number_bucket:long"
      "email:sales@example.com"
      "email_user:sales"
      "domain:example.com"
      "host_label:example"
      "root_domain:example.com"
    }, {
      stem_words: true
    }




