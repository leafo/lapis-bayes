
inv_chi2 = (chi, df) ->
  assert df % 2 == 0, "df must be even"
  m = chi / 2.0
  sum = math.exp -m
  term = sum
  for i=1, math.floor df/2
    term *= m / i
    sum += term

  math.min sum, 1

class FisherClassifier extends require "lapis.bayes.classifiers.base"
  @default_options: {
    robs: 1
    robx: 0.5
  }

  word_probabilities: (categories, available_words) =>
    return nil, "only two categories supported at once" unless #categories == 2

    {a, b} = categories

    s = @opts.robs
    x = @opts.robx

    mul_a = 0
    mul_b = 0
    for word in *available_words
      a_count = a.word_counts and a.word_counts[word] or 0
      b_count = b.word_counts and b.word_counts[word] or 0

      p = a_count / (a_count + b_count)
      n = a_count + b_count
      val = ((s * x) + (n * p)) / (s + n)

      mul_a += math.log val
      mul_b += math.log 1 - val

    pa = inv_chi2 -2 * mul_a, 2 * #available_words
    pb = inv_chi2 -2 * mul_b, 2 * #available_words

    p = (1 + pa - pb) / 2

    tuples = {
      {a.name, p}
      {b.name, 1 - p}
    }

    table.sort tuples, (a,b) -> a[2] > b[2]

    tuples


