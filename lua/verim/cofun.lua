function count(start)
   start = start or 1
   return coroutine.wrap(function()
      local cur = start
      while true do
         coroutine.yield(cur)
         cur = cur + 1
      end
   end)
end

function take(n, co)
   return coroutine.wrap(
      function() for i = 1, n do coroutine.yield(co()) end end)
end

function map(mapper, co)
   return coroutine.wrap(function()
      for i in co do coroutine.yield(mapper(i)) end
   end)
end

function filter(pred, co)
   return coroutine.wrap(function()
      local i = co()
      while i do
         if type(pred) == 'function' then
            if pred(i) then coroutine.yield(i) end
         else
            if pred ~= i then coroutine.yield(i) end
         end
         i = co()
      end
   end)
end

function zip(...)
   local coroutines = {...}
   return coroutine.wrap(function()
      local results = {}
      local populate_results = function()
         for i, co in ipairs(coroutines) do results[i] = co() end
      end
      populate_results()
      while all(iter(results)) do
         coroutine.yield(unpack(results))
         populate_results()
      end
   end)
end

function takewhile(pred, co)
   return coroutine.wrap(function()
      local i = co()
      while i and pred(i) do
         coroutine.yield(i)
         i = co()
      end
   end)
end

function dropwhile(pred, co)
   return coroutine.wrap(function()
      local i
      repeat i = co() until not i or pred(i)
      while i do
         coroutine.yield(i)
         i = co()
      end
   end)
end

function recur(i)
   return coroutine.wrap(function() while true do coroutine.yield(i) end end)
end

function enumerate(co) return zip(count(), co) end

function iter(tbl)
   return coroutine.wrap(function()
      for _, v in pairs(tbl) do coroutine.yield(v) end
   end)
end

function collect(co)
   local arr = {}
   for i in co do arr[#arr + 1] = i end
   return arr
end

function collectmap(co, key_fun, val_fun)
   local map = {}
   for i in co do map[key_fun(i)] = val_fun(i) end
   return map
end

function groupby(co, key_fun)
   local map = {}
   for i in co do
      local key = key_fun(i)
      if not map[key] then map[key] = {} end
      local group = map[key]
      group[#group + 1] = i
   end
end

function id(x) return x end

function reduce(bifun, co, init)
   local state = init or co()
   if state then
      for i in co do
         state = bifun(state, i)
      end
   end
   return state
end

function any(co)
   for i in co do if i then return true end end
   return false
end

function all(co)
   for i in co do if not i then return false end end
   return true
end

function sum(co) return reduce(function(l, r) return l + r end, co, 0) end

function negated(f) return function(...) return not f(...) end end
