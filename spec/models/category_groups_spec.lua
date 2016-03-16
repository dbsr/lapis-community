local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, CategoryGroups, CategoryGroupCategories
do
  local _obj_0 = require("community.models")
  Categories, CategoryGroups, CategoryGroupCategories = _obj_0.Categories, _obj_0.CategoryGroups, _obj_0.CategoryGroupCategories
end
local factory = require("spec.factory")
return describe("models.category_groups", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Categories, CategoryGroups, CategoryGroupCategories)
  end)
  it("should create category group", function()
    local group = factory.CategoryGroups()
    group:refresh()
    return assert.same(0, group.categories_count)
  end)
  return describe("with group", function()
    local group
    before_each(function()
      group = factory.CategoryGroups()
    end)
    it("adds a category to a group", function()
      local category = factory.Categories()
      group:add_category(category)
      assert.same(1, group.categories_count)
      category:refresh()
      assert.same(1, category.category_groups_count)
      local gs = group:get_category_group_categories_paginated():get_page()
      assert.same(1, #gs)
      local g = unpack(gs)
      assert.same(category.id, g.category_id)
      assert.same(group.id, g.category_group_id)
      group:add_category(category)
      group:refresh()
      assert.same(1, group.categories_count)
      category:refresh()
      assert.same(1, category.category_groups_count)
      local c_group = category:get_category_group()
      return assert.same(group.id, c_group.id)
    end)
    it("removes a category from group", function()
      local category = factory.Categories()
      group:add_category(category)
      assert.same(1, group.categories_count)
      group:remove_category(category)
      group:refresh()
      assert.same(0, group.categories_count)
      category:refresh()
      assert.same(0, category.category_groups_count)
      local gs = group:get_category_group_categories_paginated():get_page()
      assert.same({ }, gs)
      return group:remove_category(category)
    end)
    it("sets categories", function()
      local category1 = factory.Categories()
      local category2 = factory.Categories()
      group:add_category(category1)
      group:set_categories({
        category2
      })
      local cats
      do
        local _tbl_0 = { }
        local _list_0 = CategoryGroupCategories:select()
        for _index_0 = 1, #_list_0 do
          local cgc = _list_0[_index_0]
          _tbl_0[cgc.category_id] = true
        end
        cats = _tbl_0
      end
      return assert.same({
        [category2.id] = true
      }, cats)
    end)
    return it("gets categories", function()
      local category1 = factory.Categories()
      local category2 = factory.Categories()
      local category3 = factory.Categories()
      group:add_category(category1)
      group:add_category(category2)
      local categories = group:get_categories_paginated():get_all()
      local category_ids
      do
        local _tbl_0 = { }
        for _index_0 = 1, #categories do
          local c = categories[_index_0]
          _tbl_0[c.id] = true
        end
        category_ids = _tbl_0
      end
      return assert.same({
        [category1.id] = true,
        [category2.id] = true
      }, category_ids)
    end)
  end)
end)
