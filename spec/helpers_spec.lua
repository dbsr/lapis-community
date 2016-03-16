local use_test_env
use_test_env = require("lapis.spec").use_test_env
return describe("community.helpers", function()
  use_test_env()
  return describe("models", function()
    local memoize1
    memoize1 = require("community.helpers.models").memoize1
    return it("memoizes method", function()
      local M
      do
        local _class_0
        local _base_0 = {
          calls = 0,
          value = memoize1(function(self, t)
            self.calls = self.calls + 1
            return self.initial + t.amount
          end)
        }
        _base_0.__index = _base_0
        _class_0 = setmetatable({
          __init = function(self, initial)
            self.initial = initial
          end,
          __base = _base_0,
          __name = "M"
        }, {
          __index = _base_0,
          __call = function(cls, ...)
            local _self_0 = setmetatable({}, _base_0)
            cls.__init(_self_0, ...)
            return _self_0
          end
        })
        _base_0.__class = _class_0
        M = _class_0
      end
      local a = M(2)
      local b = M(3)
      local i1 = {
        amount = 2
      }
      local i2 = {
        amount = 3
      }
      assert.same(4, a:value(i1))
      assert.same(5, a:value(i2))
      assert.same(4, a:value(i1))
      assert.same(2, a.calls)
      assert.same(5, b:value(i1))
      assert.same(6, b:value(i2))
      assert.same(5, b:value(i1))
      return assert.same(2, b.calls)
    end)
  end)
end)
