-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Save file ctrl+l, avoids left pinky usage of :w and ZZ for RSI purposes
vim.keymap.set("n", "<C-l>", ":w<CR>", { desc = "Save file" })
vim.keymap.set("i", "<C-l>", "<C-o>:w<CR>", { desc = "Save file" })

local ls = require("luasnip")

local v = {
  ls.parser.parse_snippet("ts", "// @ts-expect-error"),
  ls.parser.parse_snippet("da", "// eslint-disable-next-line @typescript-eslint/no-explicit-any"),
  ls.parser.parse_snippet("da", "// eslint-disable-next-line @typescript-eslint/no-floating-promises"),
  ls.parser.parse_snippet("da", "// eslint-disable-next-line @typescript-eslint/no-unnecessary-condition"),
  ls.parser.parse_snippet("da", 'const decoder = new TextDecoder("utf8")'),
  ls.parser.parse_snippet("pa", "/**\n* #property\n*/"),
  ls.parser.parse_snippet("pa", "/**\n* #action\n*/"),
  ls.parser.parse_snippet("pa", "/**\n* #getter\n*/"),
  ls.parser.parse_snippet("pa", "/**\n* #method\n*/"),
  ls.parser.parse_snippet("pa", "/**\n* #volatile\n*/"),
  ls.parser.parse_snippet("ps", "const {$1} = self"),
  ls.parser.parse_snippet("ps", "import {expect,test} from 'vitest'"),
  ls.parser.parse_snippet("ps", "import {afterEach,expect,test} from 'vitest'\nafterEach(()=>{cleanup()})"),
  ls.parser.parse_snippet("cl", "console.log({$1})"),
  ls.parser.parse_snippet("cl", "console.log($1)"),
  ls.parser.parse_snippet("cl", 'console.log("$1")'),
  ls.parser.parse_snippet("cl", "console.log(e)"),
  ls.parser.parse_snippet("wa", '"language":["$1"],'),
  ls.parser.parse_snippet("wa", '"tags":["$1"],'),
  ls.parser.parse_snippet("wa", '"pub":{"doi":""},'),
}

ls.add_snippets(nil, {
  javascript = v,
  javascriptreact = v,
  typescript = v,
  typescriptreact = v,
  json = v,
  rust = {
    ls.parser.parse_snippet("cl", 'println!("{}",$1)'),
  },
  java = {
    ls.parser.parse_snippet("cl", "System.out.println($1)"),
  },
})
