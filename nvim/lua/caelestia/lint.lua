-- nvim-lint scoped to qmllint for QML only (spec: no other linters).
-- Mirrors upstream caelestia's own CI lint job (shell/.github/workflows/
-- lint.yml): import paths come from the Quickshell-generated .qmlls.ini
-- next to shell.qml, passed as -I args alongside --import disable.

vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

local lint = require 'lint'

-- Arch ships qmllint in qt6-declarative under /usr/lib/qt6/bin; fall back
-- to that when it isn't symlinked onto PATH
local qmllint_cmd = vim.fn.executable 'qmllint' == 1 and 'qmllint' or '/usr/lib/qt6/bin/qmllint'

---.qmlls.ini values are quoted (buildDir="...", importPaths="a:b:c"),
---same format upstream's CI greps out of it
---@param bufnr integer
---@return string[]
local function qmllint_args(bufnr)
  local args = { '--import', 'disable' }
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  local ini = vim.fs.find('.qmlls.ini', { upward = true, path = dir })[1]
  if not ini then return args end
  for line in io.lines(ini) do
    local build_dir = line:match '^buildDir="(.-)"'
    if build_dir and build_dir ~= '' then vim.list_extend(args, { '-I', build_dir }) end
    local import_paths = line:match '^importPaths="(.-)"'
    if import_paths then
      for path in import_paths:gmatch '[^:]+' do
        vim.list_extend(args, { '-I', path })
      end
    end
  end
  return args
end

-- Defined as a function so the -I args are re-resolved on every lint run
-- (the .qmlls.ini appears/changes when Quickshell runs)
lint.linters.qmllint = function()
  return {
    cmd = qmllint_cmd,
    stdin = false,
    append_fname = true,
    args = qmllint_args(0),
    stream = 'both',
    ignore_exitcode = true,
    -- e.g. "Warning: /path/shell.qml:10:5: Unqualified access [unqualified]"
    parser = require('lint.parser').from_pattern('^(%a+): (.-):(%d+):(%d+): (.+)$', { 'severity', 'file', 'lnum', 'col', 'message' }, {
      Error = vim.diagnostic.severity.ERROR,
      Warning = vim.diagnostic.severity.WARN,
      Info = vim.diagnostic.severity.INFO,
    }, { source = 'qmllint' }),
  }
end

lint.linters_by_ft = { qml = { 'qmllint' } }

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = vim.api.nvim_create_augroup('caelestia-lint', { clear = true }),
  callback = function()
    -- try_lint is a no-op for filetypes not in linters_by_ft
    lint.try_lint(nil, { ignore_errors = true })
  end,
})
