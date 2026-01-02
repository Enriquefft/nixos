# Cyber Tardigrade Color Palette
# Single source of truth for all theming
{
  cyberTardigrade = {
    # Base colors
    bg_base = "0d0d1a";       # Main background
    bg_surface = "1a1432";    # Panels, bars
    bg_elevated = "2a2045";   # Popups, menus

    # Foreground colors
    fg_dim = "6b6b8a";        # Comments, inactive
    fg_normal = "a8a8c0";     # Body text
    fg_bright = "d4d4e8";     # Headings, focus

    # Accent colors
    accent_cyan = "5a8fba";      # Links, info
    accent_purple = "7a4a8a";    # Selections
    accent_magenta = "b55a9a";   # Keywords
    accent_orange = "e86a30";    # PRIMARY ACCENT - active borders, focus
    accent_gold = "f0a050";      # Warnings, special

    # Status colors
    success = "5aaa7a";       # Git add, success
    error = "d55a5a";         # Git del, errors
    border = "3a3055";        # Inactive borders

    # High-contrast variants for terminal/dark backgrounds
    terminal_success = "7fd4a8";     # Brighter green for git clean
    terminal_modified = "ffbe78";    # Brighter gold for git modified
    terminal_untracked = "ff9966";   # Brighter orange for git untracked
    terminal_error = "ff8a8a";       # Brighter red for errors
    terminal_cyan = "7eb3d4";        # Brighter cyan for info
  };
}
