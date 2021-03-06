import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Users from require "models"
import Categories, Topics, Posts from require "community.models"

db = require "lapis.db"

factory = require "spec.factory"

describe "models.posts", ->
  use_test_env!

  before_each ->
    truncate_tables Users, Categories, Topics, Posts

  it "checks permissions", ->
    post_user = factory.Users!
    topic = factory.Topics!
    post = factory.Posts user_id: post_user.id, topic_id: topic.id
    topic_user = post\get_topic!\get_user!
    some_user = factory.Users!

    admin_user = with factory.Users!
      .is_admin = => true

    assert.false post\allowed_to_edit nil
    assert.false post\allowed_to_edit topic_user
    assert.false post\allowed_to_edit some_user
    assert.true post\allowed_to_edit post_user
    assert.true post\allowed_to_edit admin_user
    -- otherwise hits topic\allowed_to_moderate

    assert.false post\allowed_to_reply nil
    assert.true post\allowed_to_reply post_user
    assert.true post\allowed_to_reply topic_user
    assert.true post\allowed_to_reply some_user

    assert.false post\allowed_to_report nil
    assert.false post\allowed_to_report post_user
    assert.true post\allowed_to_report topic_user
    assert.true post\allowed_to_report some_user

    -- archived
    post\archive!
    post = Posts\find post.id

    assert.false post\allowed_to_edit nil
    assert.false post\allowed_to_edit topic_user
    assert.false post\allowed_to_edit some_user
    assert.false post\allowed_to_edit post_user
    assert.true post\allowed_to_edit admin_user
    -- otherwise hits topic\allowed_to_moderate

    assert.false post\allowed_to_reply nil
    assert.false post\allowed_to_reply post_user
    assert.false post\allowed_to_reply topic_user
    assert.false post\allowed_to_reply some_user
    assert.false post\allowed_to_reply admin_user

    assert.false post\allowed_to_report nil
    assert.false post\allowed_to_report post_user
    assert.false post\allowed_to_report topic_user
    assert.false post\allowed_to_report some_user
    assert.false post\allowed_to_report admin_user

  describe "has_replies", ->
    it "with no replies", ->
      post = factory.Posts!
      assert.same false, post\has_replies!

    it "with replies", ->
      post = factory.Posts!
      factory.Posts topic_id: post.topic_id, parent_post_id: post.id
      assert.same true, post\has_replies!

  describe "has_next_post", ->
    it "singular post", ->
      post = factory.Posts!
      assert.same false, post\has_next_post!

    it "with reply", ->
      post = factory.Posts!
      factory.Posts topic_id: post.topic_id, parent_post_id: post.id
      assert.same false, post\has_next_post!

    it "with series", ->
      p1 = factory.Posts!
      p2 = factory.Posts topic_id: p1.topic_id
      assert.same true, p1\has_next_post!

    it "with children", ->
      p1 = factory.Posts!
      p1_1 = factory.Posts parent_post_id: p1.id, topic_id: p1.topic_id
      p2 = factory.Posts topic_id: p1.topic_id
      p2_1 = factory.Posts parent_post_id: p2.id, topic_id: p1.topic_id
      p2_2 = factory.Posts parent_post_id: p2.id, topic_id: p1.topic_id

      assert.same true, p2_1\has_next_post!
      assert.same false, p2_2\has_next_post!
      assert.same false, p1_1\has_next_post!

  describe "set status", ->
    it "updates post to spam", ->
      post = factory.Posts!
      post\set_status "spam"

    it "updates topic last post when archiving", ->
      post = factory.Posts!

      topic = post\get_topic!
      topic\increment_from_post post

      topic\refresh!
      assert.same topic.last_post_id, post.id

      post\archive!

      topic\refresh!
      assert.nil topic.last_post_id

  describe "delete", ->
    local topic, post
    before_each ->
      -- permanent so the topic doesn't get deleted with the first poots
      topic = factory.Topics permanent: true
      post = factory.Posts :topic

    it "deletes topic that is the root of non permanent", ->
      topic\update permanent: false
      post\delete!
      topic\refresh!
      assert.true topic.deleted

    it "deletes orphaned posts when hard deleting", ->
      other_post = factory.Posts :topic

      child_1 = factory.Posts :topic, parent_post_id: post.id
      child_2 = factory.Posts :topic, parent_post_id: child_1.id
      post\hard_delete!
      assert.same {[other_post.id]: true}, {post.id, true for post in *Posts\select!}

    it "soft deletes a post", ->
      post\soft_delete!
      post\refresh!
      assert.same true, post.deleted

    it "hard deletes a post", ->
      assert.same 1, topic.root_posts_count
      assert.same 1, topic.posts_count

      post\hard_delete!
      topic\refresh!

      assert.same 0, topic.root_posts_count
      assert.same 0, topic.posts_count

    it "hard deletes young post with no replies", ->
      post\delete!
      assert.same nil, (Posts\find post.id)

    it "soft deletes for posts with next post", ->
      factory.Posts topic_id: post.topic_id
      post\delete!
      post\refresh!
      assert.same true, post.deleted

    it "soft deletes post with replies", ->
      factory.Posts topic_id: post.topic_id, parent_post_id: post.id
      post\delete!
      post\refresh!
      assert.same true, post.deleted

    it "soft deletes old post", ->
      post\update {
        created_at: db.raw "now() at time zone 'utc' - '1.5 hours'::interval"
      }

      post\delete!
      post\refresh!
      assert.same true, post.deleted

  it "should create a series of posts in same topic", ->
    posts = for i=1,5
      factory.Posts topic_id: 1

    assert.same [i for i=1,5], [p.post_number for p in *posts]

  it "should create correct post numbers for nested posts", ->
    root1 = factory.Posts topic_id: 1
    assert.same 1, root1.post_number

    root2 = factory.Posts topic_id: 1
    assert.same 2, root2.post_number

    child1 = factory.Posts topic_id: 1, parent_post: root1
    child2 = factory.Posts topic_id: 1, parent_post: root1

    assert.same 1, child1.post_number
    assert.same 2, child2.post_number

    other_child1 = factory.Posts topic_id: 1, parent_post: root2
    other_child2 = factory.Posts topic_id: 1, parent_post: root2

    assert.same 1, other_child1.post_number
    assert.same 2, other_child2.post_number

    root3 = factory.Posts topic_id: 1
    assert.same 3, root3.post_number

    current = root3
    for i=1,3
      current = factory.Posts topic_id: 1, parent_post: current
      assert.same 1, current.post_number


  describe "with post, topic, category", ->
    local post, topic, category

    before_each ->
      category = factory.Categories!
      topic = factory.Topics category_id: category.id
      post = factory.Posts topic_id: topic.id

    it "should check vote status on up down", ->
      category\update voting_type: Categories.voting_types.up_down
      other_user = factory.Users!

      assert.falsy post\allowed_to_vote nil
      assert.truthy post\allowed_to_vote other_user, "up"
      assert.truthy post\allowed_to_vote other_user, "down"

    it "should check vote status on up", ->
      category\update voting_type: Categories.voting_types.up
      other_user = factory.Users!

      assert.falsy post\allowed_to_vote nil
      assert.truthy post\allowed_to_vote other_user, "up"
      assert.falsy post\allowed_to_vote other_user, "down"

    it "should check vote status on disabled", ->
      category\update voting_type: Categories.voting_types.disabled
      other_user = factory.Users!

      assert.falsy post\allowed_to_vote nil
      assert.falsy post\allowed_to_vote other_user, "up"
      assert.falsy post\allowed_to_vote other_user, "down"

  it "should get mentions for post", ->
    factory.Users username: "mentioned_person"
    post = factory.Posts body: "hello @mentioned_person how are you doing @mentioned_person I am @nonexist"
    assert.same {"mentioned_person"}, [u.username for u in *post\get_mentioned_users!]

  it "should preload mentions for many posts", ->
    factory.Users username: "mentioned_person1"
    factory.Users username: "mentioned_person2"

    posts = {
      factory.Posts body: "hello @mentioned_person1 how are you doing @nonexist"
      factory.Posts body: "this is @mentioned_person2 how are you doing"
      factory.Posts body: "this is @mentioned_person2 how are you @mentioned_person1"
      factory.Posts body: "this is @nothing"
    }

    Posts\preload_mentioned_users posts

    usernames = for post in *posts
      [u.username for u in *post.mentioned_users]


    assert.same {"mentioned_person1"}, usernames[1]
    assert.same {"mentioned_person2"}, usernames[2]
    assert.same {"mentioned_person2", "mentioned_person1"}, usernames[3]
    assert.same {}, usernames[4]

  describe "mention targets", ->
    it "gets no targets for first post", ->
      post = factory.Posts!
      assert.same {}, post\notification_targets!

    it "gets targets for post in topic", ->
      root = factory.Posts!
      topic = root\get_topic!
      topic\increment_from_post root

      post = factory.Posts topic_id: topic.id
      topic\increment_from_post post

      for {kind, user} in *post\notification_targets!
        assert.same "post", kind
        assert.same topic.user_id,user.id

    it "gets targets for post in topic reply", ->
      root = factory.Posts!
      topic = root\get_topic!
      topic\increment_from_post root

      post = factory.Posts parent_post_id: root.id, topic_id: topic.id
      topic\increment_from_post post

      for {kind, user, parent} in *post\notification_targets!
        assert.same "reply", kind
        assert.same topic.user_id, user.id
        assert parent.__class == Posts
        assert.same root.id, parent.id

    it "gets target for category owner", ->
      category_user = factory.Users!
      category = factory.Categories user_id: category_user.id
      topic = factory.Topics category_id: category.id
      post = factory.Posts topic_id: topic.id, user_id: topic.user_id

      tuples = post\notification_targets!
      assert.same 1, #tuples

      tuple = unpack tuples

      assert.same "topic", tuple[1]
      assert.same category_user.id, tuple[2].id
      assert Categories == tuple[3].__class
      assert.same category.id, tuple[3].id

    it "gets target for category group owner owner", ->
      import CategoryGroupCategories, CategoryGroups from require "community.models"
      truncate_tables CategoryGroupCategories, CategoryGroups

      category_group_user = factory.Users!
      group = factory.CategoryGroups user_id: category_group_user.id
      category = factory.Categories!

      group\add_category category

      topic = factory.Topics category_id: category.id
      post = factory.Posts topic_id: topic.id, user_id: topic.user_id

      tuples = post\notification_targets!
      assert.same 1, #tuples

      tuple = unpack tuples

      assert.same "topic", tuple[1]
      assert.same category_group_user.id, tuple[2].id

      assert CategoryGroups == tuple[3].__class
      assert.same group.id, tuple[3].id

  it "gets ancestors of post", ->
    assert.same {}, factory.Posts!\get_ancestors!

  it "gets ancestors of nested post", ->
    parent = factory.Posts!
    post = factory.Posts {
      topic_id: parent.topic_id
      parent_post_id: parent.id
    }

    assert.same {parent.id},
      [p.id for p in *post\get_ancestors!]

  it "gets ancestors of many nested post in deep first", ->
    post = factory.Posts!
    ids = for i=1,5
      with post.id
        post = factory.Posts {
          topic_id: post.topic_id
          parent_post_id: post.id
        }

    ids = [ids[i] for i=#ids,1,-1]

    ancestors = post\get_ancestors!

    assert.same ids, [p.id for p in *ancestors]
    assert.same [i for i=5,1,-1], [p.depth for p in *ancestors]

  it "gets root ancestor", ->
    post = factory.Posts!
    root_post = post
    for i=1,5
      post = factory.Posts {
        topic_id: post.topic_id
        parent_post_id: post.id
      }

    ancestor = post\get_root_ancestor!
    assert.same root_post.id, ancestor.id
    assert.same 1, ancestor.depth

