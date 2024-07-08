# Bat with Fish Shell

`bat` is a clone of `cat` with syntax highlighting and Git integration. It is a great tool for viewing files in the terminal with enhanced features.

## Basic Usage

- View a file: `bat filename`
- View multiple files: `bat file1 file2`
- Show non-printable characters: `bat -A filename`
- Show line numbers: `bat -n filename`

## Keyboard Shortcuts

When using `bat` interactively (e.g., through a pager like `less`), the following keyboard shortcuts can be very useful:

- **Scroll Up**: `k` or `↑`
- **Scroll Down**: `j` or `↓`
- **Page Up**: `Ctrl+u` or `Page Up`
- **Page Down**: `Ctrl+d` or `Page Down`
- **Go to the start of the file**: `g`
- **Go to the end of the file**: `G`
- **Search**: `/` then type your search term and press `Enter`
- **Next Search Result**: `n`
- **Previous Search Result**: `N`
- **Quit**: `q`

## Customizing Bat with Fish

You can customize `bat` by adding aliases and functions in your `fish` configuration.

### Alias for Common Usage

```fish
alias cat='bat'
alias batn='bat -n'  # Alias to show line numbers
```

### Function to View a Directory with `ls`

```fish
function batdir
    exa -la | bat --language=sh
end
```

### Reload Fish Configuration

```fish
source ~/.config/fish/config.fish
```
