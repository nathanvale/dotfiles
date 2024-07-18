function switch_to_zsh
    if type -q zsh
        exec zsh
    else
        echo "zsh shell is not installed. Please install zsh first."
    end
end
