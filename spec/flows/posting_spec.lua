local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, CategoryTags, Moderators, CommunityUsers, PostEdits, Votes, Posts, TopicParticipants, Topics, ActivityLogs
do
  local _obj_0 = require("community.models")
  Categories, CategoryTags, Moderators, CommunityUsers, PostEdits, Votes, Posts, TopicParticipants, Topics, ActivityLogs = _obj_0.Categories, _obj_0.CategoryTags, _obj_0.Moderators, _obj_0.CommunityUsers, _obj_0.PostEdits, _obj_0.Votes, _obj_0.Posts, _obj_0.TopicParticipants, _obj_0.Topics, _obj_0.ActivityLogs
end
local factory = require("spec.factory")
local Application
Application = require("lapis").Application
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local TestApp
TestApp = require("spec.helpers").TestApp
local TopicsFlow = require("community.flows.topics")
local PostsFlow = require("community.flows.posts")
local PostingApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/new-topic"] = capture_errors_json(function(self)
      TopicsFlow(self):new_topic()
      return {
        json = {
          topic = self.topic,
          post = self.post,
          success = true
        }
      }
    end),
    ["/delete-topic"] = capture_errors_json(function(self)
      local res = TopicsFlow(self):delete_topic()
      return {
        json = {
          success = res
        }
      }
    end),
    ["/new-post"] = capture_errors_json(function(self)
      PostsFlow(self):new_post()
      return {
        json = {
          post = self.post,
          success = true
        }
      }
    end),
    ["/edit-post"] = capture_errors_json(function(self)
      PostsFlow(self):edit_post()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/delete-post"] = capture_errors_json(function(self)
      local res = PostsFlow(self):delete_post()
      return {
        json = {
          success = res
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
    __name = "PostingApp",
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
  PostingApp = _class_0
end
return describe("posting flow", function()
  use_test_env()
  local current_user
  before_each(function()
    truncate_tables(Users, Categories, Topics, Posts, Votes, Moderators, PostEdits, CommunityUsers, TopicParticipants, ActivityLogs, CategoryTags)
    current_user = factory.Users()
  end)
  describe("new topic", function()
    it("should not post anything when missing all data", function()
      local res = PostingApp:get(current_user, "/new-topic", { })
      return assert.truthy(res.errors)
    end)
    it("should fail with bad category", function()
      local res = PostingApp:get(current_user, "/new-topic", {
        current_user_id = current_user.id,
        category_id = 0,
        ["topic[title]"] = "hello",
        ["topic[body]"] = "world"
      })
      return assert.same({
        "invalid category"
      }, res.errors)
    end)
    it("should fail with empty body", function()
      local res = PostingApp:get(current_user, "/new-topic", {
        current_user_id = current_user.id,
        category_id = factory.Categories().id,
        ["topic[title]"] = "hello",
        ["topic[body]"] = ""
      })
      return assert.same({
        "body must be provided"
      }, res.errors)
    end)
    it("should fail with empty html body", function()
      local res = PostingApp:get(current_user, "/new-topic", {
        current_user_id = current_user.id,
        category_id = factory.Categories().id,
        ["topic[title]"] = "hello",
        ["topic[body]"] = " <ol><li>   </ol>"
      })
      return assert.same({
        "body must be provided"
      }, res.errors)
    end)
    it("should post a new topic", function()
      local category = factory.Categories()
      local res = PostingApp:get(current_user, "/new-topic", {
        current_user_id = current_user.id,
        category_id = category.id,
        ["topic[title]"] = "Hello world",
        ["topic[body]"] = "This is the body"
      })
      assert.truthy(res.success)
      local topic = unpack(Topics:select())
      local post = unpack(Posts:select())
      assert.same(category.id, topic.category_id)
      assert.same(current_user.id, topic.user_id)
      assert.same("Hello world", topic.title)
      assert.same(1, topic.category_order)
      assert.same(current_user.id, post.user_id)
      assert.same(topic.id, post.topic_id)
      assert.same("This is the body", post.body)
      category:refresh()
      assert.same(1, category.topics_count)
      local cu = CommunityUsers:for_user(current_user)
      assert.same(1, cu.topics_count)
      assert.same(0, cu.posts_count)
      local tps = TopicParticipants:select("where topic_id = ?", topic.id)
      assert.same(1, #tps)
      category:refresh()
      assert.same(topic.id, category.last_topic_id)
      assert.same(post.id, topic.last_post_id)
      assert.same(1, topic.root_posts_count)
      assert.same(1, topic.posts_count)
      assert.same(1, ActivityLogs:count())
      local log = unpack(ActivityLogs:select())
      assert.same(current_user.id, log.user_id)
      assert.same(topic.id, log.object_id)
      assert.same(ActivityLogs.object_types.topic, log.object_type)
      return assert.same("create", log:action_name())
    end)
    return it("should post a new topic with tags", function()
      local category = factory.Categories()
      factory.CategoryTags({
        slug = "hello",
        category_id = category.id
      })
      local res = PostingApp:get(current_user, "/new-topic", {
        current_user_id = current_user.id,
        category_id = category.id,
        ["topic[title]"] = "Hello world",
        ["topic[body]"] = "This is the body",
        ["topic[tags]"] = "hello"
      })
      local topic = unpack(Topics:select())
      return assert.same({
        "hello"
      }, (function()
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = topic:get_tags()
        for _index_0 = 1, #_list_0 do
          local t = _list_0[_index_0]
          _accum_0[_len_0] = t.slug
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    end)
  end)
  describe("new post", function()
    local topic
    before_each(function()
      topic = factory.Topics()
    end)
    it("should post a new post", function()
      local res = PostingApp:get(current_user, "/new-post", {
        topic_id = topic.id,
        ["post[body]"] = "This is post body"
      })
      topic:refresh()
      local post = unpack(Posts:select())
      assert.same(current_user.id, post.user_id)
      assert.same(topic.id, post.topic_id)
      assert.same("This is post body", post.body)
      assert.same(topic.posts_count, 1)
      assert.same(topic.root_posts_count, 1)
      local cu = CommunityUsers:for_user(current_user)
      assert.same(0, cu.topics_count)
      assert.same(1, cu.posts_count)
      local tps = TopicParticipants:select("where topic_id = ?", topic.id)
      assert.same(1, #tps)
      assert.same(post.id, topic.last_post_id)
      assert.same(1, ActivityLogs:count())
      local log = unpack(ActivityLogs:select())
      assert.same(current_user.id, log.user_id)
      assert.same(post.id, log.object_id)
      assert.same(ActivityLogs.object_types.post, log.object_type)
      return assert.same("create", log:action_name())
    end)
    it("should post two posts", function()
      for i = 1, 2 do
        PostingApp:get(current_user, "/new-post", {
          topic_id = topic.id,
          ["post[body]"] = "This is post body"
        })
      end
      local tps = TopicParticipants:select("where topic_id = ?", topic.id)
      assert.same(1, #tps)
      return assert.same(2, tps[1].posts_count)
    end)
    return it("should post a threaded post", function()
      local post = factory.Posts({
        topic_id = topic.id
      })
      local res = PostingApp:get(current_user, "/new-post", {
        topic_id = topic.id,
        parent_post_id = post.id,
        ["post[body]"] = "This is a sub message"
      })
      assert.truthy(res.success)
      local child_post = res.post
      local posts = Posts:select()
      assert.same(2, #posts)
      child_post = Posts:find(child_post.id)
      return assert.same(post.id, child_post.parent_post_id)
    end)
  end)
  describe("edit topic", function()
    local topic
    before_each(function()
      topic = factory.Topics({
        user_id = current_user.id
      })
    end)
    it("should delete topic", function()
      local res = PostingApp:get(current_user, "/delete-topic", {
        topic_id = topic.id
      })
      assert.truthy(res.success)
      topic:refresh()
      assert.truthy(topic.deleted)
      assert.truthy(topic.deleted_at)
      assert.same(-1, CommunityUsers:for_user(current_user).topics_count)
      assert.same(1, ActivityLogs:count())
      local log = unpack(ActivityLogs:select())
      assert.same(current_user.id, log.user_id)
      assert.same(topic.id, log.object_id)
      assert.same(ActivityLogs.object_types.topic, log.object_type)
      return assert.same("delete", log:action_name())
    end)
    return it("should not allow unrelated user to delete topic", function()
      local other_user = factory.Users()
      local res = PostingApp:get(other_user, "/delete-topic", {
        topic_id = topic.id
      })
      return assert.same({
        errors = {
          "not allowed to edit"
        }
      }, res)
    end)
  end)
  return describe("edit post", function()
    it("should edit post", function()
      local post = factory.Posts({
        user_id = current_user.id
      })
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = post.id,
        ["post[body]"] = "the new body"
      })
      assert.truthy(res.success)
      post:refresh()
      assert.same("the new body", post.body)
      assert.same(1, ActivityLogs:count())
      local log = unpack(ActivityLogs:select())
      assert.same(current_user.id, log.user_id)
      assert.same(post.id, log.object_id)
      assert.same(ActivityLogs.object_types.post, log.object_type)
      return assert.same("edit", log:action_name())
    end)
    it("should edit post and title", function()
      local post = factory.Posts({
        user_id = current_user.id
      })
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = post.id,
        ["post[body]"] = "the new body",
        ["post[title]"] = "the new title"
      })
      local old_body = post.body
      assert.truthy(res.success)
      post:refresh()
      assert.same("the new body", post.body)
      assert.same("the new title", post:get_topic().title)
      assert.same("the-new-title", post:get_topic().slug)
      local edit = unpack(PostEdits:select())
      assert(edit, "missing edit")
      assert.same(current_user.id, edit.user_id)
      assert.same(post.id, edit.post_id)
      assert.same(old_body, edit.body_before)
      assert.same(1, post.edits_count)
      return assert.truthy(post.last_edited_at)
    end)
    it("should edit tags", function()
      local post = factory.Posts({
        user_id = current_user.id
      })
      local topic = post:get_topic()
      local category = topic:get_category()
      factory.CategoryTags({
        category_id = category.id,
        slug = "hello"
      })
      factory.CategoryTags({
        category_id = category.id,
        slug = "zone"
      })
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = post.id,
        ["post[body]"] = "good stuff",
        ["post[tags]"] = "hello,zone,woop"
      })
      topic:refresh()
      assert.same({
        "hello",
        "zone"
      }, topic.tags)
      return assert.same(2, #topic:get_tags())
    end)
    it("should edit post with reason", function()
      local post = factory.Posts({
        user_id = current_user.id
      })
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = post.id,
        ["post[body]"] = "the newer body",
        ["post[reason]"] = "changed something"
      })
      local old_body = post.body
      assert.truthy(res.success)
      post:refresh()
      assert.same("the newer body", post.body)
      local edit = unpack(PostEdits:select())
      assert(edit, "missing edit")
      assert.same(current_user.id, edit.user_id)
      assert.same(post.id, edit.post_id)
      assert.same(old_body, edit.body_before)
      assert.same("changed something", edit.reason)
      assert.same(1, post.edits_count)
      return assert.truthy(post.last_edited_at)
    end)
    it("should not create post edit when editing with unchanged body", function()
      local post = factory.Posts({
        user_id = current_user.id
      })
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = post.id,
        ["post[body]"] = post.body,
        ["post[reason]"] = "this will be ingored"
      })
      local edit = unpack(PostEdits:select())
      assert.falsy(edit)
      post:refresh()
      assert.same(0, post.edits_count)
      return assert.falsy(post.last_edited_at)
    end)
    it("should not edit invalid post", function()
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = 0,
        ["post[body]"] = "the new body",
        ["post[title]"] = "the new title"
      })
      return assert.truthy(res.errors)
    end)
    it("should not let stranger edit post", function()
      local post = factory.Posts()
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = post.id,
        ["post[body]"] = "the new body",
        ["post[title]"] = "the new title"
      })
      return assert.truthy(res.errors)
    end)
    it("should let moderator edit post", function()
      local post = factory.Posts()
      local topic = post:get_topic()
      factory.Moderators({
        user_id = current_user.id,
        object = topic:get_category()
      })
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = post.id,
        ["post[body]"] = "the new body",
        ["post[title]"] = "the new title"
      })
      assert.truthy(res.success)
      post:refresh()
      assert.same("the new body", post.body)
      return assert.same("the new title", post:get_topic().title)
    end)
    it("should edit nth post in topic", function()
      local topic = factory.Topics()
      local post1 = factory.Posts({
        topic_id = topic.id
      })
      local post2 = factory.Posts({
        topic_id = topic.id,
        user_id = current_user.id
      })
      local res = PostingApp:get(current_user, "/edit-post", {
        post_id = post2.id,
        ["post[body]"] = "the new body",
        ["post[title]"] = "the new title"
      })
      assert.truthy(res.success)
      post1:refresh()
      post2:refresh()
      local before_title = topic.title
      topic:refresh()
      assert.same("the new body", post2.body)
      return assert.same(before_title, topic.title)
    end)
    it("softs delete post with replies", function()
      local post = factory.Posts({
        user_id = current_user.id,
        topic_id = factory.Posts({
          user_id = current_user.id
        }).topic_id
      })
      factory.Posts({
        topic_id = post.topic_id,
        parent_post_id = post.id
      })
      local topic = post:get_topic()
      topic:increment_participant(current_user)
      local res = PostingApp:get(current_user, "/delete-post", {
        post_id = post.id
      })
      assert.truthy(res.success)
      post:refresh()
      assert.truthy(post.deleted)
      assert.truthy(post.deleted_at)
      assert.same(-1, CommunityUsers:for_user(current_user).posts_count)
      local tps = TopicParticipants:select("where topic_id = ?", topic.id)
      assert.same(0, #tps)
      topic:refresh()
      assert.same(nil, topic.last_post_id)
      assert.same(1, ActivityLogs:count())
      local log = unpack(ActivityLogs:select())
      assert.same(current_user.id, log.user_id)
      assert.same(post.id, log.object_id)
      assert.same(ActivityLogs.object_types.post, log.object_type)
      return assert.same("delete", log:action_name())
    end)
    it("should hard delete post", function()
      local post = factory.Posts({
        user_id = current_user.id,
        topic_id = factory.Posts({
          user_id = current_user.id
        }).topic_id
      })
      local topic = post:get_topic()
      topic:increment_participant(current_user)
      local res = PostingApp:get(current_user, "/delete-post", {
        post_id = post.id
      })
      assert.truthy(res.success)
      assert.same(nil, (Posts:find(post.id)))
      assert.same(-1, CommunityUsers:for_user(current_user).posts_count)
      local tps = TopicParticipants:select("where topic_id = ?", topic.id)
      assert.same(0, #tps)
      topic:refresh()
      assert.same(nil, topic.last_post_id)
      return assert.same(0, ActivityLogs:count())
    end)
    it("should delete primary post, deleting topic", function()
      local post = factory.Posts({
        user_id = current_user.id
      })
      local topic = post:get_topic()
      local res = PostingApp:get(current_user, "/delete-post", {
        post_id = post.id
      })
      topic:refresh()
      assert.truthy(topic.deleted)
      assert.truthy(topic.deleted_at)
      assert.same(1, ActivityLogs:count())
      local log = unpack(ActivityLogs:select())
      assert.same(current_user.id, log.user_id)
      assert.same(topic.id, log.object_id)
      assert.same(ActivityLogs.object_types.topic, log.object_type)
      return assert.same("delete", log:action_name())
    end)
    it("should delete primary post of permanent topic, keep topic", function()
      local topic = factory.Topics({
        user_id = current_user.id,
        permanent = true
      })
      local post = factory.Posts({
        topic_id = topic.id,
        user_id = current_user.id
      })
      Topics:recount({
        id = topic.id
      })
      local res = PostingApp:get(current_user, "/delete-post", {
        post_id = post.id
      })
      topic:refresh()
      assert.falsy(topic.deleted)
      return assert.same(0, topic.posts_count)
    end)
    it("should not delete unrelated post", function()
      local other_user = factory.Users()
      local post = factory.Posts({
        user_id = current_user.id
      })
      local res = PostingApp:get(other_user, "/delete-post", {
        post_id = post.id
      })
      return assert.same({
        errors = {
          "not allowed to edit"
        }
      }, res)
    end)
    it("should delete last post, refreshing topic on category and topic", function()
      local category = factory.Categories()
      local topic = factory.Topics({
        category = category
      })
      local p1 = factory.Posts({
        topic = topic
      })
      local p2 = factory.Posts({
        topic = topic
      })
      local other_topic = factory.Topics({
        category = category
      })
      local other_post = factory.Posts({
        topic = other_topic
      })
      local post = factory.Posts({
        topic = topic,
        user_id = current_user.id
      })
      category:refresh()
      topic:refresh()
      assert.same(topic.id, category.last_topic_id)
      assert.same(post.id, topic.last_post_id)
      local res = PostingApp:get(current_user, "/delete-post", {
        post_id = post.id
      })
      category:refresh()
      topic:refresh()
      assert.same(p2.id, topic.last_post_id)
      return assert.same(topic.id, category.last_topic_id)
    end)
    return it("hard deletes post that has been soft deleted", function()
      local moderator = factory.Users()
      local category = factory.Categories({
        user_id = moderator.id
      })
      local topic = factory.Topics({
        category = category,
        permanent = true
      })
      local post = factory.Posts({
        topic = topic,
        deleted = true
      })
      local res = PostingApp:get(moderator, "/delete-post", {
        post_id = post.id
      })
      return assert.same({ }, Posts:select())
    end)
  end)
end)
