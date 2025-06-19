-- lua/visual-counter/init.lua
local M = {}

local last_update = 0

-- Default configuration
local config = {
  -- What highlight group to use for the virtual text.
  highlight_group = "Comment",
  -- Location of the virtual text. Can take legal values of `virt_text_pos`.
  pos = "eol",
  -- Minimal amount of time to pass in milli-secs before rerunning.
  debounce_ms = 50,
  -- Whether to count using bytes or actual characters (e.g. for CJK).
  count_bytes = false,
  -- Whether to count newline characters or not. Due to neovim native counting
  -- mechanisms, probably does not work correctly in blockwise selection.
  count_newlines = false,
  -- Whether to count white space characters or not.
  count_whitespace = true,
  -- additional spaces to put before the virtual text.
  spacing = 0,
  -- Configuration for creation a 'pill/button' like virtual text.
  --   left: the left edge string for the button
  --   right: the right edge string for the button
  --   edge_highlight_group: the highlight group for the edges of the button.
  --       if not provided, creates a simple reversed hl group using the main
  --       highlight_group. (For best effects, this should be one with colored
  --       bg and dark fg.)
  button = nil,
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

local function count(lines, count_bytes, count_newlines, count_whitespace)
  if not lines or #lines == 0 then
    return ""
  end
  local total_lines = #lines
  local total_chars = 0
  for _, line in ipairs(lines) do
    if not count_whitespace then
      line = string.gsub(line, "%s", "")
    end
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
  return total_lines, vim.fn.wordcount().visual_words, total_chars
end

local function make_virtual_text(spacing, content)
  vim.api.nvim_buf_set_extmark(0, ns_id, vim.fn.line('.') - 1, 0, {
    virt_text = {
      { string.rep(" ", spacing), "Normal" },
      { content,                  config.highlight_group }
    },
    virt_text_pos = config.pos
  })
end

local function make_button_virtual_text(spacing, content, button)
  vim.api.nvim_buf_set_extmark(0, ns_id, vim.fn.line('.') - 1, 0, {
    virt_text = {
      { string.rep(" ", spacing), "Normal" },
      { button.left or "",        button.edge_highlight_group },
      { content,                  config.highlight_group },
      { button.right or "",       button.edge_highlight_group },
    },
    virt_text_pos = config.pos
  })
end

local function clear_virtual_text()
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

local function create_inverse_highlight(orig_grp)
  local new_grp = orig_grp .. "Reversed"
  -- Get original highlight
  local orig_hl = vim.api.nvim_get_hl(0, { name = orig_grp })
  if vim.tbl_isempty(orig_hl) then
    return new_grp
  end
  vim.api.nvim_set_hl(0, new_grp, { fg = orig_hl.bg, bg = orig_hl.fg })
  return new_grp
end

function M.refresh()
  clear_virtual_text()
  local in_visual = vim.fn.mode():match('[vV\22]')
  if not in_visual then return end
  local region = get_visual_region()
  if not region then return end
  local virtext = config.format(count(
    region,
    config.count_bytes,
    config.count_newlines,
    config.count_whitespace
  ))
  if not virtext then return end
  local button = config.button
  if button and (button.left or button.right) then
    make_button_virtual_text(config.spacing, virtext, button)
  else
    make_virtual_text(config.spacing, virtext)
  end
end

local function setup_edge_highlight_group()
  if not config.button then return end
  if next(config.button) == nil then return end
  if not config.button.edge_highlight_group then
    config.button.edge_highlight_group = create_inverse_highlight(config.highlight_group)
  end
end

local function setup_autocmds()
  setup_edge_highlight_group()
  local autogrp = vim.api.nvim_create_augroup("VisualCounterVirtualText", { clear = true })

  -- activate on both mode change and cursor move so that
  --   - entering visual mode immediately creates the virtext
  --   - leaving immediately clears it
  vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
    pattern = { "*" },
    callback = function()
      local now = vim.loop.hrtime() / 1000000 -- Convert to ms
      if now - last_update < config.debounce_ms then return end
      last_update = now
      M.refresh()
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

  -- count_whitespace overrides count_newlines: newlines are whitespaces
  if not config.count_whitespace then config.count_newlines = false end
  setup_autocmds()
end

function M.disable()
  clear_virtual_text()
  vim.api.nvim_del_augroup_by_name("VisualCounterVirtualText")
end

return M
