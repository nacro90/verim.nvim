local bufs = {}

local api = vim.api
local log = require('verim.log')
local node = require('verim.node')
local frontend = require('verim.frontend.dired')
local adapter = require('verim.adapter')
local formatter = require('verim.formatter')
local config = require('verim.config')

-- Buffer states for verim
bufs.verim_buffers = {}

local function getbufbyname(name)
    for _, bufnr in ipairs(api.nvim_list_bufs()) do
        local buf_name = api.nvim_buf_get_name(bufnr)
        if name == buf_name then return bufnr end
    end
end

function bufs.createbuf(name)
    local options = {buftype = 'nowrite', undolevels = -1}

    local buf = api.nvim_create_buf(true, true)
    assert(buf ~= 0, 'error when creating buffer')
    log.trace('Buffer created:', buf)
    api.nvim_buf_set_name(buf, name)
    for option, value in pairs(options) do
        api.nvim_buf_set_option(buf, option, value)
    end
    api.nvim_buf_call(buf, function()
        vim.b.verim = {nodes = {}, columns = {}}
        api.nvim_command(
            [[command! -buffer VerimExecute lua require('verim').execute()]])
        api.nvim_command(
            [[command! -buffer VerimCheck lua require('verim').check()]])
    end)
    return buf
end

function bufs.getbuf(dir)
    log.trace('Getting verim buffer for', dir)
    local buffers = bufs.verim_buffers
    if not buffers[dir] then
        log.info('No buffer found:', dir)
        local dangling_bufnr = getbufbyname(dir)
        if dangling_bufnr then
            log.info('Removing dangling buffer:', dangling_bufnr, '->', dir)
            api.nvim_buf_delete(dangling_bufnr, {force = true})
        end
        buffers[dir] = bufs.createbuf(dir)
    end
    return buffers[dir]
end

function bufs.onchanged() end

local function linecallback(_, bufnr, changedtick, first_line, last_line,
    new_last_line)
    log.trace('bufs._linecallback()')
    local end_line
    if last_line < new_last_line then
        end_line = new_last_line
    else
        end_line = last_line
    end
    log.info('end_line', end_line)
    for i, line in ipairs(api.nvim_buf_get_lines(bufnr, first_line, end_line,
        true)) do
        log.info(line)
        if not string.match(line, vim.b.linepattern) then
            if config.virtualtext.enabled then
                local pattern_err_conf = config.virtualtext.pattern_error
                api.nvim_buf_set_virtual_text(buf, ns, i - 1, {
                    {pattern_err_conf.text, pattern_err_conf.hl},
                }, {})
            end
        else
            api.nvim_buf_set_virtual_text(buf, ns, i - 1, {}, {})
        end
    end
    log.info('verim.on_lines()',
        api.nvim_buf_get_lines(bufnr, first_line, new_last_line, true))
end

--- Fill the buffer with node data
function bufs.populate(bufnr, dir)
    log.trace('bufs.populate()')
    local nodes = node.readdir(dir)

    local columns = adapter.rendernodes(nodes, frontend)
    columns = formatter.align(columns)

    local lines = adapter.createlines(columns)

    api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    api.nvim_buf_set_var(bufnr, 'linepattern', adapter.createpattern(frontend))

    -- Enable back the undo with the user global option
    api.nvim_buf_set_option(bufnr, 'undolevels',
        api.nvim_get_option('undolevels'))
    api.nvim_buf_set_option(bufnr, 'modified', false)

    api.nvim_buf_attach(bufnr, nil, {on_lines = linecallback})
end

return bufs
