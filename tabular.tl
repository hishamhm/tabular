local record Tabular
    show: function(t: any, column_order?: {string}, color?: boolean): string
end

local tabular: Tabular = {}

local record AnsiColors
  noReset: function(string):string
end

local _require = require
local ansicolors = _require("ansicolors") as AnsiColors

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

local colors: {string} = {
  ansicolors.noReset("%{cyan}"),
  ansicolors.noReset("%{white}"),
}

local function strlen(s: string): integer
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

  strlen = function(s: string): integer
    s = s:gsub("\27[^m]*m", "")
    return utf8.len(s) as integer or #s
  end

  strsub = function(s: string, i: number, j: number): string
    local uj: number = utf8.offset(s, j + 1)
    if uj then
      uj = uj - 1
    end
    return s:sub(utf8.offset(s, i) as integer, uj as integer)
  end

end

local record Output
  {string}
  width: number
end

local show: function(any, string, {any:boolean}, {any:number}, ?{string}):Output
local show_as_columns: function({{any:any}}, string, {any:boolean}, {any:number}, {string}, ?boolean): Output

local function output_line(out: Output, line: string)
  table.insert(out, line)
  out.width = math.max(out.width or 0, strlen(line))
end

local function escape_chars(c:string):string
  return "\\" .. string.byte(c)
end

local type Pair = {string, any}

local function show_as_list(t: {any:any}, color: string, seen: {any:boolean}, ids: {any:number}, skip_array?: boolean): Output
  local tt: {Pair} = {}
  local width = 0
  local keys = {}

  for k, v in pairs(t) do
    if not skip_array or type(k) ~= "number" then
      table.insert(tt, { k as string, v })
      keys[k] = tostring(k)
      width = math.max(width, strlen(keys[k]))
    end
  end

  table.sort(tt, function(a: Pair, b: Pair): boolean
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

  return show_as_columns(tt as {{any:any}}, color, seen, ids, nil, true)
end

local function show_primitive(t: any): Output
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
    -- word wrap
    for i = 1, strlen(s), 80 do
      output_line(out, strsub(s, i, i+79))
    end
  else
    output_line(out, s)
  end

  return out
end

local record Row
  {Output}
  width: number
end

show_as_columns = function(t: {{any:any}}, bgcolor: string, seen: {any:boolean}, ids: {any:number}, column_order: {string}, skip_header: boolean): Output
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

  local function output_cell(line: {string}, cname: string, text: string, color?: string)
    local w = columns[cname].width
    text = text or ""
    if color then
      table.insert(line, color)
    elseif bgcolor then
      table.insert(line, bgcolor)
    end
    table.insert(line, text .. (" "):rep((w - strlen(text)) as integer))
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
    table.insert(border_top, draw.H:rep(w as integer))
    table.insert(border_bot, draw.H:rep(w as integer))
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
        output_cell(line, cname, row and row[math.floor(h)] or "", bgcolor and colors[(i % #colors) + 1])
      end
      output_line(out, table.concat(line))
    end
  end
  output_line(out, table.concat(border_bot))

  local mt = t as {any:any}
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

show = function(t: any, color: string, seen: {any:boolean}, ids: {any:number}, column_order: {string}): Output
  if type(t) == "table" and seen[t] then
    local msg = "<see " .. ids[t] .. ">"
    return { msg, width = strlen(msg) }
  end
  seen[t] = true

  if type(t) == "table" then
    local tt = t as {any:any}
    if #(tt as {any}) > 0 and type(tt[1]) == "table" then
      return show_as_columns(tt as {{any:any}}, color, seen, ids, column_order)
    else
      return show_as_list(tt, color, seen, ids)
    end
  else
    return show_primitive(t)
  end
end

local function detect_cycles(t: any, n?: number, seen?: {any:number}): {any:number}, number
  n = n or 0
  seen = seen or {}
  if type(t) == "table" then
    if seen[t] then
      return seen
    end
    n = n + 1
    seen[t] = n
    for _k, v in pairs(t as {any:any}) do
      seen, n = detect_cycles(v, n, seen)
    end
  end
  return seen, n
end

function tabular.show(t: any, column_order?: {string}, color?: boolean): string
  local ids = detect_cycles(t)
  return table.concat(show(t, color and colors and ansicolors.noReset("%{reset}"), {}, ids, column_order), "\n")
end

if arg and arg[0]:match("tabular%..*$") then
  print(tabular.show(_G, nil, true))
  os.exit(0)
end

return setmetatable( tabular, { 
    __call = function(_: Tabular, ...:any): string 
        return tabular.show(... as {string}) 
    end 
} )
