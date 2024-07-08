
# Using `fzf` with Homebrew

## Overview

`fzf` is a general-purpose command-line fuzzy finder. It allows you to quickly search and navigate through files, command history, and other text input. It can be used as a standalone tool or integrated into various commands and workflows.

## Installation

To install `fzf` using Homebrew, open your terminal and run:

```sh
brew install fzf
```

After installing, you can run the install script to enable useful key bindings and fuzzy completion:

```sh
$(brew --prefix)/opt/fzf/install
```

## Using `fzf` with Fish Shell

To enhance your Fish shell experience with `fzf`, you can set up key bindings and aliases. Here's how to do it:

1. Open your Fish shell configuration file:
   ```sh
   nano ~/.config/fish/config.fish
   ```

2. Add the following lines to the file:
   ```fish
   # Enable fuzzy auto-completion and key bindings
   set -U FZF_DEFAULT_COMMAND 'fd --type f'
   set -Ux FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
   set -Ux FZF_ALT_C_COMMAND 'fd --type d'
   ```

3. Save and close the file.

4. Reload your Fish shell configuration:
   ```sh
   source ~/.config/fish/config.fish
   ```

Now, you can use `fzf` with the following key bindings:
- `Ctrl+T`: Fuzzy file finder
- `Alt+C`: Fuzzy directory changer
- `Ctrl+R`: Fuzzy command history search

## Example Usage

Here are a few examples of using `fzf`:

- **Find a file in the current directory**:
  ```sh
  fzf
  ```

- **Find a file using a custom command**:
  ```sh
  fd --type f | fzf
  ```

- **Search through command history**:
  ```sh
  history | fzf
  ```

- **Preview file content while searching**:
  ```sh
  fzf --preview 'cat {}'
  ```

## Tips for Using `fzf` with Fish Shell

1. **Search with Ripgrep**:
   ```sh
   rg --files | fzf
   ```
   Use `ripgrep` for faster searching.

2. **Set Default Editor for `fzf`**:
   ```sh
   set -U FZF_DEFAULT_OPTS '--bind ctrl-e:execute(vim {})'
   ```
   Open the selected file in Vim with `Ctrl+E`.

3. **Customize `fzf` Layout**:
   ```sh
   set -U FZF_DEFAULT_OPTS '--layout=reverse'
   ```
   Display the search results at the top.

4. **Preview Images with `fzf`**:
   ```sh
   fzf --preview 'ueberzug cat {}'
   ```
   Use `ueberzug` to preview images.

5. **Use `fzf` with Git**:
   ```sh
   git ls-files | fzf
   ```
   Fuzzy-find files in a Git repository.

6. **Interactive Grep with `fzf`**:
   ```sh
   fzf --bind 'ctrl-g:execute-silent(echo {} | xargs grep -nH)'
   ```
   Search within files interactively.

7. **Search and Open Files**:
   ```sh
   fzf --bind 'enter:execute(nvim {})'
   ```
   Open selected files in Neovim.

8. **Colorize Output**:
   ```sh
   set -U FZF_DEFAULT_OPTS '--color=dark'
   ```
   Customize the color scheme.

9. **Limit Results to Directories**:
   ```sh
   fzf --filter 'type:directory'
   ```
   Only show directories in results.

10. **Integrate with Fish Functions**:
    ```sh
    function fcd
        set dir (fzf --query "$argv")
        if test -d "$dir"
            cd "$dir"
        end
    end
    ```
    Create a Fish function to change directories using `fzf`.

## Additional Resources

- [fzf GitHub Repository](https://github.com/junegunn/fzf)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/index.html)

By using the `fzf` package, you can enhance your terminal experience with powerful and flexible fuzzy searching capabilities.
