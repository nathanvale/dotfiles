function load_nvm
    # Load nvm using bass
    bass source (brew --prefix nvm)/nvm.sh
    set nvmrc_path (nvm_find_nvmrc)
    # If an .nvmrc file is found
    if test -n "$nvmrc_path"
        # Read the Node.js version specified in the .nvmrc file
        set nvm_version (cat $nvmrc_path)
        # Check if the Node.js version is already installed
        nvm use $nvm_version
        # If the Node.js version is not installed, install it 
        if test $status -ne 0
            nvm install $npm_version
            nvm use $npm_version
        end
    end
end
