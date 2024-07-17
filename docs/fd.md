
# Using `fd` with Homebrew

## Overview

`fd` is a simple, fast, and user-friendly alternative to `find`. It offers intuitive syntax, colorized output, and faster search capabilities.

## Installation

To install `fd` using Homebrew, open your terminal and run:

```sh
brew install fd
```

## Using `fd` with Fish Shell

To enhance your Fish shell experience with `fd`, you can set up aliases and functions. Here's how to do it:

1. Open your Fish shell configuration file:
   ```sh
   nano ~/.config/fish/config.fish
   ```

2. Add the following aliases and functions to the file:
   ```fish
   # Alias for fd
   alias find 'fd'

   # Function to search for files with a specific extension
   function fdext
       fd --extension $argv[1]
   end

   # Function to exclude a specific directory from search
   function fdexclude
       fd --exclude $argv[1] $argv[2]
   end

   # Function to search for files containing a specific pattern
   function fdgrep
       fd --exec grep -l $argv[1]
   end

   # Function to search and delete files
   function fddelete
       fd $argv[1] --exec rm
   end
   ```

3. Save and close the file.

4. Reload your Fish shell configuration:
   ```sh
   source ~/.config/fish/config.fish
   ```

Now, you can use these aliases and functions to search for files more effectively.

## Example Usage

Here are a few examples of using `fd`:

- **Search for files with a specific extension**:
  ```sh
  fdext txt
  ```

- **Exclude a specific directory from search**:
  ```sh
  fdexclude node_modules pattern
  ```

- **Search for files containing a specific pattern**:
  ```sh
  fdgrep "TODO"
  ```

- **Search and delete files**:
  ```sh
  fddelete "*.tmp"
  ```

## Tips for Using `fd` with Fish Shell

1. **Search by Filename**:
   ```sh
   fd pattern
   ```
   Search for files matching the pattern in their filenames.

2. **Show Hidden Files**:
   ```sh
   fd --hidden pattern
   ```
   Include hidden files in the search results.

3. **Follow Symlinks**:
   ```sh
   fd --follow pattern
   ```
   Follow symbolic links during the search.

4. **Use Regular Expressions**:
   ```sh
   fd --regex "pattern"
   ```
   Use regular expressions for more complex searches.

5. **Search for Directories**:
   ```sh
   fd --type d pattern
   ```
   Search specifically for directories.

6. **Limit Depth of Search**:
   ```sh
   fd --max-depth 2 pattern
   ```
   Limit the search to a maximum depth of 2 directories.

7. **Search by Modification Time**:
   ```sh
   fd --changed-within 2days pattern
   ```
   Search for files modified within the last 2 days.

8. **Execute Commands on Matches**:
   ```sh
   fd pattern --exec echo
   ```
   Execute a command on each search result.

9. **Colorize Output**:
   ```sh
   fd --color always pattern
   ```
   Always colorize the search output.

10. **Exclude Multiple Patterns**:
    ```sh
    fd --exclude "pattern1" --exclude "pattern2" pattern
    ```
    Exclude multiple patterns from the search results.

## Additional Resources

- [fd GitHub Repository](https://github.com/sharkdp/fd)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/index.html)

By using the `fd` package, you can perform fast and efficient file searches with a more user-friendly syntax compared to `find`.
