local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Topics, Posts, PostReports, ModerationLogs
do
  local _obj_0 = require("community.models")
  Categories, Topics, Posts, PostReports, ModerationLogs = _obj_0.Categories, _obj_0.Topics, _obj_0.Posts, _obj_0.PostReports, _obj_0.ModerationLogs
end
local TestApp
TestApp = require("spec.helpers").TestApp
local factory = require("spec.factory")
local mock_request
mock_request = require("lapis.spec.request").mock_request
local Application
Application = require("lapis").Application
local capture_errors_json
capture_errors_json = require("lapis.application").capture_errors_json
local ReportingApp
do
  local _class_0
  local _parent_0 = TestApp
  local _base_0 = {
    ["/report"] = capture_errors_json(function(self)
      self.flow:update_or_create_report()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/moderate-report"] = capture_errors_json(function(self)
      self.flow:moderate_report()
      return {
        json = {
          success = true
        }
      }
    end),
    ["/show"] = capture_errors_json(function(self)
      local CategoriesFlow = require("community.flows.categories")
      CategoriesFlow(self):load_category()
      self.flow:show_reports(self.category)
      return {
        json = {
          page = self.page,
          reports = self.reports,
          success = true
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
    __name = "ReportingApp",
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
    local ReportsFlow = require("community.flows.reports")
    self.flow = ReportsFlow(self)
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ReportingApp = _class_0
end
return describe("reports", function()
  use_test_env()
  local current_user
  before_each(function()
    truncate_tables(Users, Categories, Topics, Posts, PostReports, ModerationLogs)
    current_user = factory.Users()
  end)
  describe("report", function()
    it("should fail to create report", function()
      local res = ReportingApp:get(current_user, "/report", { })
      return assert.truthy(res.errors)
    end)
    it("should not report be created for own post", function()
      local post = factory.Posts({
        user_id = current_user.id
      })
      local res = ReportingApp:get(current_user, "/report", {
        post_id = post.id,
        ["report[reason]"] = "other",
        ["report[body]"] = "this is the problem"
      })
      assert.truthy(res.errors)
      return assert.same(0, PostReports:count())
    end)
    it("should create a new report", function()
      local post = factory.Posts()
      local res = ReportingApp:get(current_user, "/report", {
        post_id = post.id,
        ["report[reason]"] = "other",
        ["report[body]"] = "this is the problem"
      })
      assert.same({
        success = true
      }, res)
      local reports = PostReports:select()
      assert.same(1, #reports)
      local topic = post:get_topic()
      local report = unpack(reports)
      assert.same(topic.category_id, report.category_id)
      assert.same(post.id, report.post_id)
      assert.same(current_user.id, report.user_id)
      assert.same(PostReports.statuses.pending, report.status)
      assert.same(PostReports.reasons.other, report.reason)
      return assert.same("this is the problem", report.body)
    end)
    it("creates new report without body", function()
      local post = factory.Posts()
      local res = ReportingApp:get(current_user, "/report", {
        post_id = post.id,
        ["report[reason]"] = "other"
      })
      return assert.falsy(res.errors)
    end)
    it("should create new report for post in topic without category", function()
      local topic = factory.Topics({
        category = false
      })
      local post = factory.Posts({
        topic_id = topic.id
      })
      local res = ReportingApp:get(current_user, "/report", {
        post_id = post.id,
        ["report[reason]"] = "other",
        ["report[body]"] = "please report"
      })
      assert.truthy(res.success)
      local reports = PostReports:select()
      assert.same(1, #reports)
      local report = unpack(reports)
      assert.same(nil, report.category_id)
      return assert.same(post.id, report.post_id)
    end)
    it("should update existing report", function()
      local report = factory.PostReports({
        user_id = current_user.id
      })
      local res = ReportingApp:get(current_user, "/report", {
        post_id = report.post_id,
        ["report[reason]"] = "spam",
        ["report[body]"] = "I am updating my report"
      })
      assert.falsy(res.errors)
      assert.truthy(res.success)
      assert.same(1, PostReports:count())
      report:refresh()
      assert.same("I am updating my report", report.body)
      return assert.same(PostReports.reasons.spam, report.reason)
    end)
    return it("increments report count for category", function()
      local r1 = factory.PostReports({
        category_id = 1
      })
      local r2 = factory.PostReports({
        category_id = 1
      })
      local r3 = factory.PostReports({
        category_id = 2
      })
      assert.same(1, r1.category_report_number)
      assert.same(2, r2.category_report_number)
      return assert.same(1, r3.category_report_number)
    end)
  end)
  describe("moderate_report", function()
    it("should fail with no params", function()
      local res = ReportingApp:get(current_user, "/moderate-report", { })
      return assert.truthy(res.errors)
    end)
    it("should update report", function()
      local category = factory.Categories({
        user_id = current_user.id
      })
      local report = factory.PostReports({
        category_id = category.id
      })
      local res = ReportingApp:get(current_user, "/moderate-report", {
        report_id = report.id,
        ["report[status]"] = "resolved"
      })
      assert.truthy(res.success)
      report:refresh()
      assert.same(PostReports.statuses.resolved, report.status)
      assert.same(current_user.id, report.moderating_user_id)
      assert.same(1, ModerationLogs:count())
      local log = unpack(ModerationLogs:select())
      assert.same(category.id, log.category_id)
      assert.same(current_user.id, log.user_id)
      assert.same(report.id, log.object_id)
      assert.same(ModerationLogs.object_types.post_report, log.object_type)
      return assert.same("report.status(resolved)", log.action)
    end)
    return it("should not let unrelated user update report", function()
      local report = factory.PostReports()
      local res = ReportingApp:get(current_user, "/moderate-report", {
        report_id = report.id,
        ["report[status]"] = "resolved"
      })
      assert.truthy(res.errors)
      assert.falsy(res.success)
      report:refresh()
      return assert.same(PostReports.statuses.pending, report.status)
    end)
  end)
  return describe("show_reports", function()
    local category
    before_each(function()
      category = factory.Categories({
        user_id = current_user.id
      })
    end)
    it("doesn't let unrelated user view reports", function()
      local other_user = factory.Users()
      local res = ReportingApp:get(other_user, "/show", {
        category_id = category.id
      })
      return assert.same({
        errors = {
          "invalid category"
        }
      }, res)
    end)
    it("shows empty reports", function()
      local res = ReportingApp:get(current_user, "/show", {
        category_id = category.id
      })
      return assert.same({ }, res.reports)
    end)
    it("shows reports with status", function()
      local res = ReportingApp:get(current_user, "/show", {
        category_id = category.id,
        status = "ignored"
      })
      return assert.same({ }, res.reports)
    end)
    return it("shows reports", function()
      local report = factory.PostReports({
        category_id = category.id
      })
      local other_report = factory.PostReports({
        category_id = factory.Categories().id
      })
      local res = ReportingApp:get(current_user, "/show", {
        category_id = category.id
      })
      local _list_0 = res.reports
      for _index_0 = 1, #_list_0 do
        local r = _list_0[_index_0]
        assert.same(category.id, r.category_id)
      end
    end)
  end)
end)
