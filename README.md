
# tabular

This is `tabular`, yet another library for visualizing Lua tables!

This module is especially useful for visualizing arrays of tables, a common
occurrence in Lua. That is, if you have an array like this:

```
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
```

running this

```
print(tabular(data))
```

will display it like this:

```
┌──────┬────────┬──────┬─────────────────────┐
│handed│id      │name  │plays                │
│──────│──      │────  │─────                │
│right │19401009│John  │┌───┬───────────────┐│
│      │        │      ││1 :│rhythm guitar  ││
│      │        │      ││2 :│acoustic guitar││
│      │        │      ││3 :│harmonica      ││
│      │        │      ││4 :│piano          ││
│      │        │      ││5 :│vocals         ││
│      │        │      │└───┴───────────────┘│
│left  │19420618│Paul  │┌───┬───────────────┐│
│      │        │      ││1 :│bass guitar    ││
│      │        │      ││2 :│electric guitar││
│      │        │      ││3 :│piano          ││
│      │        │      ││4 :│vocals         ││
│      │        │      ││5 :│drums          ││
│      │        │      │└───┴───────────────┘│
│right │19430225│George│┌───┬───────────┐    │
│      │        │      ││1 :│lead guitar│    │
│      │        │      ││2 :│sitar      │    │
│      │        │      ││3 :│vocals     │    │
│      │        │      ││4 :│synthesizer│    │
│      │        │      │└───┴───────────┘    │
│left  │19400707│Ringo │┌───┬──────────┐     │
│      │        │      ││1 :│drums     │     │
│      │        │      ││2 :│percussion│     │
│      │        │      ││3 :│vocals    │     │
│      │        │      │└───┴──────────┘     │
└──────┴────────┴──────┴─────────────────────┘

```

With the optional second argument, you can specify the order of the
top-level table and also filter columns:

```
print(tabular(data, { "id", "name", "handed" }))
```

produces

```
┌────────┬──────┬──────┐
│id      │name  │handed│
│──      │────  │──────│
│19401009│John  │right │
│19420618│Paul  │left  │
│19430225│George│right │
│19400707│Ringo │left  │
└────────┴──────┴──────┘
```

The third argument enables coloring:

```
print(tabular(_G, nil, true))
```

![Colorful output](screenshots/color.png)

## Install

Install it using [LuaRocks](https://luarocks.org):

```
luarocks install tabular
```

## Reference

The return value of `require` is a table which can be used as a function,
which is the same as `tabular.show`:

### `tabular.show`

```
function tabular.show(t: any, column_order: {string}, color: boolean): string
```

#### Arguments

* `t: any` is a Lua value. `tabular` does its best work handling tables and arrays,
  which can be nested, but it will `tostring` any other kind of data.
* `column_order: {string}` is an array of top-level column names. It determines which
  columns are displayed and in which order.
* `color: boolean` enables ANSI coloring, and "stripes" the output (alternates colors
  on each row) for better readability of complex structures.

#### Returns

* `{string}` It returns the tabular representation as a string.

## Credits and license

`tabular` was written by [Hisham Muhammad](https://hisham.hm) using [tl](http://github.com/hishamhm/tl).

License is MIT, the same as Lua.
