local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Topics, Posts, ModerationLogs, ModerationLogObjects
do
  local _obj_0 = require("community.models")
  Categories, Topics, Posts, ModerationLogs, ModerationLogObjects = _obj_0.Categories, _obj_0.Topics, _obj_0.Posts, _obj_0.ModerationLogs, _obj_0.ModerationLogObjects
end
local TestApp
TestApp = require("spec.helpers").TestApp
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local factory = require("spec.factory")
local TopicsApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/lock-topic"] = capture_errors_json(function(self)
      self.flow:lock_topic()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/unlock-topic"] = capture_errors_json(function(self)
      self.flow:unlock_topic()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/stick-topic"] = capture_errors_json(function(self)
      self.flow:stick_topic()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/unstick-topic"] = capture_errors_json(function(self)
      self.flow:unstick_topic()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/archive-topic"] = capture_errors_json(function(self)
      self.flow:archive_topic()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/unarchive-topic"] = capture_errors_json(function(self)
      self.flow:unarchive_topic()
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
    __name = "TopicsApp",
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
    local TopicsFlow = require("community.flows.topics")
    self.flow = TopicsFlow(self)
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TopicsApp = _class_0
end
return describe("topics", function()
  use_test_env()
  local current_user, topic
  before_each(function()
    truncate_tables(Users, Categories, Topics, Posts, ModerationLogs, ModerationLogObjects)
    current_user = factory.Users()
    local category = factory.Categories({
      user_id = current_user.id
    })
    topic = factory.Topics({
      category_id = category.id
    })
  end)
  describe("lock", function()
    it("should lock topic", function()
      local res = TopicsApp:get(current_user, "/lock-topic", {
        topic_id = topic.id,
        reason = "this topic is stupid"
      })
      assert.truthy(res.success)
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(ModerationLogs.object_types.topic, log.object_type)
      assert.same(topic.id, log.object_id)
      assert.same("topic.lock", log.action)
      assert.same("this topic is stupid", log.reason)
      assert.same(topic.category_id, log.category_id)
      return assert.same(0, #ModerationLogObjects:select())
    end)
    it("should unlock topic", function()
      topic:update({
        locked = true
      })
      local res = TopicsApp:get(current_user, "/unlock-topic", {
        topic_id = topic.id
      })
      assert.truthy(res.success)
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(ModerationLogs.object_types.topic, log.object_type)
      assert.same(topic.id, log.object_id)
      assert.same("topic.unlock", log.action)
      assert.same(topic.category_id, log.category_id)
      return assert.same(0, #ModerationLogObjects:select())
    end)
    it("should not let random user lock topic", function()
      local res = TopicsApp:get(factory.Users(), "/lock-topic", {
        topic_id = topic.id
      })
      return assert.truthy(res.errors)
    end)
    return it("should not let random user unlock topic", function()
      topic:update({
        locked = true
      })
      local res = TopicsApp:get(factory.Users(), "/unlock-topic", {
        topic_id = topic.id
      })
      return assert.truthy(res.errors)
    end)
  end)
  describe("stick", function()
    it("should stick topic", function()
      local res = TopicsApp:get(current_user, "/stick-topic", {
        topic_id = topic.id,
        reason = " this topic is great and important "
      })
      assert["nil"](res.errors)
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(ModerationLogs.object_types.topic, log.object_type)
      assert.same(topic.id, log.object_id)
      assert.same("topic.stick", log.action)
      assert.same("this topic is great and important", log.reason)
      assert.same(topic.category_id, log.category_id)
      return assert.same(0, #ModerationLogObjects:select())
    end)
    return it("should unstick topic", function()
      topic:update({
        sticky = true
      })
      local res = TopicsApp:get(current_user, "/unstick-topic", {
        topic_id = topic.id
      })
      assert["nil"](res.errors)
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(ModerationLogs.object_types.topic, log.object_type)
      assert.same(topic.id, log.object_id)
      assert.same("topic.unstick", log.action)
      assert.same(topic.category_id, log.category_id)
      return assert.same(0, #ModerationLogObjects:select())
    end)
  end)
  return describe("archive", function()
    it("archives topic", function()
      local res = TopicsApp:get(current_user, "/archive-topic", {
        topic_id = topic.id,
        reason = "NOW ARCHIVED "
      })
      assert["nil"](res.errors)
      topic:refresh()
      assert["true"](topic:is_archived())
      local logs = ModerationLogs:select()
      assert.same(1, #logs)
      local log = unpack(logs)
      assert.same(current_user.id, log.user_id)
      assert.same(ModerationLogs.object_types.topic, log.object_type)
      assert.same(topic.id, log.object_id)
      assert.same("topic.archive", log.action)
      assert.same("NOW ARCHIVED", log.reason)
      assert.same(topic.category_id, log.category_id)
      return assert.same(0, #ModerationLogObjects:select())
    end)
    return it("unarchives topic", function()
      topic:archive()
      local res = TopicsApp:get(current_user, "/unarchive-topic", {
        topic_id = topic.id
      })
      assert["nil"](res.errors)
      topic:refresh()
      return assert["false"](topic:is_archived())
    end)
  end)
end)
