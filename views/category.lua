local Category
do
  local _class_0
  local _parent_0 = require("widgets.base")
  local _base_0 = {
    inner_content = function(self)
      h1(self.category.title)
      if self.user then
        p(function()
          text("Created by ")
          return a({
            href = self:url_for("user", {
              user_id = self.user.id
            })
          }, self.user:name_for_display())
        end)
      end
      ul(function()
        li(function()
          return a({
            href = self:url_for("new_topic", {
              category_id = self.category.id
            })
          }, "New topic")
        end)
        if self.category:allowed_to_edit(self.current_user) then
          li(function()
            return a({
              href = self:url_for("edit_category", {
                category_id = self.category.id
              })
            }, "Edit category")
          end)
        end
        if self.category:allowed_to_moderate(self.current_user) then
          li(function()
            return a({
              href = self:url_for("category_moderators", {
                category_id = self.category.id
              })
            }, "Moderators")
          end)
          return li(function()
            return a({
              href = self:url_for("category_members", {
                category_id = self.category.id
              })
            }, "Members")
          end)
        end
      end)
      h3("Topics")
      p(function()
        strong("Count")
        text(" ")
        return text(self.category.topics_count)
      end)
      if self.sticky_topics and next(self.sticky_topics) then
        self:render_topics(self.sticky_topics)
      end
      return self:render_topics(self.topics)
    end,
    render_topics = function(self, topics)
      element("table", {
        border = "1"
      }, function()
        thead(function()
          return tr(function()
            td("L")
            td("S")
            td("id")
            td("Title")
            td("Poster")
            td("Posts")
            td("Posted")
            td("Views")
            return td("Last post")
          end)
        end)
        for _index_0 = 1, #topics do
          local topic = topics[_index_0]
          tr(function()
            td(function()
              if topic.locked then
                return raw("&#x2713;")
              end
            end)
            td(function()
              if topic.sticky then
                return raw("&#x2713;")
              end
            end)
            td(topic.id)
            td(function()
              text("(" .. tostring(topic.category_order) .. ") ")
              return (topic:has_unread(self.current_user) and strong or span)(function()
                return a({
                  href = self:url_for("topic", {
                    topic_id = topic.id
                  })
                }, topic.title)
              end)
            end)
            td(function()
              return a({
                href = self:url_for("user", {
                  user_id = topic.user.id
                })
              }, topic.user:name_for_display())
            end)
            td(tostring(topic.posts_count))
            td(topic.created_at)
            td(topic.views_count)
            return td(function()
              do
                local seen = topic.user_topic_last_seen
                if seen then
                  text("(seen " .. tostring(seen.post_id) .. ") ")
                end
              end
              text(topic.last_post_id)
              text(" ")
              do
                local last_post = topic.last_post
                if last_post then
                  text("by ")
                  a({
                    href = self:url_for("user", {
                      user_id = last_post.user.id
                    })
                  }, last_post.user:name_for_display())
                  text(" on ")
                  return text(last_post.created_at)
                end
              end
            end)
          end)
        end
      end)
      return p(function()
        local cat_opts = {
          category_id = self.category.id
        }
        if self.next_page then
          a({
            href = self:url_for("category", cat_opts, self.next_page),
            "Next page"
          })
          text(" ")
        end
        if self.prev_page then
          a({
            href = self:url_for("category", cat_opts, self.prev_page),
            "Previous page"
          })
          text(" ")
          a({
            href = self:url_for("category", cat_opts),
            "First page"
          })
          return text(" ")
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
    __name = "Category",
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
  Category = _class_0
  return _class_0
end
