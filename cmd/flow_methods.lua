local exec
exec = function(cmd)
  local f = io.popen(cmd)
  do
    local _with_0 = f:read("*all"):gsub("%s*$", "")
    f:close()
    return _with_0
  end
end
for mod in exec("ls community/flows/*.moon"):gmatch("([%w_]+)%.moon") do
  local flow = require("community.flows." .. tostring(mod))
  print(flow.__name)
  local methods
  do
    local _accum_0 = { }
    local _len_0 = 1
    for k, v in pairs(flow.__base) do
      if type(v) == "function" then
        _accum_0[_len_0] = k
        _len_0 = _len_0 + 1
      end
    end
    methods = _accum_0
  end
  table.sort(methods)
  for _index_0 = 1, #methods do
    local m = methods[_index_0]
    print("  " .. tostring(m))
  end
  print()
end
