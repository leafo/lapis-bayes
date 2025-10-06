-- Provides a common interface contract for tokenizers. Subclasses should
-- extend this class and override the `tokenize_text` method with their
-- implementation.
--
-- Required override:
--   * `tokenize_text(text)` - accept raw text input and return an array-like table
--     of token strings suitable for classification.

class BaseTokenizer
  tokenize_text: (...) =>
    class_name = @__class and @__class.__name or "TokenizerBase"
    error "#{class_name} must implement tokenize_text(...)", 2
