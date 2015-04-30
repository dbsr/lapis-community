db = require "lapis.db"
import Model from require "community.model"

class Posts extends Model
  @timestamp: true

  @relations: {
    {"topic", belongs_to: "Topics"}
    {"user", belongs_to: "Users"}
  }

  @create: (opts={}) =>
    assert opts.topic_id, "missing topic id"
    assert opts.user_id, "missing user id"
    assert opts.body, "missing body"

    parent = if id = opts.parent_post_id
      @find id
    else
      with opts.parent_post
        opts.parent_post = nil

    if parent
      assert parent.topic_id == opts.topic_id, "invalid parent"
      opts.depth = parent.depth + 1
      opts.parent_post_id = parent.id
    else
      opts.depth = 1

    post_number = db.interpolate_query "
     (select count(*) from #{db.escape_identifier @table_name!}
     where topic_id = ? and depth = ?) + 1
    ", opts.topic_id, opts.depth

    opts.post_number = db.raw post_number
    Model.create @, opts

  is_topic_post: =>
    @post_number == 1 and @depth == 1

  allowed_to_vote: (user) =>
    return false unless user
    return false if @deleted
    true

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    return true if user.id == @user_id
    return false if @deleted

    topic = @get_topic!

    return true if topic\allowed_to_moderate user

    false

  allowed_to_reply: (user) =>
    return false unless user
    true

  delete: =>
    import soft_delete from require "community.helpers.models"

    if soft_delete @
      import CommunityUsers from require "models"
      CommunityUsers\for_user(@get_user!)\increment "posts_count", -1
      return true

  false
