package = "tabular"
version = "dev-1"
source = {
   url = "git+https://github.com/hishamhm/tl.git"
}
description = {
   homepage = "https://github.com/hishamhm/tl",
   license = "MIT"
}
dependencies = {
   "ansicolors ~> 1.0",
}
build = {
   type = "builtin",
   modules = {
      tabular = "tabular.lua"
   }
}
