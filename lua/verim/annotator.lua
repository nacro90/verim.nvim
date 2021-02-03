local annotator = {}

local NAMESPACE = 'verim'

local function setvirtualtext(bufnr, line_state_map)
end

local function setsigns(bufnr, line_state_map)
end

function annotator.clearall()
end

function annotator.annotatelines(line_state_map)
    local buf_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local ns = api.nvim_create_namespace(NAMESPACE)
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
    for line, state in pairs(line_state_map) do
    end

end

return annotator
