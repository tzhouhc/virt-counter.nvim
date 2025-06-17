# virt-counter.nvim

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Shows line/char count for current visual selection as virtual text.

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
  -- Location of the virtual text.
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
  -- Custom format function for the count, receives the number of lines and chars
  -- as two integers params, and expects a string (or nil) in return.
  format = function(lines, chars)
    return string.format("%d lines, %d characters", lines, chars)
  end,
}
```

## Example

Sample setup with customized formatting and "pill"-like visuals using powerline
symbols:

![Sample](https://github.com/tzhouhc/virt-counter/raw/main/images/demo_1.png)

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
