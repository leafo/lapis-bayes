local BaseTrainer
do
  local _class_0
  local _base_0 = {
    normalize_tokens = function(self, tokens)
      if self.opts.filter_tokens then
        tokens = self.opts.filter_tokens(tokens, self.opts)
      end
      local merged = { }
      if tokens then
        for k, v in pairs(tokens) do
          local word, count
          if type(k) == "string" then
            word, count = k, v
          else
            word, count = v, 1
          end
          local _update_0 = word
          merged[_update_0] = merged[_update_0] or 0
          local _update_1 = word
          merged[_update_1] = merged[_update_1] + count
        end
      end
      return merged
    end,
    select_tokens = function(self, target_name, tokens)
      return error(tostring(self.__class.__name) .. ": select_tokens: subclass must implement")
    end,
    train_text = function(self, target_name, text)
      local tokens = self.classifier:tokenize_text(text)
      local selected, stats = self:select_tokens(target_name, tokens)
      local Categories
      Categories = require("lapis.bayes.models").Categories
      local target = Categories:find_or_create(target_name)
      local written
      if next(selected) then
        written = target:increment_words(selected)
      else
        written = 0
      end
      return written, stats
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.opts = opts
      self.categories = assert(self.opts.categories, tostring(self.__class.__name) .. ": missing categories")
      self.classifier = self.opts.classifier
      if not (self.classifier) then
        local DefaultClassifier = require("lapis.bayes.classifiers.default")
        self.classifier = DefaultClassifier(self.opts)
      end
    end,
    __base = _base_0,
    __name = "BaseTrainer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BaseTrainer = _class_0
  return _class_0
end
