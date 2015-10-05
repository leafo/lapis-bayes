local db = require("lapis.db")
local Model
Model = require("lapis.bayes.model").Model
local delete_and_return
delete_and_return = function(self)
  local res = db.query("\n    delete from " .. tostring(db.escape_identifier(self.__class:table_name())) .. "\n    where " .. tostring(db.encode_clause(self:_primary_cond())) .. "\n    returning *\n  ")
  if res.affected_rows and res.affected_rows > 0 then
    return self.__class:load(unpack(res))
  else
    return false
  end
end
local WordClassifications
do
  local _parent_0 = Model
  local _base_0 = {
    delete = function(self)
      do
        local deleted = delete_and_return(self)
        if deleted then
          local Categories
          Categories = require("lapis.bayes.models").Categories
          db.update(Categories:table_name(), {
            total_count = db.raw(db.interpolate_query(" total_count - ?", deleted.count))
          }, {
            id = self.category_id
          })
          return true
        end
      end
    end,
    increment = function(self, amount)
      amount = assert(tonumber(amount), "expecting number")
      return self:update({
        count = db.raw("count + " .. tostring(amount))
      })
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "WordClassifications",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.primary_key = {
    "category_id",
    "word"
  }
  self.relations = {
    {
      "category",
      belongs_to = "Categories"
    }
  }
  self.find_or_create = function(self, opts)
    if opts == nil then
      opts = { }
    end
    return self:find(opts) or self:create(opts)
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  WordClassifications = _class_0
  return _class_0
end
