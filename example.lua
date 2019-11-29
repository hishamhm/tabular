local tabular = require("tabular")

local data = {
   {
      id = 19401009,
      name = "John",
      plays = { "rhythm guitar", "acoustic guitar", "harmonica", "piano", "vocals" },
      handed = "right",
   },
   {
      id = 19420618,
      name = "Paul",
      plays = { "bass guitar", "electric guitar", "piano", "vocals", "drums" },
      handed = "left",
   },
   {
      id = 19430225,
      name = "George",
      plays = { "lead guitar", "sitar", "vocals", "synthesizer" },
      handed = "right",
   },
   {
      id = 19400707,
      name = "Ringo",
      plays = { "drums", "percussion", "vocals" },
      handed = "left",
   },
}

print(tabular(data))

print()

print(tabular(data, { "id", "name", "handed" }))

print()

print(tabular(_G, nil, true))
