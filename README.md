# lapis-bayes


`lapis-bayes` is a [Naive Bayes
classifier](https://en.wikipedia.org/wiki/Naive_Bayes_classifier) for use in
Lua. It can be used to classify text into any category that has been trained
for ahead of time.

It's built on top of [Lapis](http://leafo.net/lapis), but can be used as a
standalone library as well. It persists training data into any database
supported by Lapis.

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
assert("ham" == bayes.classify_text({"spam", "ham"}, "Games to download")
assert("spam" == bayes.classify_text({"spam", "ham"}, "discount rolex watch")
```

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


