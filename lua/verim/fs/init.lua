--- Module for filesystem operations that are involved with libuv.

local ops = {}

local DEFAULT_DIR_MODE = tonumber(755, 8)

local log = require('verim.log')
local node = require('verim.node')

local api = vim.api
local uv = vim.loop

local function permission_table_to_number(tbl)
    local num = 0
    local permission_order_table = {
        tbl.others.execute,
        tbl.others.write,
        tbl.others.read,
        tbl.group.execute,
        tbl.group.write,
        tbl.group.read,
        tbl.owner.execute,
        tbl.owner.write,
        tbl.owner.read,
    }
    for i, permission in ipairs(permission_order_table) do
        if permission then num = num + 2 ^ (i - 1) end
    end
    return num
end

local function parent(f) return f:gsub('/[^/]+$', '') end

local function mkdir(dir, recurse)
    local pa, _ = parent(dir)
    if recurse and not vim.loop.fs_stat(pa) then mkdir(parent(dir)) end
    print(dir)
end

function ops.project_transformation(node, target)
    local changes = node - target
    if changes.parent then
        log.info(node:path(), 'MOVE:', node.parent, '->', target.parent)
        local parent_stats = uv.fs_stat(target.parent)
        if parent_stats and parent_stats.type == 'directory' then
            local in_fd = uv.fs_open(node:path())
            local out_fd = uv.fs_open(target:path())
            uv.fs_sendfile(in_fd, out_fd)
        else
            log.error('Parent does not exists!')
        end
    end
    if changes.name then
        log.info(node:path(), 'RENAME:', node.name, '->', target.name)
        uv.fs_rename(node:path(), target:path())
    end

    if changes.user_id or changes.group_id then
        log.info(node:path(), 'CHOWN', 'user:', node.user_id, '->',
            target.user_id, ', group:', node.group_id, '->', target.group_id)
        uv.fs_chown(node:path(), target.user_id, target.group_id)
    end

    if changes.permissions then
        local new_permission_number = permission_table_to_number(
            target.permissions)
        log.info(node:path(), 'CHMOD',
            permission_table_to_number(node.permissions), '->',
            new_permission_number)
        uv.fs_chmod(node:path(), new_permission_number)
    end
end

return ops
