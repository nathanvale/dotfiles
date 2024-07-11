function github_create_pr_and_merge

    set -l branch_name (__git.current_branch)
    set -l base_branch (__git.default_branch)

    # Check if the base branch is the same as the current branch
    if test $base_branch = $branch_name
        echo "The current branch is the same as the $base_branch branch. No PR will be created."
        return
    end

    # Check commit differences
    set -l commit_diff (git rev-list --count $base_branch..$branch_name)
    if test $commit_diff -eq 0
        echo "The current branch has no commits compared to the $base_branch. No PR will be created."
        return
    else if test $commit_diff -gt 1
        echo "Current branch has $commit_diff more commits than the base branch. This will create a PR with $commit_diff commits and merge them all into $base_branch."
        read -l continue -P "Do you want to continue? (y/N):"
        if test -z $continue
            set continue N
        end
        set continue (string lower $continue)
        if test $continue != y
            return
        end
    end

    git push origin $branch_name
    set -l pull_request_url (gh pr create --base $base_branch --head $branch_name -f)
    gh pr merge $pull_request_url --merge -d
end
