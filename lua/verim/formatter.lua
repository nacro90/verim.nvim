local formatter = {}

function formatter.align(columns)
    for i, column in ipairs(columns) do
        if i < #columns then
            local formatted_cells = {}
            local padchar = column.fe_item.align == 'right' and '' or '-'
            for _, cell in ipairs(column.cells) do
                local format_str = string.format('%%%s%ds', padchar,
                    column.finish - column.start)
                formatted_cells[#formatted_cells + 1] =
                    string.format(format_str, cell)
            end
            column.cells = formatted_cells
        end
    end
    return columns
end

return formatter
