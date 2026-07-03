-- Caelestia colorscheme.
--
-- Two modes, one pipeline (CLAUDE.md "Neovim > Colorscheme"): matugen renders
-- ~/.local/state/caelestia/nvim-colors.lua from the wallpaper or a picked
-- seed color; if that file doesn't exist yet we fall back to the fixed
-- palette below. Errors/warnings/git diff stay semantically red/amber/green
-- unconditionally - a safety signal, not an aesthetic choice.

local M = {}

-- Fixed-mode palette (the spec's role table)
local fixed = {
  background = '#16171b',
  foreground = '#E8E8EA', -- default text
  muted = '#9A9AA0', -- secondary text
  keyword = '#29D3F0', -- electric cyan accent
  string = '#6FA8B5', -- desaturated teal, same hue family pulled back
  number = '#c9a86a', -- muted warm gold (M3 tertiary: hue-rotated 60deg)
  comment = '#6a6d73', -- dimmed gray, italic
  type = '#f2f2f3', -- near-white for component/type names
  -- UI surfaces: M3 tonal elevation, pure neutral grays
  surface0 = '#1d1e23',
  surface1 = '#24252b',
  surface2 = '#2c2d34',
  selection = '#2a3b40',
  border = '#3a3b42',
}

-- Semantic colors: NOT driven by matugen, always recognizable
local semantic = {
  error = '#f2708a',
  warn = '#e5c076',
  ok = '#8fbf7f',
  info = '#29D3F0',
}

---Read the matugen-generated palette if it exists, else use fixed values
---@return table
local function palette()
  local state = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. '/.local/state')) .. '/caelestia/nvim-colors.lua'
  local ok, dynamic = pcall(dofile, state)
  if ok and type(dynamic) == 'table' then return vim.tbl_extend('force', fixed, dynamic) end
  return fixed
end

