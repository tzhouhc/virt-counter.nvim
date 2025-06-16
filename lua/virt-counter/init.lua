-- lua/visual-counter/init.lua
local M = {}

-- Default configuration
local config = {
  highlight_group = "Comment",
  format = function(lines, chars)
    return string.format("%d lines, %d characters", lines, chars)
  end,
}

-- Create a namespace for virtual text
local ns_id = vim.api.nvim_create_namespace("visual_counter")

local function get_visual_region()
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  return vim.fn.getregion(
    start_pos, end_pos, { type = vim.fn.mode() }
  )
end

local function line_and_char_count(lines)
  if not lines or #lines == 0 then
    return ""
  end
  local total_lines = #lines
  local total_chars = 0
  for _, line in ipairs(lines) do
    total_chars = total_chars + string.len(line)
  end
  return config.format(total_lines, total_chars)
end

local function make_virtual_text(content)
  vim.api.nvim_buf_set_extmark(0, ns_id, vim.fn.line('.') - 1, 0, {
    virt_text = { { content, config.highlight_group } },
    virt_text_pos = "eol"
  })
end

local function clear_virtual_text()
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

local function setup_autocmds()
  local autogrp = vim.api.nvim_create_augroup("VisualCounterVirtualText", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    pattern = { "*.*" },
    callback = function()
      clear_virtual_text()
      local in_visual = vim.fn.mode():match('[vV\22]')
      if not in_visual then return end
      local region = get_visual_region()
      if not region then return end
      local virtext = line_and_char_count(region)
      if not virtext then return end
      make_virtual_text(virtext)
    end,
    group = autogrp,
  })

  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    pattern = { "*.*" },
    callback = function()
      clear_virtual_text()
    end,
    group = autogrp,
  })
end

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)
  setup_autocmds()
end

return M
