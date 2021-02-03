--- Filesystem operations module
local fs = {}

local uv = vim.loop

-- local function create_absolute(parent, child)
--    local sep = require('plenary.path').sep
--    if parent == sep then
--       -- Parent is root folder
--       return parent .. child
--    else
--       return parent .. sep .. child
--    end
-- end

function fs.walk(dir)
   return coroutine.wrap(function()
      local fd, err = uv.fs_scandir(dir)
      assert(not err, err)
      local item = uv.fs_scandir_next(fd)
      while item do
         coroutine.yield(item)
         item = uv.fs_scandir_next(fd)
      end
   end)
end

return fs
