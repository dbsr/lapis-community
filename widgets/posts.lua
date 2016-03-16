local Posts
do
  local _class_0
  local _parent_0 = require("widgets.base")
  local _base_0 = {
    inner_content = function(self)
      local _list_0 = self.posts
      for _index_0 = 1, #_list_0 do
        local post = _list_0[_index_0]
        self:render_post(post)
      end
    end,
    render_post = function(self, post)
      local vote_types = self.topic:available_vote_types()
      if post.deleted then
        div({
          class = "post deleted"
        }, function()
          return em("This post has been deleted")
        end)
      elseif post.block then
        div({
          class = "post deleted"
        }, function()
          em("You have blocked this user (" .. tostring(post.user:name_for_display()) .. ")")
          return form({
            action = self:url_for("unblock_user", {
              blocked_user_id = post.user_id
            }),
            method = "post"
          }, function()
            return button("Unblock")
          end)
        end)
      else
        div({
          class = "post"
        }, function()
          u(function()
            return a({
              href = self:url_for("post", {
                post_id = post.id
              })
            }, "#" .. tostring(post.post_number))
          end)
          text(" ")
          strong(post.user:name_for_display())
          text(" ")
          em(post.created_at)
          em(" (" .. tostring(post.id) .. ")")
          if post.parent_post_id then
            em(" (parent: " .. tostring(post.parent_post_id) .. ")")
          end
          if post.edits_count > 0 then
            em(" (" .. tostring(post.edits_count) .. " edits)")
          end
          if vote_types.up then
            em(" (+" .. tostring(post.up_votes_count) .. ")")
          end
          if vote_types.down then
            return em(" (-" .. tostring(post.down_votes_count) .. ")")
          end
        end)
        p(post.body)
        fieldset(function()
          legend("Post tools")
          if post:allowed_to_edit(self.current_user) then
            p(function()
              a({
                href = self:url_for("edit_post", {
                  post_id = post.id
                })
              }, "Edit")
              raw(" &middot; ")
              return a({
                href = self:url_for("delete_post", {
                  post_id = post.id
                })
              }, "Delete")
            end)
          end
          if self.current_user then
            return p(function()
              a({
                href = self:url_for("reply_post", {
                  post_id = post.id
                })
              }, "Reply")
              form({
                action = self:url_for("block_user", {
                  blocked_user_id = post.user_id
                }),
                method = "post"
              }, function()
                return button("Block")
              end)
              return form({
                action = self:url_for("vote_object", {
                  object_type = "post",
                  object_id = post.id
                }),
                method = "post"
              }, function()
                if vote_types.up then
                  button({
                    value = "up",
                    name = "direction"
                  }, "Upvote")
                end
                if vote_types.up and vote_types.down then
                  raw(" &middot; ")
                end
                if vote_types.down then
                  button({
                    value = "down",
                    name = "direction"
                  }, "Downvote")
                end
                do
                  local vote = post.vote
                  if vote then
                    if vote_types[vote:name()] then
                      text(" You voted " .. tostring(vote:name()))
                      raw(" &middot; ")
                      return button({
                        value = "remove",
                        name = "action"
                      }, "Remove")
                    end
                  end
                end
              end)
            end)
          end
        end)
      end
      if post.children and post.children[1] then
        blockquote(function()
          local _list_0 = post.children
          for _index_0 = 1, #_list_0 do
            local child = _list_0[_index_0]
            self:render_post(child)
          end
        end)
      end
      return hr()
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Posts",
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
  self.needs = {
    "posts",
    "topic"
  }
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Posts = _class_0
  return _class_0
end
