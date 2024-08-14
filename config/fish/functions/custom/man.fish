function man
    set tmp_file (mktemp)
    command man $argv | col -bx >$tmp_file
    bat $tmp_file
    rm $tmp_file
end
