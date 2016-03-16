local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Votes, Posts, Topics
do
  local _obj_0 = require("community.models")
  Votes, Posts, Topics = _obj_0.Votes, _obj_0.Posts, _obj_0.Topics
end
local factory = require("spec.factory")
return describe("models.votes", function()
  use_test_env()
  local current_user
  before_each(function()
    truncate_tables(Users, Topics, Posts)
    current_user = factory.Users()
  end)
  it("should create vote for post", function()
    local post = factory.Posts()
    return Votes:create({
      object = post,
      user_id = current_user.id,
      positive = false
    })
  end)
  return it("should vote on object", function()
    local post = factory.Posts()
    Votes:vote(post, current_user, true)
    post:refresh()
    assert.same(1, post.up_votes_count)
    assert.same(0, post.down_votes_count)
    Votes:vote(post, current_user, true)
    post:refresh()
    assert.same(1, post.up_votes_count)
    assert.same(0, post.down_votes_count)
    Votes:vote(post, current_user, false)
    post:refresh()
    assert.same(0, post.up_votes_count)
    return assert.same(1, post.down_votes_count)
  end)
end)
