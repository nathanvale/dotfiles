function switch_to_zsh
    if type -q zsh
        # Change the default shell to Fish
        sudo chsh -s $(which zsh) $(whoami)
        exec zsh
    else
        echo "zsh shell is not installed. Please install zsh first."
    end
end
