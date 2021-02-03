--- Adapter for nodes and frontends
local adapter = {}

function adapter.rendernodes(nodes, column_renderers, opts)
   local columns = {}
   for i, renderer in ipairs(column_renderers) do
      local column_cells = {}
      if true then -- TODO config
         -- Insert column as first element of column
         column_cells[1] = renderer.header or ''
      end
      local max_len = 0
      for _, item in ipairs(nodes) do
         local printed_str
         if type(renderer) == 'string' then
            printed_str = renderer
            max_len = #renderer
         else
            printed_str = tostring(renderer.printer(item)):gsub('\n', '')
            if #printed_str > max_len then max_len = #printed_str end
         end
         column_cells[#column_cells + 1] = printed_str
      end
      local start = i > 1 and columns[i - 1].finish or 1
      columns[i] = {
         start = start,
         finish = start + max_len,
         cells = column_cells,
         fe_item = renderer,
      }
   end
   return columns
end

function adapter.createpattern(frontend)
   local patterns = {}
   local function append(elem) patterns[#patterns + 1] = elem end
   for _, fe_item in ipairs(frontend) do
      if type(fe_item) == 'table' then
         local right_align = fe_item.align == 'right'
         local manipulator = fe_item.manipulator

         if right_align then append('%s*') end
         if manipulator then append('(') end
         append(fe_item.pattern)
         if manipulator then append(')') end
         if right_align then append('%s*') end
      else
         append(fe_item)
      end
   end
   return table.concat(patterns)
end

--- Creates a list of textlines from the list of column data.
function adapter.createlines(columns)
   local lines = {}
   for i = 1, #columns[1].cells do
      local line = {}
      for _, column in ipairs(columns) do line[#line + 1] = column.cells[i] end
      lines[#lines + 1] = table.concat(line)
   end
   -- Remove header line if empty
   if string.find(lines[1], '^%s*$') then table.remove(lines, 1) end
   return lines
end

return adapter
