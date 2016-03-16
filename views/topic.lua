local Posts = require("widgets.posts")
local Topic
do
  local _class_0
  local _parent_0 = require("widgets.base")
  local _base_0 = {
    inner_content = function(self)
      if self.topic.category_id then
        a({
          href = self:url_for("category", {
            category_id = self.topic:get_category().id
          })
        }, self.topic:get_category().title)
      end
      h1(self.topic.title)
      p(function()
        strong("Post count")
        text(" ")
        return text(self.topic.posts_count)
      end)
      if self.topic.locked then
        fieldset(function()
          local log = self.topic:get_lock_log()
          p(function()
            return em("This topic is locked")
          end)
          self:moderation_log_data(log)
          if self.topic:allowed_to_moderate(self.current_user) then
            return form({
              action = self:url_for("unlock_topic", {
                topic_id = self.topic.id
              }),
              method = "post"
            }, function()
              return button("Unlock")
            end)
          end
        end)
      end
      if self.topic.sticky then
        fieldset(function()
          local log = self.topic:get_sticky_log()
          p(function()
            return em("This topic is sticky")
          end)
          self:moderation_log_data(log)
          if self.topic:allowed_to_moderate(self.current_user) then
            return form({
              action = self:url_for("unstick_topic", {
                topic_id = self.topic.id
              }),
              method = "post"
            }, function()
              return button("Unstick")
            end)
          end
        end)
      end
      ul(function()
        if not (self.topic.locked) then
          li(function()
            return a({
              href = self:url_for("new_post", {
                topic_id = self.topic.id
              })
            }, "Reply")
          end)
        end
        if self.topic:allowed_to_moderate(self.current_user) then
          if not (self.topic.locked) then
            li(function()
              return a({
                href = self:url_for("lock_topic", {
                  topic_id = self.topic.id
                })
              }, "Lock")
            end)
          end
          if not (self.topic.sticky) then
            return li(function()
              return a({
                href = self:url_for("stick_topic", {
                  topic_id = self.topic.id
                })
              }, "Stick")
            end)
          end
        end
      end)
      self:pagination()
      hr()
      widget(Posts())
      return self:pagination()
    end,
    pagination = function(self)
      local topic_opts = {
        topic_id = self.topic.id
      }
      if self.next_page then
        a({
          href = self:url_for("topic", topic_opts, self.next_page),
          "Next page"
        })
      end
      text(" ")
      if self.prev_page then
        return a({
          href = self:url_for("topic", topic_opts, self.prev_page),
          "Previous page"
        })
      end
    end,
    moderation_log_data = function(self, log)
      if not (log) then
        return 
      end
      local log_user = log:get_user()
      return p(function()
        em("By " .. tostring(log_user:name_for_display()) .. " on " .. tostring(log.created_at))
        if log.reason then
          return em(": " .. tostring(log.reason))
        end
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
    __name = "Topic",
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
  Topic = _class_0
  return _class_0
end
