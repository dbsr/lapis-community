import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Users from require "models"
import Categories, Topics, Posts, Votes from require "community.models"

factory = require "spec.factory"

import mock_request from require "lapis.spec.request"

import Application from require "lapis"
import capture_errors_json from require "lapis.application"

import TestApp from require "spec.helpers"

class BrowsingApp extends TestApp
  @before_filter =>
    @current_user = @params.current_user_id and assert Users\find @params.current_user_id
    Browsing = require "community.flows.browsing"
    @flow = Browsing @

  "/topic-posts": capture_errors_json =>
    @flow\topic_posts!
    json: { posts: @posts, success: true, before: @before, after: @after }

  "/category-topics": capture_errors_json =>
    @flow\category_topics!
    json: {
      success: true
      topics: @topics
    }

describe "browsing flow", ->
  use_test_env!

  before_each ->
    truncate_tables Users, Categories, Topics, Posts, Votes

  for logged_in in *{true, nil} -- false
    local current_user

    describe logged_in and "logged in" or "logged out", ->
      before_each ->
        current_user = factory.Users! if logged_in

      describe "topic posts", ->
        it "should error with no topic id", ->
          res = BrowsingApp\get current_user, "/topic-posts"
          assert.truthy res.errors
          assert.same {"topic_id must be an integer"}, res.errors

        it "should get some posts", ->
          topic = factory.Topics!
          for i=1,3
            post = factory.Posts topic_id: topic.id
            topic\increment_from_post post

          res = BrowsingApp\get current_user, "/topic-posts", topic_id: topic.id
          assert.truthy res.success
          assert.same 3, #res.posts

        it "should get paginated posts with after", ->
          topic = factory.Topics!
          for i=1,3
            post = factory.Posts topic_id: topic.id
            topic\increment_from_post post

          res = BrowsingApp\get current_user, "/topic-posts", topic_id: topic.id, after: 1
          assert.truthy res.success
          assert.same 2, #res.posts
          assert.same 2, res.before

        it "should get paginated posts with before", ->
          topic = factory.Topics!
          for i=1,3
            post = factory.Posts topic_id: topic.id
            topic\increment_from_post post

          res = BrowsingApp\get current_user, "/topic-posts", topic_id: topic.id, before: 2
          assert.truthy res.success
          assert.same 1, #res.posts

        it "sets pagination on posts", ->
          limits = require "community.limits"
          topic = factory.Topics!

          for i=1,limits.POSTS_PER_PAGE
            p = factory.Posts topic_id: topic.id
            topic\increment_from_post p

          res = BrowsingApp\get current_user, "/topic-posts", topic_id: topic.id
          assert.falsy res.after
          assert.falsy res.before

          -- one more to push it over the limit
          p = factory.Posts topic_id: topic.id
          topic\increment_from_post p

          res = BrowsingApp\get current_user, "/topic-posts", topic_id: topic.id
          assert.same 20, res.after
          assert.falsy res.before


          for i=1,3
            p = factory.Posts topic_id: topic.id
            topic\increment_from_post p

          res = BrowsingApp\get current_user, "/topic-posts", topic_id: topic.id, after: res.after
          assert.same 21, res.before
          assert.falsy res.after
          assert.same 4, #res.posts


        it "should get some nested posts", ->
          topic = factory.Topics!

          expected_nesting = {}

          for i=1,3
            p = factory.Posts topic_id: topic.id
            topic\increment_from_post p

            node = {id: p.id, children: {} }
            table.insert expected_nesting, node

            for i = 1,2
              pp = factory.Posts topic_id: topic.id, parent_post: p
              topic\increment_from_post pp
              inner_node = {id: pp.id, children: {}}
              table.insert node.children, inner_node

              ppp = factory.Posts topic_id: topic.id, parent_post: pp
              topic\increment_from_post ppp
              table.insert inner_node.children, {
                id: ppp.id, children: {}
              }

          res = BrowsingApp\get current_user, "/topic-posts", topic_id: topic.id

          assert.truthy res.posts
          flatten = (list, accum={}) ->
            return for p in *list
              {
                id: p.id
                children: p.children and flatten(p.children) or {}
              }

          nesting = flatten res.posts
          assert.same expected_nesting, nesting

      describe "category topics", ->
        it "should get empty category", ->
          category = factory.Categories!
          res = BrowsingApp\get current_user, "/category-topics", category_id: category.id
          assert.truthy res.success
          assert.same 0, #res.topics

        it "should get some topics", ->
          category = factory.Categories!
          for i=1,4
            factory.Topics category_id: category.id

          res = BrowsingApp\get current_user, "/category-topics", category_id: category.id

          assert.truthy res.success
          assert.same 4, #res.topics

