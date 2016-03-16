local NewTopic
do
  local _class_0
  local _parent_0 = require("widgets.base")
  local _base_0 = {
    inner_content = function(self)
      h1("New topic")
      self:render_errors()
      return form({
        method = "post"
      }, function()
        div(function()
          return label(function()
            strong("Title")
            return input({
              type = "text",
              name = "topic[title]"
            })
          end)
        end)
        div(function()
          return label(function()
            strong("Body")
            return textarea({
              name = "topic[body]"
            })
          end)
        end)
        if self.category:allowed_to_moderate(self.current_user) then
          div(function()
            return label(function()
              input({
                type = "checkbox",
                name = "topic[sticky]"
              })
              return text(" Sticky")
            end)
          end)
          div(function()
            return label(function()
              input({
                type = "checkbox",
                name = "topic[locked]"
              })
              return text(" Locked")
            end)
          end)
        end
        return button("New topic")
      end)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "NewTopic",
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  NewTopic = _class_0
  return _class_0
end
