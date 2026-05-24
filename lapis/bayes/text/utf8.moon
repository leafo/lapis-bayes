import P, R, Cs from require "lpeg"

cont = R "\128\191"

-- Han ideographs (basic, extensions, compatibility, supplementary planes)
han_ext_a = P"\227" * R("\144\191") * cont + P"\228" * R("\128\182") * cont
han_unified = P"\228" * R("\184\191") * cont + R("\229\232") * cont * cont + P"\233" * R("\128\191") * cont
han_compat = P"\239" * R("\164\171") * cont
han_supplement = P"\240" * R("\160\178") * cont * cont
han_character = han_ext_a + han_unified + han_compat + han_supplement

-- Japanese Hiragana
hiragana_block = P"\227\129" * cont + P"\227\130" * R("\128\159")

-- Kana supplement & historic kana (hentaigana, archaic forms)
kana_supplement = P"\240\155" * R("\128\133") * cont

hiragana_character = hiragana_block + kana_supplement

-- Japanese Katakana (standard, extensions, halfwidth)
katakana_main = P"\227\130" * R("\160\191") + P"\227\131" * cont
katakana_phonetic_ext = P"\227\135" * R("\176\191")
katakana_halfwidth = P"\239\189" * R("\166\191") + P"\239\190" * R("\128\159")
katakana_character = katakana_main + katakana_phonetic_ext + katakana_halfwidth + kana_supplement

kana_character = hiragana_block + katakana_main + katakana_phonetic_ext + katakana_halfwidth + kana_supplement

-- Korean Hangul (jamo, syllables, compatibility/halfwidth)
hangul_jamo = P"\225" * R("\132\135") * cont
hangul_jamo_ext_a = P"\234\165" * R("\160\191")
hangul_compat_jamo = P"\227\132" * R("\176\191") + P"\227\133" * cont + P"\227\134" * cont + P"\227\135" * R("\128\143")
hangul_syllables = P"\234" * R("\176\191") * cont + R("\235\236") * cont * cont + P"\237" * (R("\128\157") * cont + P"\158" * R("\128\163"))
hangul_jamo_ext_b = P"\237\158" * R("\176\191") + P"\237\159" * cont
hangul_halfwidth = P"\239\190" * R("\160\191") + P"\239\191" * R("\128\156")
hangul_character = hangul_jamo + hangul_jamo_ext_a + hangul_compat_jamo + hangul_syllables + hangul_jamo_ext_b + hangul_halfwidth

-- Zero-width / invisible formatting characters commonly injected to evade
-- exact-match tokenization (e.g., exa​mple.com). Grouped by leading UTF-8 byte.
zero_width_character = P"\205\143" + -- U+034F COMBINING GRAPHEME JOINER
  P"\194\173" + -- U+00AD SOFT HYPHEN
  P"\216\156" + -- U+061C ARABIC LETTER MARK
  P"\225\160\142" + -- U+180E MONGOLIAN VOWEL SEPARATOR
  P"\226\128" * (R"\139\143" + R"\170\174") + -- U+200B–U+200F (ZWSP/ZWNJ/ZWJ/LRM/RLM) + U+202A–U+202E (bidi formatting/overrides)
  P"\226\129" * (R"\160\164" + R"\166\175") + -- U+2060–U+2064 (WORD JOINER + invisible operators) + U+2066–U+206F (bidi isolates/deprecated format controls)
  P"\239\184" * R"\128\143" + -- U+FE00–U+FE0F (variation selectors)
  P"\239\187\191" + -- U+FEFF (BOM / zero-width no-break space)
  P"\243\160" * R"\128\129" * R"\128\191" + -- U+E0000–U+E007F (TAG block: LANGUAGE TAG and ASCII tag chars)
  P"\243\160" * (R"\132\134" * R"\128\191" + P"\135" * R"\128\175") -- U+E0100–U+E01EF (variation selectors supplement)

strip_zero_width_pattern = Cs((zero_width_character / "" + P(1))^0)

strip_zero_width_string = (str) ->
  return str unless str
  strip_zero_width_pattern\match(str) or str

cjk_character = han_character + kana_character + hangul_character

{
  :cont
  :han_character
  :hiragana_character
  :katakana_character
  :kana_character
  :hangul_character
  :cjk_character
  :zero_width_character
  :strip_zero_width_string
}
