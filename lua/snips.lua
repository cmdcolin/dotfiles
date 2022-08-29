local luasnip = require 'luasnip'
local snip = luasnip.snippet
local text = luasnip.text_node
local insert = luasnip.insert_node

luasnip.add_snippets(nil, {
  all = {
    snip({
      trig = 'cl',
    }, {
      text { 'console.log({' },
      insert(1, ''),
      text { '})' },
    }),
    snip({
      trig = 'cj',
    }, {
      text { 'console.log(' },
      insert(1, ''),
      text { ')' },
    }),
    snip({
      trig = 'ck',
    }, {
      text { "console.log('" },
      insert(1, ''),
      text { "')" },
    }),
    snip({
      trig = 'da',
    }, {
      text { '// eslint-disable-next-line @typescript-eslint/no-explicit-any' },
    }),
    snip({
      trig = 'ts',
    }, {
      text { '// @ts-ignore' },
    }),
    snip({
      trig = 'pp',
    }, {
      text { 'println!("{}",' },
      insert(1, ''),
      text { ');' },
    }),
  },
})
