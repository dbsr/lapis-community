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
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local TestApp
TestApp = require("spec.helpers").TestApp
local BookmarksFlow = require("community.flows.bookmarks")
local filter_bans
filter_bans = require("spec.helpers").filter_bans
local BookmarksApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/show-topics"] = capture_errors_json(function(self)
      BookmarksFlow(self):show_topic_bookmarks()
      filter_bans(unpack(self.topics))
      return {
        json = {
          success = true,
          topics = self.topics
        }
      }
    end),
    ["/save"] = capture_errors_json(function(self)
      BookmarksFlow(self):save_bookmark()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/remove"] = capture_errors_json(function(self)
      BookmarksFlow(self):remove_bookmark()
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
    __name = "BookmarksApp",
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
  self:require_user()
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BookmarksApp = _class_0
end
return describe("flows.bookmarks", function()
  use_test_env()
  local current_user
  before_each(function()
    truncate_tables(Topics, Users, Bookmarks)
    current_user = factory.Users()
  end)
  describe("show #ddd", function()
    it("fetches empty topic list", function()
      local res = BookmarksApp:get(current_user, "/show-topics")
      return assert.same({
        success = true,
        topics = { }
      }, res)
    end)
    return it("fetches topic with bookmark", function()
      local other_topic = factory.Topics()
      Bookmarks:save(other_topic, factory.Users())
      local topics
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = 1, 2 do
          do
            local topic = factory.Topics()
            Bookmarks:save(topic, current_user)
            _accum_0[_len_0] = topic
          end
          _len_0 = _len_0 + 1
        end
        topics = _accum_0
      end
      local res = BookmarksApp:get(current_user, "/show-topics")
      return assert.same((function()
        local _tbl_0 = { }
        for _index_0 = 1, #topics do
          local t = topics[_index_0]
          _tbl_0[t.id] = true
        end
        return _tbl_0
      end)(), (function()
        local _tbl_0 = { }
        local _list_0 = res.topics
        for _index_0 = 1, #_list_0 do
          local t = _list_0[_index_0]
          _tbl_0[t.id] = true
        end
        return _tbl_0
      end)())
    end)
  end)
  it("should save a bookmark", function()
    local topic = factory.Topics()
    BookmarksApp:get(current_user, "/save", {
      object_type = "topic",
      object_id = topic.id
    })
    assert.same(1, Bookmarks:count())
    local bookmark = unpack(Bookmarks:select())
    assert.same(Bookmarks.object_types.topic, bookmark.object_type)
    assert.same(topic.id, bookmark.object_id)
    return assert.same(current_user.id, bookmark.user_id)
  end)
  it("should not error if bookmark exists", function()
    local topic = factory.Topics()
    for i = 1, 2 do
      BookmarksApp:get(current_user, "/save", {
        object_type = "topic",
        object_id = topic.id
      })
    end
    return assert.same(1, Bookmarks:count())
  end)
  it("should remove bookmark", function()
    local bm = factory.Bookmarks({
      user_id = current_user.id
    })
    BookmarksApp:get(current_user, "/remove", {
      object_type = "topic",
      object_id = bm.object_id
    })
    return assert.same(0, Bookmarks:count())
  end)
  return it("should not fail when removing non-existant bookmark", function()
    BookmarksApp:get(current_user, "/remove", {
      object_type = "topic",
      object_id = 1234
    })
    return assert.same(0, Bookmarks:count())
  end)
end)
