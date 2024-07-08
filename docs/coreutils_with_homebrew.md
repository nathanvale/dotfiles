
# Using GNU Core Utilities with Homebrew

## Overview

The `coreutils` package in Homebrew provides the GNU core utilities, which are the basic file, shell, and text manipulation utilities of the GNU operating system. These utilities include essential commands such as `ls`, `cat`, `rm`, `mv`, and many others.

On macOS, the default core utilities are the BSD versions, which can differ slightly from the GNU versions. Installing the `coreutils` package allows you to use the GNU versions, which are often more feature-rich.

## Installation

To install the `coreutils` package using Homebrew, open your terminal and run:

```sh
brew install coreutils
```

Once installed, the GNU versions of the utilities are prefixed with a "g" to differentiate them from the BSD versions. For example:
- `ls` becomes `gls`
- `cat` becomes `gcat`
- `rm` becomes `grm`
- `mv` becomes `gmv`
ee
## Using with Fish Shell

To use the GNU core utilities without the "g" prefix in the Fish shell, you can create aliases. Here's how to do it:

1. Open your Fish shell configuration file:
   ```sh
   nano ~/.config/fish/config.fish
   ```

2. Add the following aliases to the file:
   ```fish
   alias ls 'gls'
   alias cat 'gcat'
   alias rm 'grm'
   alias mv 'gmv'
   ```

3. Save and close the file.

4. Reload your Fish shell configuration:
   ```sh
   source ~/.config/fish/config.fish
   ```

Now, when you use `ls`, `cat`, `rm`, and `mv`, the Fish shell will use the GNU versions of these commands.

## Example Usage

Here are a few examples of using the GNU core utilities:

- **List files with detailed information**:
  ```sh
  ls -lh
  ```

- **Concatenate and display file content**:
  ```sh
  cat file.txt
  ```

- **Remove a file**:
  ```sh
  rm file.txt
  ```

- **Move or rename a file**:
  ```sh
  mv oldname.txt newname.txt
  ```

## Additional Resources

- [GNU Core Utilities Documentation](https://www.gnu.org/software/coreutils/manual/coreutils.html)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/index.html)

By using the `coreutils` package, you can enhance your terminal experience with the powerful and feature-rich GNU versions of these essential commands.
