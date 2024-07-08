
# Using `eza` with Homebrew

## Overview

The `eza` package is a modern ***REMOVED*** for the `ls` command. It provides a more user-friendly and feature-rich way to list files and directories, with additional features such as improved formatting, colorization, and more intuitive output.

## Installation

To install the `eza` package using Homebrew, open your terminal and run:

```sh
brew install eza
```

## Using `eza` with Fish Shell

To replace the default `ls` command with `eza` in the Fish shell, you can create an alias. Here's how to do it:

1. Open your Fish shell configuration file:
   ```sh
   nano ~/.config/fish/config.fish
   ```

2. Add the following alias to the file:
   ```fish
   alias ls 'eza'
   ```

3. Save and close the file.

4. Reload your Fish shell configuration:
   ```sh
   source ~/.config/fish/config.fish
   ```

Now, when you use `ls`, the Fish shell will use `eza` instead of the default `ls` command.

## Example Usage

Here are a few examples of using `eza`:

- **List files with detailed information**:
  ```sh
  eza -lh
  ```

- **List files with colors and icons**:
  ```sh
  eza --color=auto --icons
  ```

- **List files with tree view**:
  ```sh
  eza --tree
  ```

## Additional Resources

- [eza GitHub Repository](https://github.com/eza-community/eza)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/index.html)

By using the `eza` package, you can enhance your terminal experience with a modern and user-friendly ***REMOVED*** for the `ls` command.
