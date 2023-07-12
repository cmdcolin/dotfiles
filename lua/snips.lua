local ls = require 'luasnip'
local p = ls.parser

local v = {
  p.parse_snippet('ti', 'import $1 from "$2"'),
  p.parse_snippet('ti', 'import $1 from "$2"'),
  p.parse_snippet('ts', '// @ts-expect-error'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-explicit-any'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-floating-promises'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-non-null-assertion'),
  p.parse_snippet('cl', 'console.log({$1})'),
  p.parse_snippet('cl', 'console.log($1)'),
}

ls.add_snippets(nil, {
  javascript = v,
  javascriptreact = v,
  typescript = v,
  typescriptreact = v,
  rust = {
    p.parse_snippet('pp', 'println!("{}",$1)'),
  },
  java = {
    p.parse_snippet('pp', 'System.out.println($1)'),
  },
})
