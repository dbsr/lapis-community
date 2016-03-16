local use_test_env
use_test_env = require("lapis.spec").use_test_env
local request
request = require("lapis.spec.server").request
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Bookmarks, Topics
do
  local _obj_0 = require("community.models")
  Bookmarks, Topics = _obj_0.Bookmarks, _obj_0.Topics
end
local factory = require("spec.factory")
return describe("models.bookmarks", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Topics, Users, Bookmarks)
  end)
  return it("create a bookmark", function()
    local user = factory.Users()
    local topic = factory.Topics()
    return assert(Bookmarks:create({
      user_id = user.id,
      object_type = "topic",
      object_id = topic.id
    }))
  end)
end)
