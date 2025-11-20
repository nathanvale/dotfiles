# MD to PDF Converter

Convert markdown files to beautiful PDFs using the Eisvogel LaTeX template.

## Features

- ✅ Professional typography with Eisvogel template
- ✅ Clean formatting (no horizontal rules)
- ✅ Proper bullet points and lists
- ✅ Syntax highlighting for code blocks
- ✅ Blue clickable links
- ✅ UTF-8 character support
- ✅ One simple command: `md2pdf file.md`

## Installation

### 1. Install BasicTeX

BasicTeX provides the LaTeX engine needed for PDF generation:

```bash
brew install --cask basictex
```

After installation, update your PATH:

```bash
eval "$(/usr/libexec/path_helper)"
```

Or restart your terminal.

### 2. Install Required LaTeX Packages

These packages are needed by the Eisvogel template:

```bash
sudo tlmgr update --self
sudo tlmgr install adjustbox babel-german background bidi collectbox \
  csquotes everypage filehook footmisc footnotebackref framed fvextra \
  letltxmacro ly1 mdframed mweights needspace pagecolor sourcecodepro \
  sourcesanspro titling ucharcat unicode-math upquote xecjk xurl zref \
  draftwatermark soul
```

This takes a few minutes but you only need to do it once.

### 3. Install Eisvogel Template

The template is already included in your pandoc templates directory at:
`~/.pandoc/templates/eisvogel.latex`

If you need to reinstall it:

```bash
# Download latest release
cd /tmp
curl -L https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/v3.2.1/Eisvogel-3.2.1.zip -o eisvogel.zip
unzip eisvogel.zip

# Install template
mkdir -p ~/.pandoc/templates
cp Eisvogel-3.2.1/eisvogel.latex ~/.pandoc/templates/
```

### 4. Install the md2pdf Script

Copy the script to your PATH:

```bash
cp ~/code/dotfiles/scripts/md2pdf/md2pdf ~/code/dotfiles/bin/md2pdf
chmod +x ~/code/dotfiles/bin/md2pdf
```

Make sure `~/code/dotfiles/bin` is in your PATH.

## Usage

### Basic Usage

Convert a markdown file to PDF:

```bash
md2pdf your-file.md
```

This creates `your-file.pdf` in the same directory.

### Custom Output Name

Specify a custom output filename:

```bash
md2pdf input.md custom-output.pdf
```

### Example

```bash
md2pdf "00_Inbox/Tasmania_Hiking_Boots_Research-HUMAN.md"
```

Creates: `00_Inbox/Tasmania_Hiking_Boots_Research-HUMAN.pdf`

## What Gets Formatted

The script handles all standard markdown:

- **Headings** (H1, H2, H3, etc.)
- **Bold** and _italic_ text
- Bullet lists
- Numbered lists
- Block quotes
- Code blocks with syntax highlighting
- Links (rendered in blue)
- Images
- Tables

### Automatic Adjustments

The script automatically:

- Removes horizontal rules (`---`) which render as lines in PDF
- Preserves proper line breaks in lists
- Uses clean typography defaults

## Configuration

The script uses these pandoc settings:

- **Template**: Eisvogel
- **Syntax highlighting**: Idiomatic style
- **Link color**: Blue
- **Paper size**: A4
- **Margins**: 2.5cm
- **Line breaks**: Preserved in lists

To customize, edit the script at: `~/code/dotfiles/scripts/md2pdf/md2pdf`

## Troubleshooting

### "pdflatex not found"

Make sure BasicTeX is installed and in your PATH:

```bash
which pdflatex
# Should return: /Library/TeX/texbin/pdflatex
```

If not found, run:

```bash
eval "$(/usr/libexec/path_helper)"
```

Or restart your terminal.

### "File 'X.sty' not found"

You're missing a LaTeX package. Install it with:

```bash
sudo tlmgr install package-name
```

Common missing packages:

- `sourcecodepro`
- `sourcesanspro`
- `footnotebackref`

Or install all required packages using the command in step 2 above.

### Lists Not Formatting Correctly

Make sure your markdown uses proper list syntax:

```markdown
- Item 1
- Item 2
- Item 3
```

Not:

```markdown
- Item 1
- Item 2
- Item 3
```

Each list item should be on its own line with no extra blank lines between items.

### Horizontal Lines Appearing

The script automatically removes markdown horizontal rules (`---`). If you see lines in your PDF,
check if you have other line characters in your source.

## Dependencies

### Software

- **Homebrew** (for installing BasicTeX)
- **BasicTeX** (LaTeX distribution, ~100MB)
- **pandoc** (document converter, likely already installed)

### LaTeX Packages

All required packages are listed in installation step 2.

### Template

- **Eisvogel v3.2.1** (pandoc LaTeX template)
- Source: https://github.com/Wandmalfarbe/pandoc-latex-template

## Why This Solution?

After trying various clipboard/RTF approaches (which had character encoding and line spacing
issues), we built this PDF solution because:

1. **Reliable** - No clipboard formatting quirks
2. **Professional** - Proper typography from Eisvogel template
3. **Portable** - PDFs work everywhere
4. **Simple** - One command to convert
5. **Customizable** - Easy to adjust settings

The Eisvogel template is used by thousands of developers and academics for professional documents
(6.8k GitHub stars).

## Credits

- **Eisvogel Template**:
  [Wandmalfarbe/pandoc-latex-template](https://github.com/Wandmalfarbe/pandoc-latex-template)
- **Pandoc**: [pandoc.org](https://pandoc.org/)
- **BasicTeX**: [tug.org/mactex](https://www.tug.org/mactex/)

## License

The md2pdf script is part of nathanvale/dotfiles.

The Eisvogel template is licensed under BSD-3-Clause.

---

**Created**: 2025-10-12 **Last Updated**: 2025-10-12 **Version**: 1.0.0
