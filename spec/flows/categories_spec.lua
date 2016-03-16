local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local db = require("lapis.db")
local factory = require("spec.factory")
local TestApp
TestApp = require("spec.helpers").TestApp
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local Users
Users = require("models").Users
local ActivityLogs, Categories, CategoryMembers, CategoryTags, CategoryPostLogs, ModerationLogObjects, ModerationLogs, Moderators, PendingPosts, Posts, Topics
do
  local _obj_0 = require("community.models")
  ActivityLogs, Categories, CategoryMembers, CategoryTags, CategoryPostLogs, ModerationLogObjects, ModerationLogs, Moderators, PendingPosts, Posts, Topics = _obj_0.ActivityLogs, _obj_0.Categories, _obj_0.CategoryMembers, _obj_0.CategoryTags, _obj_0.CategoryPostLogs, _obj_0.ModerationLogObjects, _obj_0.ModerationLogs, _obj_0.Moderators, _obj_0.PendingPosts, _obj_0.Posts, _obj_0.Topics
end
local filter_bans
filter_bans = require("spec.helpers").filter_bans
local CategoryApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/new-category"] = capture_errors_json(function(self)
      self.flow:new_category()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/edit-category"] = capture_errors_json(function(self)
      self.flow:edit_category()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/show-members"] = capture_errors_json(function(self)
      self.flow:members_flow():show_members()
      return {
        json = {
          success = true,
          members = self.members
        }
      }
    end),
    ["/add-member"] = capture_errors_json(function(self)
      self.flow:members_flow():add_member()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/remove-member"] = capture_errors_json(function(self)
      self.flow:members_flow():remove_member()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/accept-member"] = capture_errors_json(function(self)
      self.flow:members_flow():accept_member()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/moderation-logs"] = capture_errors_json(function(self)
      self.flow:moderation_logs()
      return {
        json = {
          success = true,
          page = self.page,
          moderation_logs = self.moderation_logs
        }
      }
    end),
    ["/pending-posts"] = capture_errors_json(function(self)
      self.flow:pending_posts()
      return {
        json = {
          success = true,
          page = self.page,
          pending_posts = self.pending_posts
        }
      }
    end),
    ["/pending-post"] = capture_errors_json(function(self)
      local status, post = self.flow:edit_pending_post()
      return {
        json = {
          status = status,
          post = post
        }
      }
    end),
    ["/set-children"] = capture_errors_json(function(self)
      self.flow:set_children()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/set-tags"] = capture_errors_json(function(self)
      self.flow:set_tags()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/recent-posts"] = capture_errors_json(function(self)
      self.flow:recent_posts()
      filter_bans(unpack(self.posts))
      return {
        json = {
          success = true,
          posts = self.posts
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
    __name = "CategoryApp",
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
  self:before_filter(function(self)
    local CategoriesFlow = require("community.flows.categories")
    self.flow = CategoriesFlow(self)
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  CategoryApp = _class_0
end
return describe("categories", function()
  use_test_env()
  local current_user
  before_each(function()
    truncate_tables(Users, Categories, Posts, Topics, CategoryMembers, Moderators, ActivityLogs, ModerationLogs, ModerationLogObjects, PendingPosts, CategoryTags, CategoryPostLogs)
    current_user = factory.Users()
  end)
  it("should create category", function()
    local res = CategoryApp:get(current_user, "/new-category", {
      ["category[title]"] = "hello world",
      ["category[membership_type]"] = "public",
      ["category[voting_type]"] = "disabled",
      ["category[short_description]"] = "This category is about something",
      ["category[hidden]"] = "on"
    })
    assert.falsy(res.errors)
    assert.truthy(res.success)
    local category = unpack(Categories:select())
    assert.truthy(category)
    assert.same(current_user.id, category.user_id)
    assert.same("hello world", category.title)
    assert.same("This category is about something", category.short_description)
    assert.falsy(category.description)
    assert.falsy(category.archived)
    assert.truthy(category.hidden)
    assert.same(Categories.membership_types.public, category.membership_type)
    assert.same(Categories.voting_types.disabled, category.voting_type)
    assert.same(1, ActivityLogs:count())
    local log = unpack(ActivityLogs:select())
    assert.same(current_user.id, log.user_id)
    assert.same(category.id, log.object_id)
    assert.same(ActivityLogs.object_types.category, log.object_type)
    return assert.same("create", log:action_name())
  end)
  describe("with category", function()
    local category
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id,
        description = "okay okay"
      })
    end)
    describe("edit", function()
      it("should edit category", function()
        local res = CategoryApp:get(current_user, "/edit-category", {
          category_id = category.id,
          ["category[title]"] = "The good category",
          ["category[membership_type]"] = "members_only",
          ["category[voting_type]"] = "up",
          ["category[topic_posting_type]"] = "moderators_only",
          ["category[short_description]"] = "yeah yeah",
          ["category[archived]"] = "on"
        })
        assert.same({
          success = true
        }, res)
        category:refresh()
        assert.same("The good category", category.title)
        assert.same("yeah yeah", category.short_description)
        assert.same("okay okay", category.description)
        assert.truthy(category.archived)
        assert.falsy(category.hidden)
        assert.same(Categories.membership_types.members_only, category.membership_type)
        assert.same(Categories.voting_types.up, category.voting_type)
        assert.same(Categories.topic_posting_types.moderators_only, category.topic_posting_type)
        assert.same(1, ActivityLogs:count())
        local log = unpack(ActivityLogs:select())
        assert.same(current_user.id, log.user_id)
        assert.same(category.id, log.object_id)
        assert.same(ActivityLogs.object_types.category, log.object_type)
        return assert.same("edit", log:action_name())
      end)
      it("should update partial", function()
        category:update({
          archived = true
        })
        local res = CategoryApp:get(current_user, "/edit-category", {
          category_id = category.id,
          ["category[update_archived]"] = "yes"
        })
        assert.same({
          success = true
        }, res)
        category:refresh()
        return assert["false"](category.hidden)
      end)
      return it("should noop edit", function()
        local res = CategoryApp:get(current_user, "/edit-category", {
          category_id = category.id
        })
        assert.same({
          success = true
        }, res)
        return assert.same(0, ActivityLogs:count())
      end)
    end)
    it("should not let unknown user edit category", function()
      local other_user = factory.Users()
      local res = CategoryApp:get(other_user, "/edit-category", {
        category_id = category.id,
        ["category[title]"] = "The good category",
        ["category[membership_type]"] = "members_only"
      })
      return assert.same({
        errors = {
          "invalid category"
        }
      }, res)
    end)
    describe("tags", function()
      it("sets tags", function()
        local res = CategoryApp:get(current_user, "/set-tags", {
          category_id = category.id,
          ["category_tags[1][label]"] = "the first one",
          ["category_tags[2][label]"] = "Second here",
          ["category_tags[2][color]"] = "#dfdfee"
        })
        assert.same({
          success = true
        }, res)
        local ts
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = category:get_tags()
          for _index_0 = 1, #_list_0 do
            local t = _list_0[_index_0]
            _accum_0[_len_0] = {
              category_id = t.category_id,
              label = t.label,
              slug = t.slug,
              tag_order = t.tag_order,
              color = t.color
            }
            _len_0 = _len_0 + 1
          end
          ts = _accum_0
        end
        return assert.same({
          {
            category_id = category.id,
            tag_order = 1,
            label = "the first one",
            slug = "the-first-one"
          },
          {
            category_id = category.id,
            tag_order = 2,
            label = "Second here",
            slug = "second-here",
            color = "#dfdfee"
          }
        }, ts)
      end)
      it("clears tags", function()
        for i = 1, 2 do
          factory.CategoryTags({
            category_id = category.id
          })
        end
        local res = CategoryApp:get(current_user, "/set-tags", {
          category_id = category.id
        })
        assert.same({
          success = true
        }, res)
        return assert.same({ }, category:get_tags())
      end)
      it("edits tags", function()
        local existing
        do
          local _accum_0 = { }
          local _len_0 = 1
          for i = 1, 2 do
            _accum_0[_len_0] = factory.CategoryTags({
              category_id = category.id
            })
            _len_0 = _len_0 + 1
          end
          existing = _accum_0
        end
        local res = CategoryApp:get(current_user, "/set-tags", {
          category_id = category.id,
          ["category_tags[1][label]"] = "the first one",
          ["category_tags[1][id]"] = tostring(existing[2].id),
          ["category_tags[1][color]"] = "#daddad",
          ["category_tags[2][label]"] = "new one"
        })
        assert.same({
          success = true
        }, res)
        local tags = category:get_tags()
        assert.same(2, #tags)
        local first, second = unpack(tags)
        assert.same(existing[2].id, first.id)
        local t = existing[2]
        t:refresh()
        assert.same("the first one", t.label)
        return assert["not"].same(existing[1].id, second.id)
      end)
      it("doesn't fail when recreating tag of same slug", function()
        local existing = factory.CategoryTags({
          category_id = category.id
        })
        local res = CategoryApp:get(current_user, "/set-tags", {
          category_id = category.id,
          ["category_tags[1][label]"] = existing.label
        })
        return assert.same(1, #category:get_tags())
      end)
      return it("doesn't fail when trying to create dupes", function()
        local res = CategoryApp:get(current_user, "/set-tags", {
          category_id = category.id,
          ["category_tags[1][label]"] = "alpha",
          ["category_tags[1][label]"] = "alpha"
        })
        return assert.same(1, #category:get_tags())
      end)
    end)
    return describe("recent posts", function()
      it("gets empty recent posts", function()
        category:update({
          directory = true
        })
        local res = CategoryApp:get(current_user, "/recent-posts", {
          category_id = category.id
        })
        return assert.same({ }, res.posts)
      end)
      return it("gets category with posts from many topics", function()
        category:update({
          directory = true
        })
        for i = 1, 2 do
          local post = factory.Posts()
          CategoryPostLogs:create({
            category_id = category.id,
            post_id = post.id
          })
        end
        local res = CategoryApp:get(current_user, "/recent-posts", {
          category_id = category.id
        })
        return assert.same(2, #res.posts)
      end)
    end)
  end)
  describe("show members", function()
    local category
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id
      })
    end)
    it("shows empty members", function()
      local res = CategoryApp:get(current_user, "/show-members", {
        category_id = category.id,
        user_id = current_user.id
      })
      assert["nil"](res.errors)
      return assert.same({ }, res.members)
    end)
    return it("shows members", function()
      CategoryMembers:create({
        user_id = factory.Users().id,
        category_id = category.id,
        accepted = true
      })
      CategoryMembers:create({
        user_id = factory.Users().id,
        category_id = category.id,
        accepted = false
      })
      local res = CategoryApp:get(current_user, "/show-members", {
        category_id = category.id,
        user_id = current_user.id
      })
      assert["nil"](res.errors)
      assert.same(2, #res.members)
      return assert.truthy(res.members[1].user)
    end)
  end)
  describe("add_member", function()
    local category
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id
      })
    end)
    it("should add member", function()
      local other_user = factory.Users()
      local res = CategoryApp:get(current_user, "/add-member", {
        category_id = category.id,
        user_id = other_user.id
      })
      local members = CategoryMembers:select()
      assert.same(1, #members)
      local member = unpack(members)
      assert.same(category.id, member.category_id)
      assert.same(other_user.id, member.user_id)
      assert.same(false, member.accepted)
      return assert.same({
        success = true
      }, res)
    end)
    it("should accept member", function()
      local other_user = factory.Users()
      factory.CategoryMembers({
        user_id = other_user.id,
        category_id = category.id,
        accepted = false
      })
      local res = CategoryApp:get(other_user, "/accept-member", {
        category_id = category.id
      })
      return assert.same({
        success = true
      }, res)
    end)
    return it("should not accept unininvited user", function()
      local other_user = factory.Users()
      local res = CategoryApp:get(other_user, "/accept-member", {
        category_id = category.id
      })
      return assert.same({
        errors = {
          "no pending membership"
        }
      }, res)
    end)
  end)
  describe("moderation_logs", function()
    local category
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id
      })
    end)
    it("gets moderation log", function()
      ModerationLogs:create({
        category_id = category.id,
        object = category,
        user_id = current_user.id,
        action = "did.something"
      })
      local res = CategoryApp:get(current_user, "/moderation-logs", {
        category_id = category.id
      })
      assert.truthy(res.moderation_logs)
      return assert.same(1, #res.moderation_logs)
    end)
    return it("doesn't get moderation log for unrelated user", function()
      local other_user = factory.Users()
      local res = CategoryApp:get(other_user, "/moderation-logs", {
        category_id = category.id
      })
      return assert.same({
        errors = {
          "invalid category"
        }
      }, res)
    end)
  end)
  describe("pending posts", function()
    local category
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id
      })
    end)
    it("gets empty pending posts", function()
      local res = CategoryApp:get(current_user, "/pending-posts", {
        category_id = category.id
      })
      return assert.same({ }, res.pending_posts)
    end)
    return describe("with pending posts", function()
      local pending_post
      before_each(function()
        pending_post = factory.PendingPosts({
          category_id = category.id
        })
      end)
      it("gets pending posts", function()
        local res = CategoryApp:get(current_user, "/pending-posts", {
          category_id = category.id
        })
        assert.same(1, #res.pending_posts)
        return assert.same(pending_post.id, res.pending_posts[1].id)
      end)
      it("doesn't let stranger view pending posts", function()
        local res = CategoryApp:get(factory.Users(), "/pending-posts", {
          category_id = category.id
        })
        return assert.truthy(res.errors)
      end)
      it("doesn't get incorrect satus", function()
        local res = CategoryApp:get(current_user, "/pending-posts", {
          category_id = category.id,
          status = "deleted"
        })
        return assert.same({ }, res.pending_posts)
      end)
      it("promotes pending post", function()
        local res = CategoryApp:get(current_user, "/pending-post", {
          category_id = category.id,
          pending_post_id = pending_post.id,
          action = "promote"
        })
        assert.same(0, PendingPosts:count())
        return assert.same(1, Posts:count())
      end)
      it("doesn't let stranger edit pending post", function()
        local res = CategoryApp:get(factory.Users(), "/pending-post", {
          category_id = category.id,
          pending_post_id = pending_post.id,
          action = "promote"
        })
        return assert.truthy(res.errors)
      end)
      return it("deletes pending post", function()
        local res = CategoryApp:get(current_user, "/pending-post", {
          category_id = category.id,
          pending_post_id = pending_post.id,
          action = "deleted"
        })
        assert.same(1, PendingPosts:count())
        assert.same(0, Posts:count())
        pending_post:refresh()
        return assert.same(PendingPosts.statuses.deleted, pending_post.status)
      end)
    end)
  end)
  return describe("set children", function(self)
    local category
    local simplify_children
    simplify_children = function(children)
      return (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #children do
          local c = children[_index_0]
          _accum_0[_len_0] = {
            title = c.title,
            children = c.children and next(c.children) and simplify_children(c.children) or nil
          }
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)()
    end
    local assert_children
    assert_children = function(tree, category)
      category = Categories:find(category.id)
      category:get_children()
      return assert.same(tree, simplify_children(category.children))
    end
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id
      })
    end)
    it("should set empty cateogires", function()
      return CategoryApp:get(current_user, "/set-children", {
        category_id = category.id
      })
    end)
    it("creates new categories", function()
      local res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][title]"] = "alpha",
        ["categories[2][title]"] = "beta"
      })
      assert["nil"](res.errors)
      return assert_children({
        {
          title = "alpha"
        },
        {
          title = "beta"
        }
      }, category)
    end)
    it("creates new categories with nesting", function()
      local res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][title]"] = "alpha",
        ["categories[1][children][1][title]"] = "alpha one",
        ["categories[1][children][2][title]"] = "alpha two",
        ["categories[2][title]"] = "beta",
        ["categories[3][title]"] = "cow",
        ["categories[3][children][1][title]"] = "cow moo"
      })
      assert["nil"](res.errors)
      return assert_children({
        {
          title = "alpha",
          children = {
            {
              title = "alpha one"
            },
            {
              title = "alpha two"
            }
          }
        },
        {
          title = "beta"
        },
        {
          title = "cow",
          children = {
            {
              title = "cow moo"
            }
          }
        }
      }, category)
    end)
    it("creates new nested child", function()
      local b1 = factory.Categories({
        parent_category_id = category.id,
        title = "before1"
      })
      local b2 = factory.Categories({
        parent_category_id = category.id,
        title = "before2"
      })
      local b3 = factory.Categories({
        parent_category_id = category.id,
        title = "before2"
      })
      local res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][id]"] = b1.id,
        ["categories[1][title]"] = "Hey cool category yeah",
        ["categories[1][children][1][id]"] = b2.id,
        ["categories[1][children][1][title]"] = "Here's a child category",
        ["categories[1][children][2][title]"] = "Another child category",
        ["categories[2][id]"] = b3.id,
        ["categories[2][title]"] = "Another thing here?"
      })
      assert["nil"](res.errors)
      return assert_children({
        {
          title = "Hey cool category yeah",
          children = {
            {
              title = "Here's a child category"
            },
            {
              title = "Another child category"
            }
          }
        },
        {
          title = "Another thing here?"
        }
      }, category)
    end)
    it("edits existing children", function()
      local b1 = factory.Categories({
        parent_category_id = category.id,
        title = "before1"
      })
      local b2 = factory.Categories({
        parent_category_id = category.id,
        title = "before2"
      })
      local res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][id]"] = tostring(b1.id),
        ["categories[1][title]"] = "before1 updated",
        ["categories[2][title]"] = "beta",
        ["categories[3][id]"] = tostring(b2.id),
        ["categories[3][title]"] = "before2"
      })
      assert["nil"](res.errors)
      assert_children({
        {
          title = "before1 updated"
        },
        {
          title = "beta"
        },
        {
          title = "before2"
        }
      }, category)
      b1:refresh()
      assert.same(category.id, b1.parent_category_id)
      assert.same(1, b1.position)
      assert.same("before1 updated", b1.title)
      b2:refresh()
      assert.same(category.id, b1.parent_category_id)
      assert.same(1, b1.position)
      return assert.same("before1 updated", b1.title)
    end)
    it("renests existing into new parent", function()
      local b1 = factory.Categories({
        parent_category_id = category.id,
        title = "before1"
      })
      local res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][title]"] = "new parent",
        ["categories[1][children][1][id]"] = tostring(b1.id),
        ["categories[1][children][1][title]"] = b1.title
      })
      assert["nil"](res.errors)
      assert_children({
        {
          title = "new parent",
          children = {
            {
              title = "before1"
            }
          }
        }
      }, category)
      b1:refresh()
      local parent = b1:get_parent_category()
      return assert.same(category.id, parent.parent_category_id)
    end)
    it("deletes empty orphans", function()
      local b1 = factory.Categories({
        parent_category_id = category.id,
        title = "before1"
      })
      local b2 = factory.Categories({
        parent_category_id = b1.id,
        title = "before2"
      })
      local res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][title]"] = "cool parent",
        ["categories[1][children][1][id]"] = tostring(b2.id),
        ["categories[1][children][1][title]"] = b2.title
      })
      b2:refresh()
      assert["not"].same(category.id, b2.parent_category_id)
      return assert["nil"](Categories:find({
        id = b1.id
      }))
    end)
    it("archives orphan", function()
      local b1 = factory.Categories({
        parent_category_id = category.id,
        title = "orphan"
      })
      local topic = factory.Topics({
        category_id = b1.id
      })
      b1:increment_from_topic(topic)
      local res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][title]"] = "new category"
      })
      b1:refresh()
      assert["true"](b1.archived)
      assert["true"](b1.hidden)
      return assert.same(2, b1.position)
    end)
    return it("updates hidden/archive", function()
      local res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][title]"] = "new category",
        ["categories[1][hidden]"] = "on"
      })
      local child = unpack(category:get_children())
      assert["true"](child.hidden)
      assert["false"](child.archived)
      res = CategoryApp:get(current_user, "/set-children", {
        category_id = category.id,
        ["categories[1][id]"] = tostring(child.id),
        ["categories[1][title]"] = "new category",
        ["categories[1][archived]"] = "on"
      })
      child:refresh()
      assert["false"](child.hidden)
      return assert["true"](child.archived)
    end)
  end)
end)
