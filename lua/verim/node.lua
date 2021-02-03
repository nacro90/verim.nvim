local node = {}
node.__index = node

local log = require('verim.log')
local bit = require('verim.util.bit')

local uv = vim.loop

local function parsemod(stats_mode_num)
   local _, bits = bit.shr(stats_mode_num, 9)
   local permissions = {
      {true, true, true},
      {true, true, true},
      {true, true, true},
   }
   for i = 3, 1, -1 do
      local perm_triplet = permissions[i]
      for j = 3, 1, -1 do
         local last_bit
         bits, last_bit = bit.shr(bits)
         if last_bit == 0 then perm_triplet[j] = false end
      end
   end
   local owner_permissions = permissions[1]
   local group_permissions = permissions[2]
   local others_permissions = permissions[3]
   return {
      owner = {
         read = owner_permissions[1],
         write = owner_permissions[2],
         execute = owner_permissions[3],
      },
      group = {
         read = group_permissions[1],
         write = group_permissions[2],
         execute = group_permissions[3],
      },
      others = {
         read = others_permissions[1],
         write = others_permissions[2],
         execute = others_permissions[3],
      },
   }
end

local function createpath(parent, name)
   return string.format('%s/%s', parent ~= '/' and parent or '', name)
end

function node.construct(parent, name)
   parent = uv.fs_realpath(parent) -- TODO is it required?
   local stats = uv.fs_lstat(createpath(parent, name))
   local instance = {
      parent = parent,
      name = name,
      permissions = parsemod(stats.mode),
      type = stats.type,
      num_hard_links = stats.nlink,
      size = stats.size,
      user_id = stats.uid,
      group_id = stats.gid,
      create_time = stats.ctime.sec,
      access_time = stats.atime.sec,
      modified_time = stats.mtime.sec,
      path = node.path,
   }
   setmetatable(instance, node)
   return instance
end

function node:path() return createpath(self.parent, self.name) end

function node.diff(a, b)
   local differences = {}
   for key, value in pairs(a) do
      if type(value) == 'table' then
         differences[key] = node.diff(a[key], b[key])
      elseif a[key] ~= b[key] then
         differences[key] = b[key]
      end
   end
   if not vim.tbl_isempty(differences) then return differences end
end

--- Reads the directory and returns a list of Nodes
function node.readdir(dir)
   local nodes = {}
   local fd, err = uv.fs_scandir(dir)
   assert(not err, err)
   local direntry = uv.fs_scandir_next(fd)
   while direntry do
      nodes[#nodes + 1] = node.construct(dir, direntry)
      direntry = uv.fs_scandir_next(fd)
   end
   return nodes
end

return node
