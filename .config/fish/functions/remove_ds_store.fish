function remove_ds_store
    set dir $argv[1]

    # Check if the directory exists
    if test -d $dir
        # Find and delete .DS_Store files within the directory
        find $dir -name ".DS_Store" -type f -delete

        # Recursively process subdirectories
        for subdir in $dir/*
            if test -d $subdir
                remove_ds_store $subdir
            end
        end
    end
end