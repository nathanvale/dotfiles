
# Install Script Usage

This repository contains an `install.sh` script designed to download and execute a series of scripts, each potentially with its own parameters. The script supports both public and private repositories.

## Prerequisites

- `curl` must be installed on your system.
- If accessing private repositories, you will need a GitHub Personal Access Token.

## Usage

### Running the Installation Script

1. **Set the GitHub Token (if needed)**:
   If the scripts are hosted in private repositories, you need to set your GitHub Personal Access Token. If the scripts are public, you can leave the token empty.

   ```bash
   export GITHUB_TOKEN="YOUR_GITHUB_TOKEN"  # Leave it empty if not needed
   ```

2. **Execute the Installation Script**:
   Use `curl` to download and run the `install.sh` script.

   ```bash
   curl -H "Authorization: token $GITHUB_TOKEN" -s https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/install.sh | bash
   ```

### Script Details

The `install.sh` script downloads and executes other scripts specified in its configuration. Each script can be run with or without parameters.

### Example Configuration

In the `install.sh` script, the `scripts` array defines the URLs and parameters for the scripts to be executed:

```bash
scripts=(
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/create_dotfiles_symlinks.sh|--unlink"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/hello_world.sh|--force"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/no_params_script.sh|"
)
```

- **`create_dotfiles_symlinks.sh`**: Will be executed with the `--unlink` parameter.
- **`hello_world.sh`**: Will be executed with the `--force` parameter.
- **`no_params_script.sh`**: Will be executed without any parameters.

### Adding New Scripts

To add new scripts to the installation process, update the `scripts` array in the `install.sh` script:

1. Open `install.sh` in a text editor.
2. Add the new script URL and parameters (if any) to the `scripts` array.

#### Example

```bash
scripts+=("https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/new_script.sh|--example-param")
```

### Handling Public and Private Repositories

- **Public Repositories**: The script URLs can be accessed without a GitHub token.
- **Private Repositories**: Export your GitHub token as shown in the usage section to access private URLs.

### Example Scripts

Ensure your scripts are ready to handle parameters if required.

#### `create_dotfiles_symlinks.sh`

```bash
#!/bin/bash

if [ "$1" == "--unlink" ]; then
    echo "Unlinking dotfiles..."
    # Add your unlink logic here
else
    echo "Creating symlinks..."
    # Add your symlink creation logic here
fi
```

#### `hello_world.sh`

```bash
#!/bin/bash

if [ "$1" == "--force" ]; then
    echo "Force option selected."
    # Add your force logic here
else
    echo "Hello, World!"
    # Default behavior
fi
```

#### `no_params_script.sh`

```bash
#!/bin/bash

echo "This script does not require any parameters."
# Add your script logic here
```

### Cleaning Up

The `install.sh` script will clean up the temporary directory used to store the downloaded scripts after execution.

```bash
# Cleanup: remove the temporary directory
rm -rf "$tmp_dir"
```

## Conclusion

This `install.sh` script simplifies the process of downloading and executing multiple scripts, handling both public and private repositories, and passing parameters as needed. Customize the `scripts` array in `install.sh` to suit your specific requirements.
