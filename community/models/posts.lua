local db = require("lapis.db")
local Model
Model = require("community.model").Model
local Posts
do
  local _parent_0 = Model
  local _base_0 = {
    get_mentioned_users = function(self)
      if not (self.mentioned_users) then
        local usernames = self.__class:_parse_usernames(self.body)
        local Users
        Users = require("models").Users
        self.mentioned_users = Users:find_all(usernames, {
          key = "username"
        })
      end
      return self.mentioned_users
    end,
    filled_body = function(self, r)
      local body = self.body
      do
        local m = self:get_mentioned_users()
        if m then
          local mentions_by_username
          do
            local _tbl_0 = { }
            for _index_0 = 1, #m do
              local u = m[_index_0]
              _tbl_0[u.username] = u
            end
            mentions_by_username = _tbl_0
          end
          local escape
          escape = require("lapis.html").escape
          body = body:gsub("@([%w-_]+)", function(username)
            local user = mentions_by_username[username]
            if not (user) then
              return "@" .. tostring(username)
            end
            return "<a href='" .. tostring(escape(r:build_url(r:url_for(user)))) .. "'>@" .. tostring(escape(user:name_for_display())) .. "</a>"
          end)
        end
      end
      return body
    end,
    is_topic_post = function(self)
      return self.post_number == 1 and self.depth == 1
    end,
    allowed_to_vote = function(self, user, direction)
      if not (user) then
        return false
      end
      if self.deleted then
        return false
      end
      local topic = self:get_topic()
      local category = self.topic:get_category()
      if category then
        return category:allowed_to_vote(user, direction)
      else
        return true
      end
    end,
    allowed_to_edit = function(self, user)
      if not (user) then
        return false
      end
      if user:is_admin() then
        return true
      end
      if user.id == self.user_id then
        return true
      end
      if self.deleted then
        return false
      end
      local topic = self:get_topic()
      if topic:allowed_to_moderate(user) then
        return true
      end
      return false
    end,
    allowed_to_reply = function(self, user)
      if not (user) then
        return false
      end
      local topic = self:get_topic()
      return topic:allowed_to_post(user)
    end,
    delete = function(self)
      local soft_delete
      soft_delete = require("community.helpers.models").soft_delete
      if soft_delete(self) then
        self:update({
          deleted_at = db.format_date()
        }, {
          timestamp = false
        })
        local CommunityUsers, Topics
        do
          local _obj_0 = require("community.models")
          CommunityUsers, Topics = _obj_0.CommunityUsers, _obj_0.Topics
        end
        CommunityUsers:for_user(self:get_user()):increment("posts_count", -1)
        Topics:load({
          id = self.topic_id
        }):update({
          deleted_posts_count = db.raw("deleted_posts_count + 1")
        }, {
          timestamp = false
        })
        return true
      end
    end,
    allowed_to_report = function(self, user)
      if not (user) then
        return false
      end
      if user.id == self.user_id then
        return false
      end
      if not (self:allowed_to_view(user)) then
        return false
      end
      return true
    end,
    allowed_to_view = function(self, user)
      return self:get_topic():allowed_to_view(user)
    end,
    notification_targets = function(self, extra_targets)
      local targets = { }
      local _list_0 = self:get_mentioned_users()
      for _index_0 = 1, #_list_0 do
        local user = _list_0[_index_0]
        targets[user.id] = targets[user.id] or {
          "mention",
          user.id
        }
      end
      do
        local parent = self:get_parent_post()
        if parent then
          targets[parent.user_id] = {
            "reply",
            parent:get_user()
          }
        end
      end
      local topic = self:get_topic()
      local _list_1 = topic:notification_target_users()
      for _index_0 = 1, #_list_1 do
        local target_user = _list_1[_index_0]
        targets[target_user.id] = targets[target_user.id] or {
          "post",
          target_user,
          topic
        }
      end
      do
        local category = self:is_topic_post() and topic:get_category()
        if category then
          local _list_2 = category:notification_target_users()
          for _index_0 = 1, #_list_2 do
            local target_user = _list_2[_index_0]
            targets[target_user.id] = targets[target_user.id] or {
              "topic",
              target_user,
              category,
              topic
            }
          end
          local category_group = category:get_category_group()
          if category_group then
            local _list_3 = category_group:notification_target_users()
            for _index_0 = 1, #_list_3 do
              local target_user = _list_3[_index_0]
              targets[target_user.id] = targets[target_user.id] or {
                "topic",
                target_user,
                category_group,
                topic
              }
            end
          end
        end
      end
      if extra_targets then
        for _index_0 = 1, #extra_targets do
          local t = extra_targets[_index_0]
          local user = t[2]
          targets[user.id] = targets[user.id] or t
        end
      end
      targets[self.user_id] = nil
      local _accum_0 = { }
      local _len_0 = 1
      for _, v in pairs(targets) do
        _accum_0[_len_0] = v
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end,
    find_ancestor_posts = function(self)
      if self.depth == 1 then
        return { }
      end
      local tname = db.escape_identifier(self.__class:table_name())
      local res = db.query("\n      with recursive nested as (\n        (select * from " .. tostring(tname) .. " where id = ?)\n        union\n        select pr.* from " .. tostring(tname) .. " pr, nested\n          where pr.id = nested.parent_post_id\n      )\n      select * from nested\n    ", self.parent_post_id)
      for _index_0 = 1, #res do
        local post = res[_index_0]
        self.__class:load(post)
      end
      table.sort(res, function(a, b)
        return a.depth > b.depth
      end)
      return res
    end,
    find_root_ancestor = function(self)
      local ancestors = self:find_ancestor_posts()
      return ancestors[#ancestors]
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Posts",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
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
  self.timestamp = true
  self.relations = {
    {
      "topic",
      belongs_to = "Topics"
    },
    {
      "user",
      belongs_to = "Users"
    },
    {
      "parent_post",
      belongs_to = "Posts"
    }
  }
  self.create = function(self, opts)
    if opts == nil then
      opts = { }
    end
    assert(opts.topic_id, "missing topic id")
    assert(opts.user_id, "missing user id")
    assert(opts.body, "missing body")
    local parent
    do
      local id = opts.parent_post_id
      if id then
        parent = self:find(id)
      else
        do
          local _with_0 = opts.parent_post
          opts.parent_post = nil
          parent = _with_0
        end
      end
    end
    if parent then
      assert(parent.topic_id == opts.topic_id, "invalid parent (" .. tostring(parent.topic_id) .. " != " .. tostring(opts.topic_id) .. ")")
      opts.depth = parent.depth + 1
      opts.parent_post_id = parent.id
    else
      opts.depth = 1
    end
    local number_cond = {
      topic_id = opts.topic_id,
      depth = opts.depth,
      parent_post_id = opts.parent_post_id or db.NULL
    }
    local post_number = db.interpolate_query("\n     (select coalesce(max(post_number), 0) from " .. tostring(db.escape_identifier(self:table_name())) .. "\n       where " .. tostring(db.encode_clause(number_cond)) .. ") + 1\n    ")
    opts.post_number = db.raw(post_number)
    return Model.create(self, opts)
  end
  self.preload_mentioned_users = function(self, posts)
    local Users
    Users = require("models").Users
    local all_usernames = { }
    local usernames_by_post = { }
    for _index_0 = 1, #posts do
      local post = posts[_index_0]
      local usernames = self:_parse_usernames(post.body)
      if next(usernames) then
        usernames_by_post[post.id] = usernames
        for _index_1 = 1, #usernames do
          local u = usernames[_index_1]
          table.insert(all_usernames, u)
        end
      end
    end
    local users = Users:find_all(all_usernames, {
      key = "username"
    })
    local users_by_username
    do
      local _tbl_0 = { }
      for _index_0 = 1, #users do
        local u = users[_index_0]
        _tbl_0[u.username] = u
      end
      users_by_username = _tbl_0
    end
    for _index_0 = 1, #posts do
      local post = posts[_index_0]
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = usernames_by_post[post.id] or { }
        for _index_1 = 1, #_list_0 do
          local _continue_0 = false
          repeat
            local uname = _list_0[_index_1]
            if not (users_by_username[uname]) then
              _continue_0 = true
              break
            end
            local _value_0 = users_by_username[uname]
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        post.mentioned_users = _accum_0
      end
    end
    return posts
  end
  self._parse_usernames = function(self, body)
    local _accum_0 = { }
    local _len_0 = 1
    for username in body:gmatch("@([%w-_]+)") do
      _accum_0[_len_0] = username
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
  local _ = false
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Posts = _class_0
  return _class_0
end
