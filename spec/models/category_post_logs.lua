local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Categories, Topics, Posts, CategoryPostLogs
do
  local _obj_0 = require("community.models")
  Categories, Topics, Posts, CategoryPostLogs = _obj_0.Categories, _obj_0.Topics, _obj_0.Posts, _obj_0.CategoryPostLogs
end
local factory = require("spec.factory")
return describe("models.category_tags", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Users, Categories, Topics, Posts, CategoryPostLogs)
  end)
  it("doesn't create post log for post with no loggable ancestors", function()
    local post = factory.Posts()
    CategoryPostLogs:log_post(post)
    return assert.same({ }, CategoryPostLogs:select())
  end)
  it("creates single log for post", function()
    local directory = factory.Categories({
      directory = true
    })
    local category = factory.Categories({
      parent_category_id = directory.id
    })
    local topic = factory.Topics({
      category_id = category.id
    })
    local post = factory.Posts({
      topic_id = topic.id
    })
    CategoryPostLogs:log_post(post)
    CategoryPostLogs:log_post(post)
    return assert.same({
      {
        category_id = directory.id,
        post_id = post.id
      }
    }, CategoryPostLogs:select())
  end)
  it("creates multiple log for each directory", function()
    local top_directory = factory.Categories({
      directory = true
    })
    local bottom_directory = factory.Categories({
      directory = true,
      parent_category_id = top_directory.id
    })
    local category = factory.Categories({
      parent_category_id = bottom_directory.id
    })
    local topic = factory.Topics({
      category_id = category.id
    })
    local post = factory.Posts({
      topic_id = topic.id
    })
    CategoryPostLogs:log_post(post)
    CategoryPostLogs:log_post(post)
    return assert.same({
      {
        category_id = top_directory.id,
        post_id = post.id
      },
      {
        category_id = bottom_directory.id,
        post_id = post.id
      }
    }, CategoryPostLogs:select("order by category_id asc"))
  end)
  it("create logs for topic with multiple categories", function()
    local top_directory = factory.Categories({
      directory = true
    })
    local bottom_directory = factory.Categories({
      directory = true,
      parent_category_id = top_directory.id
    })
    local category = factory.Categories({
      parent_category_id = bottom_directory.id
    })
    local topic = factory.Topics({
      category_id = category.id
    })
    local posts
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, 2 do
        _accum_0[_len_0] = factory.Posts({
          topic_id = topic.id
        })
        _len_0 = _len_0 + 1
      end
      posts = _accum_0
    end
    CategoryPostLogs:log_topic_posts(topic)
    CategoryPostLogs:log_topic_posts(topic)
    return assert.same({
      {
        category_id = top_directory.id,
        post_id = posts[1].id
      },
      {
        category_id = bottom_directory.id,
        post_id = posts[1].id
      },
      {
        category_id = top_directory.id,
        post_id = posts[2].id
      },
      {
        category_id = bottom_directory.id,
        post_id = posts[2].id
      }
    }, CategoryPostLogs:select("order by post_id, category_id"))
  end)
  it("clears logs for post", function()
    local post = factory.Posts()
    local post2 = factory.Posts()
    CategoryPostLogs:create({
      post_id = post.id,
      category_id = -1
    })
    CategoryPostLogs:create({
      post_id = post.id,
      category_id = -2
    })
    CategoryPostLogs:create({
      post_id = post2.id,
      category_id = -1
    })
    CategoryPostLogs:clear_post(post)
    return assert.same({
      {
        category_id = -1,
        post_id = post2.id
      }
    }, CategoryPostLogs:select())
  end)
  return it("clears posts for topic", function()
    local topic = factory.Topics()
    for i = 1, 3 do
      local post = factory.Posts({
        topic_id = topic.id
      })
      CategoryPostLogs:create({
        post_id = post.id,
        category_id = -1
      })
    end
    local other_post = factory.Posts()
    CategoryPostLogs:create({
      post_id = other_post.id,
      category_id = -1
    })
    CategoryPostLogs:clear_posts_for_topic(topic)
    return assert.same({
      {
        category_id = -1,
        post_id = other_post.id
      }
    }, CategoryPostLogs:select())
  end)
end)
