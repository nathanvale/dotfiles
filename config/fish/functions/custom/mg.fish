
## make a directory and cd into it
function mg
  mkdir "$argv" && cd "$argv" || exit;
end