local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Votes, Posts, Topics, Categories, CommunityUsers
do
  local _obj_0 = require("community.models")
  Votes, Posts, Topics, Categories, CommunityUsers = _obj_0.Votes, _obj_0.Posts, _obj_0.Topics, _obj_0.Categories, _obj_0.CommunityUsers
end
local factory = require("spec.factory")
local Application
Application = require("lapis").Application
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local TestApp
TestApp = require("spec.helpers").TestApp
local VotesFlow = require("community.flows.votes")
local VotingApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/vote"] = capture_errors_json(function(self)
      VotesFlow(self):vote()
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
    __name = "VotingApp",
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
  self:before_filter(function(self)
    self.current_user = Users:find(assert(self.params.current_user_id, "missing user id"))
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  VotingApp = _class_0
end
return describe("votes flow", function()
  use_test_env()
  local current_user
  before_each(function()
    truncate_tables(Users, Votes, Posts, Topics, Categories, CommunityUsers)
    current_user = factory.Users()
  end)
  it("should vote on a post", function()
    local post = factory.Posts()
    local res = VotingApp:get(current_user, "/vote", {
      object_type = "post",
      object_id = post.id,
      direction = "up"
    })
    assert.same({
      success = true
    }, res)
    local vote = assert(unpack(Votes:select()))
    assert.same(post.id, vote.object_id)
    assert.same(Votes.object_types.post, vote.object_type)
    assert.same(current_user.id, vote.user_id)
    assert.same(true, vote.positive)
    post:refresh()
    assert.same(1, post.up_votes_count)
    assert.same(0, post.down_votes_count)
    local cu = CommunityUsers:for_user(current_user)
    return assert.same(1, cu.votes_count)
  end)
  it("should update a vote with no changes", function()
    local post = factory.Posts()
    local res = VotingApp:get(current_user, "/vote", {
      object_type = "post",
      object_id = post.id,
      direction = "up"
    })
    assert.same({
      success = true
    }, res)
    res = VotingApp:get(current_user, "/vote", {
      object_type = "post",
      object_id = post.id,
      direction = "up"
    })
    assert.same({
      success = true
    }, res)
    local vote = assert(unpack(Votes:select()))
    assert.same(post.id, vote.object_id)
    assert.same(Votes.object_types.post, vote.object_type)
    assert.same(current_user.id, vote.user_id)
    assert.same(true, vote.positive)
    post:refresh()
    assert.same(1, post.up_votes_count)
    assert.same(0, post.down_votes_count)
    local cu = CommunityUsers:for_user(current_user)
    return assert.same(1, cu.votes_count)
  end)
  it("should update a vote", function()
    local vote = factory.Votes({
      user_id = current_user.id
    })
    local res = VotingApp:get(current_user, "/vote", {
      object_type = "post",
      object_id = vote.object_id,
      direction = "down"
    })
    local votes = Votes:select()
    assert.same(1, #votes)
    local new_vote = unpack(votes)
    assert.same(false, new_vote.positive)
    local post = Posts:find(new_vote.object_id)
    assert.same(0, post.up_votes_count)
    assert.same(1, post.down_votes_count)
    local cu = CommunityUsers:for_user(current_user)
    return assert.same(0, cu.votes_count)
  end)
  return it("should remove vote on post", function()
    local post = factory.Posts()
    local _, vote = Votes:vote(post, current_user)
    local res = VotingApp:get(current_user, "/vote", {
      object_type = "post",
      object_id = post.id,
      action = "remove"
    })
    assert.same(0, #Votes:select())
    post:refresh()
    assert.same(0, post.up_votes_count)
    assert.same(0, post.up_votes_count)
    local cu = CommunityUsers:for_user(current_user)
    return assert.same(-1, cu.votes_count)
  end)
end)
