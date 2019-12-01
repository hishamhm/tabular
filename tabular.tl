local tabular = {}

local AnsiColors = record
   noReset: function(string):string
end

local ansicolors = require("ansicolors") as AnsiColors

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

local colors: {string} = {}

local function strlen(s: string): number
   s = s:gsub("\27[^m]*m", "")
   return #s
end

local strsub = string.sub

if (os.getenv("LANG") or ""):upper():match("UTF%-?8") then
   colors = {
      ansicolors.noReset("%{cyan}"),
      ansicolors.noReset("%{white}"),
   }
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

   strlen = function(s: string): number
      s = s:gsub("\27[^m]*m", "")
      return utf8.len(s) or #s
   end

   strsub = function(s: string, i: number, j: number): string
      local uj = utf8.offset(s, j + 1)
      if uj then
         uj = uj - 1
      end
      return s:sub(utf8.offset(s, i), uj)
   end

end

local Output = record
   {string}
   width: number
end

local show: function(any, string, {any:boolean}, {string}):Output
local show_as_columns: function({{any:any}}, string, {any:boolean}, {string}, boolean): Output

local function output_line(out: Output, line: string)
  table.insert(out, line)
  out.width = math.max(out.width or 0, strlen(line))
end

local Pair = record
   v1: string
   v2: any
end

local function escape_chars(c:string):string
   return "\\" .. string.byte(c)
end

local function show_as_list(t: {any:any}, color: string, seen: {any:boolean}, skip_array: boolean): Output
  local tt: {Pair} = {}
  local width = 0
  local keys = {}

  for k, v in pairs(t) do
    if not skip_array or type(k) ~= "number" then
      table.insert(tt, { v1 = k as string, v2 = v })
      keys[k] = tostring(k)
      width = math.max(width, strlen(keys[k]))
    end
  end

  table.sort(tt, function(a: Pair, b: Pair): boolean
    if type(a.v1) == "number" and type(b.v1) == "number" then
       return a.v1 < b.v1
    else
       return tostring(a.v1) < tostring(b.v1)
    end
  end)

  for i = 1, #tt do
     local k = keys[tt[i].v1]
     tt[i].v1 = k .. " " .. ("."):rep(width - strlen(k)) .. ":"
  end

  return show_as_columns(tt as {{any:any}}, color, seen, nil, true)
end

local function show_primitive(t: any, color: string, seen: {any:boolean}): Output
  local out = {}
  local s = tostring(t)

  if utf8.len(s) then
    s = s:gsub("[\n\t]", {
      ["\n"] = "\\n",
      ["\t"] = "\\t",
    })
  else
    s = s:gsub("[\0-\31\127-\255]", escape_chars)
  end

  if strlen(s) > 80 then
    -- word wrap
    for i = 1, strlen(s), 80 do
      output_line(out, strsub(s, i, i+79))
    end
  else
     output_line(out, s)
  end

  return out
end

local Row = record
   {Output}
   width: number
end

show_as_columns = function(t: {{any:any}}, bgcolor: string, seen: {any:boolean}, column_order: {string}, skip_header: boolean): Output
  local columns: {string:Row} = {}
  local row_heights: {number:number} = {}

  local column_names: {string}
  local column_set: {string:boolean}

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
        local k = tostring(k)
        if (not column_set) or column_set[k] then
          if not columns[k] then
            columns[k] = {}
            columns[k].width = strlen(k)
          end
          local sv = show(v, bgcolor and colors[(i % #colors) + 1], seen)
          columns[k][i] = sv
          columns[k].width = math.max(columns[k].width, sv.width)
          row_heights[i] = math.max(row_heights[i] or 0, #sv)
        end
      end
    end
  end

  if not column_order then
     column_names = {}
     column_set = {}
     for name, row in pairs(columns) do
       if not column_set[name] then
         table.insert(column_names, name)
         column_set[name] = true
       end
     end
     table.sort(column_names)
  end

  local function output_cell(line: {string}, cname: string, text: string, color: string)
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

  local border_top = {draw.NW}
  local border_bot = {draw.SW}
  for i, cname in ipairs(column_names) do
    table.insert(border_top, draw.H:rep(columns[cname].width))
    table.insert(border_bot, draw.H:rep(columns[cname].width))
    if i < #column_names then
      table.insert(border_top, draw.N)
      table.insert(border_bot, draw.S)
    end
  end
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

  local t = t as {any:any}
  for k, v in pairs(t) do
    if type(k) ~= "number" then
      local out2 = show_as_list(t, bgcolor, seen, true)
      for _, line in ipairs(out2) do
        output_line(out, line)
      end
      break
    end
  end

  return out
end

show = function(t: any, color: string, seen: {any:boolean}, column_order: {string}): Output
  if type(t) == "table" and seen[t] then
     local msg = "<see above>"
     return { msg, width = strlen(msg) }
  end
  seen[t] = true

  if type(t) == "table" then
    local t = t as {any:any}
    if #t > 0 and type(t[1]) == "table" then
      return show_as_columns(t as {{any:any}}, color, seen, column_order)
    else
      return show_as_list(t, color, seen)
    end
  else
    return show_primitive(t, color, seen)
  end
end

function tabular.show(t: any, column_order: {string}, color: boolean): string
  return table.concat(show(t, color and ansicolors.noReset("%{reset}"), {}, column_order), "\n")
end

if arg[0] == "tabular.tl" then
   print(tabular.show(_G))
   os.exit(0)
end

return setmetatable( tabular, { __call = function(_, ...): string return tabular.show(...) end } )
