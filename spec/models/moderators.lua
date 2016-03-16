local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Moderators, Posts, Topics
do
  local _obj_0 = require("community.models")
  Categories, Moderators, Posts, Topics = _obj_0.Categories, _obj_0.Moderators, _obj_0.Posts, _obj_0.Topics
end
local factory = require("spec.factory")
return describe("models.moderators", function()
  use_test_env()
  local current_user, mod
  before_each(function()
    truncate_tables(Users, Categories, Moderators, Posts, Topics)
    current_user = factory.Users()
    mod = factory.Moderators({
      user_id = current_user.id
    })
  end)
  it("gets all moderators for category", function()
    local category = mod:get_object()
    return assert.same({
      current_user.id
    }, (function()
      local _accum_0 = { }
      local _len_0 = 1
      local _list_0 = category:get_moderators()
      for _index_0 = 1, #_list_0 do
        local m = _list_0[_index_0]
        _accum_0[_len_0] = m.user_id
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
  end)
  it("gets moderator for category", function()
    local category = mod:get_object()
    mod = category:find_moderator(current_user)
    assert.truthy(mod)
    assert.same(category.id, mod.object_id)
    assert.same(Moderators.object_types.category, mod.object_type)
    return assert.same(current_user.id, mod.user_id)
  end)
  it("lets moderator edit post in category", function()
    local topic = factory.Topics({
      category_id = mod.object_id
    })
    local post = factory.Posts({
      topic_id = topic.id
    })
    return assert.truthy(post:allowed_to_edit(current_user))
  end)
  return it("doesn't let moderator edit post other category", function()
    local post = factory.Posts()
    return assert.falsy(post:allowed_to_edit(current_user))
  end)
end)
