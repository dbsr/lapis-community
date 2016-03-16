local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Topics, Posts, Votes, UserCategoryLastSeens, UserTopicLastSeens
do
  local _obj_0 = require("community.models")
  Categories, Topics, Posts, Votes, UserCategoryLastSeens, UserTopicLastSeens = _obj_0.Categories, _obj_0.Topics, _obj_0.Posts, _obj_0.Votes, _obj_0.UserCategoryLastSeens, _obj_0.UserTopicLastSeens
end
local factory = require("spec.factory")
local mock_request
mock_request = require("lapis.spec.request").mock_request
local Application
Application = require("lapis").Application
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local TestApp
TestApp = require("spec.helpers").TestApp
local filter_bans
filter_bans = require("spec.helpers").filter_bans
local BrowsingApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/post"] = capture_errors_json(function(self)
      self.flow:post_single()
      filter_bans(self.post:get_topic())
      return {
        json = {
          success = true,
          post = self.post
        }
      }
    end),
    ["/category"] = capture_errors_json(function(self)
      self.flow:category_single()
      filter_bans(self.category)
      return {
        json = {
          success = true,
          category = self.category
        }
      }
    end),
    ["/topic-posts"] = capture_errors_json(function(self)
      self.flow:topic_posts({
        order = self.params.order
      })
      filter_bans(unpack((function()
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self.posts
        for _index_0 = 1, #_list_0 do
          local post = _list_0[_index_0]
          _accum_0[_len_0] = post.topic
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)()))
      return {
        json = {
          success = true,
          posts = self.posts,
          next_page = self.next_page,
          prev_page = self.prev_page
        }
      }
    end),
    ["/category-topics"] = capture_errors_json(function(self)
      self.flow:category_topics()
      return {
        json = {
          success = true,
          topics = self.topics,
          next_page = self.next_page,
          prev_page = self.prev_page
        }
      }
    end),
    ["/sticky-category-topics"] = capture_errors_json(function(self)
      self.flow:sticky_category_topics()
      return {
        json = {
          success = true,
          sticky_topics = self.sticky_topics
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
    __name = "BrowsingApp",
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
    self.current_user = self.params.current_user_id and assert(Users:find(self.params.current_user_id))
    local Browsing = require("community.flows.browsing")
    self.flow = Browsing(self)
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BrowsingApp = _class_0
end
return describe("browsing flow", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Users, Categories, Topics, Posts, Votes, UserCategoryLastSeens, UserTopicLastSeens)
  end)
  local _list_0 = {
    true,
    nil
  }
  for _index_0 = 1, #_list_0 do
    local logged_in = _list_0[_index_0]
    local current_user
    describe(logged_in and "logged in" or "logged out", function()
      before_each(function()
        if logged_in then
          current_user = factory.Users()
        end
      end)
      describe("topic posts", function()
        it("should error with no topic id", function()
          local res = BrowsingApp:get(current_user, "/topic-posts")
          assert.truthy(res.errors)
          return assert.same({
            "topic_id must be an integer"
          }, res.errors)
        end)
        it("get flat posts in topic", function()
          local topic = factory.Topics()
          local posts
          do
            local _accum_0 = { }
            local _len_0 = 1
            for i = 1, 3 do
              local post = factory.Posts({
                topic_id = topic.id
              })
              topic:increment_from_post(post)
              local _value_0 = post
              _accum_0[_len_0] = _value_0
              _len_0 = _len_0 + 1
            end
            posts = _accum_0
          end
          local res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id
          })
          assert.truthy(res.success)
          assert.same(3, #res.posts)
          return assert.same((function()
            local _accum_0 = { }
            local _len_0 = 1
            for _index_1 = 1, #posts do
              local p = posts[_index_1]
              _accum_0[_len_0] = p.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)(), (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_1 = res.posts
            for _index_1 = 1, #_list_1 do
              local p = _list_1[_index_1]
              _accum_0[_len_0] = p.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
        end)
        it("gets posts in reverse", function()
          local topic = factory.Topics()
          local posts
          do
            local _accum_0 = { }
            local _len_0 = 1
            for i = 1, 3 do
              local post = factory.Posts({
                topic_id = topic.id
              })
              topic:increment_from_post(post)
              local _value_0 = post
              _accum_0[_len_0] = _value_0
              _len_0 = _len_0 + 1
            end
            posts = _accum_0
          end
          local res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id,
            order = "desc"
          })
          assert.truthy(res.success)
          assert.same(3, #res.posts)
          return assert.same((function()
            local _accum_0 = { }
            local _len_0 = 1
            for i = #posts, 1, -1 do
              _accum_0[_len_0] = posts[i].id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)(), (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_1 = res.posts
            for _index_1 = 1, #_list_1 do
              local p = _list_1[_index_1]
              _accum_0[_len_0] = p.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
        end)
        it("should get paginated posts with after", function()
          local topic = factory.Topics()
          for i = 1, 3 do
            local post = factory.Posts({
              topic_id = topic.id
            })
            topic:increment_from_post(post)
          end
          local res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id,
            after = 1
          })
          assert.truthy(res.success)
          assert.same(2, #res.posts)
          return assert.same({ }, res.prev_page)
        end)
        it("should get paginated posts with before", function()
          local topic = factory.Topics()
          for i = 1, 3 do
            local post = factory.Posts({
              topic_id = topic.id
            })
            topic:increment_from_post(post)
          end
          local res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id,
            before = 2
          })
          assert.truthy(res.success)
          return assert.same(1, #res.posts)
        end)
        it("sets pagination on posts", function()
          local limits = require("community.limits")
          local topic = factory.Topics()
          for i = 1, limits.POSTS_PER_PAGE do
            local p = factory.Posts({
              topic_id = topic.id
            })
            topic:increment_from_post(p)
          end
          local res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id
          })
          assert.falsy(res.next_page)
          assert.falsy(res.prev_page)
          local p = factory.Posts({
            topic_id = topic.id
          })
          topic:increment_from_post(p)
          res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id
          })
          assert.same({
            after = 20
          }, res.next_page)
          assert.falsy(res.prev_page)
          for i = 1, 3 do
            p = factory.Posts({
              topic_id = topic.id
            })
            topic:increment_from_post(p)
          end
          res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id,
            after = res.next_page.after
          })
          assert.same({ }, res.prev_page)
          assert["nil"](res.next_page)
          return assert.same(4, #res.posts)
        end)
        it("sets blank pagination on posts when there are archived in first position", function()
          local topic = factory.Topics()
          local posts
          do
            local _accum_0 = { }
            local _len_0 = 1
            for i = 1, 2 do
              do
                local post = factory.Posts({
                  topic_id = topic.id
                })
                topic:increment_from_post(post)
                _accum_0[_len_0] = post
              end
              _len_0 = _len_0 + 1
            end
            posts = _accum_0
          end
          assert(posts[1]:archive())
          local res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id
          })
          assert.falsy(res.next_page)
          return assert.falsy(res.prev_page)
        end)
        return it("should get some nested posts", function()
          local topic = factory.Topics()
          local expected_nesting = { }
          for i = 1, 3 do
            local p = factory.Posts({
              topic_id = topic.id
            })
            topic:increment_from_post(p)
            local node = {
              id = p.id,
              children = { }
            }
            table.insert(expected_nesting, node)
            for i = 1, 2 do
              local pp = factory.Posts({
                topic_id = topic.id,
                parent_post = p
              })
              topic:increment_from_post(pp)
              local inner_node = {
                id = pp.id,
                children = { }
              }
              table.insert(node.children, inner_node)
              local ppp = factory.Posts({
                topic_id = topic.id,
                parent_post = pp
              })
              topic:increment_from_post(ppp)
              table.insert(inner_node.children, {
                id = ppp.id,
                children = { }
              })
            end
          end
          local res = BrowsingApp:get(current_user, "/topic-posts", {
            topic_id = topic.id
          })
          assert.truthy(res.posts)
          local flatten
          flatten = function(list, accum)
            if accum == nil then
              accum = { }
            end
            return (function()
              local _accum_0 = { }
              local _len_0 = 1
              for _index_1 = 1, #list do
                local p = list[_index_1]
                _accum_0[_len_0] = {
                  id = p.id,
                  children = p.children and flatten(p.children) or { }
                }
                _len_0 = _len_0 + 1
              end
              return _accum_0
            end)()
          end
          local nesting = flatten(res.posts)
          return assert.same(expected_nesting, nesting)
        end)
      end)
      describe("category topics", function()
        it("gets empty category", function()
          local category = factory.Categories()
          local res = BrowsingApp:get(current_user, "/category-topics", {
            category_id = category.id
          })
          assert.truthy(res.success)
          assert.same(0, #res.topics)
          return assert.same(0, UserCategoryLastSeens:count())
        end)
        it("gets empty sticky topics", function()
          local category = factory.Categories()
          local res = BrowsingApp:get(current_user, "/sticky-category-topics", {
            category_id = category.id
          })
          assert.truthy(res.success)
          return assert.same(0, #res.sticky_topics)
        end)
        it("gets some topics", function()
          local category = factory.Categories()
          local topics
          do
            local _accum_0 = { }
            local _len_0 = 1
            for i = 1, 4 do
              do
                local topic = factory.Topics({
                  category_id = category.id
                })
                category:increment_from_topic(topic)
                _accum_0[_len_0] = topic
              end
              _len_0 = _len_0 + 1
            end
            topics = _accum_0
          end
          local res = BrowsingApp:get(current_user, "/category-topics", {
            category_id = category.id
          })
          assert.truthy(res.success)
          assert.same(4, #res.topics)
          assert.falsy(res.next_page)
          assert.falsy(res.prev_page)
          local last_seen, other = unpack(UserCategoryLastSeens:select())
          assert["nil"](other)
          local last_topic = topics[4]
          last_topic:refresh()
          return assert.same({
            category_id = category.id,
            user_id = current_user.id,
            topic_id = last_topic.id,
            category_order = last_topic.category_order
          }, last_seen)
        end)
        it("gets only sticky topics", function()
          local category = factory.Categories()
          local topics
          do
            local _accum_0 = { }
            local _len_0 = 1
            for i = 1, 2 do
              do
                local topic = factory.Topics({
                  category_id = category.id
                })
                category:increment_from_topic(topic)
                _accum_0[_len_0] = topic
              end
              _len_0 = _len_0 + 1
            end
            topics = _accum_0
          end
          topics[1]:update({
            sticky = true
          })
          local res = BrowsingApp:get(current_user, "/sticky-category-topics", {
            category_id = category.id
          })
          assert.truthy(res.success)
          assert.same(1, #res.sticky_topics)
          return assert.same(topics[1].id, res.sticky_topics[1].id)
        end)
        it("archived topics are exluded by default", function()
          local category = factory.Categories()
          local topics
          do
            local _accum_0 = { }
            local _len_0 = 1
            for i = 1, 4 do
              do
                local topic = factory.Topics({
                  category_id = category.id
                })
                category:increment_from_topic(topic)
                _accum_0[_len_0] = topic
              end
              _len_0 = _len_0 + 1
            end
            topics = _accum_0
          end
          topics[1]:archive()
          local res = BrowsingApp:get(current_user, "/category-topics", {
            category_id = category.id
          })
          assert.same(3, #res.topics)
          local ids
          do
            local _tbl_0 = { }
            local _list_1 = res.topics
            for _index_1 = 1, #_list_1 do
              local t = _list_1[_index_1]
              _tbl_0[t.id] = true
            end
            ids = _tbl_0
          end
          return assert.same({
            [topics[2].id] = true,
            [topics[3].id] = true,
            [topics[4].id] = true
          }, ids)
        end)
        it("only shows archived topics", function()
          local category = factory.Categories()
          local topics
          do
            local _accum_0 = { }
            local _len_0 = 1
            for i = 1, 4 do
              do
                local topic = factory.Topics({
                  category_id = category.id
                })
                category:increment_from_topic(topic)
                _accum_0[_len_0] = topic
              end
              _len_0 = _len_0 + 1
            end
            topics = _accum_0
          end
          topics[2]:archive()
          local res = BrowsingApp:get(current_user, "/category-topics", {
            category_id = category.id,
            status = "archived"
          })
          assert.same(1, #res.topics)
          return assert.same(topics[2].id, res.topics[1].id)
        end)
        return it("sets pagination for category", function()
          local category = factory.Categories()
          local limits = require("community.limits")
          for i = 1, limits.TOPICS_PER_PAGE + 1 do
            local topic = factory.Topics({
              category_id = category.id
            })
            category:increment_from_topic(topic)
          end
          local res = BrowsingApp:get(current_user, "/category-topics", {
            category_id = category.id
          })
          assert.truthy(res.success)
          assert.same(20, #res.topics)
          assert.same({
            before = 2
          }, res.next_page)
          assert.same(nil, res.prev_page)
          res = BrowsingApp:get(current_user, "/category-topics", {
            category_id = category.id,
            before = res.next_page.before
          })
          assert.truthy(res.success)
          assert.same(1, #res.topics)
          assert.same(nil, res.next_page)
          return assert.same({
            after = 1
          }, res.prev_page)
        end)
      end)
      describe("post", function()
        it("gets post with no nested content", function()
          local post = factory.Posts()
          local res = BrowsingApp:get(current_user, "/post", {
            post_id = post.id
          })
          assert.same(post.id, res.post.id)
          assert.same({ }, res.post.children)
          assert.truthy(res.post.user)
          return assert.truthy(res.post.topic)
        end)
        it("gets post with nested content", function()
          local p = factory.Posts()
          local topic = p:get_topic()
          topic:increment_from_post(p)
          local pp1 = factory.Posts({
            topic_id = topic.id,
            parent_post = p
          })
          topic:increment_from_post(pp1)
          local pp2 = factory.Posts({
            topic_id = topic.id,
            parent_post = p
          })
          topic:increment_from_post(pp2)
          local ppp1 = factory.Posts({
            topic_id = topic.id,
            parent_post = pp1
          })
          topic:increment_from_post(ppp1)
          local res = BrowsingApp:get(current_user, "/post", {
            post_id = p.id
          })
          assert.same(p.id, res.post.id)
          assert.truthy(res.post.user)
          assert.truthy(res.post.topic)
          assert.same({
            pp1.id,
            pp2.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_1 = res.post.children
            for _index_1 = 1, #_list_1 do
              local child = _list_1[_index_1]
              _accum_0[_len_0] = child.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
          local _list_1 = res.post.children
          for _index_1 = 1, #_list_1 do
            local child = _list_1[_index_1]
            assert.same(p.id, child.parent_post_id)
            assert.truthy(child.user)
            assert.truthy(child.topic)
          end
        end)
        it("gets post without spam nested content", function()
          local p = factory.Posts()
          local topic = p:get_topic()
          topic:increment_from_post(p)
          local c1 = factory.Posts({
            status = "spam",
            topic_id = topic.id,
            parent_post_id = p.id
          })
          topic:increment_from_post(c1)
          local c2 = factory.Posts({
            topic_id = topic.id,
            parent_post_id = p.id
          })
          topic:increment_from_post(c2)
          local res = BrowsingApp:get(current_user, "/post", {
            post_id = p.id
          })
          assert.same(1, #res.post.children)
          return assert.same(c2.id, res.post.children[1].id)
        end)
        return it("shows archive children when viewing archived post", function()
          local p = factory.Posts({
            status = "archived"
          })
          local topic = p:get_topic()
          topic:increment_from_post(p)
          local c1 = factory.Posts({
            topic_id = topic.id,
            parent_post_id = p.id
          })
          topic:increment_from_post(c1)
          local c2 = factory.Posts({
            status = "archived",
            topic_id = topic.id,
            parent_post_id = p.id
          })
          topic:increment_from_post(c2)
          local res = BrowsingApp:get(current_user, "/post", {
            post_id = p.id
          })
          assert.same(2, #res.post.children)
          return assert.same({
            [c1.id] = true,
            [c2.id] = true
          }, (function()
            local _tbl_0 = { }
            local _list_1 = res.post.children
            for _index_1 = 1, #_list_1 do
              local c = _list_1[_index_1]
              _tbl_0[c.id] = true
            end
            return _tbl_0
          end)())
        end)
      end)
      return describe("category", function()
        it("gets empty category", function()
          local category = factory.Categories()
          local res = BrowsingApp:get(current_user, "/category", {
            category_id = category.id
          })
          return assert.same({ }, res.category.children)
        end)
        return it("gets category with children preloaded", function()
          local category = factory.Categories()
          local a = factory.Categories({
            parent_category_id = category.id
          })
          local b = factory.Categories({
            parent_category_id = category.id
          })
          local category_topic
          category_topic = function(cat)
            local topic = factory.Topics({
              category_id = cat.id
            })
            local post = factory.Posts({
              topic_id = topic.id
            })
            topic:increment_from_post(post)
            cat:increment_from_topic(topic)
            return topic
          end
          local a_topic = category_topic(a)
          local b_topic = category_topic(b)
          local res = BrowsingApp:get(current_user, "/category", {
            category_id = category.id
          })
          local children = res.category.children
          assert.same(2, #children)
          for _index_1 = 1, #children do
            local child = children[_index_1]
            assert.same(category.id, child.parent_category_id)
          end
          assert.same(a_topic.id, children[1].last_topic.id)
          assert.same(b_topic.id, children[2].last_topic.id)
          assert.same(a_topic.last_post_id, children[1].last_topic.last_post.id)
          assert.same(b_topic.last_post_id, children[2].last_topic.last_post.id)
          assert.same(a_topic:get_last_post().user_id, children[1].last_topic.last_post.user.id)
          return assert.same(b_topic:get_last_post().user_id, children[2].last_topic.last_post.user.id)
        end)
      end)
    end)
  end
end)
