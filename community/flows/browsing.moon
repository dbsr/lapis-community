
import Flow from require "lapis.flow"

import Categories, Topics, Posts, Users from require "models"
import OrderedPaginator from require "lapis.db.pagination"

import assert_error, yield_error from require "lapis.application"
import assert_valid from require "lapis.validate"

db = require "lapis.db"

date = require "date"

class BrowsingFlow extends Flow
  expose_assigns: true

  _date_to_unix: (d) =>
    (date(d) - date\epoch!)\spanseconds!

  _date_from_unix: (d) =>
    d = assert_error tonumber(d), "invalid date"
    db.format_date d

  set_before_after: =>
    assert_valid @params, {
      {"before", optional: true, is_integer: true}
      {"after", optional: true, is_integer: true}
    }

    @before = tonumber @params.before
    @after = tonumber @params.after

  topic_posts: =>
    TopicsFlow = require "community.flows.topics"
    TopicsFlow(@)\load_topic!
    assert_error @topic\allowed_to_view(@current_user), "not allowed to view"

    @set_before_after!

    import OrderedPaginator from require "lapis.db.pagination"
    pager = OrderedPaginator Posts, "post_number", [[
      where topic_id = ?
    ]], @topic.id, {
      per_page: 20
      prepare_results: (posts) ->
        Users\include_in posts, "user_id"

        if @current_user
          import PostVotes from require "models"

          PostVotes\include_in posts, "post_id", {
            flip: true
            where: {
              user_id: @current_user.id
            }
          }

        posts
    }

    if @before
      pager\before @before
    else
      pager\after @after

  category_topics: =>
    CategoriesFlow = require "community.flows.categories"
    CategoriesFlow(@)\load_category!
    assert_error @category\allowed_to_view(@current_user), "not allowed to view"

    local after_date, after_id
    local before_date, before_id

    if @params.after_date and @params.after_id
      after_date = @_date_from_unix @params.after_date
      after_id = assert_error tonumber(@params.after_id), "invalid id"

    if @params.before_date and @params.before_date
      before_date = @_date_from_unix @params.before_date
      before_id = assert_error tonumber(@params.before_id), "invalid id"

    import OrderedPaginator from require "lapis.db.pagination"
    pager = OrderedPaginator Topics, {"last_post_at", "id"}, [[
      where category_id = ? and not deleted
    ]], @category.id, {
      per_page: 20
      prepare_results: (topics) ->
        Users\include_in topics, "user_id"
        topics
    }

    @topics = if after_date
      pager\after after_date, after_id
    else
      pager\before before_date, before_id

    if t = @topics[1]
      @after_date = @_date_to_unix t.last_post_at
      @after_id = t.id

    if t = @topics[#@topics]
      print "Before: #{@_date_to_unix t.last_post_at} vs. #{t.unix_last_post_at}"
      @before_date = @_date_to_unix t.last_post_at
      @before_id = t.id

    @topics

