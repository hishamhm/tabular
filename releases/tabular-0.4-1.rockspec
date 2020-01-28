package = "tabular"
version = "0.4-1"
source = {
   url = "git+https://github.com/hishamhm/tabular.git",
   tag = "0.4"
}
description = {
   summary = "yet another library for visualizing Lua tables",
   detailed = [[
      This module is especially useful for visualizing arrays of tables,
      displaying keys as columns in tabular fashion.
   ]],
   homepage = "https://github.com/hishamhm/tabular",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "compat53",
   "ansicolors ~> 1.0"
}
build = {
   type = "builtin",
   modules = {
      tabular = "tabular.lua"
   }
}
