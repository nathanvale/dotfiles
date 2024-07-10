# Dotfiles Symlink Creation Script

This script creates symbolic links for your dotfiles based on a JSON configuration file. It ensures that the symbolic links are created correctly and updates them if they already exist but point to the wrong target.

## Prerequisites

- Make sure you have `jq` installed on your system. `jq` is a lightweight and flexible command-line JSON processor.

## JSON Configuration File

The JSON configuration file (`symlinks.json`) should be located at `${HOME}/code/dotfiles/config/symlinks/symlinks.json`. This file defines the symbolic links to be created.

### Example `symlinks.json`

```json
{
  "symlinks": [
    {
      "target": "${HOME}/code/dotfiles/.bashrc",
      "link_name": "${HOME}/.bashrc"
    },
    {
      "target": "${HOME}/code/dotfiles/.vimrc",
      "link_name": "${HOME}/.vimrc"
    }
  ]
}
```

## Usage

1. Make sure the script is executable. If it is not, you can make it executable by running the following command:

   ```bash
   chmod +x create_dotfiles_symlinks.sh
   ```

2. Run the script:

   ```bash
   create_dotfiles_symlinks.sh
   ```

## How It Works

1. The script reads the JSON configuration file and iterates over the defined symlinks.
2. For each symlink:
   - If the symlink already exists and points to the correct target, it will confirm the correct setup.
   - If the symlink exists but points to the wrong target, it will update the symlink to point to the correct target.
   - If the file or directory already exists and is not a symlink, it will notify you without making changes.
   - If the symlink does not exist, it will create the symlink.

## Notes

- This script is designed to work with a specific structure for your dotfiles. Adjust the paths and configuration as needed for your setup.

## Example Output

When you run the script, you might see output similar to the following:

```
Symlink created: /home/user/.bashrc -> /home/user/code/dotfiles/.bashrc
Symlink /home/user/.vimrc already exists and points to the correct target.
Symlink /home/user/.config exists but is not a symlink.
Symlink updated: /home/user/.gitconfig -> /home/user/code/dotfiles/.gitconfig
Symlink creation process completed.
```

This output shows the status of each symlink and what actions were taken by the script.

## Troubleshooting

- Ensure that the paths in the JSON configuration file are correct.
- Make sure you have the necessary permissions to create or update the symlinks in the specified locations.

For any issues or questions, please feel free to open an issue or contact the maintainer.
