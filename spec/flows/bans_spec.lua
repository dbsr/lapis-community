local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Bans, Categories, ModerationLogs, ModerationLogObjects, CategoryGroups
do
  local _obj_0 = require("community.models")
  Bans, Categories, ModerationLogs, ModerationLogObjects, CategoryGroups = _obj_0.Bans, _obj_0.Categories, _obj_0.ModerationLogs, _obj_0.ModerationLogObjects, _obj_0.CategoryGroups
end
local TestApp
TestApp = require("spec.helpers").TestApp
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local factory = require("spec.factory")
local BansApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/ban"] = capture_errors_json(function(self)
      self.flow:create_ban()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/unban"] = capture_errors_json(function(self)
      self.flow:delete_ban()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/show-bans"] = capture_errors_json(function(self)
      self.flow:show_bans()
      return {
        json = {
          success = true,
          bans = self.bans
        }
      }
    end)
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "BansApp",
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
  self:require_user()
  self:before_filter(function(self)
    local BansFlow = require("community.flows.bans")
    self.flow = BansFlow(self)
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BansApp = _class_0
end
local CategoryBansApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/:category_id/ban"] = capture_errors_json(function(self)
      self.bans_flow:create_ban()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/:category_id/unban"] = capture_errors_json(function(self)
      self.bans_flow:delete_ban()
      return {
        json = {
          success = true
        }
      }
    end)
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "CategoryBansApp",
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
  self:require_user()
  self:before_filter(function(self)
    local CategoriesFlow = require("community.flows.categories")
    self.flow = CategoriesFlow(self)
    self.bans_flow = self.flow:bans_flow()
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  CategoryBansApp = _class_0
end
return describe("bans", function()
  use_test_env()
  local current_user
  before_each(function(self)
    truncate_tables(Users, Bans, Categories, ModerationLogs, ModerationLogObjects)
    current_user = factory.Users()
  end)
  local assert_log_contains_user
  assert_log_contains_user = function(log, user)
    local objs = log:get_log_objects()
    assert.same(1, #objs)
    assert.same(ModerationLogObjects.object_types.user, objs[1].object_type)
    return assert.same(user.id, objs[1].object_id)
  end
  describe("with category", function()
    local category
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id
      })
    end)
    it("should ban user from category", function()
      local other_user = factory.Users()
      local res = BansApp:get(current_user, "/ban", {
        object_type = "category",
        object_id = category.id,
        banned_user_id = other_user.id,
        reason = [[ this user ]]
      })
      assert.truthy(res.success)
      local bans = Bans:select()
      assert.same(1, #bans)
      local ban = unpack(bans)
      assert.same(other_user.id, ban.banned_user_id)
      assert.same(current_user.id, ban.banning_user_id)
      assert.same(category.id, ban.object_id)
      assert.same(Bans.object_types.category, ban.object_type)
      assert.same("this user", ban.reason)
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(category.id, log.category_id)
      assert.same(category.id, log.object_id)
      assert.same(ModerationLogs.object_types.category, log.object_type)
      assert.same("category.ban", log.action)
      assert.same("this user", log.reason)
      return assert_log_contains_user(log, other_user)
    end)
    it("should not let unrelated user ban", function()
      local other_user = factory.Users()
      local res = BansApp:get(other_user, "/ban", {
        object_type = "category",
        object_id = category.id,
        banned_user_id = current_user.id,
        reason = [[ this user ]]
      })
      return assert.same({
        errors = {
          "invalid permissions"
        }
      }, res)
    end)
    it("should unban user", function()
      local other_user = factory.Users()
      factory.Bans({
        object = category,
        banned_user_id = other_user.id
      })
      local res = BansApp:get(current_user, "/unban", {
        object_type = "category",
        object_id = category.id,
        banned_user_id = other_user.id
      })
      assert.falsy(res.errors)
      assert.same(0, #Bans:select())
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(category.id, log.category_id)
      assert.same(category.id, log.object_id)
      assert.same(ModerationLogs.object_types.category, log.object_type)
      assert.same("category.unban", log.action)
      return assert_log_contains_user(log, other_user)
    end)
    it("shows bans when there are no bans", function()
      local res = BansApp:get(current_user, "/show-bans", {
        object_type = "category",
        object_id = category.id
      })
      assert.falsy(res.errors)
      return assert.same({ }, res.bans)
    end)
    return it("shows bans", function()
      for i = 1, 2 do
        factory.Bans({
          object = category
        })
      end
      local res = BansApp:get(current_user, "/show-bans", {
        object_type = "category",
        object_id = category.id
      })
      assert.falsy(res.errors)
      return assert.same(2, #res.bans)
    end)
  end)
  describe("with topic", function()
    local topic
    before_each(function()
      local category = factory.Categories({
        user_id = current_user.id
      })
      topic = factory.Topics({
        category_id = category.id
      })
    end)
    it("should ban user from topic", function()
      local other_user = factory.Users()
      local res = BansApp:get(current_user, "/ban", {
        object_type = "topic",
        object_id = topic.id,
        banned_user_id = other_user.id,
        reason = [[ this user ]]
      })
      assert.truthy(res.success)
      local bans = Bans:select()
      assert.same(1, #bans)
      local ban = unpack(bans)
      assert.same(other_user.id, ban.banned_user_id)
      assert.same(current_user.id, ban.banning_user_id)
      assert.same(topic.id, ban.object_id)
      assert.same(Bans.object_types.topic, ban.object_type)
      assert.same("this user", ban.reason)
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(topic.category_id, log.category_id)
      assert.same(topic.id, log.object_id)
      assert.same(ModerationLogs.object_types.topic, log.object_type)
      assert.same("topic.ban", log.action)
      assert.same("this user", log.reason)
      return assert_log_contains_user(log, other_user)
    end)
    return it("should unban user", function()
      local other_user = factory.Users()
      factory.Bans({
        object = topic,
        banned_user_id = other_user.id
      })
      local res = BansApp:get(current_user, "/unban", {
        object_type = "topic",
        object_id = topic.id,
        banned_user_id = other_user.id
      })
      assert.falsy(res.errors)
      assert.same(0, #Bans:select())
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(topic.category_id, log.category_id)
      assert.same(topic.id, log.object_id)
      assert.same(ModerationLogs.object_types.topic, log.object_type)
      assert.same("topic.unban", log.action)
      return assert_log_contains_user(log, other_user)
    end)
  end)
  describe("with category group", function()
    local category_group
    before_each(function()
      truncate_tables(CategoryGroups)
      category_group = factory.CategoryGroups({
        user_id = current_user.id
      })
    end)
    it("bans user from category group", function()
      local user = factory.Users()
      local res = BansApp:get(current_user, "/ban", {
        object_type = "category_group",
        object_id = category_group.id,
        banned_user_id = user.id,
        reason = "get rid of this thing"
      })
      assert["true"](res.success)
      local bans = Bans:select()
      assert.same(1, #bans)
      local ban = unpack(bans)
      assert.same(user.id, ban.banned_user_id)
      assert.same(current_user.id, ban.banning_user_id)
      assert.same(category_group.id, ban.object_id)
      return assert.same(Bans.object_types.category_group, ban.object_type)
    end)
    return it("unbans user from category group", function()
      local user = factory.Users()
      factory.Bans({
        object = category_group,
        banned_user_id = user.id
      })
      local res = BansApp:get(current_user, "/unban", {
        object_type = "category_group",
        object_id = category_group.id,
        banned_user_id = user.id
      })
      assert["true"](res.success)
      return assert.same(0, Bans:count())
    end)
  end)
  return describe("cateogry bans flow", function()
    local category
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id
      })
    end)
    it("bans user", function()
      local banned_user = factory.Users()
      local res = CategoryBansApp:get(current_user, "/" .. tostring(category.id) .. "/ban", {
        banned_user_id = banned_user.id,
        reason = [[ this user ]]
      })
      assert.same({
        success = true
      }, res)
      local ban = unpack(Bans:select())
      assert.same(banned_user.id, ban.banned_user_id)
      local _list_0 = ModerationLogs:select()
      for _index_0 = 1, #_list_0 do
        local log = _list_0[_index_0]
        assert.same(category.id, log.category_id)
      end
    end)
    return it("unbans user", function()
      local banned_user = factory.Users()
      factory.Bans({
        object = category,
        banned_user_id = banned_user.id
      })
      local res = CategoryBansApp:get(current_user, "/" .. tostring(category.id) .. "/unban", {
        banned_user_id = banned_user.id
      })
      assert.same({
        success = true
      }, res)
      assert.same(0, Bans:count())
      local _list_0 = ModerationLogs:select()
      for _index_0 = 1, #_list_0 do
        local log = _list_0[_index_0]
        assert.same(category.id, log.category_id)
      end
    end)
  end)
end)
