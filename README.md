# lapis-bayes

![test](https://github.com/leafo/lapis-bayes/workflows/test/badge.svg)

`lapis-bayes` is a [Naive Bayes
classifier](https://en.wikipedia.org/wiki/Naive_Bayes_classifier) for use in
Lua. It can be used to classify text into any category that has been trained
for ahead of time.

It's built on top of [Lapis](http://leafo.net/lapis), but can be used as a
standalone library as well. It requires PostgreSQL to store and parse training
data.

## Install

```bash
$ luarocks install lapis-bayes
```

## Quick start

Create a new migration that look like this: 

```lua
-- migrations.lua
{
  ...

  [1439944992]: require("lapis.bayes.schema").run_migrations
}
```

Run migrations:

```bash
$ lapis migrate
```

Train the classifier:

```lua
local bayes = require("lapis.bayes")

bayes.train_text("spam", "Cheap Prom Dresses 2014 - Buy discount Prom Dress")
bayes.train_text("spam", "Older Models Rolex Watches - View Large Selection of Rolex")
bayes.train_text("spam", "Hourglass Underwire - $125.00 : Professional swimwear")

bayes.train_text("ham", "Games I've downloaded so I remember them and stuff")
bayes.train_text("ham", "Secret Tunnel's Collection of Rad Games That I Dig")
bayes.train_text("ham", "Things I need to pay for when I get my credit card back")
```

Classify text:

```lua
assert("ham" == bayes.classify_text({"spam", "ham"}, "Games to download"))
assert("spam" == bayes.classify_text({"spam", "ham"}, "discount rolex watch"))
```


## Reference

The `lapis.bayes` module includes a set of functions that operate on the
default classifier and tokenizer:

* `BayesClassifier`
* `PostgresTextTokenizer`
* `UrlDomainsTokenizer`
* `SpamTokenizer`
* `NgramTokenizer`

These functions work with the default classifier class defined by `require
"lapis.bayes.classifiers.default"` (which resolves to the `BayesClassifier`. If
you want finer control over tokenization and classification then you can work
with tokenizers and classifiers directly.

#### `num_words = bayes.train_text(category, text)`

```lua
local bayes = require("lapis.bayes")
bayes.train_text("spam", "Cheap Prom Dresses 2014 - Buy discount Prom Dress")
```

Inserts the tokenized words from `text` into the database associated with the
category named `category`. Categories don't need to be created ahead of time,
use any name you'd like. Later when classifying text you'll list all the
eligible categories.

The tokenizer will normalize words and remove stop words before inserting into
the database. The number of words kept from the original text is returned.

#### `category, score = bayes.classify_text({category1, category2, ...}, text)`

```lua
local bayes = require("lapis.bayes")
print bayes.classify_text({"spam", "ham"}, "Games to download")
```

Attempts to classify text. If none of the words in `text` are available in any
of the listed categories then `nil` and an error message are returned.

Returns the name of the category that best matches, along with a probability
score in natrual log (`math.log`). The closer to 0 this is, the better the
match.

The input text is normalized using the same tokenizer as the trainer: stop
words are removed and stems are used. Only words that are available in at least
one category are used for the classification.

## Tokenization

Whenever a string is passed to any train or classify functions, it's passed through the default tokenizer to turn the string into an array of *words*.

* For classification, these words are used to check the database for existing probabilities
* For training, the words are inserted directly into the database

Tokenization is more complicated than just splitting the string by spaces, text
can be normalized and extraneous data can be stripped.

Sometimes, you may want to explicitly provide the words for insertion and
classification. You can bypass tokenization by passing an array of words in
place of the string when calling any classify or train function.

```lua
local bayes = require("lapis.bayes")

-- Providing a list of word tokens directly for training will skip the tokenization

local tokens = {"cheap", "prom", "dresses", "buy", "discount", "prom", "dress"}
bayes.train_text("spam", tokens)

local tokens2 = {"games", "downloaded", "remember", "stuff"}
bayes.train_text("ham", tokens2)
```

You can manually tokenize by providing a `tokenize_text` function to the
options table. The function takes a single arugment, the string of text, and
the return value is an array of tokens. For example:

```lua
local bayes = require("lapis.bayes")
bayes.train_text("spam", "Cheap Prom Dresses 2014 - Buy discount Prom Dress", {
  tokenize_text = function(text)
    -- your custom tokenizer goes here
    return {tok1, tok2, ...}
  end
})
```

Alternatively, you can pass in a specific tokenzer instance like so:

```lua
local SpamTokenizer = require "lapis.bayes.tokenizers.spam"

local tokenizer = SpamTokenizer({
  stem_words = true,
  bigram_tokens = true,
})

local bayes = require("lapis.bayes")

bayes.train_text("ham", "I love video games and discounts", {
  tokenizer = tokenizer
})

bayes.train_text("spam", "discounted prescription drugs", {
  tokenizer = tokenizer
})

local input_strinct = "Download latest games at huge discounts"

local category, score = bayes.classify_text({"spam", "ham"}, input_string, {
  tokenizer = tokenizer
})

print(category, score) --> "ham", 0.95
```

> It's important that you avoid mixing and matching category names with
> different tokenizer types, as the different tokens can have different
> meanings and distributions.

### Built-in tokenizers

*Postgres Text* is the default tokenizer used when no tokenizer is provided.
You can customize the tokenizer when instantiating the classifer:

```lua
BayesClassifier = require "lapis.bayes.classifiers.bayes"
classifier = BayesClassifier({
  tokenizer = <tokenizer instance>
})

local result = classifier:classify_text(...)
```

####  Postgres Text

Uses Postgres `tsvector` objects to normalize text. This will remove stop
words, normalize capitalization and symbols, and convert words to lexemes.
Duplicates are removed.

> Note: The characteristics of this tokenizer may not be suitable for your
> objectives with spam detection. If you have very specific training data,
> preserving symbols, capitalization, and duplication could be beneficial. This
> tokenizer aims to generalize spam text to match a wider range of text that
> may not have specific training.

This tokenizer requires an active connection to a Postgres database (provided
in the Lapis config). It will issue a single query when tokenizing a string of
text. The tokenizer is uses a query that is specific to English:


```sql
select unnest(tsvector_to_array(to_tsvector('english', 'my text here'))) as word
```

Example:


```lua
local Tokenizer = require "lapis.bayes.tokenizers.postgres_text"

local t = Tokenizer(opts)

local tokens = t:tokenize_text("Hello world This Is my tests example") --> {"exampl", "hello", "test", "world"}

local tokens2 = t:tokenize_text([[
  <div class='what is going on'>hello world<a href="http://leafo.net/hi.png">my image</a></div>
]]) --> {"hello", "imag", "world"}
```

Tokenizer options:

* `min_token_length`: minimum token length (default `2`)
* `max_token_length`: maximum token length (default `12`), tokens that don't fulfill length requirements will be excluded, not truncated
* `strip_numbers`: remove tokens that are numbers (default `true`)
* `strip_tags`: remove HTML tags from input text (default `false`)
* `symbols_split_tokens`: split apart tokens that contain a symbol before tokenization, eg. `hello:world` goes to `hello world` (default `false`)
* `ignore_words`: table of words to ignore, keys are words and values should be truthy (optional, default `nil`)
* `filter_text`: custom pre-filter function to process incoming text, takes text as first argument, should return text (optional, default `nil`)
* `filter_tokens`: custom post-filter function to process output tokens, takes token array and opts, should return a token array (optional, default `nil`)
* `legacy_tokenizer`: use slower `ts_debug` tokenizer that preserves duplicate words (default `false`)
* `regconfig`: PostgreSQL text search configuration to use for tokenization (default `"english"`)

####  Spam Tokenizer

`SpamTokenizer = require "lapis.bayes.tokenizers.spam"`

A tokenization specially designed to generate token arrays that are effective
at spam classification. This includes normalizing accented characters,
extracting URLs and domains, working with HTML markup, generating bigrams,
generating tagged tokens for punctuation, currencies, emails, and more.

Token types include:

* lowercase word tokens (with apostrophes removed and optional unaccenting)
* `caps:<word>` for words containing uppercase letters
* `punct:<char><run-length>` for repeated punctuation (e.g., `punct:!3` for `!!!`)
* `currency:<symbol>` for currency symbols (e.g., `currency:$`)
* plain number strings (e.g., `"12345"`, `"5.99"`)
* plain percent strings (e.g., `"99%"`)
* `domain:<domain>` for full domains and hierarchical suffixes with leading dots (e.g., `domain:example.com`, `domain:.com`)
* `email:<address>` for full email addresses
* `email_user:<username>` for the username part of emails
* `invalid_byte:<byte>` for invalid UTF-8 bytes
* optional word bigrams (`word1 word2`) when enabled

Options:

* `min_word_length` / `max_word_length`: bounds applied before emitting word tokens (defaults `2` / `32`)
* `ignore_words`: table of words to ignore (keys are words, values should be truthy) (optional)
* `ignore_tokens`: table of tokens to ignore (keys are tokens, values should be truthy) (optional)
* `ignore_domains`: list of domains to ignore; prefix with `.` to ignore subdomains (e.g., `".example.com"` ignores all subdomains, `"example.com"` ignores exact match only) (optional)
* `dedupe`: defaults to `true`; set `false` to keep duplicate tokens
* `bigram_tokens`: when `true`, append sequential word bigrams
* `sample_at_most`: keeps at most N word tokens and at most N bigrams separately; tagged tokens (domain, email, etc.) are never sampled
* `dither`: defaults to `true`; when enabled, applies dithering randomization when sampling tokens
* `unaccent`: defaults to `true`; set to `false` to keep original accents
* `stem_words`: defaults to `false`; when `true`, applies Porter stemming to word tokens (e.g., "running" → "run")
* `filter_text`: custom pre-filter function to process incoming text, takes text as first argument, should return text (optional)
* `filter_tokens`: custom post-filter function to process output tokens, takes token array and opts as arguments, should return a token array (optional)

```lua
local SpamTokenizer = require "lapis.bayes.tokenizers.spam"

local tokenizer = SpamTokenizer {
  bigram_tokens = true,
  sample_at_most = 128
}

local tokens = tokenizer:tokenize_text([[<div>Limited time offer! Visit https://example.com for 50% off</div>]])
```

Produces tokens:

```lua
{
  "limited",
  "time",
  "offer",
  "visit",
  "50%",
  "domain:example.com",
  "domain:.com",
  "limited time",
  "time offer",
  "offer visit"
}
```

####  N-gram Tokenizer

`NgramTokenizer = require "lapis.bayes.tokenizers.ngram"`

A character-level n-gram tokenizer that splits text into overlapping sequences of n characters. This tokenizer is useful for language-agnostic classification, handling misspellings, and working with languages that don't have clear word boundaries. It properly handles UTF-8 multi-byte characters.

N-grams are created at the character level from normalized words. For example, with bigrams (n=2), the word "hello" produces: `"he"`, `"el"`, `"ll"`, `"lo"`.

Options:

* `n`: size of n-grams to generate (default `2` for bigrams); supports 1 (unigrams), 2 (bigrams), 3 (trigrams), etc.
* `ignore_numbers`: when `true` (default), skips tokens that are purely numeric
* `filter_text`: custom pre-filter function to process incoming text, takes text as first argument, should return text (optional)
* `filter_tokens`: custom post-filter function to process output tokens, takes token array and opts as arguments, should return a token array (optional)

```lua
local NgramTokenizer = require "lapis.bayes.tokenizers.ngram"

-- Default bigram tokenizer
local tokenizer = NgramTokenizer()
local tokens = tokenizer:tokenize_text("hello world")
--> {"he", "el", "ll", "lo", "wo", "or", "rl", "ld"}

-- Trigram tokenizer
local tokenizer3 = NgramTokenizer({ n = 3 })
local tokens3 = tokenizer3:tokenize_text("testing")
--> {"tes", "est", "sti", "tin", "ing"}

-- Works with UTF-8 characters
local tokens_utf8 = tokenizer:tokenize_text("café")
--> {"ca", "af", "fé"}
```

**Use cases:**

* Language detection and multilingual classification
* Handling text with typos or non-standard spellings
* Working with languages without clear word boundaries (e.g., Chinese, Japanese)
* Creating more robust features that are less sensitive to exact word matches
* SMS or social media text classification where spelling varies

**Normalization:**

Before generating n-grams, the tokenizer:
1. Converts text to lowercase
2. Removes punctuation from words
3. Strips whitespace
4. Optionally filters out numeric-only tokens (default)

####  URL Domains

Extracts mentions of domains from the text text, all other text is ignored.

```lua
local Tokenizer = require "lapis.bayes.tokenizers.url_domains"

local t = Tokenizer(opts)
local tokens = t:tokenize_text([[
  Please go to my https://leafo.net website <a href='itch.io'>hmm</a>
]]) --> {"leafo.net", "itch.io"}
```

## Schema

`lapis-bayes` creates two tables:

* `lapis_bayes_categories`
* `lapis_bayes_word_classifications`

## Running outside of Lapis

### Creating a configuration

If you're not running `lapis-bayes` directly inside of Lapis you'll need to
create a configuration file that instructs your script on how to connect to a
database.

In your project root, create `config.lua`:


```lua
-- config.lua
local config = require("lapis.config")

config("development", {
  postgres = {
    database = "lapis_bayes"
  }
})
```

The example above provides the minimum required for `lapis-bayes` to connect to
a PostgreSQL database. You're responsible for creating the actual database if
it doesn't already exist.

For PostgreSQL you might run the command:

```bash
$ createdb -U postgres lapis_bayes
```

We're using the standard Lapis configuration format, you can read more about it
here: http://leafo.net/lapis/reference/configuration.html

### Creating the schema

After database connection has been established the schema (database tables)
need to be created. This is done using [Lapis'
migrations](http://leafo.net/lapis/reference/database.html#database-migrations).

Create a file, `migrations.lua`, and make it look like the following:


```lua
-- migrations.lua

return {
  require("lapis.bayes.schema").run_migrations
}
```

You can test your configuration now by running the migrations with the
following command from your shell: *(Note you must be in the same directory as
your code, `migrations.lua` and `config.lua`)*

```bash
$ lapis migrate
```

You're now ready to start training and classifying text! (Go back to the top of
this document for the tutorial)

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))  
Email: leafot@gmail.com  
Homepage: <http://leafo.net>  
License: MIT
