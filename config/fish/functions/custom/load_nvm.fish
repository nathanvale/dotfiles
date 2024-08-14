function load_nvm
    # Get the current directory
    set current_dir (pwd)

    # Get the top-level directory of the Git project, suppress error output if not a git repo
    set git_root_dir (git rev-parse --show-toplevel 2>/dev/null)

    # Only proceed if the current directory is the Git root directory
    if test "$current_dir" = "$git_root_dir"
        # Use fish's built-in string manipulation instead of cat
        set nvmrc_path (nvm_find_nvmrc)

        # If an .nvmrc file is found
        if test -n "$nvmrc_path"
            # Read the Node.js version specified in the .nvmrc file
            set nvm_version (string trim (cat $nvmrc_path))
            # Try to use the desired Node.js version
            nvm use $nvm_version
            # If the Node.js version is not installed, install it 
            if test $status -ne 0
                nvm install $nvm_version
                nvm use $nvm_version
            end
        end
    end
end
