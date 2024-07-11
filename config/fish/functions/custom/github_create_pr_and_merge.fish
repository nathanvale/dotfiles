function github_create_pr_and_merge
    set -l branch_name (__git.current_branch)
    if test -z $branch_name
        echo "No git branch found to create a pr with!"
        return
    end
    set -l base_branch (__git.default_branch)
    git push origin $branch_name
    set -l pull_request_url (gh pr create --base $base_branch --head $branch_name -f)
    gh pr merge $pull_request_url --merge -d
end
