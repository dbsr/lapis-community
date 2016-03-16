local Users
Users = require("models").Users
local mock_request
mock_request = require("lapis.spec.request").mock_request
local Application
Application = require("lapis").Application
local assert = require("luassert")
local filter_bans
filter_bans = function(thing, ...)
  if not (thing) then
    return 
  end
  thing.user_bans = nil
  if thing.category or thing.topic then
    local rest = {
      ...
    }
    if thing.category then
      table.insert(rest, thing.category)
    end
    if thing.topic then
      table.insert(rest, thing.topic)
    end
    return thing, filter_bans(unpack(rest))
  else
    return thing, filter_bans(...)
  end
end
local TestApp
do
  local _class_0
  local _parent_0 = Application
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "TestApp",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  self.require_user = function(self)
    return self:before_filter(function(self)
      self.current_user = Users:find(assert(self.params.current_user_id, "missing user id"))
    end)
  end
  self.get = function(self, user, path, get)
    if get == nil then
      get = { }
    end
    if user then
      get.current_user_id = get.current_user_id or user.id
    end
    local status, res = mock_request(self, path, {
      get = get,
      expect = "json"
    })
    assert.same(200, status)
    return res
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TestApp = _class_0
end
return {
  TestApp = TestApp,
  filter_bans = filter_bans
}
