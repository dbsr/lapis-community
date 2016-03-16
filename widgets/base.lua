local Widget
Widget = require("lapis.html").Widget
local underscore, time_ago_in_words
do
  local _obj_0 = require("lapis.util")
  underscore, time_ago_in_words = _obj_0.underscore, _obj_0.time_ago_in_words
end
local random
random = math.random
local Base
do
  local _class_0
  local _parent_0 = Widget
  local _base_0 = {
    base_widget = true,
    inner_content = function(self) end,
    content = function(self, fn)
      if fn == nil then
        fn = self.inner_content
      end
      local classes = self:widget_classes()
      local inner
      if self.base_widget then
        classes = classes .. " base_widget"
      end
      self._opts = {
        class = classes,
        function()
          return raw(inner)
        end
      }
      if self.js_init then
        self:widget_id()
        self:content_for("js_init", function()
          return raw(self:js_init())
        end)
      end
      inner = capture(function()
        return fn(self)
      end)
      return element(self.elm_type or "div", self._opts)
    end,
    widget_classes = function(self)
      return self.css_class or self.__class:widget_name()
    end,
    widget_id = function(self)
      if not (self._widget_id) then
        self._widget_id = tostring(self.__class:widget_name()) .. "_" .. tostring(random(0, 100000))
        if self._opts then
          self._opts.id = self._opts.id or self._widget_id
        end
      end
      return self._widget_id
    end,
    widget_selector = function(self)
      return "'#" .. tostring(self:widget_id()) .. "'"
    end,
    render_errors = function(self)
      if not (self.errors and next(self.errors)) then
        return 
      end
      h3("There was an errror")
      return ul(function()
        local _list_0 = self.errors
        for _index_0 = 1, #_list_0 do
          local e = _list_0[_index_0]
          li(e)
        end
      end)
    end,
    dump = function(self, thing)
      return pre(require("moon").dump(thing))
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Base",
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
  self.widget_name = function(self)
    return underscore(self.__name or "some_widget")
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Base = _class_0
  return _class_0
end
