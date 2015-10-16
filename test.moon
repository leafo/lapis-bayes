UrlDomainsTokenizer = require "lapis.bayes.tokenizers.url_domains"

grammar = UrlDomainsTokenizer!\build_grammer!

require("moon").p {
  grammar\match "href='http://leafo.net ' http://google.com/p8isslord please help the good one www.leafopiss.com yeah what the freak"
}
