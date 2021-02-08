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

You can customize the tokenizer by providing a `tokenize_text` option. This
should be a function that takes a single arugment, the string of text, and the
return value is the tokens. For example:

```lua
local bayes = require("lapis.bayes")
bayes.train_text("spam", "Cheap Prom Dresses 2014 - Buy discount Prom Dress", {
  tokenize_text = function(text)
    -- your custom tokenizer goes here
    return {tok1, tok2, ...}
  end
})
```

### Built-in tokenizers

*Postgres Text* is the default tokenizer used when no tokenizer is provided.

####  Postgres Text

Uses Postgres `tsvector` objects to normalize text. This will remove stop
words, normalize capitalization and symbols, and convert words to lexemes.
Duplicates are removed.

> Note: The characteristics of this tokenizer may not be appropriate for your
> goals with spam detector: if you have very specific training data then
> preserving symbols, capitalization, and duplication would actually be useful.
> This tokenizer tries to make spam text more general purpose to match wider
> range of text that might not have specific training.

This tokenizer requires an active connection to a Postgres database (provided
in the Lapis config). It will issue queries when tokenizing. The tokenizer is
uses a query that is specific to English:


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

* `min_len`: minimum token length (default `2`)
* `max_len`: maximum token length (default `12`), tokens that don't fulfill length requirements will be excluded, not truncated
* `strip_numbers`: remove tokens that are numbers (default `true`)
* `symbols_split_tokens`: split apart tokens that contain a symbol before tokenization, eg. `hello:world` goes to `hello world` (default `false`)
* `filter_text`: custom pre-filter function to process incoming text, takes text as first argument, should return text (optional, default `nil`)
* `filter_tokens`: custom post-filter function to process output tokens, takes token array, should return a token array (optional, default `nil`)

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


