import P, R, S, Cs from require "lpeg"

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
  P"\226\128" * (R"\139\140" + R"\142\143" + R"\170\174") + -- U+200B–U+200C + U+200E–U+200F + U+202A–U+202E
  P"\226\129" * (R"\160\164" + R"\166\175") + -- U+2060–U+2064 (WORD JOINER + invisible operators) + U+2066–U+206F (bidi isolates/deprecated format controls)
  P"\239\187\191" + -- U+FEFF (BOM / zero-width no-break space)
  P"\243\160" * R"\128\129" * R"\128\191" -- U+E0000–U+E007F (TAG block: LANGUAGE TAG and ASCII tag chars)

variation_selector = P"\239\184" * R"\128\143" + -- U+FE00–U+FE0F
  P"\243\160" * (R"\132\134" * R"\128\191" + P"\135" * R"\128\175") -- U+E0100–U+E01EF

zero_width_joiner = P"\226\128\141" -- U+200D ZERO WIDTH JOINER

-- Subdivision flag sequence: U+1F3F4 BLACK FLAG + tag chars (U+E0020–U+E007E)
-- + U+E007F CANCEL TAG. Encodes flags like 🏴󠁧󠁢󠁥󠁮󠁧󠁿 (England).
tag_char = P"\243\160\128" * R"\160\191" + P"\243\160\129" * R"\128\190" -- U+E0020–U+E007E
cancel_tag = P"\243\160\129\191" -- U+E007F
flag_tag_sequence = P"\240\159\143\180" * tag_char^1 * cancel_tag

utf8_2 = R"\194\223" * cont
utf8_3 = R"\224\239" * cont * cont
utf8_4 = R"\240\244" * cont * cont * cont
non_ascii_character = utf8_2 + utf8_3 + utf8_4

-- A non-ASCII char with an optional variation selector. Used as the base
-- unit inside ZWJ sequences. Broader than "emoji", any non-ASCII char
-- qualifies, which keeps Ideographic Variation Sequences (Han + VS) intact.
joinable_unit = non_ascii_character * variation_selector^-1
variation_sequence = non_ascii_character * variation_selector
joiner_sequence = joinable_unit * (zero_width_joiner * joinable_unit)^1
keycap_sequence = (R"09" + S"#*") * variation_selector^-1 * P"\226\131\163" -- U+20E3 COMBINING ENCLOSING KEYCAP

-- Order matters: preserve multi-codepoint sequences first, then strip stray
-- invisibles, then fall through to single non-ASCII / ASCII characters.
strip_zero_width_pattern = Cs((
  flag_tag_sequence +
  joiner_sequence +
  keycap_sequence +
  variation_sequence +
  zero_width_character / "" +
  variation_selector / "" +
  zero_width_joiner / "" +
  non_ascii_character +
  P(1)
)^0)

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
  :variation_selector
  :zero_width_joiner
  :flag_tag_sequence
  :strip_zero_width_string
}
