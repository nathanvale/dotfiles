
# Using `ghq` with Homebrew

## Overview

`ghq` is a tool to manage remote repository clones. It helps you organize your local repositories in a structured directory tree based on the repository URL.

## Installation

To install `ghq` using Homebrew, open your terminal and run:

```sh
brew install ghq
```

## Using `ghq` with Fish Shell

To enhance your Fish shell experience with `ghq`, you can set up aliases and functions. Here's how to do it:

1. Open your Fish shell configuration file:
   ```sh
   nano ~/.config/fish/config.fish
   ```

2. Add the following aliases and functions to the file:
   ```fish
   # Alias for listing repositories
   alias ghql 'ghq list'

   # Function to get the path of a repository
   function ghqpath
       ghq list --full-path | grep $argv
   end

   # Function to get into a repository directory
   function ghqcd
       cd (ghq root)/$argv
   end

   # Function to clone a repository
   function ghqget
       ghq get $argv
   end
   ```

3. Save and close the file.

4. Reload your Fish shell configuration:
   ```sh
   source ~/.config/fish/config.fish
   ```

Now, you can use these aliases and functions to manage your repositories more easily.

## Example Usage

Here are a few examples of using `ghq`:

- **List all repositories**:
  ```sh
  ghql
  ```

- **Get the full path of a repository**:
  ```sh
  ghqpath owner/repo
  ```

- **Change to a repository directory**:
  ```sh
  ghqcd owner/repo
  ```

- **Clone a repository**:
  ```sh
  ghqget https://github.com/owner/repo
  ```

## Tips for Using `ghq` with Fish Shell

1. **Open a Repository in Editor**:
   ```sh
   function ghqedit
       set repo (ghq list --full-path | fzf)
       vim $repo
   end
   ```
   Create a function to open a repository in Vim using `fzf` for selection.

2. **List Repositories with Full Paths**:
   ```sh
   ghq list --full-path
   ```
   List all repositories with their full paths.

3. **Find Repository Paths Quickly**:
   ```sh
   ghq list --full-path | grep <keyword>
   ```
   Search for repositories matching a keyword.

4. **Custom Clone Path**:
   ```sh
   function ghqgetpath
       set path $argv
       set repo (ghq get $path | tail -n 1)
       cd $repo
   end
   ```
   Clone a repository and change to its directory.

5. **Batch Clone Repositories**:
   ```sh
   ghq get <url1> <url2> <url3>
   ```
   Clone multiple repositories at once.

6. **Set Default Root Directory**:
   ```sh
   set -Ux GHQ_ROOT ~/my_repos
   ```
   Set a custom root directory for `ghq`.

7. **Check Repository Status**:
   ```sh
   function ghqstatus
       for repo in (ghq list --full-path)
           echo "Checking $repo"
           git -C $repo status
       end
   end
   ```
   Create a function to check the Git status of all repositories.

8. **Update All Repositories**:
   ```sh
   function ghqupdate
       for repo in (ghq list --full-path)
           echo "Updating $repo"
           git -C $repo pull
       end
   end
   ```
   Create a function to update all repositories.

9. **Integrate with `fzf` for Interactive Selection**:
   ```sh
   function ghqfzf
       cd (ghq list --full-path | fzf)
   end
   ```
   Create a function to change directories interactively using `fzf`.

10. **Open Repository in Browser**:
    ```sh
    function ghqopen
        open (ghq list --full-path | fzf | sed 's|/Users/youruser/my_repos/||' | sed 's|^|https://github.com/|')
    end
    ```
    Create a function to open a selected repository in the default web browser.

## Additional Resources

- [ghq GitHub Repository](https://github.com/x-motemen/ghq)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/index.html)

By using the `ghq` package, you can manage your local repositories more efficiently and keep them organized.