function M.load()
  local p = palette()

  vim.cmd 'highlight clear'
  vim.g.colors_name = 'caelestia'
  vim.o.termguicolors = true

  local hl = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

  -- Core editor
  hl('Normal', { fg = p.foreground, bg = p.background })
  hl('NormalFloat', { fg = p.foreground, bg = p.surface0 })
  hl('FloatBorder', { fg = p.border, bg = p.surface0 })
  hl('CursorLine', { bg = p.surface0 })
  hl('CursorLineNr', { fg = p.keyword, bold = true })
  hl('LineNr', { fg = p.comment })
  hl('SignColumn', { bg = p.background })
  hl('Visual', { bg = p.selection })
  hl('Search', { fg = p.background, bg = p.number })
  hl('IncSearch', { fg = p.background, bg = p.keyword })
  hl('CurSearch', { link = 'IncSearch' })
  hl('MatchParen', { fg = p.keyword, bold = true })
  hl('WinSeparator', { fg = p.border })
  hl('ColorColumn', { bg = p.surface0 })
  hl('Folded', { fg = p.muted, bg = p.surface0 })
  hl('NonText', { fg = p.surface2 })
  hl('Whitespace', { fg = p.surface2 })
  hl('EndOfBuffer', { fg = p.background })
  hl('Directory', { fg = p.keyword })
  hl('Title', { fg = p.keyword, bold = true })
  hl('Question', { fg = p.string })
  hl('MoreMsg', { fg = p.string })
  hl('ErrorMsg', { fg = semantic.error })
  hl('WarningMsg', { fg = semantic.warn })

  -- Menus / statusline base
  hl('Pmenu', { fg = p.foreground, bg = p.surface1 })
  hl('PmenuSel', { fg = p.background, bg = p.keyword })
  hl('PmenuSbar', { bg = p.surface1 })
  hl('PmenuThumb', { bg = p.border })
  hl('StatusLine', { fg = p.foreground, bg = p.surface1 })
  hl('StatusLineNC', { fg = p.muted, bg = p.surface0 })
  hl('WildMenu', { link = 'PmenuSel' })

  -- Syntax (spec role table)
  hl('Comment', { fg = p.comment, italic = true })
  hl('String', { fg = p.string })
  hl('Character', { fg = p.string })
  hl('Number', { fg = p.number })
  hl('Float', { fg = p.number })
  hl('Boolean', { fg = p.number })
  hl('Constant', { fg = p.foreground })
  hl('Identifier', { fg = p.foreground })
  hl('Function', { fg = p.foreground, bold = true })
  hl('Statement', { fg = p.keyword })
  hl('Keyword', { fg = p.keyword })
  hl('Conditional', { fg = p.keyword })
  hl('Repeat', { fg = p.keyword })
  hl('Operator', { fg = p.muted })
  hl('Exception', { fg = p.keyword })
  hl('PreProc', { fg = p.keyword })
  hl('Include', { fg = p.keyword })
  hl('Define', { fg = p.keyword })
  hl('Macro', { fg = p.number })
  hl('Type', { fg = p.type })
  hl('StorageClass', { fg = p.keyword })
  hl('Structure', { fg = p.type })
  hl('Typedef', { fg = p.type })
  hl('Special', { fg = p.string })
  hl('SpecialComment', { fg = p.comment, italic = true })
  hl('Delimiter', { fg = p.muted })
  hl('Underlined', { underline = true })
  hl('Todo', { fg = p.background, bg = p.number, bold = true })

  -- Treesitter
  hl('@comment', { link = 'Comment' })
  hl('@string', { link = 'String' })
  hl('@number', { link = 'Number' })
  hl('@boolean', { link = 'Boolean' })
  hl('@keyword', { link = 'Keyword' })
  hl('@keyword.import', { link = 'Include' })
  hl('@type', { link = 'Type' })
  hl('@type.builtin', { link = 'Type' })
  hl('@function', { link = 'Function' })
  hl('@function.builtin', { link = 'Function' })
  hl('@constructor', { fg = p.type }) -- QML component names (Item, Text, ...)
  hl('@property', { fg = p.foreground })
  hl('@variable', { fg = p.foreground })
  hl('@variable.member', { fg = p.foreground })
  hl('@variable.builtin', { fg = p.keyword, italic = true })
  hl('@constant', { link = 'Constant' })
  hl('@operator', { link = 'Operator' })
  hl('@punctuation', { link = 'Delimiter' })
  hl('@tag', { fg = p.keyword })
  hl('@tag.attribute', { fg = p.foreground })

  -- Diagnostics (semantic, unconditional)
  hl('DiagnosticError', { fg = semantic.error })
  hl('DiagnosticWarn', { fg = semantic.warn })
  hl('DiagnosticInfo', { fg = semantic.info })
  hl('DiagnosticHint', { fg = p.muted })
  hl('DiagnosticOk', { fg = semantic.ok })
  hl('DiagnosticUnderlineError', { undercurl = true, sp = semantic.error })
  hl('DiagnosticUnderlineWarn', { undercurl = true, sp = semantic.warn })
  hl('DiagnosticUnderlineInfo', { undercurl = true, sp = semantic.info })
  hl('DiagnosticUnderlineHint', { undercurl = true, sp = p.muted })

  -- Git (semantic, unconditional)
  hl('GitSignsAdd', { fg = semantic.ok })
  hl('GitSignsChange', { fg = semantic.warn })
  hl('GitSignsDelete', { fg = semantic.error })
  hl('DiffAdd', { bg = '#1e2b22' })
  hl('DiffChange', { bg = '#2b2820' })
  hl('DiffDelete', { bg = '#2e1f22' })
  hl('DiffText', { bg = '#3a3524' })
  hl('Added', { fg = semantic.ok })
  hl('Changed', { fg = semantic.warn })
  hl('Removed', { fg = semantic.error })

  -- Telescope
  hl('TelescopeBorder', { fg = p.border })
  hl('TelescopePromptPrefix', { fg = p.keyword })
  hl('TelescopeSelection', { bg = p.surface1 })
  hl('TelescopeMatching', { fg = p.keyword, bold = true })

  -- Snacks dashboard (header rendered in the accent per spec)
  hl('SnacksDashboardHeader', { fg = p.keyword })
  hl('SnacksDashboardDesc', { fg = p.foreground })
  hl('SnacksDashboardIcon', { fg = p.keyword })
  hl('SnacksDashboardKey', { fg = p.number })
  hl('SnacksDashboardFooter', { fg = p.muted })

  -- which-key / blink
  hl('WhichKey', { fg = p.keyword })
  hl('WhichKeyGroup', { fg = p.string })
  hl('BlinkCmpMenuBorder', { fg = p.border })
  hl('BlinkCmpDocBorder', { fg = p.border })
end

---Expose the active palette for other modules (lualine theme)
---@return table, table
function M.palettes() return palette(), semantic end

return M
