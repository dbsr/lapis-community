local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local CommunityUsers
CommunityUsers = require("community.models").CommunityUsers
local factory = require("spec.factory")
return describe("models.users", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Users, CommunityUsers)
  end)
  return it("should create a user", function()
    return factory.Users()
  end)
end)
