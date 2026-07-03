-- lualine, themed to our palette - not the default rainbow mode-colors.
-- Mode indicator stays cyan in every mode (single-accent discipline).
-- Sections per spec: mode, git branch, filename+modified, diagnostics,
-- filetype, LSP name, line:col.

vim.pack.add { 'https://github.com/nvim-lualine/lualine.nvim' }

local p, semantic = require('caelestia.colors').palettes()

local mode_block = { a = { fg = p.background, bg = p.keyword, gui = 'bold' }, b = { fg = p.foreground, bg = p.surface2 }, c = { fg = p.muted, bg = p.surface1 } }
local theme = {
  normal = mode_block,
  insert = mode_block,
  visual = mode_block,
  replace = mode_block,
  command = mode_block,
  inactive = {
    a = { fg = p.muted, bg = p.surface0 },
    b = { fg = p.muted, bg = p.surface0 },
    c = { fg = p.muted, bg = p.surface0 },
  },
}

local function lsp_name()
  local clients = vim.lsp.get_clients { bufnr = 0 }
  if #clients == 0 then return '' end
  return table.concat(
    vim.tbl_map(function(c) return c.name end, clients),
    ' '
  )
end

require('lualine').setup {
  options = {
    theme = theme,
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    globalstatus = true,
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = { { 'filename', symbols = { modified = ' ●', readonly = ' ' } } },
    lualine_x = {
      {
        'diagnostics',
        diagnostics_color = {
          error = { fg = semantic.error },
          warn = { fg = semantic.warn },
          info = { fg = semantic.info },
          hint = { fg = p.muted },
        },
      },
      'filetype',
      lsp_name,
    },
    lualine_y = {},
    lualine_z = { 'location' },
  },
}
