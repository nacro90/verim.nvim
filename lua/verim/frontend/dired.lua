local uv = vim.loop

local sysnames = {LINUX = "Linux"}

local log = require('verim.log')
local filesize = require('verim.util.filesize')

local FILE_TYPE_CHAR = {
    file = '-',
    directory = 'd',
    link = 'l',
    block = 'b',
    char = 'c',
    socket = 'S',
    fifo = 'p',
}

local filesize_units = {"K", "M", "G", "T", "P", "E", "Z", "Y"}

local FILE_TYPE_SUFFIX = {
    file = '',
    directory = '/',
    link = '@',
    socket = '=',
    fifo = '|',
}
vim.tbl_add_reverse_lookup(FILE_TYPE_SUFFIX)

local uid_username_cache = {}
local gid_group_name_cache = {}

local function permission_to_str(permission_table)
    local output_table = {}
    local perm_groups = {
        permission_table.owner,
        permission_table.group,
        permission_table.others,
    }

    for _, perm_group in ipairs(perm_groups) do
        output_table[#output_table + 1] = perm_group.read and 'r' or '-'
        output_table[#output_table + 1] = perm_group.write and 'w' or '-'
        output_table[#output_table + 1] = perm_group.execute and 'x' or '-'
    end
    return table.concat(output_table)
end

local function manipulate_permission(str, node)
    local permissions = {
        {true, true, true},
        {true, true, true},
        {true, true, true},
    }

    for i = 1, 3 do
        local perm_triplet = permissions[i]
        for j = 1, 3 do
            local index = ((i - 1) * 3 + (j - 1)) + 1
            local char = str:sub(index, index)
            print(char)
            if char == '-' then perm_triplet[j] = false end
        end
    end

    local owner_permissions = permissions[1]
    local group_permissions = permissions[2]
    local others_permissions = permissions[3]

    local new_permissions = {
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

    node.permissions = new_permissions
    return node
end

local function filename(node)
    if node.type == 'link' then
        return string.format('%s -> %s', node.name, uv.fs_readlink(node:path()))
    end
    return node.name
end

local function typechar(node) return FILE_TYPE_CHAR[node.type] end

local function permissions(node) return permission_to_str(node.permissions) end

local function num_hard_links(node) return node.num_hard_links end

local function size(node) return filesize(node.size, {unix = true}) end

local function usernamefromid(id)
    assert(uv.os_uname().sysname == 'Linux',
        'Owner operations only available in linux.')

    local handle = io.popen('id -un ' .. id)
    local result = handle:read('*l')
    handle:close()
    return result
end

local function user(node)
    local id = node.user_id
    if uv.os_uname().sysname ~= 'Linux' then return id end
    if not uid_username_cache[id] then
        local name = usernamefromid(id)
        uid_username_cache[id] = name
        -- Add reverse lookup for parsing
        uid_username_cache[name] = id
    end
    return uid_username_cache[id]
end

local function group(node)
    if uv.os_uname().sysname ~= sysnames.LINUX then return node.group_id end
    if not gid_group_name_cache[node.group_id] then
        local handle = io.popen('getent group ' .. node.group_id)
        local result = handle:read('*a')
        handle:close()
        local colon_index, _ = result:find(':')
        local group_name = result:sub(1, colon_index - 1)
        gid_group_name_cache[node.group_id] = group_name
        -- Add reverse lookup for parsing
        gid_group_name_cache[group_name] = node.group_id
    end
    return gid_group_name_cache[node.group_id]
end

local nospace = ''
local space = ' '

local function modified_date_time(node)
    return os.date('%b %d %H:%M', node.modified_time):gsub('0', ' ', 1)
end

local function manipulate_name(str, node)
    node.name = vim.trim(str)
    return node
end

local function manipulate_owner(str, node)
    if not uid_username_cache[str] then
        local handle = io.popen('id -u ' .. str)
        local result = handle:read('*n')
        -- Remove the null character
        result = result:sub(1, -2)
        result = tonumber(result)
        handle:close()
        uid_username_cache[str] = result
        uid_username_cache[result] = str
    end
    node.user_id = uid_username_cache[str]
    return node
end

local function manipulate_group(str, node)
    local sysname = uv.os_uname().sysname
    if sysname ~= sysnames.LINUX then
        log.info('Groups are not supported in ' .. sysname)
    end
    if not gid_group_name_cache[str] then
        local handle = io.popen('getent group ' .. str)
        local result = handle:read('*a')
        handle:close()
        local gid = tonumber(string.match(result, '(%d+):$'))
        gid_group_name_cache[str] = gid
        -- Add reverse lookup for parsing
        gid_group_name_cache[gid] = str
    end
    node.group_id = gid_group_name_cache[str]
    return node
end

local function checkowner(str) return end

return {
    {printer = typechar, pattern = '[dlbcSp-]'},
    nospace,
    {
        printer = permissions,
        pattern = string.rep('[r-][w-][x-]', 3),
        manipulator = manipulate_permission,
    },
    space,
    {printer = num_hard_links, pattern = '%d+'},
    space,
    {
        printer = user,
        pattern = '[a-z_][a-z0-9_-]*',
        manipulator = manipulate_owner,
    },
    space,
    {
        printer = group,
        pattern = '[a-z_][a-z0-9_-]*',
        manipulator = manipulate_group,
    },
    space,
    {
        printer = size,
        align = 'right',
        pattern = string.format('%%d+[%s]?', table.concat(filesize_units)),
    },
    space,
    {printer = modified_date_time, pattern = '%a%a%a [ %d]%d %d?%d:%d%d'},
    space,
    {printer = filename, pattern = '.+', manipulator = manipulate_name},
}
