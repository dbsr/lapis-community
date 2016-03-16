local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Moderators
do
  local _obj_0 = require("community.models")
  Categories, Moderators = _obj_0.Categories, _obj_0.Moderators
end
local factory = require("spec.factory")
local mock_request
mock_request = require("lapis.spec.request").mock_request
local Application
Application = require("lapis").Application
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local TestApp
TestApp = require("spec.helpers").TestApp
local ModeratorsApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/add-moderator"] = capture_errors_json(function(self)
      self.flow:add_moderator()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/remove-moderator"] = capture_errors_json(function(self)
      self.flow:remove_moderator()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/accept-mod"] = capture_errors_json(function(self)
      self.flow:accept_moderator_position()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/show-mods"] = capture_errors_json(function(self)
      local moderators = self.flow:show_moderators()
      return {
        json = {
          success = true,
          moderators = moderators
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
    __name = "ModeratorsApp",
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
    local ModeratorsFlow = require("community.flows.moderators")
    self.flow = ModeratorsFlow(self)
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ModeratorsApp = _class_0
end
return describe("moderators flow", function()
  use_test_env()
  local current_user
  before_each(function()
    truncate_tables(Users, Moderators, Categories)
    current_user = factory.Users()
  end)
  describe("add_moderator", function()
    it("should fail to do anything with missing params", function()
      local res = ModeratorsApp:get(current_user, "/add-moderator", { })
      return assert.truthy(res.errors)
    end)
    it("should let category owner add moderator", function()
      local category = factory.Categories({
        user_id = current_user.id
      })
      local other_user = factory.Users()
      local res = ModeratorsApp:get(current_user, "/add-moderator", {
        object_type = "category",
        object_id = category.id,
        user_id = other_user.id
      })
      assert.falsy(res.errors)
      local mod = assert(unpack(Moderators:select()))
      assert.same(false, mod.accepted)
      assert.same(false, mod.admin)
      assert.same(other_user.id, mod.user_id)
      assert.same(category.id, mod.object_id)
      return assert.same(Moderators.object_types.category, mod.object_type)
    end)
    it("should not let category owner add self", function()
      local category = factory.Categories({
        user_id = current_user.id
      })
      local res = ModeratorsApp:get(current_user, "/add-moderator", {
        object_type = "category",
        object_id = category.id,
        user_id = current_user.id
      })
      return assert.truthy(res.errors)
    end)
    it("should not add owner", function()
      local owner = factory.Users()
      local category = factory.Categories({
        user_id = owner.id
      })
      factory.Moderators({
        object = category,
        user_id = current_user.id,
        admin = true
      })
      local other_user = factory.Users()
      local res = ModeratorsApp:get(current_user, "/add-moderator", {
        object_type = "category",
        object_id = category.id,
        user_id = owner.id
      })
      return assert.same({
        "already moderator"
      }, res.errors)
    end)
    it("should not existing moderator", function()
      local category = factory.Categories({
        user_id = current_user.id
      })
      local mod = factory.Moderators({
        object = category
      })
      local res = ModeratorsApp:get(current_user, "/add-moderator", {
        object_type = "category",
        object_id = category.id,
        user_id = mod.user_id
      })
      return assert.same({
        "already moderator"
      }, res.errors)
    end)
    it("should let category admin add moderator", function()
      local category = factory.Categories()
      factory.Moderators({
        object = category,
        user_id = current_user.id,
        admin = true
      })
      local other_user = factory.Users()
      local res = ModeratorsApp:get(current_user, "/add-moderator", {
        object_type = "category",
        object_id = category.id,
        user_id = other_user.id
      })
      assert.falsy(res.errors)
      local mod = assert(unpack(Moderators:select([[        where user_id != ?
      ]], current_user.id)))
      assert.same(false, mod.accepted)
      assert.same(false, mod.admin)
      assert.same(other_user.id, mod.user_id)
      assert.same(category.id, mod.object_id)
      return assert.same(Moderators.object_types.category, mod.object_type)
    end)
    it("should not let stranger add moderator", function()
      local category = factory.Categories()
      local other_user = factory.Users()
      local res = ModeratorsApp:get(current_user, "/add-moderator", {
        object_type = "category",
        object_id = category.id,
        user_id = other_user.id
      })
      assert.truthy(res.errors)
      return assert.same({ }, Moderators:select())
    end)
    return it("should not let non-admin moderator add moderator", function()
      local category = factory.Categories()
      factory.Moderators({
        object = category,
        user_id = current_user.id
      })
      local other_user = factory.Users()
      local res = ModeratorsApp:get(current_user, "/add-moderator", {
        object_type = "category",
        object_id = category.id,
        user_id = other_user.id
      })
      return assert.truthy(res.errors)
    end)
  end)
  describe("remove_moderator", function()
    it("should fail to do anything with missing params", function()
      local res = ModeratorsApp:get(current_user, "/remove-moderator", { })
      return assert.truthy(res.errors)
    end)
    it("should not let stranger remove moderator", function()
      local category = factory.Categories()
      local mod = factory.Moderators({
        object = category
      })
      local res = ModeratorsApp:get(current_user, "/remove-moderator", {
        object_type = "category",
        object_id = mod.object_id,
        user_id = mod.user_id
      })
      return assert.truthy(res.errors)
    end)
    it("should let category owner remove moderator", function()
      local category = factory.Categories({
        user_id = current_user.id
      })
      local mod = factory.Moderators({
        object = category
      })
      local res = ModeratorsApp:get(current_user, "/remove-moderator", {
        object_type = "category",
        object_id = mod.object_id,
        user_id = mod.user_id
      })
      assert.falsy(res.errors)
      return assert.same({ }, Moderators:select())
    end)
    it("should let category admin remove moderator", function()
      local category = factory.Categories()
      factory.Moderators({
        object = category,
        user_id = current_user.id,
        admin = true
      })
      local mod = factory.Moderators({
        object = category
      })
      local res = ModeratorsApp:get(current_user, "/remove-moderator", {
        object_type = "category",
        object_id = mod.object_id,
        user_id = mod.user_id
      })
      return assert.falsy(res.errors)
    end)
    it("should let (non admin/owner) moderator remove self", function()
      local mod = factory.Moderators({
        user_id = current_user.id
      })
      local res = ModeratorsApp:get(current_user, "/remove-moderator", {
        object_type = "category",
        object_id = mod.object_id,
        user_id = mod.user_id
      })
      assert.falsy(res.errors)
      return assert.same({ }, Moderators:select())
    end)
    return it("should not let non-admin moderator remove moderator", function()
      factory.Moderators({
        user_id = current_user.id
      })
      local mod = factory.Moderators()
      local res = ModeratorsApp:get(current_user, "/remove-moderator", {
        object_type = "category",
        object_id = mod.object_id,
        user_id = mod.user_id
      })
      return assert.truthy(res.errors)
    end)
  end)
  describe("accept_moderator_position", function()
    it("should do nothing for stranger", function()
      local mod = factory.Moderators({
        accepted = false
      })
      local res = ModeratorsApp:get(current_user, "/accept-mod", {
        object_type = "category",
        object_id = mod.object_id
      })
      assert.truthy(res.errors)
      mod:refresh()
      return assert.same(false, mod.accepted)
    end)
    it("should accept moderator position", function()
      local mod = factory.Moderators({
        accepted = false,
        user_id = current_user.id
      })
      local res = ModeratorsApp:get(current_user, "/accept-mod", {
        object_type = "category",
        object_id = mod.object_id
      })
      assert.falsy(res.errors)
      mod:refresh()
      return assert.same(true, mod.accepted)
    end)
    return it("should reject moderator position", function()
      local mod = factory.Moderators({
        accepted = false,
        user_id = current_user.id
      })
      local res = ModeratorsApp:get(current_user, "/remove-moderator", {
        object_type = "category",
        object_id = mod.object_id,
        user_id = mod.user_id,
        current_user_id = current_user.id
      })
      assert.falsy(res.errors)
      return assert.same({ }, Moderators:select())
    end)
  end)
  return describe("show moderators", function()
    it("should get moderators when there are none", function()
      local category = factory.Categories()
      local res = ModeratorsApp:get(current_user, "/show-mods", {
        object_type = "category",
        object_id = category.id
      })
      return assert.same({
        success = true,
        moderators = { }
      }, res)
    end)
    return it("should get moderators when there are some", function()
      local category = factory.Categories()
      factory.Moderators()
      for i = 1, 2 do
        factory.Moderators({
          object = category
        })
      end
      local res = ModeratorsApp:get(current_user, "/show-mods", {
        object_type = "category",
        object_id = category.id
      })
      assert.falsy(res.errors)
      return assert.same(2, #res.moderators)
    end)
  end)
end)
