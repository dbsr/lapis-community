local db = require("lapis.db")
local enum
enum = require("lapis.db.model").enum
local Model
Model = require("community.model").Model
local slugify
slugify = require("lapis.util").slugify
local Categories
do
  local _parent_0 = Model
  local _base_0 = {
    get_category_group = function(self)
      do
        local cgc = self:get_category_group_category()
        if cgc then
          return cgc:get_category_group()
        end
      end
    end,
    allowed_to_post = function(self, user)
      if not (user) then
        return false
      end
      if self.archived then
        return false
      end
      if self.hidden then
        return false
      end
      return self:allowed_to_view(user)
    end,
    allowed_to_view = function(self, user)
      if self.hidden then
        return false
      end
      local can_view
      local _exp_0 = self.__class.membership_types[self.membership_type]
      if "public" == _exp_0 then
        can_view = true
      elseif "members_only" == _exp_0 then
        if not (user) then
          return false
        end
        if self:allowed_to_moderate(user) then
          return true
        end
        can_view = self:is_member(user)
      end
      if can_view then
        if self:find_ban(user) then
          return false
        end
      end
      return can_view
    end,
    allowed_to_vote = function(self, user, direction)
      if not (user) then
        return false
      end
      if direction == "remove" then
        return true
      end
      local _exp_0 = self.voting_type
      if self.__class.voting_types.up_down == _exp_0 then
        return true
      elseif self.__class.voting_types.up == _exp_0 then
        return direction == "up"
      else
        return false
      end
    end,
    allowed_to_edit = function(self, user)
      if not (user) then
        return nil
      end
      if user:is_admin() then
        return true
      end
      if user.id == self.user_id then
        return true
      end
      return false
    end,
    allowed_to_edit_moderators = function(self, user)
      if not (user) then
        return nil
      end
      if user:is_admin() then
        return true
      end
      if user.id == self.user_id then
        return true
      end
      do
        local mod = self:find_moderator(user)
        if mod then
          if mod.accepted and mod.admin then
            return true
          end
        end
      end
      return false
    end,
    allowed_to_edit_members = function(self, user)
      if not (user) then
        return nil
      end
      return self:allowed_to_moderate(user)
    end,
    allowed_to_moderate = function(self, user, ignore_admin)
      if ignore_admin == nil then
        ignore_admin = false
      end
      if not (user) then
        return nil
      end
      if not ignore_admin and user:is_admin() then
        return true
      end
      if user.id == self.user_id then
        return true
      end
      do
        local mod = self:find_moderator(user)
        if mod then
          if mod.accepted then
            return true
          end
        end
      end
      do
        local group = self:get_category_group()
        if group then
          if group:allowed_to_moderate(user) then
            return true
          end
        end
      end
      return false
    end,
    find_moderator = function(self, user)
      if not (user) then
        return nil
      end
      local Moderators
      Moderators = require("community.models").Moderators
      return Moderators:find({
        object_type = Moderators.object_types.category,
        object_id = self.id,
        user_id = user.id
      })
    end,
    is_member = function(self, user)
      local member = self:find_member(user)
      return member and member.accepted
    end,
    find_member = function(self, user)
      if not (user) then
        return nil
      end
      local CategoryMembers
      CategoryMembers = require("community.models").CategoryMembers
      return CategoryMembers:find({
        category_id = self.id,
        user_id = user.id
      })
    end,
    find_ban = function(self, user)
      if not (user) then
        return nil
      end
      local Bans
      Bans = require("community.models").Bans
      return Bans:find_for_object(self, user)
    end,
    get_order_ranges = function(self)
      local Topics
      Topics = require("community.models").Topics
      local res = db.query("\n      select sticky, min(category_order), max(category_order)\n      from " .. tostring(db.escape_identifier(Topics:table_name())) .. "\n      where category_id = ? and not deleted\n      group by sticky\n    ", self.id)
      local ranges = {
        sticky = { },
        regular = { }
      }
      for _index_0 = 1, #res do
        local _des_0 = res[_index_0]
        local sticky, min, max
        sticky, min, max = _des_0.sticky, _des_0.min, _des_0.max
        local r = ranges[sticky and "sticky" or "regular"]
        r.min = min
        r.max = max
      end
      return ranges
    end,
    available_vote_types = function(self)
      local _exp_0 = self.voting_type
      if self.__class.voting_types.up_down == _exp_0 then
        return {
          up = true,
          down = true
        }
      elseif self.__class.voting_types.up == _exp_0 then
        return {
          up = true
        }
      else
        return { }
      end
    end,
    refresh_last_topic = function(self)
      local Topics
      Topics = require("community.models").Topics
      return self:update({
        last_topic_id = db.raw(db.interpolate_query("(\n        select id from " .. tostring(db.escape_identifier(Topics:table_name())) .. " where category_id = ? and not deleted\n        order by category_order desc\n        limit 1\n      )", self.id))
      }, {
        timestamp = false
      })
    end,
    increment_from_topic = function(self, topic)
      assert(topic.category_id == self.id)
      return self:update({
        topics_count = db.raw("topics_count + 1"),
        last_topic_id = topic.id
      }, {
        timestamp = false
      })
    end,
    increment_from_post = function(self, post)
      return self:update({
        last_topic_id = post.topic_id
      }, {
        timestamp = false
      })
    end,
    notification_target_users = function(self)
      return {
        self:get_user()
      }
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Categories",
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
  self.membership_types = enum({
    public = 1,
    members_only = 2
  })
  self.voting_types = enum({
    up_down = 1,
    up = 2,
    disabled = 3
  })
  self.relations = {
    {
      "moderators",
      has_many = "Moderators",
      key = "object_id",
      where = {
        accepted = true,
        object_type = 1
      }
    },
    {
      "category_group_category",
      has_one = "CategoryGroupCategories"
    },
    {
      "user",
      belongs_to = "Users"
    },
    {
      "last_topic",
      belongs_to = "Topics"
    }
  }
  self.create = function(self, opts)
    if opts == nil then
      opts = { }
    end
    assert(opts.title, "missing title")
    opts.membership_type = self.membership_types:for_db(opts.membership_type or "public")
    opts.voting_type = self.voting_types:for_db(opts.voting_type or "up_down")
    opts.slug = opts.slug or slugify(opts.title)
    return Model.create(self, opts)
  end
  self.preload_last_topics = function(self, categories)
    local Topics
    Topics = require("community.models").Topics
    return Topics:include_in(categories, "last_topic_id", {
      as = "last_topic"
    })
  end
  self.recount = function(self)
    local Topics
    Topics = require("community.models").Topics
    return db.update(self:table_name(), {
      topics_count = db.raw("\n        (select count(*) from " .. tostring(db.escape_identifier(Topics:table_name())) .. "\n          where category_id = " .. tostring(db.escape_identifier(self:table_name())) .. ".id)\n      ")
    })
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Categories = _class_0
  return _class_0
end