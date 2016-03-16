local factory = require("community.spec.factory")
local base_models = require("models")
factory.Users = function(opts)
  if opts == nil then
    opts = { }
  end
  local community_user = opts.community_user
  opts.community_user = nil
  opts.username = opts.username or "user-" .. tostring(factory.next_counter("username"))
  do
    local user = assert(base_models.Users:create(opts))
    if community_user then
      factory.CommunityUsers({
        user_id = user.id
      })
    end
    return user
  end
end
return factory
