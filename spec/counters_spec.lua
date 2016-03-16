local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Topics
Topics = require("community.models").Topics
local factory = require("spec.factory")
return describe("community.helpers.counters", function()
  use_test_env()
  return it("should bulk increment", function()
    truncate_tables(Users, Topics)
    local t1 = factory.Topics()
    local t2 = factory.Topics()
    local t3 = factory.Topics()
    local bulk_increment
    bulk_increment = require("community.helpers.counters").bulk_increment
    bulk_increment(Topics, "views_count", {
      {
        t1.id,
        1
      },
      {
        t2.id,
        2
      }
    })
    t1:refresh()
    t2:refresh()
    t3:refresh()
    assert.same(1, t1.views_count)
    assert.same(2, t2.views_count)
    return assert.same(0, t3.views_count)
  end)
end)
