if status is-interactive
    source ~/.config/fish/env_vars.fish
    source ~/.config/fish/aliases.fish

    # Load nvm using bass
    bass source (brew --prefix nvm)/nvm.sh --no-use

    # Source the iterm2 shell integration if it exists
    test -e {$HOME}/.iterm2_shell_integration.fish; and source {$HOME}/.iterm2_shell_integration.fish

    # Set the bat theme to Night Owl if it is not already set
    set themes_output (bat --list-themes)
    if not string match -q "*Night Owl*" $themes_output
        echo "Installing Night Owl theme"
        bat cache --build
    end

    # Bindings for fzf
    fzf_configure_bindings --directory=\cf --processes=\cp --variables=\cv --git_status=\cS --git_log=\cl



end
