import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Users from require "models"
import Categories, Moderators, CategoryMembers, Topics, Posts, Bans, UserTopicLastSeens from require "community.models"

factory = require "spec.factory"

import Model from require "lapis.db.model"

describe "models.topics", ->
  use_test_env!

  before_each ->
    truncate_tables Users, Categories, Moderators, CategoryMembers, Topics, Posts, Bans, UserTopicLastSeens

  it "should create a topic", ->
    factory.Topics!
    factory.Topics category: false

  it "should check permissions of topic with category", ->
    category_user = factory.Users!
    category = factory.Categories user_id: category_user.id

    topic = factory.Topics category_id: category.id
    user = topic\get_user!

    assert.truthy topic\allowed_to_post user
    assert.truthy topic\allowed_to_view user
    assert.truthy topic\allowed_to_edit user
    assert.falsy topic\allowed_to_moderate user

    other_user = factory.Users!

    assert.truthy topic\allowed_to_post other_user
    assert.truthy topic\allowed_to_view other_user
    assert.falsy topic\allowed_to_edit other_user
    assert.falsy topic\allowed_to_moderate other_user

    mod = factory.Moderators object: topic\get_category!
    mod_user = mod\get_user!

    assert.truthy topic\allowed_to_post mod_user
    assert.truthy topic\allowed_to_view mod_user
    assert.truthy topic\allowed_to_edit mod_user
    assert.truthy topic\allowed_to_moderate mod_user

    -- 

    assert.truthy topic\allowed_to_post category_user
    assert.truthy topic\allowed_to_view category_user
    assert.truthy topic\allowed_to_edit category_user
    assert.truthy topic\allowed_to_moderate category_user

  it "doesn't allow posts in locked topics", ->
    category_user = factory.Users!
    category = factory.Categories user_id: category_user.id

    topic = factory.Topics category_id: category.id, locked: true
    user = topic\get_user!

    assert.falsy topic\allowed_to_post category_user

  it "should check permissions of topic with members only category", ->
    category_user = factory.Users!
    category = factory.Categories {
      user_id: category_user.id
      membership_type: Categories.membership_types.members_only
    }

    topic = factory.Topics category_id: category.id

    other_user = factory.Users!
    assert.falsy topic\allowed_to_view other_user
    assert.falsy topic\allowed_to_post other_user

    member_user = factory.Users!
    factory.CategoryMembers user_id: member_user.id, category_id: category.id

    assert.truthy topic\allowed_to_view member_user
    assert.truthy topic\allowed_to_post member_user

  it "should check permissions of topic without category", ->
    topic = factory.Topics category: false

    user = topic\get_user!

    assert.truthy topic\allowed_to_post user
    assert.truthy topic\allowed_to_view user
    assert.truthy topic\allowed_to_edit user
    assert.falsy topic\allowed_to_moderate user

    other_user = factory.Users!

    assert.truthy topic\allowed_to_post other_user
    assert.truthy topic\allowed_to_view other_user
    assert.falsy topic\allowed_to_edit other_user
    assert.falsy topic\allowed_to_moderate other_user

  it "should set category order", ->
    one = factory.Topics category_id: 123
    two = factory.Topics category_id: 123
    three = factory.Topics category_id: 123

    assert.same 1, one.category_order
    assert.same 2, two.category_order
    assert.same 3, three.category_order

    post = factory.Posts topic_id: one.id
    one\increment_from_post post
    assert.same 4, one.category_order

    four = factory.Topics category_id: 123
    assert.same 5, four.category_order

  it "should check permission for banned user", ->
    topic = factory.Topics!
    banned_user = factory.Users!

    assert.falsy topic\find_ban banned_user
    factory.Bans object: topic, banned_user_id: banned_user.id
    assert.truthy topic\find_ban banned_user

    assert.falsy topic\allowed_to_view banned_user
    assert.falsy topic\allowed_to_post banned_user

  it "should refresh last post id", ->
    topic = factory.Topics!
    factory.Posts topic_id: topic.id -- first
    post = factory.Posts topic_id: topic.id
    factory.Posts topic_id: topic.id, deleted: true

    topic\refresh_last_post!
    assert.same post.id, topic.last_post_id

  it "should refresh last post id to nil if there's only 1 post", ->
    topic = factory.Topics!
    factory.Posts topic_id: topic.id -- first

    topic\refresh_last_post!
    assert.same nil, topic.last_post_id

  it "should not mark for no last post", ->
    user = factory.Users!
    topic = factory.Topics!
    topic\set_seen user

  it "should not mark for no last post", ->
    user = factory.Users!
    topic = factory.Topics!
    post = factory.Posts topic_id: topic.id
    topic\increment_from_post post

    topic\set_seen user
    last_seen = unpack UserTopicLastSeens\select!
    assert.same user.id, last_seen.user_id
    assert.same topic.id, last_seen.topic_id
    assert.same post.id, last_seen.post_id

    -- noop
    topic\set_seen user

    -- update

    post2 = factory.Posts topic_id: topic.id
    topic\increment_from_post post2

    topic\set_seen user

    assert.same 1, UserTopicLastSeens\count!
    last_seen = unpack UserTopicLastSeens\select!

    assert.same user.id, last_seen.user_id
    assert.same topic.id, last_seen.topic_id
    assert.same post2.id, last_seen.post_id

  describe "renumber_posts", ->
    it "renumbers root posts", ->
      topic = factory.Topics!
      p1 = factory.Posts topic_id: topic.id
      p2 = factory.Posts topic_id: topic.id

      p2_1 = factory.Posts topic_id: topic.id, parent_post_id: p2.id
      p2_2 = factory.Posts topic_id: topic.id, parent_post_id: p2.id
      p2_3 = factory.Posts topic_id: topic.id, parent_post_id: p2.id

      p3 = factory.Posts topic_id: topic.id
      Model.delete p1

      topic\renumber_posts!

      posts = Posts\select "where depth = 1 order by post_number"
      assert.same {1,2}, [p.post_number for p in *posts]

      posts = Posts\select "where depth = 2 order by post_number"
      assert.same {1,2,3}, [p.post_number for p in *posts]

    it "renumbers nested posts posts", ->
      topic = factory.Topics!
      p1 = factory.Posts topic_id: topic.id
      p1_1 = factory.Posts topic_id: topic.id, parent_post_id: p1.id

      p2 = factory.Posts topic_id: topic.id
      p2_1 = factory.Posts topic_id: topic.id, parent_post_id: p2.id
      p2_2 = factory.Posts topic_id: topic.id, parent_post_id: p2.id
      p2_3 = factory.Posts topic_id: topic.id, parent_post_id: p2.id

      p3 = factory.Posts topic_id: topic.id

      Model.delete p2_2

      topic\renumber_posts p2

      posts = Posts\select "where depth = 1 order by post_number"
      assert.same {1,2,3}, [p.post_number for p in *posts]

      posts = Posts\select "where parent_post_id = ? order by post_number", p2.id
      assert.same {1,2}, [p.post_number for p in *posts]

  describe "get_root_order_ranges", ->
    it "gets order ranges in empty topic", ->
      topic = factory.Topics!
      min, max = topic\get_root_order_ranges!

      assert.same nil, min
      assert.same nil, max

    it "gets order ranges topic with posts", ->
      topic = factory.Topics!
      p1 = factory.Posts topic_id: topic.id
      topic\increment_from_post p1

      p2 = factory.Posts topic_id: topic.id
      topic\increment_from_post p2

      for i=1,3
        pc = factory.Posts topic_id: topic.id, parent_post_id: p1.id
        topic\increment_from_post pc

      min, max = topic\get_root_order_ranges!

      assert.same 1, min
      assert.same 2, max

    it "ignores archive posts when getting order ranges", ->
      topic = factory.Topics!

      posts = for i=1,3
        with post = factory.Posts topic_id: topic.id
          topic\increment_from_post post

      posts[1]\archive!

      min, max = topic\get_root_order_ranges!
      assert.same 2, min
      assert.same 3, max

