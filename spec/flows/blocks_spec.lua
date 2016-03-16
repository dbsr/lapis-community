local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Blocks
Blocks = require("community.models").Blocks
local TestApp
TestApp = require("spec.helpers").TestApp
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local factory = require("spec.factory")
local BlocksApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/block-user"] = capture_errors_json(function(self)
      self.flow:block_user()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/unblock-user"] = capture_errors_json(function(self)
      self.flow:unblock_user()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/show-blocks"] = capture_errors_json(function(self)
      local blocks = self.flow:show_blocks()
      return {
        json = {
          success = true,
          blocks = blocks
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
    __name = "BlocksApp",
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
    local BlocksFlow = require("community.flows.blocks")
    self.flow = BlocksFlow(self)
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BlocksApp = _class_0
end
return describe("blocks", function()
  use_test_env()
  local current_user
  before_each(function(self)
    truncate_tables(Users, Blocks)
    current_user = factory.Users()
  end)
  it("should block user", function()
    local other_user = factory.Users()
    local res = BlocksApp:get(current_user, "/block-user", {
      blocked_user_id = other_user.id
    })
    assert.truthy(res.success)
    local blocks = Blocks:select()
    assert.same(1, #blocks)
    local block = unpack(blocks)
    assert.same(current_user.id, block.blocking_user_id)
    return assert.same(other_user.id, block.blocked_user_id)
  end)
  it("should not error on double block", function()
    local other_user = factory.Users()
    factory.Blocks({
      blocking_user_id = current_user.id,
      blocked_user_id = other_user.id
    })
    return BlocksApp:get(current_user, "/block-user", {
      blocked_user_id = other_user.id
    })
  end)
  it("should unblock user", function()
    local other_user = factory.Users()
    factory.Blocks({
      blocking_user_id = current_user.id,
      blocked_user_id = other_user.id
    })
    local res = BlocksApp:get(current_user, "/unblock-user", {
      blocked_user_id = other_user.id
    })
    assert.truthy(res.success)
    local blocks = Blocks:select()
    return assert.same(0, #blocks)
  end)
  it("should not error on invalid unblock", function()
    local other_user = factory.Users()
    local res = BlocksApp:get(current_user, "/unblock-user", {
      blocked_user_id = other_user.id
    })
  end)
  return describe("show blocks", function()
    it("should get blocks when there are none", function()
      local res = BlocksApp:get(current_user, "/show-blocks")
      return assert.same({
        success = true,
        blocks = { }
      }, res)
    end)
    return it("should get blocks when there are some", function()
      for i = 1, 2 do
        factory.Blocks({
          blocking_user_id = current_user.id
        })
      end
      local res = BlocksApp:get(current_user, "/show-blocks")
      return assert.same(2, #res.blocks)
    end)
  end)
end)
