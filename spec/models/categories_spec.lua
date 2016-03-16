local use_test_env
use_test_env = require("lapis.spec").use_test_env
local truncate_tables
truncate_tables = require("lapis.spec.db").truncate_tables
local Users
Users = require("models").Users
local Bans, Categories, CategoryGroupCategories, CategoryGroups, CategoryMembers, CategoryTags, Moderators, UserCategoryLastSeens
do
  local _obj_0 = require("community.models")
  Bans, Categories, CategoryGroupCategories, CategoryGroups, CategoryMembers, CategoryTags, Moderators, UserCategoryLastSeens = _obj_0.Bans, _obj_0.Categories, _obj_0.CategoryGroupCategories, _obj_0.CategoryGroups, _obj_0.CategoryMembers, _obj_0.CategoryTags, _obj_0.Moderators, _obj_0.UserCategoryLastSeens
end
local factory = require("spec.factory")
return describe("models.categories", function()
  use_test_env()
  before_each(function()
    return truncate_tables(Users, Categories, Moderators, CategoryMembers, Bans, CategoryGroups, CategoryGroupCategories, UserCategoryLastSeens)
  end)
  it("should create a category", function()
    return factory.Categories()
  end)
  describe("tags", function()
    return it("should parse tags", function()
      local category = factory.Categories()
      factory.CategoryTags({
        slug = "hello",
        category_id = category.id
      })
      factory.CategoryTags({
        slug = "world",
        category_id = category.id
      })
      return assert.same({
        "hello"
      }, (function()
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = category:parse_tags("hello,zone,hello,butt")
        for _index_0 = 1, #_list_0 do
          local t = _list_0[_index_0]
          _accum_0[_len_0] = t.slug
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    end)
  end)
  describe("with category", function()
    local category, category_user
    before_each(function()
      category_user = factory.Users()
      category = factory.Categories({
        user_id = category_user.id
      })
    end)
    it("should check permissions for no user", function()
      assert.truthy(category:allowed_to_view(nil))
      assert.falsy(category:allowed_to_post_topic(nil))
      assert.falsy(category:allowed_to_edit(nil))
      assert.falsy(category:allowed_to_edit_moderators(nil))
      assert.falsy(category:allowed_to_edit_members(nil))
      return assert.falsy(category:allowed_to_moderate(nil))
    end)
    it("should check permissions for owner", function()
      assert.truthy(category:allowed_to_view(category_user))
      assert.truthy(category:allowed_to_post_topic(category_user))
      assert.truthy(category:allowed_to_edit(category_user))
      assert.truthy(category:allowed_to_edit_moderators(category_user))
      assert.truthy(category:allowed_to_edit_members(category_user))
      return assert.truthy(category:allowed_to_moderate(category_user))
    end)
    it("should check permissions for random user", function()
      local other_user = factory.Users()
      assert.truthy(category:allowed_to_view(other_user))
      assert.truthy(category:allowed_to_post_topic(other_user))
      assert.falsy(category:allowed_to_edit(other_user))
      assert.falsy(category:allowed_to_edit_moderators(other_user))
      assert.falsy(category:allowed_to_edit_members(other_user))
      return assert.falsy(category:allowed_to_moderate(other_user))
    end)
    it("should check permissions for random user with members only", function()
      category:update({
        membership_type = Categories.membership_types.members_only
      })
      local other_user = factory.Users()
      assert.falsy(category:allowed_to_view(other_user))
      assert.falsy(category:allowed_to_post_topic(other_user))
      assert.falsy(category:allowed_to_edit(other_user))
      assert.falsy(category:allowed_to_edit_moderators(other_user))
      assert.falsy(category:allowed_to_edit_members(other_user))
      return assert.falsy(category:allowed_to_moderate(other_user))
    end)
    it("should check category member with members only", function()
      category:update({
        membership_type = Categories.membership_types.members_only
      })
      local member_user = factory.Users()
      factory.CategoryMembers({
        user_id = member_user.id,
        category_id = category.id
      })
      assert.truthy(category:allowed_to_view(member_user))
      assert.truthy(category:allowed_to_post_topic(member_user))
      assert.falsy(category:allowed_to_edit(member_user))
      assert.falsy(category:allowed_to_edit_moderators(member_user))
      assert.falsy(category:allowed_to_edit_members(member_user))
      return assert.falsy(category:allowed_to_moderate(member_user))
    end)
    it("should check moderation permissions", function()
      local some_user = factory.Users()
      local admin_user
      do
        local _with_0 = factory.Users()
        _with_0.is_admin = function(self)
          return true
        end
        admin_user = _with_0
      end
      local mod_user = factory.Users()
      local some_mod_user = factory.Users()
      factory.Moderators({
        user_id = mod_user.id,
        object = category
      })
      factory.Moderators({
        user_id = some_mod_user.id
      })
      assert.falsy(category:allowed_to_moderate(nil))
      assert.falsy(category:allowed_to_moderate(some_user))
      assert.falsy(category:allowed_to_moderate(some_mod_user))
      assert.truthy(category:allowed_to_moderate(category_user))
      assert.truthy(category:allowed_to_moderate(admin_user))
      return assert.truthy(category:allowed_to_moderate(mod_user))
    end)
    it("should check moderation permissions for category in group", function()
      local group = factory.CategoryGroups()
      group:add_category(category)
      local mod_user = factory.Users()
      factory.Moderators({
        user_id = mod_user.id,
        object = group
      })
      assert.falsy(category:allowed_to_edit(mod_user))
      assert.falsy(category:allowed_to_edit_moderators(mod_user))
      return assert["true"](category:allowed_to_moderate(mod_user))
    end)
    it("should check permissions for banned user", function()
      local banned_user = factory.Users()
      assert.falsy(category:find_ban(banned_user))
      factory.Bans({
        object = category,
        banned_user_id = banned_user.id
      })
      assert.truthy(category:find_ban(banned_user))
      assert.falsy(category:allowed_to_view(banned_user))
      assert.falsy(category:allowed_to_post_topic(banned_user))
      assert.falsy(category:allowed_to_edit(banned_user))
      assert.falsy(category:allowed_to_edit_moderators(banned_user))
      assert.falsy(category:allowed_to_edit_members(banned_user))
      assert.falsy(category:allowed_to_moderate(banned_user))
      local group_banned_user = factory.Users()
      local group = factory.CategoryGroups()
      group:add_category(category)
      factory.Bans({
        object = group,
        banned_user_id = group_banned_user.id
      })
      assert.falsy(category:allowed_to_view(group_banned_user))
      return assert.falsy(category:allowed_to_post_topic(group_banned_user))
    end)
    it("should update last topic to nothing", function()
      category:refresh_last_topic()
      return assert.falsy(category.last_topic_id)
    end)
    it("should update last topic with a topic", function()
      local topic = factory.Topics({
        category_id = category.id
      })
      factory.Topics({
        category_id = category.id,
        deleted = true
      })
      category:refresh_last_topic()
      return assert.same(category.last_topic_id, topic.id)
    end)
    it("should refresh last topic ignoring spam", function()
      local t1 = factory.Topics({
        category_id = category.id
      })
      local t2 = factory.Topics({
        category_id = category.id,
        status = "spam"
      })
      category:refresh_last_topic()
      return assert.same(category.last_topic_id, t1.id)
    end)
    it("gets voting type", function()
      return assert.same(Categories.voting_types.up_down, category:get_voting_type())
    end)
    it("gets membership_type type", function()
      return assert.same(Categories.membership_types.public, category:get_membership_type())
    end)
    describe("last seen", function()
      it("does nothing for category with no last topic", function()
        local current_user = factory.Users()
        category:set_seen(current_user)
        return assert.same(0, UserCategoryLastSeens:count())
      end)
      it("sets last seen for category with topic", function()
        local current_user = factory.Users()
        local t1 = factory.Topics({
          category_id = category.id
        })
        category:increment_from_topic(t1)
        category:set_seen(current_user)
        assert.same(1, UserCategoryLastSeens:count())
        category:set_seen(current_user)
        local last_seen = assert(category:find_last_seen_for_user(current_user))
        do
          local l = unpack(UserCategoryLastSeens:select())
          assert["false"](l:should_update())
        end
        assert.same(current_user.id, last_seen.user_id)
        assert.same(t1.category_order, last_seen.category_order)
        assert.same(t1.id, last_seen.topic_id)
        assert.same(category.id, last_seen.category_id)
        local t2 = factory.Topics({
          category_id = category.id
        })
        category:increment_from_topic(t2)
        do
          local l = unpack(UserCategoryLastSeens:select())
          assert["true"](l:should_update())
        end
        category:set_seen(current_user)
        assert.same(1, UserCategoryLastSeens:count())
        last_seen = assert(category:find_last_seen_for_user(current_user))
        assert.same(current_user.id, last_seen.user_id)
        assert.same(t2.id, last_seen.topic_id)
        assert.same(t2.category_order, last_seen.category_order)
        return assert.same(category.id, last_seen.category_id)
      end)
      return it("detects unread", function()
        local current_user = factory.Users()
        assert.falsy(category:has_unread(nil))
        assert.falsy(category:has_unread(current_user))
        local t1 = factory.Topics({
          category_id = category.id
        })
        category:increment_from_topic(t1)
        local last_seen = category:find_last_seen_for_user(current_user)
        assert(not last_seen, "expected no last_seen")
        assert.falsy(category:has_unread(current_user))
        category:set_seen(current_user)
        last_seen = category:find_last_seen_for_user(current_user)
        assert(last_seen, "expected last_seen")
        category.user_category_last_seen = last_seen
        assert.falsy(category:has_unread(current_user))
        local t2 = factory.Topics({
          category_id = category.id
        })
        category:increment_from_topic(t2)
        return assert.truthy(category:has_unread(current_user))
      end)
    end)
    describe("ancestors", function()
      it("gets ancestors with no ancestors", function()
        return assert.same({ }, category:get_ancestors())
      end)
      it("preloads single with no ancestors", function()
        Categories:preload_ancestors({
          category
        })
        return assert.same({ }, category:get_ancestors())
      end)
      return describe("with hierarchy", function()
        local mid, deep
        before_each(function()
          mid = factory.Categories({
            parent_category_id = category.id
          })
          deep = factory.Categories({
            parent_category_id = mid.id
          })
        end)
        it("gets ancestors with ancestors", function()
          return assert.same({
            mid.id,
            category.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = deep:get_ancestors()
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
        end)
        it("assembles category hierarchy without any queries", function()
          Categories:preload_ancestors({
            deep,
            mid,
            category
          })
          assert.same({
            mid.id,
            category.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = deep.ancestors
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
          assert.same({
            category.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = mid.ancestors
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
          return assert.same({ }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = category.ancestors or { }
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
        end)
        it("preloads from deepest, filling ancestors", function()
          Categories:preload_ancestors({
            deep
          })
          assert.same({
            mid.id,
            category.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = deep.ancestors
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
          assert.same({
            category.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = deep.ancestors[1].ancestors
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
          return assert.same({ }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = deep.ancestors[2].ancestors or { }
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
        end)
        it("preloads many adjacent", function()
          local deep2 = factory.Categories({
            parent_category_id = mid.id
          })
          local deep3 = factory.Categories({
            parent_category_id = mid.id
          })
          Categories:preload_ancestors({
            deep,
            deep2,
            deep3
          })
          assert.same({
            mid.id,
            category.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = deep.ancestors
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
          assert.same({
            mid.id,
            category.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = deep2.ancestors
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
          return assert.same({
            mid.id,
            category.id
          }, (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = deep3.ancestors
            for _index_0 = 1, #_list_0 do
              local c = _list_0[_index_0]
              _accum_0[_len_0] = c.id
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
        end)
        it("searches ancestors for moderators", function()
          local user = factory.Users()
          local mod = deep:find_moderator(user, {
            accepted = true,
            admin = true
          })
          assert.same(nil, mod)
          mod = factory.Moderators({
            object = mid,
            user_id = user.id,
            accepted = true,
            admin = true
          })
          local found_mod = deep:find_moderator(user, {
            accepted = true,
            admin = true
          })
          return assert.same(mod.id, found_mod.id)
        end)
        it("searches ancestors for bans", function()
          local user = factory.Users()
          assert.same(nil, (deep:find_ban(user)))
          local ban = factory.Bans({
            object = mid,
            banned_user_id = user.id
          })
          local found = deep:find_ban(user)
          return assert.same({
            ban.object_type,
            ban.object_id
          }, {
            found.object_type,
            found.object_id
          })
        end)
        it("searches ancestors for members", function()
          local user = factory.Users()
          assert.same(nil, (deep:find_member(user)))
          local member = factory.CategoryMembers({
            category_id = category.id,
            user_id = user.id,
            accepted = true
          })
          local found = deep:find_member(user, {
            accepted = true
          })
          return assert.same(found.user_id, user.id)
        end)
        it("gets default voting type", function()
          return assert.same(Categories.voting_types.up_down, category:get_voting_type())
        end)
        it("gets default membership_type type", function()
          return assert.same(Categories.membership_types.public, category:get_membership_type())
        end)
        it("gets ancestor voting type", function()
          category:update({
            voting_type = Categories.voting_types.disabled
          })
          mid:update({
            voting_type = Categories.voting_types.up
          })
          return assert.same(Categories.voting_types.up, deep:get_voting_type())
        end)
        return it("gets ancestor membership type", function()
          category:update({
            membership_type = Categories.membership_types.public
          })
          mid:update({
            membership_type = Categories.membership_types.members_only
          })
          return assert.same(Categories.membership_types.members_only, deep:get_membership_type())
        end)
      end)
    end)
    describe("children", function()
      local flatten_children
      flatten_children = function(cs, fields)
        if fields == nil then
          fields = {
            "id"
          }
        end
        return (function()
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #cs do
            local c = cs[_index_0]
            local o
            do
              local _tbl_0 = { }
              for _index_1 = 1, #fields do
                local f = fields[_index_1]
                _tbl_0[f] = c[f]
              end
              o = _tbl_0
            end
            if c.children then
              o.children = flatten_children(c.children, fields)
            end
            local _value_0 = o
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
          end
          return _accum_0
        end)()
      end
      it("gets empty children", function()
        return assert.same({ }, category:get_children())
      end)
      it("gets hierarchy", function()
        local other_cat = factory.Categories()
        local a = factory.Categories({
          parent_category_id = category.id
        })
        local b = factory.Categories({
          parent_category_id = category.id
        })
        local a2 = factory.Categories({
          parent_category_id = a.id
        })
        local xx = factory.Categories({
          parent_category_id = other_cat.id
        })
        factory.Categories({
          parent_category_id = xx.id
        })
        local children = category:get_children()
        assert.same(children, category.children)
        return assert.same({
          {
            id = a.id,
            children = {
              {
                id = a2.id
              }
            }
          },
          {
            id = b.id
          }
        }, flatten_children(children))
      end)
      return it("gets hierarchy with many children", function()
        local a = factory.Categories({
          parent_category_id = category.id,
          title = "hi"
        })
        local a1 = factory.Categories({
          parent_category_id = a.id,
          title = "alpha"
        })
        local a2 = factory.Categories({
          parent_category_id = a.id,
          title = "beta"
        })
        local a3 = factory.Categories({
          parent_category_id = a.id,
          title = "gama"
        })
        return assert.same({
          {
            title = "hi",
            children = {
              {
                title = "alpha"
              },
              {
                title = "beta"
              },
              {
                title = "gama"
              }
            }
          }
        }, flatten_children(category:get_children(), {
          "title"
        }))
      end)
    end)
    return describe("get_order_ranges", function()
      it("gets empty order range", function()
        return assert.same({
          regular = { },
          sticky = { }
        }, category:get_order_ranges())
      end)
      it("gets order range with one topic", function()
        local topic = factory.Topics({
          category_id = category.id
        })
        return assert.same({
          regular = {
            min = 1,
            max = 1
          },
          sticky = { }
        }, category:get_order_ranges())
      end)
      it("gets order range with a few topics", function()
        local topic = factory.Topics({
          category_id = category.id
        })
        for i = 1, 3 do
          factory.Topics({
            category_id = category.id
          })
        end
        topic:increment_from_post(factory.Posts({
          topic_id = topic.id
        }))
        return assert.same({
          regular = {
            min = 2,
            max = 5
          },
          sticky = { }
        }, category:get_order_ranges())
      end)
      it("gets order range with deleted topics", function()
        local topic = factory.Topics({
          category_id = category.id
        })
        factory.Topics({
          category_id = category.id
        })
        topic:delete()
        return assert.same({
          regular = {
            min = 2,
            max = 2
          },
          sticky = { }
        }, category:get_order_ranges())
      end)
      return it("gets order range with archived topics", function()
        local topics
        do
          local _accum_0 = { }
          local _len_0 = 1
          for i = 1, 4 do
            do
              local topic = factory.Topics({
                category_id = category.id
              })
              category:increment_from_topic(topic)
              _accum_0[_len_0] = topic
            end
            _len_0 = _len_0 + 1
          end
          topics = _accum_0
        end
        topics[1]:archive()
        assert.same({
          regular = {
            min = 2,
            max = 4
          },
          sticky = { }
        }, category:get_order_ranges())
        return assert.same({
          regular = {
            min = 1,
            max = 1
          },
          sticky = { }
        }, category:get_order_ranges("archived"))
      end)
    end)
  end)
  describe("position", function()
    return it("creates hierarchy with position set correctly", function()
      local root = factory.Categories()
      local root2 = factory.Categories()
      local a = factory.Categories({
        parent_category_id = root.id
      })
      assert.same(1, a.position)
      local a2 = factory.Categories({
        parent_category_id = root2.id
      })
      assert.same(1, a2.position)
      local b = factory.Categories({
        parent_category_id = root.id
      })
      return assert.same(2, b.position)
    end)
  end)
  return describe("bans", function()
    local parent_category
    local categories
    before_each(function()
      parent_category = factory.Categories()
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = 1, 3 do
          _accum_0[_len_0] = factory.Categories({
            parent_category_id = i == 2 and parent_category.id or nil
          })
          _len_0 = _len_0 + 1
        end
        categories = _accum_0
      end
    end)
    it("preloads bans on many topics when user is not banned", function()
      local user = factory.Users()
      Categories:preload_bans(categories, user)
      for _index_0 = 1, #categories do
        local c = categories[_index_0]
        assert.same({
          [user.id] = false
        }, c.user_bans)
      end
    end)
    return it("preloads bans user", function()
      local other_user = factory.Users()
      local user = factory.Users()
      local b1 = factory.Bans({
        object = categories[2],
        banned_user_id = other_user.id
      })
      local b2 = factory.Bans({
        object = categories[3],
        banned_user_id = user.id
      })
      local b3 = factory.Bans({
        object = parent_category,
        banned_user_id = user.id
      })
      Categories:preload_bans(categories, user)
      assert.same({
        [user.id] = false
      }, categories[1].user_bans)
      assert.same({
        [user.id] = false
      }, categories[2].user_bans)
      assert.same({
        [user.id] = b2
      }, categories[3].user_bans)
      return assert.same({
        [user.id] = b3
      }, categories[2]:get_parent_category().user_bans)
    end)
  end)
end)
