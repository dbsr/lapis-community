local CategoryModerators
do
  local _class_0
  local _parent_0 = require("widgets.base")
  local _base_0 = {
    inner_content = function(self)
      h2(function()
        a({
          href = self:url_for("category", {
            category_id = self.category.id
          })
        }, self.category.title)
        return text(" moderators")
      end)
      ul(function()
        if self.category:allowed_to_edit_moderators(self.current_user) then
          return li(function()
            return a({
              href = self:url_for("category_new_moderator", {
                category_id = self.category.id
              })
            }, "New moderator")
          end)
        end
      end)
      element("table", {
        border = 1
      }, function()
        thead(function()
          return tr(function()
            td("Moderator")
            td("Accepted")
            td("Admin")
            td("Accept url")
            return td("Remove")
          end)
        end)
        local _list_0 = self.moderators
        for _index_0 = 1, #_list_0 do
          local mod = _list_0[_index_0]
          local user = mod:get_user()
          tr(function()
            td(function()
              return a({
                href = self:url_for("user", {
                  user_id = user.id
                })
              }, user:name_for_display())
            end)
            td(function()
              if mod.accepted then
                return raw("&#x2713;")
              end
            end)
            td(function()
              if mod.admin then
                return raw("&#x2713;")
              end
            end)
            td(function()
              if mod.accepted then
                return 
              end
              return a({
                href = self:url_for("category_accept_moderator", {
                  category_id = self.category.id
                })
              }, "Link")
            end)
            return td(function()
              return form({
                action = self:url_for("category_remove_moderator", {
                  category_id = self.category.id,
                  user_id = user.id
                }),
                method = "post"
              }, function()
                return button("Remove")
              end)
            end)
          end)
        end
      end)
      if not (next(self.moderators)) then
        return p(function()
          return em("There are no moderators")
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
    __name = "CategoryModerators",
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
  CategoryModerators = _class_0
  return _class_0
end
