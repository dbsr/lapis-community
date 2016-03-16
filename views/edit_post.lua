local EditPost
do
  local _class_0
  local _parent_0 = require("widgets.base")
  local _base_0 = {
    inner_content = function(self)
      if self.topic then
        p(function()
          return a({
            href = self:url_for("topic", {
              topic_id = self.topic.id
            })
          }, "Return to topic")
        end)
      end
      h1(function()
        if self.editing then
          return text("Edit post")
        else
          if self.parent_post then
            return text("Reply to post")
          else
            return text("New post")
          end
        end
      end)
      self:render_errors()
      form({
        method = "post"
      }, function()
        if self.parent_post then
          input({
            type = "hidden",
            name = "parent_post_id",
            value = self.parent_post.id
          })
        end
        if self.editing and self.post:is_topic_post() and not self.topic.permanent then
          div(function()
            return label(function()
              strong("Title")
              return input({
                type = "text",
                name = "post[title]",
                value = self.topic and self.topic.title
              })
            end)
          end)
        end
        div(function()
          return label(function()
            strong("Body")
            return textarea({
              name = "post[body]"
            }, self.post and self.post.body or nil)
          end)
        end)
        return button(function()
          if self.editing then
            return text("Save")
          else
            return text("Post")
          end
        end)
      end)
      if self.parent_post then
        hr()
        h3("Replying to")
        p(self.parent_post.body)
        local user = self.parent_post:get_user()
        p(function()
          return em(self.parent_post.created_at)
        end)
        return p(function()
          return a({
            href = self:url_for("user", {
              user_id = user.id
            })
          }, user:name_for_display())
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
    __name = "EditPost",
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
  EditPost = _class_0
  return _class_0
end
