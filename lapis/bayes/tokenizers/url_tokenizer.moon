
class UrlTokenizer
  new: (@opts) =>

  -- strip urls to just domains
  filter_urls: (urls) =>
    urls

  build_grammer: =>
    import P, S, R, C from require "lpeg"

    case_insensitive = (text) ->
      out = nil
      for char in text\gmatch "."
        p = S"#{char\lower!}#{char\upper!}"
        if out
          out *= p
        else
          out = p

      out

    space = S" \t\n"^0

    scheme = case_insensitive"http" * case_insensitive"s"^-1 * P"://"
    raw_url = C scheme * (P(1) - S" \t\n")^1

    alphanum = R "az", "AZ", "09"
    word = (alphanum + S"._-")^1
    attr_value = C(word) + P'"' * C((1 - P'"')^0) * P'"' + P"'" * C((1 - P"'")^0) * P"'"
    href = case_insensitive"href" * space * P"=" * space * attr_value

    simple = C case_insensitive"www" * (P"." * (1 - S"./")^1)^1

    (raw_url + href + simple + 1)^0

  tokenize_text: (text) =>



