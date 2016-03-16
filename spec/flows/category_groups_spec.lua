local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local factory = require("spec.factory")
local TestApp
TestApp = require("spec.helpers").TestApp
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local Users
Users = require("models").Users
local Categories, CategoryGroups, CategoryGroupCategories
do
  local _obj_0 = require("community.models")
  Categories, CategoryGroups, CategoryGroupCategories = _obj_0.Categories, _obj_0.CategoryGroups, _obj_0.CategoryGroupCategories
end
local CategoryGroupApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/show-categories"] = capture_errors_json(function(self)
      self.flow:show_categories()
      return {
        json = {
          success = true,
          categories = self.categories
        }
      }
    end),
    ["/new"] = capture_errors_json(function(self)
      self.flow:new_category_group()
      return {
        json = {
          success = true,
          categories = self.categories
        }
      }
    end),
    ["/edit"] = capture_errors_json(function(self)
      self.flow:edit_category_group()
      return {
        json = {
          success = true,
          categories = self.categories
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
    __name = "CategoryGroupApp",
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
    local CategoryGroupsFlow = require("community.flows.category_groups")
    self.flow = CategoryGroupsFlow(self)
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  CategoryGroupApp = _class_0
end
return describe("category groups flow", function()
  use_test_env()
  local current_user
  before_each(function()
    truncate_tables(Users, Categories, CategoryGroups, CategoryGroupCategories)
    current_user = factory.Users()
  end)
  it("should show categories", function()
    local group = factory.CategoryGroups()
    group:add_category(factory.Categories())
    local res = CategoryGroupApp:get(current_user, "/show-categories", {
      category_group_id = group.id
    })
    assert.falsy(res.errors)
    return assert.same(1, #res.categories)
  end)
  it("should create new category group", function()
    local res = CategoryGroupApp:get(current_user, "/new", {
      ["category_group[title]"] = ""
    })
    assert.falsy(res.errors)
    return assert.same(1, #CategoryGroups:select())
  end)
  return it("should edit category group", function()
    local group = factory.CategoryGroups({
      user_id = current_user.id,
      description = "yeah"
    })
    local res = CategoryGroupApp:get(current_user, "/edit", {
      category_group_id = group.id,
      ["category_group[rules]"] = "follow the rules!"
    })
    assert.falsy(res.errors)
    assert.same(1, #CategoryGroups:select())
    group:refresh()
    assert.same("follow the rules!", group.rules)
    return assert.falsy(group.description)
  end)
end)
