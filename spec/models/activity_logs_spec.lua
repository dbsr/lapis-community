local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Topics, Posts, ActivityLogs
do
  local _obj_0 = require("community.models")
  Categories, Topics, Posts, ActivityLogs = _obj_0.Categories, _obj_0.Topics, _obj_0.Posts, _obj_0.ActivityLogs
end
local factory = require("spec.factory")
return describe("models.activity_logs", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Users, Categories, Topics, Posts, ActivityLogs)
  end)
  it("should create activity log for post", function()
    local post = factory.Posts()
    local log = ActivityLogs:create({
      user_id = post.user_id,
      object = post,
      action = "create",
      data = {
        world = "cool"
      }
    })
    return assert.same("create", log:action_name())
  end)
  return it("should create activity log for topic", function()
    local topic = factory.Topics()
    local log = ActivityLogs:create({
      user_id = topic.user_id,
      object = topic,
      action = "delete"
    })
    return assert.same("delete", log:action_name())
  end)
end)
