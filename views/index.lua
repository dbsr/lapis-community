local Categories
Categories = require("community.models").Categories
local Index
do
  local _class_0
  local _parent_0 = require("widgets.base")
  local _base_0 = {
    inner_content = function(self)
      h1("Index")
      if self.current_user then
        p(function()
          text("You are logged in as ")
          return strong(self.current_user:name_for_display())
        end)
      end
      ul(function()
        if self.current_user then
          return li(function()
            return a({
              href = self:url_for("new_category")
            }, "Create category")
          end)
        else
          li(function()
            return a({
              href = self:url_for("register")
            }, "Register")
          end)
          return li(function()
            return a({
              href = self:url_for("login")
            }, "Login")
          end)
        end
      end)
      h2("Categories")
      element("table", {
        border = 1
      }, function()
        thead(function()
          return tr(function()
            td("Category")
            td("Type")
            td("Topics count")
            td("Creator")
            return td("Last topic")
          end)
        end)
        local _list_0 = self.categories
        for _index_0 = 1, #_list_0 do
          local cat = _list_0[_index_0]
          tr(function()
            td(function()
              return a({
                href = self:url_for("category", {
                  category_id = cat.id
                })
              }, cat.title)
            end)
            td(Categories.membership_types[cat.membership_type])
            td(cat.topics_count)
            td(function()
              do
                local user = cat:get_user()
                if user then
                  return a({
                    href = self:url_for("user", {
                      user_id = user.id
                    })
                  }, user:name_for_display())
                end
              end
            end)
            return td(function()
              do
                local topic = cat:get_last_topic()
                if topic then
                  return a({
                    href = self:url_for("topic", {
                      topic_id = topic.id
                    })
                  }, topic.title)
                end
              end
            end)
          end)
        end
      end)
      if not (next(self.categories)) then
        return p(function()
          return em("There are no categories")
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
    __name = "Index",
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
  Index = _class_0
  return _class_0
end
