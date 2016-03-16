local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local db = require("lapis.db")
local Users
Users = require("models").Users
local Bans, Categories, CategoryMembers, CategoryTags, Moderators, Posts, Topics, TopicSubscriptions, UserTopicLastSeens
do
  local _obj_0 = require("community.models")
  Bans, Categories, CategoryMembers, CategoryTags, Moderators, Posts, Topics, TopicSubscriptions, UserTopicLastSeens = _obj_0.Bans, _obj_0.Categories, _obj_0.CategoryMembers, _obj_0.CategoryTags, _obj_0.Moderators, _obj_0.Posts, _obj_0.Topics, _obj_0.TopicSubscriptions, _obj_0.UserTopicLastSeens
end
local factory = require("spec.factory")
local Model
Model = require("lapis.db.model").Model
return describe("models.topics", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Users, Categories, Moderators, CategoryMembers, Topics, Posts, Bans, UserTopicLastSeens, CategoryTags, TopicSubscriptions)
  end)
  it("should create a topic", function()
    factory.Topics()
    return factory.Topics({
      category = false
    })
  end)
  it("gets category tags", function()
    local topic = factory.Topics()
    local category = topic:get_category()
    local tag = factory.CategoryTags({
      category_id = category.id
    })
    topic:update({
      tags = db.array({
        tag.slug,
        "other-thing"
      })
    })
    local tags = topic:get_tags()
    assert.same(1, #tags)
    return assert.same(tag.label, tags[1].label)
  end)
  it("should check permissions of topic with category", function()
    local category_user = factory.Users()
    local category = factory.Categories({
      user_id = category_user.id
    })
    local topic = factory.Topics({
      category_id = category.id
    })
    local topic_user = topic:get_user()
    assert.truthy(topic:allowed_to_post(topic_user))
    assert.truthy(topic:allowed_to_view(topic_user))
    assert.truthy(topic:allowed_to_edit(topic_user))
    assert.falsy(topic:allowed_to_moderate(topic_user))
    local some_user = factory.Users()
    assert.truthy(topic:allowed_to_post(some_user))
    assert.truthy(topic:allowed_to_view(some_user))
    assert.falsy(topic:allowed_to_edit(some_user))
    assert.falsy(topic:allowed_to_moderate(some_user))
    local mod = factory.Moderators({
      object = topic:get_category()
    })
    local mod_user = mod:get_user()
    assert.truthy(topic:allowed_to_post(mod_user))
    assert.truthy(topic:allowed_to_view(mod_user))
    assert.truthy(topic:allowed_to_edit(mod_user))
    assert.truthy(topic:allowed_to_moderate(mod_user))
    assert.truthy(topic:allowed_to_post(category_user))
    assert.truthy(topic:allowed_to_view(category_user))
    assert.truthy(topic:allowed_to_edit(category_user))
    assert.truthy(topic:allowed_to_moderate(category_user))
    topic:archive()
    topic = Topics:find(topic.id)
    assert["false"](topic:allowed_to_post(topic_user))
    assert["true"](topic:allowed_to_view(topic_user))
    assert["false"](topic:allowed_to_edit(topic_user))
    assert["false"](topic:allowed_to_moderate(topic_user))
    assert["false"](topic:allowed_to_post(some_user))
    assert["true"](topic:allowed_to_view(some_user))
    assert["false"](topic:allowed_to_edit(some_user))
    assert["false"](topic:allowed_to_moderate(some_user))
    assert["false"](topic:allowed_to_post(mod_user))
    assert["true"](topic:allowed_to_view(mod_user))
    assert["false"](topic:allowed_to_edit(mod_user))
    return assert["true"](topic:allowed_to_moderate(mod_user))
  end)
  it("doesn't allow posts in locked topics", function()
    local category_user = factory.Users()
    local category = factory.Categories({
      user_id = category_user.id
    })
    local topic = factory.Topics({
      category_id = category.id,
      locked = true
    })
    local user = topic:get_user()
    return assert.falsy(topic:allowed_to_post(category_user))
  end)
  it("should check permissions of topic with members only category", function()
    local category_user = factory.Users()
    local category = factory.Categories({
      user_id = category_user.id,
      membership_type = Categories.membership_types.members_only
    })
    local topic = factory.Topics({
      category_id = category.id
    })
    local other_user = factory.Users()
    assert.falsy(topic:allowed_to_view(other_user))
    assert.falsy(topic:allowed_to_post(other_user))
    local member_user = factory.Users()
    factory.CategoryMembers({
      user_id = member_user.id,
      category_id = category.id
    })
    assert.truthy(topic:allowed_to_view(member_user))
    return assert.truthy(topic:allowed_to_post(member_user))
  end)
  it("should check permissions of topic without category", function()
    local topic = factory.Topics({
      category = false
    })
    local user = topic:get_user()
    assert.truthy(topic:allowed_to_post(user))
    assert.truthy(topic:allowed_to_view(user))
    assert.truthy(topic:allowed_to_edit(user))
    assert.falsy(topic:allowed_to_moderate(user))
    local other_user = factory.Users()
    assert.truthy(topic:allowed_to_post(other_user))
    assert.truthy(topic:allowed_to_view(other_user))
    assert.falsy(topic:allowed_to_edit(other_user))
    return assert.falsy(topic:allowed_to_moderate(other_user))
  end)
  it("should set category order", function()
    local one = factory.Topics({
      category_id = 123
    })
    local two = factory.Topics({
      category_id = 123
    })
    local three = factory.Topics({
      category_id = 123
    })
    assert.same(1, one.category_order)
    assert.same(2, two.category_order)
    assert.same(3, three.category_order)
    local post = factory.Posts({
      topic_id = one.id
    })
    one:increment_from_post(post)
    assert.same(4, one.category_order)
    local four = factory.Topics({
      category_id = 123
    })
    return assert.same(5, four.category_order)
  end)
  it("should check permission for banned user", function()
    local topic = factory.Topics()
    local banned_user = factory.Users()
    assert.falsy(topic:find_ban(banned_user))
    factory.Bans({
      object = topic,
      banned_user_id = banned_user.id
    })
    assert.truthy(topic:find_ban(banned_user))
    assert.falsy(topic:allowed_to_view(banned_user))
    return assert.falsy(topic:allowed_to_post(banned_user))
  end)
  it("should refresh last post id", function()
    local topic = factory.Topics()
    factory.Posts({
      topic_id = topic.id
    })
    local post = factory.Posts({
      topic_id = topic.id
    })
    factory.Posts({
      topic_id = topic.id,
      deleted = true
    })
    topic:refresh_last_post()
    return assert.same(post.id, topic.last_post_id)
  end)
  it("should refresh last post id to nil if there's only 1 post", function()
    local topic = factory.Topics()
    factory.Posts({
      topic_id = topic.id
    })
    topic:refresh_last_post()
    return assert.same(nil, topic.last_post_id)
  end)
  it("should not include archived post when refreshing last", function()
    local topic = factory.Topics()
    local posts
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, 3 do
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
    posts[3]:update({
      status = Posts.statuses.archived
    })
    topic:refresh_last_post()
    return assert.same(posts[2].id, topic.last_post_id)
  end)
  it("should not include archive and reset last post to nil", function()
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
    posts[2]:update({
      status = Posts.statuses.archived
    })
    topic:refresh_last_post()
    return assert["nil"](topic.last_post_id)
  end)
  it("should not mark for no last post", function()
    local user = factory.Users()
    local topic = factory.Topics()
    return topic:set_seen(user)
  end)
  it("should mark topic last seen", function()
    local user = factory.Users()
    local topic = factory.Topics()
    local post = factory.Posts({
      topic_id = topic.id
    })
    topic:increment_from_post(post)
    topic:set_seen(user)
    local last_seen = unpack(UserTopicLastSeens:select())
    assert.same(user.id, last_seen.user_id)
    assert.same(topic.id, last_seen.topic_id)
    assert.same(post.id, last_seen.post_id)
    topic:set_seen(user)
    local post2 = factory.Posts({
      topic_id = topic.id
    })
    topic:increment_from_post(post2)
    topic:set_seen(user)
    assert.same(1, UserTopicLastSeens:count())
    last_seen = unpack(UserTopicLastSeens:select())
    assert.same(user.id, last_seen.user_id)
    assert.same(topic.id, last_seen.topic_id)
    return assert.same(post2.id, last_seen.post_id)
  end)
  describe("delete", function()
    it("deletes a topic", function()
      local topic = factory.Topics()
      topic:delete()
      topic:refresh()
      return assert["true"](topic.deleted)
    end)
    return it("refreshes category when deleting topic", function()
      local category = factory.Categories()
      local t1 = factory.Topics({
        category = category
      })
      local t2 = factory.Topics({
        category = category
      })
      category:refresh()
      assert.same(t2.id, category.last_topic_id)
      t2:delete()
      category:refresh()
      return assert.same(t1.id, category.last_topic_id)
    end)
  end)
  describe("renumber_posts", function()
    it("renumbers root posts", function()
      local topic = factory.Topics()
      local p1 = factory.Posts({
        topic_id = topic.id
      })
      local p2 = factory.Posts({
        topic_id = topic.id
      })
      local p2_1 = factory.Posts({
        topic_id = topic.id,
        parent_post_id = p2.id
      })
      local p2_2 = factory.Posts({
        topic_id = topic.id,
        parent_post_id = p2.id
      })
      local p2_3 = factory.Posts({
        topic_id = topic.id,
        parent_post_id = p2.id
      })
      local p3 = factory.Posts({
        topic_id = topic.id
      })
      Model.delete(p1)
      topic:renumber_posts()
      local posts = Posts:select("where depth = 1 order by post_number")
      assert.same({
        1,
        2
      }, (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #posts do
          local p = posts[_index_0]
          _accum_0[_len_0] = p.post_number
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
      posts = Posts:select("where depth = 2 order by post_number")
      return assert.same({
        1,
        2,
        3
      }, (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #posts do
          local p = posts[_index_0]
          _accum_0[_len_0] = p.post_number
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    end)
    return it("renumbers nested posts posts", function()
      local topic = factory.Topics()
      local p1 = factory.Posts({
        topic_id = topic.id
      })
      local p1_1 = factory.Posts({
        topic_id = topic.id,
        parent_post_id = p1.id
      })
      local p2 = factory.Posts({
        topic_id = topic.id
      })
      local p2_1 = factory.Posts({
        topic_id = topic.id,
        parent_post_id = p2.id
      })
      local p2_2 = factory.Posts({
        topic_id = topic.id,
        parent_post_id = p2.id
      })
      local p2_3 = factory.Posts({
        topic_id = topic.id,
        parent_post_id = p2.id
      })
      local p3 = factory.Posts({
        topic_id = topic.id
      })
      Model.delete(p2_2)
      topic:renumber_posts(p2)
      local posts = Posts:select("where depth = 1 order by post_number")
      assert.same({
        1,
        2,
        3
      }, (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #posts do
          local p = posts[_index_0]
          _accum_0[_len_0] = p.post_number
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
      posts = Posts:select("where parent_post_id = ? order by post_number", p2.id)
      return assert.same({
        1,
        2
      }, (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #posts do
          local p = posts[_index_0]
          _accum_0[_len_0] = p.post_number
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    end)
  end)
  describe("get_root_order_ranges", function()
    it("gets order ranges in empty topic", function()
      local topic = factory.Topics()
      local min, max = topic:get_root_order_ranges()
      assert.same(nil, min)
      return assert.same(nil, max)
    end)
    it("gets order ranges topic with posts", function()
      local topic = factory.Topics()
      local p1 = factory.Posts({
        topic_id = topic.id
      })
      topic:increment_from_post(p1)
      local p2 = factory.Posts({
        topic_id = topic.id
      })
      topic:increment_from_post(p2)
      for i = 1, 3 do
        local pc = factory.Posts({
          topic_id = topic.id,
          parent_post_id = p1.id
        })
        topic:increment_from_post(pc)
      end
      local min, max = topic:get_root_order_ranges()
      assert.same(1, min)
      return assert.same(2, max)
    end)
    return it("ignores archive posts when getting order ranges", function()
      local topic = factory.Topics()
      local posts
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = 1, 3 do
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
      posts[1]:archive()
      local min, max = topic:get_root_order_ranges()
      assert.same(2, min)
      return assert.same(3, max)
    end)
  end)
  describe("bans", function()
    it("preloads bans on many topics when user is not banned", function()
      local user = factory.Users()
      local topics
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = 1, 3 do
          _accum_0[_len_0] = factory.Topics()
          _len_0 = _len_0 + 1
        end
        topics = _accum_0
      end
      Topics:preload_bans(topics, user)
      for _index_0 = 1, #topics do
        local t = topics[_index_0]
        assert.same({
          [user.id] = false
        }, t.user_bans)
      end
    end)
    return it("preloads bans user", function()
      local user = factory.Users()
      local other_user = factory.Users()
      local topics
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = 1, 3 do
          _accum_0[_len_0] = factory.Topics()
          _len_0 = _len_0 + 1
        end
        topics = _accum_0
      end
      local b1 = factory.Bans({
        object = topics[1],
        banned_user_id = user.id
      })
      local b2 = factory.Bans({
        object = topics[2],
        banned_user_id = other_user.id
      })
      Topics:preload_bans(topics, user)
      assert.same({
        [user.id] = b1
      }, topics[1].user_bans)
      assert.same({
        [user.id] = false
      }, topics[2].user_bans)
      return assert.same({
        [user.id] = false
      }, topics[3].user_bans)
    end)
  end)
  describe("subscribe", function()
    local fetch_subs
    fetch_subs = function()
      return TopicSubscriptions:select("order by user_id, topic_id", {
        fields = "user_id, topic_id, subscribed"
      })
    end
    it("gets topic subscriptions", function()
      local topic = factory.Topics()
      assert.same({ }, topic:get_subscriptions())
      topic:refresh()
      TopicSubscriptions:create({
        user_id = -1,
        topic_id = topic.id
      })
      return assert.same(1, #topic:get_subscriptions())
    end)
    it("subscribes user to topic", function()
      local topic = factory.Topics()
      local user = factory.Users()
      for i = 1, 2 do
        topic:subscribe(user)
        assert.same({
          {
            topic_id = topic.id,
            user_id = user.id,
            subscribed = true
          }
        }, fetch_subs())
      end
    end)
    it("topic creator subscribing is noop", function()
      local topic = factory.Topics()
      local user = topic:get_user()
      topic:subscribe(user)
      return assert.same({ }, fetch_subs())
    end)
    it("unsubscribe with no sub is noop", function()
      local topic = factory.Topics()
      local user = factory.Users()
      topic:unsubscribe(user)
      return assert.same({ }, fetch_subs())
    end)
    it("topic owner unsubscribes", function()
      local topic = factory.Topics()
      local user = topic:get_user()
      for i = 1, 2 do
        topic:unsubscribe(user)
        assert.same({
          {
            topic_id = topic.id,
            user_id = user.id,
            subscribed = false
          }
        }, fetch_subs())
      end
    end)
    it("regular user unsubscibes", function()
      local topic = factory.Topics()
      local user1 = factory.Users()
      local user2 = factory.Users()
      topic:subscribe(user1)
      topic:subscribe(user2)
      topic:unsubscribe(user1)
      return assert.same({
        {
          topic_id = topic.id,
          user_id = user2.id,
          subscribed = true
        }
      }, fetch_subs())
    end)
    it("gets notification targets for topic with no subs", function()
      local topic = factory.Topics()
      local targets = topic:notification_target_users()
      return assert.same({
        topic.user_id
      }, (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #targets do
          local t = targets[_index_0]
          _accum_0[_len_0] = t.id
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    end)
    it("gets notification targets for topic with subs", function()
      local topic = factory.Topics()
      local user = factory.Users()
      topic:subscribe(user)
      local targets = topic:notification_target_users()
      local target_ids
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #targets do
          local t = targets[_index_0]
          _accum_0[_len_0] = t.id
          _len_0 = _len_0 + 1
        end
        target_ids = _accum_0
      end
      table.sort(target_ids)
      return assert.same({
        topic.user_id,
        user.id
      }, target_ids)
    end)
    it("gets empty notification targets when owner has unsubscribed", function()
      local topic = factory.Topics()
      topic:unsubscribe(topic:get_user())
      return assert.same({ }, topic:notification_target_users())
    end)
    return it("gets targets for subs and unsubs", function()
      local topic = factory.Topics()
      local user = factory.Users()
      topic:unsubscribe(topic:get_user())
      topic:subscribe(user)
      return assert.same({
        user.id
      }, (function()
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = topic:notification_target_users()
        for _index_0 = 1, #_list_0 do
          local t = _list_0[_index_0]
          _accum_0[_len_0] = t.id
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    end)
  end)
  return describe("moving topic", function()
    local old_category, new_category, topic
    before_each(function()
      old_category = factory.Categories()
      new_category = factory.Categories()
      topic = factory.Topics({
        category = old_category
      })
    end)
    it("should move basic topic", function()
      topic:move_to_category(new_category)
      topic:refresh()
      assert.same(new_category.id, topic.category_id)
      assert.same(0, old_category.topics_count)
      return assert.same(1, new_category.topics_count)
    end)
    return it("moves a topic with more relations #ddd", function()
      local ModerationLogs, PostReports
      do
        local _obj_0 = require("community.models")
        ModerationLogs, PostReports = _obj_0.ModerationLogs, _obj_0.PostReports
      end
      truncate_tables(ModerationLogs, PostReports)
      local mod_log = ModerationLogs:create({
        object = topic,
        category_id = old_category.id,
        user_id = -1,
        action = "hello.world",
        reason = "no reason"
      })
      local other_mod_log = ModerationLogs:create({
        object = factory.Topics(),
        category_id = -1,
        user_id = -1,
        action = "another.world",
        reason = "some reason"
      })
      local report = factory.PostReports({
        post_id = factory.Posts({
          topic = topic
        }).id
      })
      local other_report = factory.PostReports()
      local pending = factory.PendingPosts({
        topic = topic
      })
      local other_pending = factory.PendingPosts()
      topic:move_to_category(new_category)
      topic:refresh()
      assert.same(new_category.id, topic.category_id)
      mod_log:refresh()
      other_mod_log:refresh()
      assert.same(new_category.id, mod_log.category_id)
      assert.same(-1, other_mod_log.category_id)
      report:refresh()
      assert.same(new_category.id, report.category_id)
      local old_other_report_category_id = other_report.category_id
      other_report:refresh()
      assert.same(old_other_report_category_id, other_report.category_id)
      pending:refresh()
      assert.same(new_category.id, pending.category_id)
      local other_pending_category_id = other_pending.category_id
      other_pending:refresh()
      assert.same(other_pending_category_id, other_pending.category_id)
      topic:refresh()
      assert.same(new_category.id, topic.category_id)
      old_category:refresh()
      new_category:refresh()
      assert["nil"](old_category.last_topic_id)
      assert.same(topic.id, new_category.last_topic_id)
      assert.same(0, old_category.topics_count)
      return assert.same(1, new_category.topics_count)
    end)
  end)
end)
