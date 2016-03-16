local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Topics, Posts
do
  local _obj_0 = require("community.models")
  Categories, Topics, Posts = _obj_0.Categories, _obj_0.Topics, _obj_0.Posts
end
local db = require("lapis.db")
local factory = require("spec.factory")
return describe("models.posts", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Users, Categories, Topics, Posts)
  end)
  it("checks permissions", function()
    local post_user = factory.Users()
    local topic = factory.Topics()
    local post = factory.Posts({
      user_id = post_user.id,
      topic_id = topic.id
    })
    local topic_user = post:get_topic():get_user()
    local some_user = factory.Users()
    local admin_user
    do
      local _with_0 = factory.Users()
      _with_0.is_admin = function(self)
        return true
      end
      admin_user = _with_0
    end
    assert["false"](post:allowed_to_edit(nil))
    assert["false"](post:allowed_to_edit(topic_user))
    assert["false"](post:allowed_to_edit(some_user))
    assert["true"](post:allowed_to_edit(post_user))
    assert["true"](post:allowed_to_edit(admin_user))
    assert["false"](post:allowed_to_reply(nil))
    assert["true"](post:allowed_to_reply(post_user))
    assert["true"](post:allowed_to_reply(topic_user))
    assert["true"](post:allowed_to_reply(some_user))
    assert["false"](post:allowed_to_report(nil))
    assert["false"](post:allowed_to_report(post_user))
    assert["true"](post:allowed_to_report(topic_user))
    assert["true"](post:allowed_to_report(some_user))
    post:archive()
    post = Posts:find(post.id)
    assert["false"](post:allowed_to_edit(nil))
    assert["false"](post:allowed_to_edit(topic_user))
    assert["false"](post:allowed_to_edit(some_user))
    assert["false"](post:allowed_to_edit(post_user))
    assert["true"](post:allowed_to_edit(admin_user))
    assert["false"](post:allowed_to_reply(nil))
    assert["false"](post:allowed_to_reply(post_user))
    assert["false"](post:allowed_to_reply(topic_user))
    assert["false"](post:allowed_to_reply(some_user))
    assert["false"](post:allowed_to_reply(admin_user))
    assert["false"](post:allowed_to_report(nil))
    assert["false"](post:allowed_to_report(post_user))
    assert["false"](post:allowed_to_report(topic_user))
    assert["false"](post:allowed_to_report(some_user))
    return assert["false"](post:allowed_to_report(admin_user))
  end)
  describe("has_replies", function()
    it("with no replies", function()
      local post = factory.Posts()
      return assert.same(false, post:has_replies())
    end)
    return it("with replies", function()
      local post = factory.Posts()
      factory.Posts({
        topic_id = post.topic_id,
        parent_post_id = post.id
      })
      return assert.same(true, post:has_replies())
    end)
  end)
  describe("has_next_post", function()
    it("singular post", function()
      local post = factory.Posts()
      return assert.same(false, post:has_next_post())
    end)
    it("with reply", function()
      local post = factory.Posts()
      factory.Posts({
        topic_id = post.topic_id,
        parent_post_id = post.id
      })
      return assert.same(false, post:has_next_post())
    end)
    it("with series", function()
      local p1 = factory.Posts()
      local p2 = factory.Posts({
        topic_id = p1.topic_id
      })
      return assert.same(true, p1:has_next_post())
    end)
    return it("with children", function()
      local p1 = factory.Posts()
      local p1_1 = factory.Posts({
        parent_post_id = p1.id,
        topic_id = p1.topic_id
      })
      local p2 = factory.Posts({
        topic_id = p1.topic_id
      })
      local p2_1 = factory.Posts({
        parent_post_id = p2.id,
        topic_id = p1.topic_id
      })
      local p2_2 = factory.Posts({
        parent_post_id = p2.id,
        topic_id = p1.topic_id
      })
      assert.same(true, p2_1:has_next_post())
      assert.same(false, p2_2:has_next_post())
      return assert.same(false, p1_1:has_next_post())
    end)
  end)
  describe("set status", function()
    it("updates post to spam", function()
      local post = factory.Posts()
      return post:set_status("spam")
    end)
    return it("updates topic last post when archiving", function()
      local post = factory.Posts()
      local topic = post:get_topic()
      topic:increment_from_post(post)
      topic:refresh()
      assert.same(topic.last_post_id, post.id)
      post:archive()
      topic:refresh()
      return assert["nil"](topic.last_post_id)
    end)
  end)
  describe("delete", function()
    local topic, post
    before_each(function()
      topic = factory.Topics({
        permanent = true
      })
      post = factory.Posts({
        topic = topic
      })
    end)
    it("deletes topic that is the root of non permanent", function()
      topic:update({
        permanent = false
      })
      post:delete()
      topic:refresh()
      return assert["true"](topic.deleted)
    end)
    it("deletes orphaned posts when hard deleting", function()
      local other_post = factory.Posts({
        topic = topic
      })
      local child_1 = factory.Posts({
        topic = topic,
        parent_post_id = post.id
      })
      local child_2 = factory.Posts({
        topic = topic,
        parent_post_id = child_1.id
      })
      post:hard_delete()
      return assert.same({
        [other_post.id] = true
      }, (function()
        local _tbl_0 = { }
        local _list_0 = Posts:select()
        for _index_0 = 1, #_list_0 do
          post = _list_0[_index_0]
          _tbl_0[post.id] = true
        end
        return _tbl_0
      end)())
    end)
    it("soft deletes a post", function()
      post:soft_delete()
      post:refresh()
      return assert.same(true, post.deleted)
    end)
    it("hard deletes a post", function()
      assert.same(1, topic.root_posts_count)
      assert.same(1, topic.posts_count)
      post:hard_delete()
      topic:refresh()
      assert.same(0, topic.root_posts_count)
      return assert.same(0, topic.posts_count)
    end)
    it("hard deletes young post with no replies", function()
      post:delete()
      return assert.same(nil, (Posts:find(post.id)))
    end)
    it("soft deletes for posts with next post", function()
      factory.Posts({
        topic_id = post.topic_id
      })
      post:delete()
      post:refresh()
      return assert.same(true, post.deleted)
    end)
    it("soft deletes post with replies", function()
      factory.Posts({
        topic_id = post.topic_id,
        parent_post_id = post.id
      })
      post:delete()
      post:refresh()
      return assert.same(true, post.deleted)
    end)
    return it("soft deletes old post", function()
      post:update({
        created_at = db.raw("now() at time zone 'utc' - '1.5 hours'::interval")
      })
      post:delete()
      post:refresh()
      return assert.same(true, post.deleted)
    end)
  end)
  it("should create a series of posts in same topic", function()
    local posts
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, 5 do
        _accum_0[_len_0] = factory.Posts({
          topic_id = 1
        })
        _len_0 = _len_0 + 1
      end
      posts = _accum_0
    end
    return assert.same((function()
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, 5 do
        _accum_0[_len_0] = i
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)(), (function()
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
  it("should create correct post numbers for nested posts", function()
    local root1 = factory.Posts({
      topic_id = 1
    })
    assert.same(1, root1.post_number)
    local root2 = factory.Posts({
      topic_id = 1
    })
    assert.same(2, root2.post_number)
    local child1 = factory.Posts({
      topic_id = 1,
      parent_post = root1
    })
    local child2 = factory.Posts({
      topic_id = 1,
      parent_post = root1
    })
    assert.same(1, child1.post_number)
    assert.same(2, child2.post_number)
    local other_child1 = factory.Posts({
      topic_id = 1,
      parent_post = root2
    })
    local other_child2 = factory.Posts({
      topic_id = 1,
      parent_post = root2
    })
    assert.same(1, other_child1.post_number)
    assert.same(2, other_child2.post_number)
    local root3 = factory.Posts({
      topic_id = 1
    })
    assert.same(3, root3.post_number)
    local current = root3
    for i = 1, 3 do
      current = factory.Posts({
        topic_id = 1,
        parent_post = current
      })
      assert.same(1, current.post_number)
    end
  end)
  describe("with post, topic, category", function()
    local post, topic, category
    before_each(function()
      category = factory.Categories()
      topic = factory.Topics({
        category_id = category.id
      })
      post = factory.Posts({
        topic_id = topic.id
      })
    end)
    it("should check vote status on up down", function()
      category:update({
        voting_type = Categories.voting_types.up_down
      })
      local other_user = factory.Users()
      assert.falsy(post:allowed_to_vote(nil))
      assert.truthy(post:allowed_to_vote(other_user, "up"))
      return assert.truthy(post:allowed_to_vote(other_user, "down"))
    end)
    it("should check vote status on up", function()
      category:update({
        voting_type = Categories.voting_types.up
      })
      local other_user = factory.Users()
      assert.falsy(post:allowed_to_vote(nil))
      assert.truthy(post:allowed_to_vote(other_user, "up"))
      return assert.falsy(post:allowed_to_vote(other_user, "down"))
    end)
    return it("should check vote status on disabled", function()
      category:update({
        voting_type = Categories.voting_types.disabled
      })
      local other_user = factory.Users()
      assert.falsy(post:allowed_to_vote(nil))
      assert.falsy(post:allowed_to_vote(other_user, "up"))
      return assert.falsy(post:allowed_to_vote(other_user, "down"))
    end)
  end)
  it("should get mentions for post", function()
    factory.Users({
      username = "mentioned_person"
    })
    local post = factory.Posts({
      body = "hello @mentioned_person how are you doing @mentioned_person I am @nonexist"
    })
    return assert.same({
      "mentioned_person"
    }, (function()
      local _accum_0 = { }
      local _len_0 = 1
      local _list_0 = post:get_mentioned_users()
      for _index_0 = 1, #_list_0 do
        local u = _list_0[_index_0]
        _accum_0[_len_0] = u.username
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
  end)
  it("should preload mentions for many posts", function()
    factory.Users({
      username = "mentioned_person1"
    })
    factory.Users({
      username = "mentioned_person2"
    })
    local posts = {
      factory.Posts({
        body = "hello @mentioned_person1 how are you doing @nonexist"
      }),
      factory.Posts({
        body = "this is @mentioned_person2 how are you doing"
      }),
      factory.Posts({
        body = "this is @mentioned_person2 how are you @mentioned_person1"
      }),
      factory.Posts({
        body = "this is @nothing"
      })
    }
    Posts:preload_mentioned_users(posts)
    local usernames
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #posts do
        local post = posts[_index_0]
        do
          local _accum_1 = { }
          local _len_1 = 1
          local _list_0 = post.mentioned_users
          for _index_1 = 1, #_list_0 do
            local u = _list_0[_index_1]
            _accum_1[_len_1] = u.username
            _len_1 = _len_1 + 1
          end
          _accum_0[_len_0] = _accum_1
        end
        _len_0 = _len_0 + 1
      end
      usernames = _accum_0
    end
    assert.same({
      "mentioned_person1"
    }, usernames[1])
    assert.same({
      "mentioned_person2"
    }, usernames[2])
    assert.same({
      "mentioned_person2",
      "mentioned_person1"
    }, usernames[3])
    return assert.same({ }, usernames[4])
  end)
  describe("mention targets", function()
    it("gets no targets for first post", function()
      local post = factory.Posts()
      return assert.same({ }, post:notification_targets())
    end)
    it("gets targets for post in topic", function()
      local root = factory.Posts()
      local topic = root:get_topic()
      topic:increment_from_post(root)
      local post = factory.Posts({
        topic_id = topic.id
      })
      topic:increment_from_post(post)
      local _list_0 = post:notification_targets()
      for _index_0 = 1, #_list_0 do
        local _des_0 = _list_0[_index_0]
        local kind, user
        kind, user = _des_0[1], _des_0[2]
        assert.same("post", kind)
        assert.same(topic.user_id, user.id)
      end
    end)
    it("gets targets for post in topic reply", function()
      local root = factory.Posts()
      local topic = root:get_topic()
      topic:increment_from_post(root)
      local post = factory.Posts({
        parent_post_id = root.id,
        topic_id = topic.id
      })
      topic:increment_from_post(post)
      local _list_0 = post:notification_targets()
      for _index_0 = 1, #_list_0 do
        local _des_0 = _list_0[_index_0]
        local kind, user, parent
        kind, user, parent = _des_0[1], _des_0[2], _des_0[3]
        assert.same("reply", kind)
        assert.same(topic.user_id, user.id)
        assert(parent.__class == Posts)
        assert.same(root.id, parent.id)
      end
    end)
    it("gets target for category owner", function()
      local category_user = factory.Users()
      local category = factory.Categories({
        user_id = category_user.id
      })
      local topic = factory.Topics({
        category_id = category.id
      })
      local post = factory.Posts({
        topic_id = topic.id,
        user_id = topic.user_id
      })
      local tuples = post:notification_targets()
      assert.same(1, #tuples)
      local tuple = unpack(tuples)
      assert.same("topic", tuple[1])
      assert.same(category_user.id, tuple[2].id)
      assert(Categories == tuple[3].__class)
      return assert.same(category.id, tuple[3].id)
    end)
    return it("gets target for category group owner owner", function()
      local CategoryGroupCategories, CategoryGroups
      do
        local _obj_0 = require("community.models")
        CategoryGroupCategories, CategoryGroups = _obj_0.CategoryGroupCategories, _obj_0.CategoryGroups
      end
      truncate_tables(CategoryGroupCategories, CategoryGroups)
      local category_group_user = factory.Users()
      local group = factory.CategoryGroups({
        user_id = category_group_user.id
      })
      local category = factory.Categories()
      group:add_category(category)
      local topic = factory.Topics({
        category_id = category.id
      })
      local post = factory.Posts({
        topic_id = topic.id,
        user_id = topic.user_id
      })
      local tuples = post:notification_targets()
      assert.same(1, #tuples)
      local tuple = unpack(tuples)
      assert.same("topic", tuple[1])
      assert.same(category_group_user.id, tuple[2].id)
      assert(CategoryGroups == tuple[3].__class)
      return assert.same(group.id, tuple[3].id)
    end)
  end)
  it("gets ancestors of post", function()
    return assert.same({ }, factory.Posts():get_ancestors())
  end)
  it("gets ancestors of nested post", function()
    local parent = factory.Posts()
    local post = factory.Posts({
      topic_id = parent.topic_id,
      parent_post_id = parent.id
    })
    return assert.same({
      parent.id
    }, (function()
      local _accum_0 = { }
      local _len_0 = 1
      local _list_0 = post:get_ancestors()
      for _index_0 = 1, #_list_0 do
        local p = _list_0[_index_0]
        _accum_0[_len_0] = p.id
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
  end)
  it("gets ancestors of many nested post in deep first", function()
    local post = factory.Posts()
    local ids
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, 5 do
        do
          local _with_0 = post.id
          post = factory.Posts({
            topic_id = post.topic_id,
            parent_post_id = post.id
          })
          _accum_0[_len_0] = _with_0
        end
        _len_0 = _len_0 + 1
      end
      ids = _accum_0
    end
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = #ids, 1, -1 do
        _accum_0[_len_0] = ids[i]
        _len_0 = _len_0 + 1
      end
      ids = _accum_0
    end
    local ancestors = post:get_ancestors()
    assert.same(ids, (function()
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #ancestors do
        local p = ancestors[_index_0]
        _accum_0[_len_0] = p.id
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
    return assert.same((function()
      local _accum_0 = { }
      local _len_0 = 1
      for i = 5, 1, -1 do
        _accum_0[_len_0] = i
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)(), (function()
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #ancestors do
        local p = ancestors[_index_0]
        _accum_0[_len_0] = p.depth
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
  end)
  return it("gets root ancestor", function()
    local post = factory.Posts()
    local root_post = post
    for i = 1, 5 do
      post = factory.Posts({
        topic_id = post.topic_id,
        parent_post_id = post.id
      })
    end
    local ancestor = post:get_root_ancestor()
    assert.same(root_post.id, ancestor.id)
    return assert.same(1, ancestor.depth)
  end)
end)
