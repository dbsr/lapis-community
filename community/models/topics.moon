db = require "lapis.db"

import Model from require "community.model"
import slugify from require "lapis.util"
import memoize1 from require "community.helpers.models"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE community_topics (
--   id integer NOT NULL,
--   category_id integer,
--   user_id integer,
--   title character varying(255),
--   slug character varying(255),
--   last_post_id integer,
--   locked boolean DEFAULT false NOT NULL,
--   sticky boolean DEFAULT false NOT NULL,
--   permanent boolean DEFAULT false NOT NULL,
--   deleted boolean DEFAULT false NOT NULL,
--   posts_count integer DEFAULT 0 NOT NULL,
--   deleted_posts_count integer DEFAULT 0 NOT NULL,
--   root_posts_count integer DEFAULT 0 NOT NULL,
--   views_count integer DEFAULT 0 NOT NULL,
--   category_order integer DEFAULT 0 NOT NULL,
--   deleted_at timestamp without time zone,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY community_topics
--   ADD CONSTRAINT community_topics_pkey PRIMARY KEY (id);
-- CREATE INDEX community_topics_category_id_sticky_category_order_idx ON community_topics USING btree (category_id, sticky, category_order) WHERE ((NOT deleted) AND (category_id IS NOT NULL));
--
class Topics extends Model
  @timestamp: true

  @relations: {
    {"category", belongs_to: "Categories"}
    {"user", belongs_to: "Users"}
  }

  @create: (opts={}) =>
    if opts.title
      opts.slug or= slugify opts.title

    opts.category_order = @update_category_order_sql opts.category_id

    Model.create @, opts

  @update_category_order_sql: (category_id) =>
    return nil unless category_id

    db.raw db.interpolate_query "
      (select coalesce(max(category_order), 0) + 1
      from #{db.escape_identifier @table_name!}
      where category_id = ?)
    ", category_id

  @recount: (where) =>
    import Posts from require "community.models"
    db.update @table_name!, {
      root_posts_count: db.raw "
        (select count(*) from #{db.escape_identifier Posts\table_name!}
          where topic_id = #{db.escape_identifier @table_name!}.id
          and depth = 1)
      "

      posts_count: db.raw "
        (select count(*) from #{db.escape_identifier Posts\table_name!}
          where topic_id = #{db.escape_identifier @table_name!}.id)
      "
    }, where

  allowed_to_post: (user) =>
    return false unless user
    return false if @deleted
    return false if @locked

    @allowed_to_view user

  allowed_to_view: memoize1 (user) =>
    return false if @deleted

    can_view = if @category_id
      @get_category!\allowed_to_view user
    else
      true

    if can_view
      return false if @find_ban user

    can_view

  allowed_to_edit: memoize1 (user) =>
    return false if @deleted
    return false unless user
    return true if user.id == @user_id
    return true if user\is_admin!
    return true if @allowed_to_moderate user

    false

  allowed_to_moderate: memoize1 (user) =>
    return false unless user
    return false unless @category_id

    import Categories from require "community.models"

    @get_category!\allowed_to_moderate user

  increment_participant: (user) =>
    return unless user
    import TopicParticipants from require "community.models"
    TopicParticipants\increment @id, user.id

  decrement_participant: (user) =>
    return unless user
    import TopicParticipants from require "community.models"
    TopicParticipants\decrement @id, user.id

  increment_from_post: (post, opts) =>
    assert post.topic_id == @id, "invalid post sent to topic"

    category_order = unless opts and opts.update_category_order == false
      Topics\update_category_order_sql @category_id

    @update {
      posts_count: db.raw "posts_count + 1"
      root_posts_count: if post.depth == 1
        db.raw "root_posts_count + 1"
      last_post_id: post.id
      :category_order
    }, timestamp: false


  refresh_last_post: =>
    import Posts from require "community.models"

    @update {
      last_post_id: db.raw db.interpolate_query "(
        select id from #{db.escape_identifier Posts\table_name!}
        where topic_id = ? and not deleted and (depth != 1 or post_number != 1)
        order by id desc
        limit 1
      )", @id
    }, timestamp: false


  delete: =>
    import soft_delete from require "community.helpers.models"

    if soft_delete @
      @update { deleted_at: db.format_date! }, timestamp: false

      import CommunityUsers, Categories from require "community.models"

      if @user_id
        CommunityUsers\for_user(@get_user!)\increment "topics_count", -1

      if @category_id
        Categories\load(id: @category_id)\update {
          deleted_topics_count: db.raw "deleted_topics_count + 1"
        }, timestamp: false

      return true

    false

  get_tags: =>
    unless @tags
      import TopicTags from require "community.models"
      @tags = TopicTags\select "where topic_id = ?", @id

    @tags

  set_tags: (tags_str) =>
    import TopicTags from require "community.models"

    tags = TopicTags\parse tags_str
    old_tags = {tag.slug, true for tag in *@get_tags!}
    new_tags = {TopicTags\slugify(tag), tag for tag in *tags}

    -- filter and mark ones to add and ones to remove
    for slug in pairs new_tags
      if slug\match("^%-*$") or old_tags[slug]
        new_tags[slug] = nil
        old_tags[slug] = nil

    if next old_tags
      slugs = table.concat [db.escape_literal slug for slug in pairs old_tags], ","
      db.delete TopicTags\table_name!, "topic_id = ? and slug in (#{slugs})", @id

    for slug, label in pairs new_tags
      TopicTags\create {
        topic_id: @id
        :label
        :slug
      }

    @tags = nil -- clear cache
    true

  find_ban: (user) =>
    return nil unless user
    import Bans from require "community.models"
    Bans\find_for_object @, user

  find_recent_log: (action) =>
    import ModerationLogs from require "community.models"
    unpack ModerationLogs\select "
      where object_type = ? and object_id = ? and action = ?
      order by id desc
      limit 1
    ", ModerationLogs.object_types.topic, @id, action

  -- most recent log entry for locking
  get_lock_log: =>
    return unless @locked

    unless @lock_log
      @lock_log = @find_recent_log "topic.lock"

    @lock_log

  -- most recent log entry for sticking
  get_sticky_log: =>
    return unless @sticky

    unless @sticky_log
      import ModerationLogs from require "community.models"
      @sticky_log = @find_recent_log "topic.stick"

    @sticky_log

  available_vote_types: =>
    if category = @get_category!
      category\available_vote_types!
    else
      { down: true, up: true }

  set_seen: (user) =>
    return unless user
    return unless @last_post_id

    import upsert from require "community.helpers.models"
    import UserTopicLastSeens from require "community.models"

    upsert UserTopicLastSeens, {
      user_id: user.id
      topic_id: @id
      post_id: @last_post_id
    }

  -- this assumes UserTopicLastSeens has been preloaded
  has_unread: (user) =>
    return unless user
    return unless @user_topic_last_seen
    @user_topic_last_seen.post_id < @last_post_id

  notification_target_users: =>
    { @get_user! }

  find_latest_root_post: =>
    import Posts from require "community.models"
    unpack Posts\select "
      where topic_id = ? and depth = 1 order by post_number desc limit 1
    ", @id

  get_topic_post: =>
    unless @topic_post
      import Posts from require "community.models"
      @topic_post = Posts\find topic_id: @id, depth: 1, post_number: 1

    @topic_post

  renumber_posts: (parent_post) =>
    import Posts from require "community.models"
    cond = if parent_post
      assert parent_post.topic_id == @id, "expecting"
      {
        parent_post_id: parent_post.id
      }
    else
      {
        topic_id: @id
        parent_post_id: db.NULL
        depth: 1
      }

    tbl = db.escape_identifier Posts\table_name!

    db.query "
      update #{tbl} as posts set post_number = new_number from (
        select id, row_number() over () as new_number
        from #{tbl}
        where #{db.encode_clause cond}
        order by post_number asc
      ) foo
      where posts.id = foo.id and posts.post_number != new_number
    "


