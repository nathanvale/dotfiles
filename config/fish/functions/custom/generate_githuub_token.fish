# echo "Generating an RSA token for GitHub"
# mkdir -p ~/.ssh
# rm -f ~/.ssh/{config,id_rsa,id_rsa.pub}
# ssh-keygen -t rsa -N "" -C "hi@nathanvale.com" -f ~/.ssh/id_rsa
# echo "Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile ~/.ssh/id_rsa" | tee ~/.ssh/config
# eval "$(ssh-agent -s)"
# echo "run 'pbcopy < ~/.ssh/id_rsa.pub' and paste that into GitHub"
# Generate GitHub RSA token
function generate_github_token
    echo "Generating an RSA token for GitHub"
    mkdir -p ~/.ssh
    rm -f ~/.ssh/config ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
    ssh-keygen -t rsa -N "" -C "hi@nathanvale.com" -f ~/.ssh/id_rsa
    echo "Host *\n    AddKeysToAgent yes\n    UseKeychain yes\n    IdentityFile ~/.ssh/id_rsa" | tee ~/.ssh/config
    eval (ssh-agent -c)
    echo "run 'pbcopy < ~/.ssh/id_rsa.pub' and paste that into GitHub"
end
