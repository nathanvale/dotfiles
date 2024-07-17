
# Using `git-delta` with Homebrew

## Overview

`git-delta` (or `delta`) is a syntax-highlighting pager for `git`, `diff`, and `grep` output. It enhances the readability of diffs with syntax highlighting, better formatting, and side-by-side view.

## Installation

To install `git-delta` using Homebrew, open your terminal and run:

```sh
brew install git-delta
```

## Using `git-delta` with Fish Shell

To integrate `git-delta` with your Git workflow in the Fish shell, you can set up aliases and configure Git to use `delta` as the pager. Here's how to do it:

1. Open your Git configuration file:
   ```sh
   git config --global core.pager delta
   ```

2. Open your Fish shell configuration file:
   ```sh
   nano ~/.config/fish/config.fish
   ```

3. Add the following alias to the file:
   ```fish
   # Alias for git diff
   alias gd 'git diff'
   
   # Alias for git log with delta
   alias glog 'git log --oneline --graph --decorate --color --format="%C(auto)%h %C(bold blue)%>(12)%ad %C(white)%s %C(dim white)- %an" --date=short | delta'
   ```

4. Save and close the file.

5. Reload your Fish shell configuration:
   ```sh
   source ~/.config/fish/config.fish
   ```

Now, you can use `git-delta` to view diffs and logs with improved readability.

## Example Usage

Here are a few examples of using `git-delta`:

- **View a Git diff**:
  ```sh
  gd
  ```

- **View a Git log with delta**:
  ```sh
  glog
  ```

## Tips for Using `git-delta` with Fish Shell

1. **Customize Delta Theme**:
   ```sh
   git config --global delta.syntax-theme "Dracula"
   ```
   Set a custom syntax theme for delta.

2. **Enable Side-by-Side Diffs**:
   ```sh
   git config --global delta.side-by-side true
   ```
   View diffs in a side-by-side format.

3. **Use Line Numbers**:
   ```sh
   git config --global delta.line-numbers true
   ```
   Display line numbers in diffs.

4. **Customize Delta Features**:
   ```sh
   git config --global delta.features "side-by-side line-numbers"
   ```
   Enable multiple features simultaneously.

5. **Integrate with `git show`**:
   ```sh
   alias gs 'git show | delta'
   ```
   Create an alias to view `git show` output with delta.

6. **Highlight Syntax in Diffs**:
   ```sh
   git config --global delta.syntax-highlighting true
   ```
   Enable syntax highlighting for diffs.

7. **Use Minimal Mode**:
   ```sh
   git config --global delta.minimal true
   ```
   Display minimal diff output.

8. **Configure Delta Pager Options**:
   ```sh
   git config --global delta.pager "less -R"
   ```
   Use `less` with delta for better pagination.

9. **Set Delta as Default for Git Grep**:
   ```sh
   git config --global grep.pager "delta --paging=always"
   ```
   Use delta for `git grep` output.

10. **Combine Delta with Other Tools**:
    ```sh
    function dgrep
        git grep --untracked -n $argv | delta
    end
    ```
    Create a function to use delta with `git grep`.

## Additional Resources

- [git-delta GitHub Repository](https://github.com/dandavison/delta)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/index.html)

By using the `git-delta` package, you can enhance your Git workflow with better diff and log readability, making it easier to understand code changes.
