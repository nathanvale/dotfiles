
function killport
  lsof -i tcp:"$argv" | awk 'NR!=1 {print $2}' | xargs kill -9 ;
end