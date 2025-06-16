-- lua/visual-counter/init.lua
local M = {}

local last_update = 0

-- Default configuration
local config = {
  -- What highlight group to use for the virtual text.
  highlight_group = "Comment",
  -- Location of the virtual text.
  pos = "eol",
  -- Minimal amount of time to pass in milli-secs before rerunning.
  debounce_ms = 50,
  -- Whether to count using bytes or actual characters (e.g. for CJK).
  count_bytes = false,
  -- Whether to count newline characters or not. Due to neovim native counting
  -- mechanisms, probably does not work correctly in blockwise selection.
  count_newlines = false,
  -- Custom format function for the count, receives the number of lines, words
  -- and chars as 3 integers params, and expects a string (or nil) in return.
  format = function(lines, words, chars)
    return string.format("%d lines, %d words, %d chars", lines, words, chars)
  end,
}

local ns_id = vim.api.nvim_create_namespace("visual_counter_virt_text")

local function get_visual_region()
  local ok, result = pcall(function()
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    return vim.fn.getregion(start_pos, end_pos, { type = vim.fn.mode() })
  end)
  return ok and result or nil
end

local function count_chars(text)
  return vim.fn.strchars(text)
end

local function is_cursor_at_eol()
  local cursor_col = vim.fn.col('.')
  local line_length = vim.fn.col('$')
  return cursor_col == line_length
end

local function count(lines, count_bytes, count_newlines)
  if not lines or #lines == 0 then
    return ""
  end
  local total_lines = #lines
  local total_chars = 0
  for _, line in ipairs(lines) do
    if count_bytes then
      total_chars = total_chars + string.len(line)
    else
      total_chars = total_chars + count_chars(line)
    end
  end
  if count_newlines then
    if vim.fn.mode() == "v" then
      total_chars = total_chars + total_lines - 1
      if is_cursor_at_eol() then
        total_chars = total_chars + 1
      end
    elseif vim.fn.mode() == "V" then
      total_chars = total_chars + total_lines
    end
  end
  return config.format(total_lines, vim.fn.wordcount().visual_words, total_chars)
end

local function make_virtual_text(content)
  vim.api.nvim_buf_set_extmark(0, ns_id, vim.fn.line('.') - 1, 0, {
    virt_text = { { content, config.highlight_group } },
    virt_text_pos = config.pos
  })
end

local function clear_virtual_text()
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

local function setup_autocmds()
  local autogrp = vim.api.nvim_create_augroup("VisualCounterVirtualText", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    pattern = { "*" },
    callback = function()
      local now = vim.loop.hrtime() / 1000000 -- Convert to ms
      if now - last_update < config.debounce_ms then return end
      last_update = now
      clear_virtual_text()
      local in_visual = vim.fn.mode():match('[vV\22]')
      if not in_visual then return end
      local region = get_visual_region()
      if not region then return end
      local virtext = count(
        region,
        config.count_bytes,
        config.count_newlines
      )
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
  if opts.format and type(opts.format) ~= "function" then
    vim.notify("virt-counter: format must be a function", vim.log.levels.ERROR)
    opts.format = nil
  end
  config = vim.tbl_deep_extend("force", config, opts)
  setup_autocmds()
end

function M.disable()
  clear_virtual_text()
  vim.api.nvim_del_augroup_by_name("VisualCounterVirtualText")
end

return M
