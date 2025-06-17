# virt-counter.nvim

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Shows line/word/char count for current visual selection as virtual text.

> [!NOTE]
> Known caveat: does not immediately update selection count when selection
> updates but the cursor does not move -- Neovim does not provide an event
> for [visual change](https://github.com/neovim/neovim/issues/19708).
> I suppose you can just wobble your cursor a bit...?

## Basic setup

```lua
-- lazy.nvim
"tzhouhc/virt-counter.nvim"
```

## Options

```lua
-- Default configuration
opts = {
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
```

## Example

Sample setup with customized formatting and "pill"-like visuals using powerline
symbols:

![Sample](https://github.com/tzhouhc/virt-counter.nvim/raw/main/images/demo_1.png)

```lua
return {
  "tzhouhc/virt-counter.nvim",
  opts = {
    count_newlines = true,
    highlight_group = "CurSearch",
    spacing = 4,
    button = {
      left = "\u{E0B6}",
      right = "\u{E0B4}",
    },
    format = function(l, w, c)
      return "󰈚 " .. l .. " 󰬞 " .. w .. " 󰬊 " .. c
    end,
  }
},
```

## API

In addition to the standard `setup` method, you can also directly invoke the
lua API with `require("virt-counter").refresh()`, which will clear the virtual
text if outside of visual mode, or update it without requiring the events.
