
inv_chi2 = (chi, df) ->
  assert df % 2 == 0, "df must be even"
  m = chi / 2.0
  sum = math.exp -m
  term = sum
  for i=1, math.floor df/2
    term *= m / i
    sum += term

  math.min sum, 1

class ChiClassifier extends require "lapis.bayes.classifiers.base"
  word_probabilities: (categories, available_words) =>
    return nil, "only two categories supported at once" unless #categories == 2

    {a, b} = categories

    s = 1
    x = 0.5

    mul = nil
    for word in *available_words
      a_count = a.word_counts and a.word_counts[word] or 0
      b_count = b.word_counts and b.word_counts[word] or 0

      p = a_count / (a_count + b_count)
      n = a_count + b_count
      val = ((s * x) + (n * p)) / (s + n)

      if mul
        mul *= val
      else
        mul = val


    ph = inv_chi2 -2 * math.log(mul), 2 * (a.total_count + b.total_count)

    tuples = {
      {a.name, ph}
      {b.name, 1 -ph}
    }

    table.sort tuples, (a,b) -> a[2] > b[2]

    tuples


