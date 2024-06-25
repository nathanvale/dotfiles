# Function to load nvm based on .nvmrc file
function load_nvm
    # Get the default Node.js version and the current Node.js version
    set -l default_node_version (nvm version default)
    set -l node_version (nvm version)

    # Find the .nvmrc file in the current directory or any parent directory
    set -l nvmrc_path (nvm_find_nvmrc)
    
    # If an .nvmrc file is found
    if test -n "$nvmrc_path"
        # Read the Node.js version specified in the .nvmrc file
        set -l nvmrc_node_version (nvm version (cat $nvmrc_path))
        
        # If the specified Node.js version is not installed, install it
        if test "$nvmrc_node_version" = "N/A"
            nvm install (cat $nvmrc_path)
        # If the specified Node.js version is different from the current one, use it
        else if test "$nvmrc_node_version" != "$node_version"
            nvm use $nvmrc_node_version
        end
    # If no .nvmrc file is found and the current Node.js version is not the default, revert to the default version
    else if test "$node_version" != "$default_node_version"
        echo "Reverting to default Node version"
        nvm use default
    end
end