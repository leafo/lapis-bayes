local MarginalValueTrainer
do
  local _class_0
  local _base_0 = {
    get_contrast = function(self, target_name)
      local a, b = unpack(self.categories)
      if target_name == a then
        return b
      elseif target_name == b then
        return a
      else
        return error("MarginalValueTrainer: target '" .. tostring(target_name) .. "' is not in configured categories {" .. tostring(a) .. ", " .. tostring(b) .. "}")
      end
    end,
    should_train_token = function(self, target_count, contrast_count)
      local n = target_count + contrast_count
      if n == 0 then
        return self.train_novel
      end
      if n < self.min_observations then
        return true
      end
      local p_target = target_count / n
      if p_target >= self.saturation_threshold then
        return false
      elseif p_target <= (1 - self.saturation_threshold) then
        return self.train_opposite
      else
        return true
      end
    end,
    train_text = function(self, target_name, text)
      local contrast_name = self:get_contrast(target_name)
      local tokens = self.classifier:tokenize_text(text)
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
      local stats = {
        total = 0,
        kept = 0,
        skipped_saturated = 0,
        skipped_novel = 0,
        kept_novel = 0,
        kept_opposite = 0,
        kept_uncertain = 0,
        kept_low_obs = 0
      }
      if not (next(merged)) then
        return 0, stats
      end
      local Categories
      Categories = require("lapis.bayes.models").Categories
      local target = Categories:find_or_create(target_name)
      local contrast = Categories:find({
        name = contrast_name
      })
      local target_counts = { }
      local contrast_counts = { }
      if contrast then
        local words
        do
          local _accum_0 = { }
          local _len_0 = 1
          for w in pairs(merged) do
            _accum_0[_len_0] = w
            _len_0 = _len_0 + 1
          end
          words = _accum_0
        end
        local wcs = self.classifier:find_word_classifications(words, {
          target.id,
          contrast.id
        })
        for _index_0 = 1, #wcs do
          local wc = wcs[_index_0]
          if wc.category_id == target.id then
            target_counts[wc.word] = wc.count
          elseif wc.category_id == contrast.id then
            contrast_counts[wc.word] = wc.count
          end
        end
      end
      local filtered = { }
      for word, count in pairs(merged) do
        stats.total = stats.total + 1
        local t = target_counts[word] or 0
        local c = contrast_counts[word] or 0
        local n = t + c
        local bucket
        if n == 0 then
          bucket = self.train_novel and "kept_novel" or "skipped_novel"
        elseif n < self.min_observations then
          bucket = "kept_low_obs"
        else
          local p_target = t / n
          if p_target >= self.saturation_threshold then
            bucket = "skipped_saturated"
          elseif p_target <= (1 - self.saturation_threshold) then
            bucket = self.train_opposite and "kept_opposite" or "skipped_saturated"
          else
            bucket = "kept_uncertain"
          end
        end
        local _update_0 = bucket
        stats[_update_0] = stats[_update_0] + 1
        if bucket:match("^kept_") then
          filtered[word] = count
          stats.kept = stats.kept + 1
        end
      end
      local written
      if next(filtered) then
        written = target:increment_words(filtered)
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
      self.categories = assert(self.opts.categories, "MarginalValueTrainer: missing categories")
      assert(#self.categories == 2, "MarginalValueTrainer: categories must be a list of exactly 2 names")
      self.saturation_threshold = self.opts.saturation_threshold or 0.95
      self.min_observations = self.opts.min_observations or 30
      if self.opts.train_novel ~= nil then
        self.train_novel = self.opts.train_novel
      else
        self.train_novel = true
      end
      if self.opts.train_opposite ~= nil then
        self.train_opposite = self.opts.train_opposite
      else
        self.train_opposite = true
      end
      self.classifier = self.opts.classifier
      if not (self.classifier) then
        local DefaultClassifier = require("lapis.bayes.classifiers.default")
        self.classifier = DefaultClassifier(self.opts)
      end
    end,
    __base = _base_0,
    __name = "MarginalValueTrainer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  MarginalValueTrainer = _class_0
  return _class_0
end
