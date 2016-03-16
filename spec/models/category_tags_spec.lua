local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Topics, Posts, CategoryTags
do
  local _obj_0 = require("community.models")
  Categories, Topics, Posts, CategoryTags = _obj_0.Categories, _obj_0.Topics, _obj_0.Posts, _obj_0.CategoryTags
end
local factory = require("spec.factory")
return describe("models.category_tags", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Categories, Topics, Posts, CategoryTags)
  end)
  return it("creates tag for category", function()
    local category = factory.Categories()
    local tag = CategoryTags:create({
      slug = "hello-world",
      category_id = category.id
    })
    assert.truthy(tag)
    local tags = category:get_tags()
    return assert.same(1, #tags)
  end)
end)
