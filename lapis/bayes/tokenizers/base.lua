local BaseTokenizer
do
  local _class_0
  local _base_0 = {
    tokenize_text = function(self, ...)
      local class_name = self.__class and self.__class.__name or "TokenizerBase"
      return error(tostring(class_name) .. " must implement tokenize_text(...)", 2)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "BaseTokenizer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BaseTokenizer = _class_0
  return _class_0
end
