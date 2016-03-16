local factory = require("spec.factory")
local words
do
  local _accum_0 = { }
  local _len_0 = 1
  for word in io.open("/usr/share/dict/american-english"):lines() do
    _accum_0[_len_0] = word
    _len_0 = _len_0 + 1
  end
  words = _accum_0
end
local random_normal
random_normal = function()
  local _random = math.random
  return (_random() + _random() + _random() + _random() + _random() + _random() + _random() + _random() + _random() + _random() + _random() + _random()) / 6
end
local pick_one
pick_one = function(...)
  local num = select("#", ...)
  return (select(math.random(num), ...))
end
local sentence
sentence = function(num_words)
  if num_words == nil then
    num_words = 5
  end
  return table.concat((function()
    local _accum_0 = { }
    local _len_0 = 1
    for i = 1, num_words do
      _accum_0[_len_0] = words[math.random(1, #words)]
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)(), " ")
end
local leafo = factory.Users({
  username = "leafo",
  community_user = true
})
local lee = factory.Users({
  username = "lee",
  community_user = true
})
local adam = factory.Users({
  username = "adam",
  community_user = true
})
local fart = factory.Users({
  username = "fart",
  community_user = true
})
local rand_user
rand_user = function()
  return pick_one(leafo, lee, adam, fart)
end
local cat1 = factory.Categories({
  user_id = leafo.id,
  title = "Leafo's category",
  membership_type = "public"
})
local cat2 = factory.Categories({
  user_id = leafo.id,
  title = "Lee's zone",
  membership_type = "members_only",
  voting_type = "up"
})
local add_posts
add_posts = function(topic, parent_post)
  local base_count
  if parent_post then
    base_count = 5
  else
    base_count = 22
  end
  local num_posts = math.floor(base_count * random_normal())
  for i = 1, num_posts do
    local poster = rand_user()
    local post = factory.Posts({
      user_id = poster.id,
      topic_id = topic.id,
      body = sentence(math.random(8, 10)),
      parent_post = parent_post
    })
    local _ = print
    local k = math.abs(random_normal() - 1)
    if k > 0.1 * post.depth then
      add_posts(topic, post)
    end
  end
end
for i = 1, 4 do
  local topic_poster = rand_user()
  local topic = factory.Topics({
    category_id = cat1.id,
    user_id = topic_poster.id,
    title = sentence(math.random(2, 5))
  })
  add_posts(topic)
end
for i = 1, 1 do
  local topic_poster = rand_user()
  local topic = factory.Topics({
    category_id = cat2.id,
    user_id = topic_poster.id,
    title = sentence(math.random(2, 5))
  })
  add_posts(topic)
end
local Categories, Topics, CommunityUsers
do
  local _obj_0 = require("community.models")
  Categories, Topics, CommunityUsers = _obj_0.Categories, _obj_0.Topics, _obj_0.CommunityUsers
end
Topics:recount()
Categories:recount()
CommunityUsers:recount()
local _list_0 = Categories:select()
for _index_0 = 1, #_list_0 do
  local c = _list_0[_index_0]
  c:refresh_last_topic()
end
local _list_1 = Topics:select()
for _index_0 = 1, #_list_1 do
  local t = _list_1[_index_0]
  t:refresh_last_post()
end
