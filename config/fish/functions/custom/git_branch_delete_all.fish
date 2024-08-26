function git_branch_delete_all

    git fetch --all --prune

    if test (count $argv) -ne 1
        echo "Usage: git_delete_branch <branch_name>"
        return 1
    end

    set branch_name $argv[1]

    # Delete local branch
    git branch -D $branch_name >/dev/null 2>&1
    if test $status -eq 0
        echo "Local branch $branch_name deleted"
    else
        echo "Local branch $branch_name not found or could not be deleted"
    end

    # Delete remote branch
    git push origin --delete $branch_name >/dev/null 2>&1
    if test $status -eq 0
        echo "Remote branch $branch_name deleted"
    else
        echo "Remote branch $branch_name not found or could not be deleted"
    end

end
