local NgramTokenizer = require("lapis.bayes.tokenizers.ngram")
local BayesMultiClassifier = require("lapis.bayes.classifiers.bayes_multi")

-- generates character ngrames of length 2
local tokenizer = NgramTokenizer({n = 2})

-- A BayesMultiClassifier supports classifying to any number of categories
local classifier = BayesMultiClassifier({tokenizer = tokenizer})

local training_data = {
  {"english", "The quick brown fox jumps over the lazy dog"},
  {"english", "Hello world this is a test of the system"},
  {"english", "Programming and software development with modern technology"},

  {"spanish", "El rápido zorro marrón salta sobre el perro perezoso"},
  {"spanish", "Hola mundo esta es una prueba del sistema"},
  {"spanish", "Los lenguajes de programación son herramientas importantes"},

  {"french", "Le rapide renard brun saute pardessus le chien paresseux"},
  {"french", "Bonjour le monde ceci est un test du système"},
  {"french", "Les langages de programmation sont des outils importants"},

  {"german", "Der schnelle braune Fuchs springt über den faulen Hund"},
  {"german", "Hallo Welt dies ist ein Test des Systems"},
  {"german", "Programmiersprachen sind wichtige Werkzeuge für die Entwicklung"},

  {"chinese", "敏捷的棕色狐狸跳过懒狗"},
  {"chinese", "你好世界这是一个系统的测试"},
  {"chinese", "编程语言是表达算法的重要工具"},
}

-- Train the classifier
print("Training classifier...")
for _, entry in ipairs(training_data) do
  local language, text = entry[1], entry[2]
  classifier:train_text(language, text)
end
print("Training complete.\n")

-- Classify new text
local test_cases = {
  "Welcome to our website",
  "Bienvenido a nuestro sitio",
  "Bienvenue sur notre site",
  "Willkommen auf unserer Website",
  "欢迎来到我们的网站",
}

print("Classifying test sentences:\n")
for _, test in ipairs(test_cases) do
  local text = test[1]

  -- Get probability distribution across all languages
  local probs = classifier:text_probabilities({
    "english",
    "spanish",
    "french",
    "german",
    "chinese"
  }, text)

  -- The result is sorted by probability, first entry is the detected language
  local detected_language = probs[1][1]
  local confidence = probs[1][2]

  print(string.format('Text: "%s"', text))
  print(string.format("Detected: %s (%.1f%% confidence)\n", detected_language, confidence * 100))
end
