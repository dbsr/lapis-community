local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local PendingPosts, Categories, Topics, Posts
do
  local _obj_0 = require("community.models")
  PendingPosts, Categories, Topics, Posts = _obj_0.PendingPosts, _obj_0.Categories, _obj_0.Topics, _obj_0.Posts
end
local db = require("lapis.db")
local factory = require("spec.factory")
return describe("models.pending_posts", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Users, PendingPosts, Categories, Topics, Posts)
  end)
  it("creates a pending post", function()
    return factory.PendingPosts()
  end)
  it("promotes pending post", function()
    local pending = factory.PendingPosts()
    pending:promote()
    assert.same(1, Posts:count())
    return assert.same(0, PendingPosts:count())
  end)
  it("promotes pending post with topic and category being updated", function()
    local category = factory.Categories()
    local topic = factory.Topics({
      category_id = category.id
    })
    category:increment_from_topic(topic)
    local other_topic = factory.Topics({
      category_id = category.id
    })
    category:increment_from_topic(other_topic)
    local pending = factory.PendingPosts({
      topic_id = topic.id
    })
    local post = pending:promote()
    assert.same(1, Posts:count())
    assert.same(0, PendingPosts:count())
    topic:refresh()
    assert.same(post.id, topic.last_post_id)
    category:refresh()
    return assert.same(topic.id, category.last_topic_id)
  end)
  return it("promotes pending post with parent", function()
    local post = factory.Posts()
    local topic = post:get_topic()
    local pending = factory.PendingPosts({
      parent_post_id = post.id,
      topic_id = topic.id
    })
    pending:promote()
    assert.same(2, Posts:count())
    return assert.same(0, PendingPosts:count())
  end)
end)
