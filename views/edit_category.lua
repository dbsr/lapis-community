local Categories
Categories = require("community.models").Categories
local EditCategory
do
  local _class_0
  local _parent_0 = require("widgets.base")
  local _base_0 = {
    inner_content = function(self)
      h1(function()
        if self.editing then
          return text("Editing category: " .. tostring(self.category.title))
        else
          return text("New category")
        end
      end)
      self:render_errors()
      return form({
        method = "post"
      }, function()
        div(function()
          return label(function()
            strong("Title")
            return input({
              type = "text",
              name = "category[title]",
              value = self.category and self.category.title
            })
          end)
        end)
        div(function()
          return label(function()
            strong("Short description")
            return input({
              type = "text",
              name = "category[short_description]",
              value = self.category and self.category.short_description
            })
          end)
        end)
        div(function()
          return label(function()
            strong("Description")
            return textarea({
              name = "category[description]"
            }, self.category and self.category.description)
          end)
        end)
        strong("Membership type")
        self:radio_buttons("category[membership_type]", Categories.membership_types, self.category and self.category:get_membership_type())
        strong("Voting type")
        self:radio_buttons("category[voting_type]", Categories.voting_types, self.category and self.category:get_voting_type())
        return button(function()
          if self.editing then
            return text("Save")
          else
            return text("New category")
          end
        end)
      end)
    end,
    radio_buttons = function(self, name, enum, val)
      for _index_0 = 1, #enum do
        local key = enum[_index_0]
        div(function()
          return label(function()
            input({
              type = "radio",
              name = name,
              value = key,
              checked = enum[key] == val and "checked" or nil
            })
            return text(" " .. tostring(key))
          end)
        end)
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "EditCategory",
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
  EditCategory = _class_0
  return _class_0
end
