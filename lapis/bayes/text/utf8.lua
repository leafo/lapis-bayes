local P, R
do
  local _obj_0 = require("lpeg")
  P, R = _obj_0.P, _obj_0.R
end
local cont = R("\128\191")
local han_ext_a = P("\227") * R("\144\191") * cont + P("\228") * R("\128\182") * cont
local han_unified = P("\228") * R("\184\191") * cont + R("\229\232") * cont * cont + P("\233") * R("\128\191") * cont
local han_compat = P("\239") * R("\164\171") * cont
local han_supplement = P("\240") * R("\160\178") * cont * cont
local han_character = han_ext_a + han_unified + han_compat + han_supplement
local hiragana_block = P("\227\129") * cont + P("\227\130") * R("\128\159")
local kana_supplement = P("\240\155") * R("\128\133") * cont
local hiragana_character = hiragana_block + kana_supplement
local katakana_main = P("\227\130") * R("\160\191") + P("\227\131") * cont
local katakana_phonetic_ext = P("\227\135") * R("\176\191")
local katakana_halfwidth = P("\239\189") * R("\166\191") + P("\239\190") * R("\128\159")
local katakana_character = katakana_main + katakana_phonetic_ext + katakana_halfwidth + kana_supplement
local kana_character = hiragana_block + katakana_main + katakana_phonetic_ext + katakana_halfwidth + kana_supplement
local hangul_jamo = P("\225") * R("\132\135") * cont
local hangul_jamo_ext_a = P("\234\165") * R("\160\191")
local hangul_compat_jamo = P("\227\132") * R("\176\191") + P("\227\133") * cont + P("\227\134") * cont + P("\227\135") * R("\128\143")
local hangul_syllables = P("\234") * R("\176\191") * cont + R("\235\236") * cont * cont + P("\237") * (R("\128\157") * cont + P("\158") * R("\128\163"))
local hangul_jamo_ext_b = P("\237\158") * R("\176\191") + P("\237\159") * cont
local hangul_halfwidth = P("\239\190") * R("\160\191") + P("\239\191") * R("\128\156")
local hangul_character = hangul_jamo + hangul_jamo_ext_a + hangul_compat_jamo + hangul_syllables + hangul_jamo_ext_b + hangul_halfwidth
local cjk_character = han_character + kana_character + hangul_character
return {
  cont = cont,
  han_character = han_character,
  hiragana_character = hiragana_character,
  katakana_character = katakana_character,
  kana_character = kana_character,
  hangul_character = hangul_character,
  cjk_character = cjk_character
}
