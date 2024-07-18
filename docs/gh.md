
# Using `gh` with Homebrew

## Overview

`gh` is the official GitHub CLI tool that allows you to interact with GitHub from the command line. You can manage repositories, issues, pull requests, and other GitHub resources directly from your terminal.

## Installation

To install `gh` using Homebrew, open your terminal and run:

```sh
brew install gh
```

After installing, authenticate with GitHub by running:

```sh
gh auth login
```

Follow the prompts to authenticate with your GitHub account.

## Using `gh` with Fish Shell

To enhance your Fish shell experience with `gh`, you can set up aliases and functions. Here's how to do it:

1. Open your Fish shell configuration file:
   ```sh
   nano ~/.config/fish/config.fish
   ```

2. Add the following aliases and functions to the file:
   ```fish
   # Alias for checking status
   alias ghs 'gh repo status'

   # Function to clone a repository
   function ghc
       gh repo clone $argv
   end

   # Function to create a new repository
   function ghnew
       gh repo create $argv --public --confirm
   end
   ```

3. Save and close the file.

4. Reload your Fish shell configuration:
   ```sh
   source ~/.config/fish/config.fish
   ```

Now, you can use these aliases and functions to interact with GitHub more easily.

## Example Usage

Here are a few examples of using `gh`:

- **Check the status of a repository**:
  ```sh
  ghs
  ```

- **Clone a repository**:
  ```sh
  ghc owner/repo
  ```

- **Create a new repository**:
  ```sh
  ghnew my-new-repo
  ```

## Tips for Using `gh` with Fish Shell

1. **View Issues**:
   ```sh
   gh issue list
   ```
   List all issues in the current repository.

2. **Create a New Issue**:
   ```sh
   gh issue create
   ```
   Open a new issue in the current repository.

3. **View Pull Requests**:
   ```sh
   gh pr list
   ```
   List all pull requests in the current repository.

4. **Checkout a Pull Request**:
   ```sh
   gh pr checkout <number>
   ```
   Check out a specific pull request by its number.

5. **Merge a Pull Request**:
   ```sh
   gh pr merge <number>
   ```
   Merge a specific pull request by its number.

6. **View Repository Information**:
   ```sh
   gh repo view
   ```
   Display detailed information about the current repository.

7. **Create a New Release**:
   ```sh
   gh release create <tag>
   ```
   Create a new release with the specified tag.

8. **View Notifications**:
   ```sh
   gh api notifications
   ```
   Fetch and display GitHub notifications.

9. **Open Repository in Browser**:
   ```sh
   gh repo view --web
   ```
   Open the current repository in your default web browser.

10. **Interact with GitHub Actions**:
    ```sh
    gh workflow list
    ```
    List all GitHub Actions workflows in the current repository.

## Additional Resources

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/index.html)

By using the `gh` package, you can streamline your GitHub workflow directly from your terminal, enhancing your productivity and efficiency.
