local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local utf8 = _tl_compat and _tl_compat.utf8 or utf8; local tabular = {}

local AnsiColors = {}



local _require = require
local ansicolors = _require("ansicolors")

local draw = {
   NW = "/",
   NE = "\\",
   SW = "\\",
   SE = "/",
   N = "+",
   S = "+",
   E = "+",
   W = "+",
   V = "|",
   H = "-",
   X = "+",
}

local colors = {
   ansicolors.noReset("%{cyan}"),
   ansicolors.noReset("%{white}"),
}

local function strlen(s)
   s = s:gsub("\27[^m]*m", "")
   return #s
end

local strsub = string.sub

if (os.getenv("LANG") or ""):upper():match("UTF%-?8") then
   draw = {
      NW = "┌",
      NE = "┐",
      SW = "└",
      SE = "┘",
      N = "┬",
      S = "┴",
      E = "┤",
      W = "├",
      V = "│",
      H = "─",
      X = "┼",
   }

   strlen = function(s)
      s = s:gsub("\27[^m]*m", "")
      return utf8.len(s) or #s
   end

   strsub = function(s, i, j)
      local uj = utf8.offset(s, j + 1)
      if uj then
         uj = uj - 1
      end
      return s:sub(utf8.offset(s, i), uj)
   end

end

local Output = {}




local show
local show_as_columns

local function output_line(out, line)
   table.insert(out, line)
   out.width = math.max(out.width or 0, strlen(line))
end

local function escape_chars(c)
   return "\\" .. string.byte(c)
end

local Pair = {}

local function show_as_list(t, color, seen, ids, skip_array)
   local tt = {}
   local width = 0
   local keys = {}

   for k, v in pairs(t) do
      if not skip_array or type(k) ~= "number" then
         table.insert(tt, { k, v })
         keys[k] = tostring(k)
         width = math.max(width, strlen(keys[k]))
      end
   end

   table.sort(tt, function(a, b)
      if type(a[1]) == "number" and type(b[1]) == "number" then
         return a[1] < b[1]
      else
         return tostring(a[1]) < tostring(b[1])
      end
   end)

   for i = 1, #tt do
      local k = keys[tt[i][1]]
      tt[i][1] = k .. " " .. ("."):rep(width - strlen(k)) .. ":"
   end

   return show_as_columns(tt, color, seen, ids, nil, true)
end

local function show_primitive(t)
   local out = {}
   local s = tostring(t)

   if utf8.len(s) then
      s = s:gsub("[\n\t]", {
         ["\n"] = "\\n",
         ["\t"] = "\\t",
      })
   else
      s = s:gsub("[%z-\31\127-\255]", escape_chars)
   end

   if strlen(s) > 80 then

      for i = 1, strlen(s), 80 do
         output_line(out, strsub(s, i, i + 79))
      end
   else
      output_line(out, s)
   end

   return out
end

local Row = {}




show_as_columns = function(t, bgcolor, seen, ids, column_order, skip_header)
   local columns = {}
   local row_heights = {}

   local column_names
   local column_set

   if column_order then
      column_names = column_order
      column_set = {}
      for _, cname in ipairs(column_names) do
         column_set[cname] = true
      end
   end

   for i, row in ipairs(t) do
      if type(row) == "table" then
         for k, v in pairs(row) do
            local sk = tostring(k)
            if (not column_set) or column_set[sk] then
               if not columns[sk] then
                  columns[sk] = {}
                  columns[sk].width = strlen(sk)
               end
               local sv = show(v, bgcolor and colors[(i % #colors) + 1], seen, ids)
               columns[sk][i] = sv
               columns[sk].width = math.max(columns[sk].width, sv.width)
               row_heights[i] = math.max(row_heights[i] or 0, #sv)
            end
         end
      end
   end

   if not column_order then
      column_names = {}
      column_set = {}
      for name, _row in pairs(columns) do
         if not column_set[name] then
            table.insert(column_names, name)
            column_set[name] = true
         end
      end
      table.sort(column_names)
   end

   local function output_cell(line, cname, text, color)
      local w = columns[cname].width
      text = text or ""
      if color then
         table.insert(line, color)
      elseif bgcolor then
         table.insert(line, bgcolor)
      end
      table.insert(line, text .. (" "):rep(w - strlen(text)))
      if color then
         table.insert(line, bgcolor)
      end
      table.insert(line, draw.V)
   end

   local out = {}

   local border_top = {}
   local border_bot = {}
   for i, cname in ipairs(column_names) do
      local w = columns[cname].width
      table.insert(border_top, draw.H:rep(w))
      table.insert(border_bot, draw.H:rep(w))
      if i < #column_names then
         table.insert(border_top, draw.N)
         table.insert(border_bot, draw.S)
      end
   end
   table.insert(border_top, 1, draw.NW)
   table.insert(border_bot, 1, draw.SW)
   table.insert(border_top, draw.NE)
   table.insert(border_bot, draw.SE)

   output_line(out, table.concat(border_top))
   if not skip_header then
      local line = { draw.V }
      local sep = { draw.V }
      for _, cname in ipairs(column_names) do
         output_cell(line, cname, cname)
         output_cell(sep, cname, draw.H:rep(strlen(cname)))
      end
      output_line(out, table.concat(line))
      output_line(out, table.concat(sep))
   end

   for i = 1, #t do
      for h = 1, row_heights[i] or 1 do
         local line = { draw.V }
         for _, cname in ipairs(column_names) do
            local row = columns[cname][i]
            output_cell(line, cname, row and row[h] or "", bgcolor and colors[(i % #colors) + 1])
         end
         output_line(out, table.concat(line))
      end
   end
   output_line(out, table.concat(border_bot))

   local mt = t
   for k, _v in pairs(mt) do
      if type(k) ~= "number" then
         local out2 = show_as_list(mt, bgcolor, seen, ids, true)
         for _, line in ipairs(out2) do
            output_line(out, line)
         end
         break
      end
   end

   return out
end

show = function(t, color, seen, ids, column_order)
   if type(t) == "table" and seen[t] then
      local msg = "<see " .. ids[t] .. ">"
      return { msg, width = strlen(msg) }
   end
   seen[t] = true

   if type(t) == "table" then
      local tt = t
      if #tt > 0 and type(tt[1]) == "table" then
         return show_as_columns(tt, color, seen, ids, column_order)
      else
         return show_as_list(tt, color, seen, ids)
      end
   else
      return show_primitive(t)
   end
end

local function detect_cycles(t, n, seen)
   n = n or 0
   seen = seen or {}
   if type(t) == "table" then
      if seen[t] then
         return seen
      end
      n = n + 1
      seen[t] = n
      for _k, v in pairs(t) do
         seen, n = detect_cycles(v, n, seen)
      end
   end
   return seen, n
end

function tabular.show(t, column_order, color)
   local ids = detect_cycles(t)
   return table.concat(show(t, color and colors and ansicolors.noReset("%{reset}"), {}, ids, column_order), "\n")
end

if arg and arg[0]:match("tabular%..*$") then
   print(tabular.show(_G, nil, true))
   os.exit(0)
end

return setmetatable(tabular, { __call = function(_, ...) return tabular.show(...) end })
