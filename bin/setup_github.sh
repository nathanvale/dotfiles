#!/bin/bash

mkdir -p ~/.ssh
rm -f ~/.ssh/{config,id_rsa,id_rsa.pub}
ssh-keygen -t rsa -N "" -C "hi@nathanvale.com" -f ~/.ssh/id_rsa
echo -e "Host *\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile ~/.ssh/id_rsa" | tee ~/.ssh/config
eval "$(ssh-agent -s)"
echo "Run 'pbcopy < ~/.ssh/id_rsa.pub' and paste that into GitHub"
