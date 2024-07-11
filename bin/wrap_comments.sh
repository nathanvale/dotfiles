# /bin/bash

# Check if a file is provided
if [ -z "$1" ]; then
	echo "Usage: $0 <file>"
	exit 1
fi

# Extract directory and filename
file="$1"
dir=$(dirname "$file")
base=$(basename "$file")
formatted_file="$dir/formatted_$base"

# Use awk to wrap comments
awk '
  function wrap_line(line, width, prefix,    n, result) {
    n = split(line, words, " ")
    result = prefix words[1]
    for (i = 2; i <= n; i++) {
      if (length(result " " words[i]) > width) {
        print result
        result = prefix words[i]
      } else {
        result = result " " words[i]
      }
    }
    return result
  }

  BEGIN { width = 80 }

  # If the line is a comment, wrap it using wrap_line function
  /^#/ {
    comment = substr($0, 3)
    wrapped_comment = wrap_line(comment, width - 2, "# ")
    split(wrapped_comment, lines, "\n")
    for (line in lines) {
      print lines[line]
    }
    next
  }

  # If it is not a comment, print the line as is
  {
    print $0
  }
' "$file" >"$formatted_file"

# Replace original file with formatted file
mv "$formatted_file" "$file"
