local verim = {}

local log = require('verim.log')
local bufs = require('verim.bufs')
local config = require('verim.config')

local uv = vim.loop
local api = vim.api

log.trace('Initializing verim')

local function createcmds()
   -- log.trace('verim.createcmds()')
   vim.cmd [[command! -nargs=? -complete=dir Verim lua require('verim').dispatch('<args>')]]
end

local function createkeymaps(keymaps)
   -- log.trace('verim.createkeymaps()')
end

function verim.setup(user_config)
   log.trace('verim.setup()')
   config.setup(user_config)
   log.debug('Config:', config.current)

   createcmds()

   createkeymaps()
end

function verim.dispatch(dir)
   log.trace('verim.dispatch()', dir)
   if not dir or dir == '' then
      dir = uv.cwd()
   else
      dir = uv.fs_realpath(dir)
      assert(vim.fn.isdirectory(dir) == 1)
   end

   local bufnr = bufs.getbuf(dir)
   log.trace('buffer retrieved:', bufnr)

   bufs.populate(bufnr, dir)
   api.nvim_win_set_buf(api.nvim_get_current_win(), bufnr)
end

--- Checks the current status of lired buffer and update the indicators
function verim.check()
   log.trace('verim.check()')
   local buf = api.nvim_get_current_buf()
   local buf_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
   local ns = api.nvim_create_namespace('verim')
   for i, line in ipairs(buf_lines) do
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
end

function verim.execute() log.trace('verim.execute()') end

return verim
