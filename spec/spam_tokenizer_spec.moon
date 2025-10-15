SpamTokenizer = require "lapis.bayes.tokenizers.spam"

it_tokenizes = (label, input, expected_tokens, opts=nil) ->
  it "tokenizes #{label}", ->
    tokenizer = SpamTokenizer opts
    tokens = tokenizer\tokenize_text input
    assert.same expected_tokens, tokens, "Tokens for #{input\sub 1, 80}"

describe "lapis.bayes.tokenizers.spam", ->
  it_tokenizes "spam-like text", "Cheap Rolex Watches for $199.99!!! Visit http://Dealz.EXAMPLE.com now or email SALES@EXAMPLE.com for 50% OFF!!!", {
    "cheap"
    "rolex"
    "watches"
    "for"
    "currency:$"
    "199.99"
    "punct:!3"
    "visit"
    "domain:dealz.example.com"
    "domain:.example.com"
    "domain:.com"
    "now"
    "or"
    "email"
    "email:sales@example.com"
    "email_user:sales"
    "domain:example.com"
    "50%"
    "off"
    "caps:off"
  }

  it_tokenizes "with bigrams", "Buy Cheap meds now", {
    "buy"
    "cheap"
    "buy cheap"
    "meds"
    "cheap meds"
    "now"
    "meds now"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "bigrams with numbers", "Only 50% off today", {
    "only"
    "50%"
    "only 50%"
    "off"
    "50% off"
    "today"
    "off today"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "spam-like text with bigrams", "Cheap Rolex Watches for $199.99!!! Visit http://Dealz.EXAMPLE.com now or email SALES@EXAMPLE.com for 50% OFF!!!", {
    "cheap"
    "rolex"
    "cheap rolex"
    "watches"
    "rolex watches"
    "for"
    "watches for"
    "currency:$"
    "199.99"
    "for 199.99"
    "punct:!3"
    "visit"
    "domain:dealz.example.com"
    "domain:.example.com"
    "domain:.com"
    "now"
    "or"
    "now or"
    "email"
    "or email"
    "email:sales@example.com"
    "email_user:sales"
    "domain:example.com"
    "50%"
    "for 50%"
    "off"
    "50% off"
    "caps:off"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "with default dedupe", "spam spam SPAM", {
    "spam"
    "caps:spam"
  }

  it_tokenizes "with duplicates when dedupe disabled", "spam spam", {
    "spam"
    "spam"
  }, {
    dedupe: false
  }

  it_tokenizes "limits tokens with sample_at_most", "alpha beta gamma delta", {
    "alpha"
    "beta"
  }, {
    sample_at_most: 2, dedupe: false, dither: false
  }

  it_tokenizes "single word with bigrams enabled", "alpha", {
    "alpha"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "bigams with punctuation", "one. two. three!!!! four. five", {
    "one"
    "two"
    "one two"
    "three"
    "two three"
    "punct:!4"
    "four"
    "five"
    "four five"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "limits bigrams with sample_at_most", "alpha beta gamma", {
    "alpha"
    "beta"
    "alpha beta"
  }, {
    sample_at_most: 3, bigram_tokens: true, dedupe: false, dither: false
  }

  it_tokenizes "chinese with url", "点击这里获取 50% 折扣!!! http://spam.cn/deal", {
    "点击这里获取"
    "50%"
    "折扣"
    "punct:!3"
    "deal"
    "domain:spam.cn"
    "domain:.cn"
  }

  it_tokenizes "chinese with url and split_cjk", "点击这里获取 50% 折扣!!! http://spam.cn/deal", {
    "点"
    "击"
    "这"
    "里"
    "获"
    "取"
    "50%"
    "折"
    "扣"
    "punct:!3"
    "deal"
    "domain:spam.cn"
    "domain:.cn"
  }, {
    split_cjk: true
  }

  it_tokenizes "with commas #ddd", "hello,world，what,heck", {
    "hello"
    "world"
    "what"
    "heck"
  }

  it_tokenizes "chinese game text", "喜欢的游戏有空洞骑士，死亡细胞，饥荒，星露谷物语等等", {
    "喜欢的游戏有空洞骑士"
    "死亡细胞"
    "饥荒"
    "星露谷物语等等"
  }

  it_tokenizes "chinese game text with split_cjk", "喜欢的游戏有空洞骑士，死亡细胞，饥荒，星露谷物语等等", {
    "喜"
    "欢"
    "的"
    "游"
    "戏"
    "有"
    "空"
    "洞"
    "骑"
    "士"
    "死"
    "亡"
    "细"
    "胞"
    "饥"
    "荒"
    "星"
    "露"
    "谷"
    "物"
    "语"
    "等"
  }, {
    split_cjk: true
  }

  it_tokenizes "html content", [[
    <div><p>Limited <strong>Offer</strong> <a href="http://example.com">Click</a> now!</p></div>
  ]], {
    "domain:example.com"
    "domain:.com"
    "limited"
    "offer"
    "click"
    "now"
  }

  it_tokenizes "mixed links", [[
    <ul><li><a href="https://love2d.org/">https://love2d.org/</a></li><li><a href="http://moonscript.org/">http://moonscript.org/</a></li><li><a href="https://github.com/leafo/lovekit">LoveKit</a></li></ul>
  ]], {
    "domain:github.com"
    "domain:.com"
    "domain:love2d.org"
    "domain:.org"
    "domain:moonscript.org"
    "lovekit"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "html with nbsp entity", [[<a href="https://example.com/weed-gummies/">&nbsp;Green Street Origins CBD Gummies Canada</a>]], {
    "domain:example.com"
    "domain:.com"
    "green"
    "street"
    "origins"
    "cbd"
    "caps:cbd"
    "gummies"
    "canada"
  }

  it_tokenizes "html strong with link", [[<strong><a href="https://howdyscbd.com/order-green-street-origins-cbd-gummies-ca/">https://howdyscbd.com/order-green-street-origins-cbd-gummies-ca/</a></strong>]], {
    "order"
    "green"
    "street"
    "origins"
    "cbd"
    "gummies"
    "ca"
    "domain:howdyscbd.com"
    "domain:.com"
  }

  it_tokenizes "url with path segments", "Visit https://spamblog.biz/super-sale-today/index.html now", {
    "visit"
    "super"
    "sale"
    "today"
    "index"
    "html"
    "domain:spamblog.biz"
    "domain:.biz"
    "now"
  }

  it_tokenizes "url with path segments", "Visit https://spamblog.biz/super-sale-today/index.html now", {
    "visit"
    "super"
    "visit super"
    "sale"
    "super sale"
    "today"
    "sale today"
    "index"
    "today index"
    "html"
    "index html" -- questionable if this should be included
    "domain:spamblog.biz"
    "domain:.biz"
    "now"
  }, {
    bigram_tokens: true
  }


  it_tokenizes "prioritizes domain tokens when enabled", "Visit https://spamblog.biz/super-sale-today/index.html now", {
    "domain:spamblog.biz"
    "domain:.biz"
    "visit"
    "super"
    "sale"
    "today"
    "index"
    "html"
    "now"
  }, {
    domain_tokens_first: true
  }

  it_tokenizes "ignores token that is part of domain ", "Visit https://spamblog.biz/super-sale-today/index.html now", {
    "visit"
    "super"
    "sale"
    "today"
    "html"
    "domain:spamblog.biz"
    "now"
  }, {
    ignore_tokens: {
      "index": true
      "domain:.biz": true
    }
  }

  it_tokenizes "url with query and fragment", "Check this link https://news.example.com/summer/sale?promo=Summer-2024&utm_medium=email#Limited-Offer now", {
    "check"
    "this"
    "link"
    "summer"
    "sale"
    "promo"
    "2024"
    "utm"
    "medium"
    "email"
    "limited"
    "offer"
    "domain:news.example.com"
    "domain:.example.com"
    "domain:.com"
    "now"
  }

  it_tokenizes "url with query and fragment with bigrams", "Check this link https://news.example.com/summer/sale?promo=Summer-2024&utm_medium=email#Limited-Offer now", {
    "check"
    "this"
    "check this"
    "link"
    "this link"
    "summer"
    "link summer"
    "sale"
    "summer sale"
    "promo"
    "sale promo"
    "promo summer"
    "2024"
    "summer 2024"
    "utm"
    "2024 utm"
    "medium"
    "utm medium"
    "email"
    "medium email"
    "limited"
    "email limited"
    "offer"
    "limited offer"
    "domain:news.example.com"
    "domain:.example.com"
    "domain:.com"
    "now"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "url without scheme", "Visit www.discount-store.net/deal-of-day today", {
    "visit"
    "deal"
    "of"
    "day"
    "domain:discount-store.net"
    "domain:.net"
    "today"
  }

  describe "ignore domains", ->
    it_tokenizes "ignores exact domain only", "Visit https://example.com/deal now", {
      "visit"
      "now"
    }, {
      ignore_domains: {"example.com"}
    }

    it_tokenizes "still tokenizes subdomain with exact ignore", "Visit https://shop.example.com/deal now", {
      "visit"
      "deal"
      "domain:shop.example.com"
      "domain:.example.com"
      "domain:.com"
      "now"
    }, {
      ignore_domains: {"example.com"}
    }

    it_tokenizes "ignores suffix domain including root", "Visit https://shop.example.com/deal now", {
      "visit"
      "now"
    }, {
      ignore_domains: {".example.com"}
    }

    -- strange case
    it_tokenizes "allows other domains", "Visit https://another.com/deal now", {
      "visit"
      "deal"
      "domain:another.com"
      "domain:.com"
      "now"
    }, {
      ignore_domains: {".example.com"}
    }

    it_tokenizes "respects mixed exact and suffix ignores", "Visit https://example.com/deal https://safe.example.com/deal https://another.net/deal now", {
      "visit"
      "deal"
      "domain:another.net"
      "domain:.net"
      "now"
    }, {
      ignore_domains: {
        "example.com"
        ".safe.example.com"
      }
    }

  describe "should_ignore_domain", ->
    it "returns false when no ignore_domains option is set", ->
      tokenizer = SpamTokenizer!
      assert.false tokenizer\should_ignore_domain "example.com"

    it "returns false with empty ignore_domains array", ->
      tokenizer = SpamTokenizer ignore_domains: {}
      assert.false tokenizer\should_ignore_domain "example.com"

    describe "exact domain matching", ->
      it "returns true for exact domain match", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com", "test.org"}
        assert.true tokenizer\should_ignore_domain "example.com"
        assert.true tokenizer\should_ignore_domain "test.org"

      it "returns false for non-matching domain", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.false tokenizer\should_ignore_domain "other.com"
        assert.false tokenizer\should_ignore_domain "example.org"

      it "returns false for subdomain when parent is exact match", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.false tokenizer\should_ignore_domain "sub.example.com"
        assert.false tokenizer\should_ignore_domain "deep.sub.example.com"

      it "returns false for parent domain when subdomain is exact match", ->
        tokenizer = SpamTokenizer ignore_domains: {"sub.example.com"}
        assert.false tokenizer\should_ignore_domain "example.com"

    describe "suffix domain matching", ->
      it "returns true for exact suffix match", ->
        tokenizer = SpamTokenizer ignore_domains: {".example.com"}
        assert.true tokenizer\should_ignore_domain "example.com"

      it "returns true for subdomain of suffix match", ->
        tokenizer = SpamTokenizer ignore_domains: {".example.com"}
        assert.true tokenizer\should_ignore_domain "sub.example.com"
        assert.true tokenizer\should_ignore_domain "deep.sub.example.com"

      it "returns false for parent domain when subdomain is suffix", ->
        tokenizer = SpamTokenizer ignore_domains: {".sub.example.com"}
        assert.false tokenizer\should_ignore_domain "example.com"

      it "returns false for different domain", ->
        tokenizer = SpamTokenizer ignore_domains: {".example.com"}
        assert.false tokenizer\should_ignore_domain "notexample.com"
        assert.false tokenizer\should_ignore_domain "example.org"

    describe "mixed exact and suffix matching", ->
      it "handles both exact and suffix patterns", ->
        tokenizer = SpamTokenizer ignore_domains: {"exact.com", ".suffix.net"}
        -- Exact match
        assert.true tokenizer\should_ignore_domain "exact.com"
        assert.false tokenizer\should_ignore_domain "sub.exact.com"
        -- Suffix match
        assert.true tokenizer\should_ignore_domain "suffix.net"
        assert.true tokenizer\should_ignore_domain "sub.suffix.net"
        -- Neither
        assert.false tokenizer\should_ignore_domain "other.com"

    describe "domain normalization", ->
      it "handles trailing dots", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.true tokenizer\should_ignore_domain "example.com."
        assert.true tokenizer\should_ignore_domain "example.com.."

      it "handles uppercase domains (normalizes to lowercase)", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.true tokenizer\should_ignore_domain "EXAMPLE.COM"
        assert.true tokenizer\should_ignore_domain "Example.Com"

      it "handles whitespace", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.true tokenizer\should_ignore_domain "  example.com  "
        assert.true tokenizer\should_ignore_domain " example.com"

      it "handles punycode domains", ->
        tokenizer = SpamTokenizer ignore_domains: {"xn--mnchen-3ya.de"}
        assert.true tokenizer\should_ignore_domain "xn--mnchen-3ya.de"
        -- Test that unicode domain gets converted to punycode for matching
        assert.true tokenizer\should_ignore_domain "münchen.de"

      it "normalizes ignore domains to punycode", ->
        tokenizer = SpamTokenizer ignore_domains: {"münchen.de"}
        assert.true tokenizer\should_ignore_domain "münchen.de"
        assert.true tokenizer\should_ignore_domain "xn--mnchen-3ya.de"

    describe "edge cases", ->
      it "returns false for nil domain", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.false tokenizer\should_ignore_domain nil

      it "returns false for empty string", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.false tokenizer\should_ignore_domain ""

      it "returns false for whitespace-only string", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.false tokenizer\should_ignore_domain "   "

      it "returns false for domain with only dots", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com"}
        assert.false tokenizer\should_ignore_domain "..."

      it "ignores invalid entries in ignore_domains", ->
        tokenizer = SpamTokenizer ignore_domains: {"example.com", "", "  ", ".", 123, nil}
        assert.true tokenizer\should_ignore_domain "example.com"
        assert.false tokenizer\should_ignore_domain "other.com"

  it_tokenizes "subscript characters", "Advanced CO₂ Extraction:", {
    "advanced"
    "co"
    "caps:co"
    "₂"
    "extraction"
  }

  it_tokenizes "ignored words", "Deal DEAL!!! Limited deal now NOW 10% NOW!!!", {
    "punct:!3"
    "limited"
    "now"
    "caps:now"
    "10%"
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
    "caps:my"
    "game"
    "caps:game"
    "not"
    "caps:not"
    "working"
    "caps:working"
    "error"
    "caps:error"
    "license"
    "caps:license"
    "found"
    "caps:found"
    "please"
    "caps:please"
    "help"
    "caps:help"
  }

  describe "bigram dedupe", ->
    it_tokenizes "with bigrams with dupes", "spam spam spam", {
      "spam"
      "spam"
      "spam spam"
      "spam"
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
      "caps:run"
      "dog"
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

    it_tokenizes "with stems & caps & bigram", "RUNNING Dogs", {
      "run"
      "caps:run"
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
      "run run"
      "run"
      "run run"
    }, {
      stem_words: true, bigram_tokens: true, dedupe: false
    }

    it_tokenizes "stemming combined with tagged tokens", "running at http://examples.com with $199.99 for sales@example.com", {
      "run"
      "at"
      "domain:examples.com"
      "domain:.com"
      "with"
      "currency:$"
      "199.99"
      "for"
      "email:sales@example.com"
      "email_user:sales"
      "domain:example.com"
    }, {
      stem_words: true
    }

    it_tokenizes "stemming, tagged tokens, and bigrams interaction", "running at http://examples.com with $199.99 for sales@example.com", {
      "run"
      "at"
      "run at"
      "domain:examples.com"
      "domain:.com"
      "with"
      "currency:$"
      "199.99"
      "with 199.99"
      "for"
      "199.99 for"
      "email:sales@example.com"
      "email_user:sales"
      "domain:example.com"
    }, {
      stem_words: true, bigram_tokens: true
    }

  describe "colon character in text", ->
    it_tokenizes "text with colons", "Note: this is important", {
      "note"
      "this"
      "is"
      "important"
    }

    it_tokenizes "multiple colons", "Warning: urgent: read this now", {
      "warning"
      "urgent"
      "read"
      "this"
      "now"
    }

    it_tokenizes "ratio format", "Score is 10:1 or maybe 3:2", {
      "score"
      "is"
      "10"
      "1"
      "or"
      "maybe"
      "3"
      "2"
    }

    it_tokenizes "colons with url", "Check: http://example.com has deals", {
      "check"
      "domain:example.com"
      "domain:.com"
      "has"
      "deals"
      "has deals"
    }, {
      bigram_tokens: true
    }

  describe "percent tokens", ->
    it_tokenizes "whole number percent", "Discount is 50% off", {
      "discount"
      "is"
      "50%"
      "off"
    }

    it_tokenizes "decimal percent", "Only 5.55% interest rate", {
      "only"
      "5.55%"
      "interest"
      "rate"
    }

    it_tokenizes "multiple percents", "Save 10% or even 15.5% today", {
      "save"
      "10%"
      "or"
      "even"
      "15.5%"
      "today"
    }

  describe "invalid byte handling", ->
    it_tokenizes "invalid UTF8 sequence", "Hello #{string.char(0xFF)} world", {
      "hello"
      "invalid_byte:255"
      "world"
    }

    it_tokenizes "invalid UTF8 sequence bigram interaction", "Hello #{string.char(0xFF)} world", {
      "hello"
      "invalid_byte:255"
      "world"
      "hello world"
    }, {
      bigram_tokens: true
    }

    it_tokenizes "multiple invalid bytes", "Test#{string.char(0xFE)}#{string.char(0xFF)}end", {
      "test"
      "invalid_byte:254"
      "invalid_byte:255"
      "end"
    }

    -- Note: Cyrillic "Привет" doesn't lowercase properly due to string.lower() not handling Unicode
    it_tokenizes "mixed valid unicode and invalid", "Привет#{string.char(0xFF)}世界", {
      "Пpиbet"
      "invalid_byte:255"
      "世界"
    }

  describe "punycode domain handling", ->
    it_tokenizes "ASCII domain unchanged", "Visit http://example.com now", {
      "visit"
      "domain:example.com"
      "domain:.com"
      "now"
    }

    it_tokenizes "German umlaut domain normalized with unaccent", "Check http://münchen.de today", {
      "check"
      "domain:munchen.de"
      "domain:.de"
      "today"
    }

    it_tokenizes "German umlaut domain", "Check http://münchen.de today", {
      "check"
      "domain:xn--mnchen-3ya.de"
      "domain:.de"
      "today"
    }, {
      unaccent: false
    }

    it_tokenizes "Japanese domain", "Visit http://日本.jp site", {
      "visit"
      "domain:xn--wgv71a.jp"
      "domain:.jp"
      "site"
    }

    it_tokenizes "Chinese domain", "See http://中国.cn here", {
      "see"
      "domain:xn--fiqs8s.cn"
      "domain:.cn"
      "here"
    }, {
      bigram_tokens: true
    }

    it_tokenizes "Chinese domain with no-op split_cjk", "See http://中国.cn here", {
      "see"
      "domain:xn--fiqs8s.cn"
      "domain:.cn"
      "here"
    }, {
      bigram_tokens: true
      split_cjk: true
    }

    it_tokenizes "mixed subdomain", "Visit http://test.münchen.example.com now", {
      "visit"
      "domain:test.xn--mnchen-3ya.example.com"
      "domain:.xn--mnchen-3ya.example.com"
      "domain:.example.com"
      "domain:.com"
      "now"
    }, {
      unaccent: false
    }

    it_tokenizes "hindi", [[
      <p>नमस्ते, मैं मोहम्मद निर्माता हूँ, या juegosruins68, भारत का एक प्रतिभाशाली गेम डेवलपर। मैंने 5 साल की उम्र से गेम बनाने शुरू किए, जब मैं मजबूरन E.A Games&trade; म</p>
    ]], {
      "नमस्ते"
      "मैं"
      "मोहम्मद"
      "निर्माता"
      "हूँ"
      "या"
      "juegosruins68"
      "भारत"
      "का"
      "एक"
      "प्रतिभाशाली"
      "गेम"
      "डेवलपर।"
      "मैंने"
      "5"
      "साल"
      "की"
      "उम्र"
      "से"
      "बनाने"
      "शुरू"
      "किए"
      "जब"
      "मजबूरन"
      "games™"
      "म"
    }

  describe "max_word_length truncation", ->
    it_tokenizes "truncates long words to max length", "supercalifragilisticexpialidocious short", {
      "supercalifragilisticexpialidoc"
      "short"
    }, {
      max_word_length: 30
    }

    it_tokenizes "truncates long words with default max", "thisisaverylongwordthatexceedsthirtytwochars normal", {
      "thisisaverylongwordthatexceedsth"
      "normal"
    }

    it_tokenizes "truncates caps words", "VERYLONGCAPSWORDEXCEEDINGTHEMAXIMUMALLOWEDLENGTH ok", {
      "verylongcapswordexceedingthema"
      "caps:verylongcapswordexceedingthema"
      "ok"
      "verylongcapswordexceedingthema ok"
    }, {
      max_word_length: 30
      bigram_tokens: true
    }

    it_tokenizes "truncates long domain names", "Visit http://thisisaverylongsubdomainnamethatshouldbetruncated.example.com now", {
      "visit"
      "domain:thisisaverylongsubdomainnameth"
      "domain:.example.com"
      "domain:.com"
      "now"
    }, {
      max_word_length: 30
    }

    it_tokenizes "truncates long email addresses", "Contact verylongemailaddressthatshouldbetruncated@example.com today", {
      "contact"
      "email:verylongemailaddressthatshould"
      "email_user:verylongemailaddressthatshould"
      "domain:example.com"
      "domain:.com"
      "today"
    }, {
      max_word_length: 30
    }

    it_tokenizes "truncates very long numbers", "Price is $123456789012345678901234567890.99 wow", {
      "price"
      "is"
      "currency:$"
      "123456789012345678901234567890"
      "wow"
    }, {
      max_word_length: 30
    }

    it_tokenizes "truncates long percent values", "Save 12345678901234567890123456789012% today", {
      "save"
      "123456789012345678901234567890%"
      "today"
    }, {
      max_word_length: 30
    }

  describe "build_grammar", ->
    it "grammar types", ->
      tokenizer = SpamTokenizer!
      grammar = tokenizer\build_grammar!
      out = grammar\match "hello http://cool.leafo.net/fart.png is here"
      assert.same {
        "hello"
        "fart"
        "png"
        {tag: "domain", value: "cool.leafo.net"}
        {tag: "domain", value: ".leafo.net"}
        {tag: "domain", value: ".net"}
        "is"
        "here"
      }, out

  describe "collect_url_tokens", ->
    it "extracts url tokens with HTML entities", ->
      tokenizer = SpamTokenizer!
      tokens = tokenizer\collect_url_tokens "http://leafo.net&amp; http://google.com/p8sslord/da?what please help www.leafodad.com"
      assert.same {
        {tag: "domain", value: "leafo.net"}
        {tag: "domain", value: ".net"}
        {tag: "domain", value: "google.com"}
        {tag: "domain", value: ".com"}
        {tag: "domain", value: "leafodad.com"}
        {tag: "domain", value: ".com"}
      }, tokens

    it "extracts url from iframe with double quotes", ->
      tokenizer = SpamTokenizer!
      tokens = tokenizer\collect_url_tokens [[<iframe src="http://youtube.com/hello-world" frameborder="0"></iframe>]]
      assert.same {
        {tag: "domain", value: "youtube.com"}
        {tag: "domain", value: ".com"}
      }, tokens

    -- TODO: this should probably be fixed at some point, it's treating ' as apostrophe word most likely
    it "BUG: does not extract url from single-quoted attribute", ->
      tokenizer = SpamTokenizer!
      -- Single quotes break the URL pattern matching in the grammar
      tokens = tokenizer\collect_url_tokens "href='http://example.com' other text"
      assert.same {}, tokens

    it "extracts multiple urls", ->
      tokenizer = SpamTokenizer!
      tokens = tokenizer\collect_url_tokens [[
        http://leafo.net
        http://good.leafo.net
        http://google.com
        http://butt.google.com
        http://plus.good.google.com
      ]]
      assert.same {
        {tag: "domain", value: "leafo.net"}
        {tag: "domain", value: ".net"}
        {tag: "domain", value: "good.leafo.net"}
        {tag: "domain", value: ".leafo.net"}
        {tag: "domain", value: ".net"}
        {tag: "domain", value: "google.com"}
        {tag: "domain", value: ".com"}
        {tag: "domain", value: "butt.google.com"}
        {tag: "domain", value: ".google.com"}
        {tag: "domain", value: ".com"}
        {tag: "domain", value: "plus.good.google.com"}
        {tag: "domain", value: ".good.google.com"}
        {tag: "domain", value: ".google.com"}
        {tag: "domain", value: ".com"}
      }, tokens
