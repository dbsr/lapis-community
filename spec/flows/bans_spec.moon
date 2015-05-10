import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Users from require "models"
import Bans, Categories, ModerationLogs, ModerationLogObjects from require "community.models"

import TestApp from require "spec.helpers"
import capture_errors_json from require "lapis.application"

factory = require "spec.factory"

class BansApp extends TestApp
  @require_user!

  @before_filter =>
    BansFlow = require "community.flows.bans"
    @flow = BansFlow @

  "/ban": capture_errors_json =>
    @flow\ban!
    json: { success: true }

  "/unban": capture_errors_json =>
    @flow\unban!
    json: { success: true }


describe "bans", ->
  use_test_env!

  local current_user

  before_each =>
    truncate_tables Users, Bans, Categories, ModerationLogs, ModerationLogObjects
    current_user = factory.Users!

  assert_log_contains_user = (log, user) ->
    objs = log\get_log_objects!
    assert.same 1, #objs
    assert.same ModerationLogObjects.object_types.user, objs[1].object_type
    assert.same user.id, objs[1].object_id

  describe "with category", ->
    local category

    before_each ->
      category = factory.Categories user_id: current_user.id

    it "should ban user from category", ->
      other_user = factory.Users!

      res = BansApp\get current_user, "/ban", {
        object_type: "category"
        object_id: category.id
        banned_user_id: other_user.id
        reason: [[ this user ]]
      }

      assert.truthy res.success
      bans = Bans\select!
      assert.same 1, #bans
      ban = unpack bans

      assert.same other_user.id, ban.banned_user_id
      assert.same current_user.id, ban.banning_user_id
      assert.same category.id, ban.object_id
      assert.same Bans.object_types.category, ban.object_type
      assert.same "this user", ban.reason

      logs = ModerationLogs\select!
      assert.same 1, #logs
      log = unpack logs

      assert.same current_user.id, log.user_id
      assert.same category.id, log.category_id
      assert.same category.id, log.object_id
      assert.same ModerationLogs.object_types.category, log.object_type
      assert.same "category.ban", log.action
      assert.same "this user", log.reason

      assert_log_contains_user log, other_user

    it "should not let unrelated user ban", ->
      other_user = factory.Users!
      res = BansApp\get other_user, "/ban", {
        object_type: "category"
        object_id: category.id
        banned_user_id: current_user.id
        reason: [[ this user ]]
      }

      assert.same {errors: {"invalid permissions"}}, res

    it "should unban user", ->
      other_user = factory.Users!
      factory.Bans object: category, banned_user_id: other_user.id

      res = BansApp\get current_user, "/unban", {
        object_type: "category"
        object_id: category.id
        banned_user_id: other_user.id
      }

      assert.same 0, #Bans\select!

      logs = ModerationLogs\select!
      assert.same 1, #logs
      log = unpack logs

      assert.same current_user.id, log.user_id
      assert.same category.id, log.category_id
      assert.same category.id, log.object_id
      assert.same ModerationLogs.object_types.category, log.object_type
      assert.same "category.unban", log.action

      assert_log_contains_user log, other_user

  describe "with topic", ->
    local topic

    before_each ->
      category = factory.Categories user_id: current_user.id
      topic = factory.Topics category_id: category.id

    it "should ban user from topic", ->
      other_user = factory.Users!
      res = BansApp\get current_user, "/ban", {
        object_type: "topic"
        object_id: topic.id
        banned_user_id: other_user.id
        reason: [[ this user ]]
      }

      assert.truthy res.success
      bans = Bans\select!
      assert.same 1, #bans
      ban = unpack bans

      assert.same other_user.id, ban.banned_user_id
      assert.same current_user.id, ban.banning_user_id
      assert.same topic.id, ban.object_id
      assert.same Bans.object_types.topic, ban.object_type
      assert.same "this user", ban.reason

      -- check log
      logs = ModerationLogs\select!
      assert.same 1, #logs
      log = unpack logs

      assert.same current_user.id, log.user_id
      assert.same topic.category_id, log.category_id
      assert.same topic.id, log.object_id
      assert.same ModerationLogs.object_types.topic, log.object_type
      assert.same "topic.ban", log.action
      assert.same "this user", log.reason

      assert_log_contains_user log, other_user

    it "should unban user", ->
      other_user = factory.Users!
      factory.Bans object: topic, banned_user_id: other_user.id

      res = BansApp\get current_user, "/unban", {
        object_type: "topic"
        object_id: topic.id
        banned_user_id: other_user.id
      }

      assert.same 0, #Bans\select!

      -- check log
      logs = ModerationLogs\select!
      assert.same 1, #logs
      log = unpack logs

      assert.same current_user.id, log.user_id
      assert.same topic.category_id, log.category_id
      assert.same topic.id, log.object_id
      assert.same ModerationLogs.object_types.topic, log.object_type
      assert.same "topic.unban", log.action

      assert_log_contains_user log, other_user


