if status is-interactive
    source ~/.config/fish/env_vars.fish
    source ~/.config/fish/aliases.fish

    set target_dir {$HOME}/code/dotfiles

    if not test -d $target_dir/.git
        # Initialize a Git repository in the target directory
        git init $target_dir
    end

    # Check if the universal variable for Tide configuration is set
    if not set -Uq tide_configured
        tide configure --auto --style=Lean --prompt_colors='True color' --show_time='12-hour format' --lean_prompt_height='One line' --prompt_spacing=Compact --icons='Many icons' --transient=Yes
        set -U tide_configured yes
        exec fish
    end


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

    # Source work configuration if using my work laptop
    if test (hostname) = ORG101475
        source ~/.config/fish/work_laptop.fish
    end

end
