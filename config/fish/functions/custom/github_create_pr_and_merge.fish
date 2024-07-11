function github_create_pr_and_merge
    set -l branch_name (__git.current_branch)
    if test -z $branch_name
        echo "No git branch found to create a pr with!"
        return
    end
    set -l base_branch (__git.default_branch)

    # Check if the base branch is the same as the current branch
    if test $base_branch = $branch_name
        echo "The current branch is the same as the $base_branch branch. No PR will be created."
        return
    end

    # if curent branch has more than one commit compared to the base branch then prompt if user wants to continue
    set -l commit_diff (git rev-list --count $base_branch..$branch_name)
    if test $commit_diff -eq 0
        echo "The current branch has no commits compared to the $base_branch. No PR will be created."
        return
    else if test $commit_diff -gt 1
        echo "Current branch has $commit_diff more commits than the base branch. This will create a PR with $commit_diff commits and merge them all into $base_branch."
        read -l continue -P "Do you want to continue? (y/N):"
        # Check if the input is empty and assign a default value
        if test -z $continue
            set continue N # Default value
        end
        set continue (string lower $continue)
        echo $continue
        if test $continue != y
            return
        end
    end
    git push origin $branch_name
    set -l pull_request_url (gh pr create --base $base_branch --head $branch_name -f)
    gh pr merge $pull_request_url --merge -d
end
