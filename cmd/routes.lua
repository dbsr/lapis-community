local moon = require("moon")
local app = require("app")()
local columnize
columnize = require("lapis.cmd.util").columnize
local tuples
do
  local _accum_0 = { }
  local _len_0 = 1
  for k, v in pairs(app.router.named_routes) do
    _accum_0[_len_0] = {
      k,
      v
    }
    _len_0 = _len_0 + 1
  end
  tuples = _accum_0
end
table.sort(tuples, function(a, b)
  return a[1] < b[1]
end)
return print(columnize(tuples, 0, 4, false))
