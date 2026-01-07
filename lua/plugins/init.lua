-- Plugin loader: imports all plugin modules
-- Each module returns a table of plugin specs

local function merge(...)
  local result = {}
  for _, tbl in ipairs({ ... }) do
    for _, v in ipairs(tbl) do
      result[#result + 1] = v
    end
  end
  return result
end

return merge(
  require "plugins.editor",
  require "plugins.navigation",
  require "plugins.ui",
  require "plugins.coding",
  require "plugins.misc"
)
