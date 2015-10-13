
trim = (str) -> tostring(str)\match "^%s*(.-)%s*$"

class UrlDomainsTokenizer
  new: (@opts) =>

  -- strip urls to just domains
  filter_urls: (urls) =>
    return for url in *urls
      url = trim url
      url = url\gsub "^%w+://", ""
      url = url\gsub "^www%.", ""
      url = url\gsub "/.*$", ""
      url = trim url

      url\gsub "<$", ""
      url\gsub "^>", ""

      continue if url == ""
      continue if url\match "^%w+:" -- mailto and co
      continue if url\match [=[[<>="' ]]=]

      continue if @opts and @opts.domain_whitelist and @opts.domain_whitelist[url]

      url

  build_grammer: =>
    import P, S, R, C, Ct, Cs from require "lpeg"

    case_insensitive = (text) ->
      out = nil
      for char in text\gmatch "."
        p = S"#{char\lower!}#{char\upper!}"
        if out
          out *= p
        else
          out = p

      out

    -- this is far from comprehensive
    unescape_char = P"&gt;" / ">" +
      P"&lt;" / "<" +
      P"&amp;" / "&" +
      P"&nbsp;" / " " +
      P"&#x27;" / "'" +
      P"&#x2F;" / "/" +
      P"&quot;" / '"'

    unescape_text = Cs (unescape_char + 1)^1

    some_space = S" \t\n"
    space = some_space^0
    alphanum = R "az", "AZ", "09"

    scheme = case_insensitive"http" * case_insensitive"s"^-1 * P"://"
    raw_url = C scheme * (P(1) - S" \t\n")^1

    word = (alphanum + S"._-")^1
    attr_value = C(word) + P'"' * C((1 - P'"')^0) * P'"' + P"'" * C((1 - P"'")^0) * P"'"

    href = case_insensitive"href" * space * P"=" * space * attr_value / (v) -> unescape_text\match(v) or ""

    simple = C case_insensitive"www" * (P"." * (1 - (S"./" + some_space))^1)^1

    Ct (raw_url + href + simple + 1)^0

  tokenize_text: (text) =>
    @grammar or= @build_grammer!
    matches = @grammar\match text
    return nil, "failed to parse text" unless matches
    @filter_urls matches

