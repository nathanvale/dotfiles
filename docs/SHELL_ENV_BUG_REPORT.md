# Diagnosis: why agent Bash calls misbehave in this dotfiles environment

**Scope:** shell-level defects in `.zshrc`, `.zprofile`, `.gitconfig`, and `bin/` that corrupt,
silently alter, or hang commands run through an agent's Bash tool (`ls`, `cat`, `rg`, `git`, `rm`, …).

**Method:** every finding below was reproduced in a real `zsh 5.9` shell, driven the way an agent
Bash tool drives it — rc/snapshot sourced as one parse unit, commands fed afterwards. Findings that
did **not** reproduce are listed under "Ruled out" rather than dropped.

---

## How the leak happens

`.zprofile:1-3` sources `.zshrc`:

```zsh
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi
```

`.zshrc` is the *interactive* rc. Sourcing it from `.zprofile` pulls the whole interactive
configuration — aliases, `setopt`s, `compinit`, ZLE widgets, the startup banner — into **login and
non-interactive** shells, which is what agent tooling runs. Verified: aliases defined in a sourced
rc *do* expand for later commands in a non-interactive zsh.

```
$ printf 'source rc\nls\n' | zsh -s
EZA-WOULD-RUN --color=always --icons     # alias applied in a NON-interactive shell
```

That single line is what turns everything below from "my prompt is quirky" into "the agent gets
wrong answers".

---

## Critical

### C1 — `git show/diff/reset HEAD^` silently operates on the wrong commit

`.zshrc:448-450`

```zsh
setopt EXTENDED_GLOB      # makes ^ a glob operator
setopt NULL_GLOB          # unmatched globs vanish instead of erroring
```

`EXTENDED_GLOB` makes `^` a pattern character, so `HEAD^` becomes a glob. It matches nothing, and
`NULL_GLOB` then **deletes the argument** instead of raising an error. Reproduced:

```
HEAD  = fd7009f (two)
HEAD^ = 749401d (one)

clean zsh:                    git show HEAD^ -> 749401d one     # correct
with these setopts:           git show HEAD^ -> fd7009f two     # WRONG, no error
```

There is no error message. Any session asked to "look at the previous commit" or "diff against
HEAD^" gets HEAD back and reports confidently on the wrong data.

Worse, with `set -x` to show the real argv:

```
$ git reset --soft HEAD^
+zsh:3> git reset --soft          # the ^ ref is gone: unstage-everything, not undo-last-commit
```

**Fix:** drop `NULL_GLOB` entirely (it is what converts an error into a wrong answer), and scope
`EXTENDED_GLOB` to interactive use only.

### C2 — `GLOB_DOTS` makes `rm -rf dir/*` delete `.git`

`.zshrc:450`

```zsh
setopt GLOB_DOTS          # Include dotfiles in globs
```

`*` now matches dotfiles. Reproduced on a throwaway repo:

```
before:            . .. .env .git .gitignore build
$ rm -rf ./*
after:             . ..                                  # .git, .env, .gitignore all destroyed
```

Standard cleanup commands (`rm -rf build/*`, `rm -rf dist/*`) become repo-destroying under this
option. **Fix:** remove `setopt GLOB_DOTS`.

### C3 — `NULL_GLOB` turns "no such file" into "here is everything"

`.zshrc:449`

```
default zsh:      $ ls *.doesnotexist   ->  zsh: no matches found: *.doesnotexist
with NULL_GLOB:   $ ls *.doesnotexist   ->  demo  g          # ran as bare `ls`
```

The agent asks "do any `.doesnotexist` files exist?", gets a directory listing back, and concludes
they do. **Fix:** same as C1 — remove `NULL_GLOB`.

### C4 — the current directory is injected into `PATH`

`.zshrc:65`

```zsh
export PATH="$(dirname "$(which node 2>/dev/null)"):$PATH" 2>/dev/null
```

When `node` is not on `PATH` yet, `which` prints nothing and `dirname ""` returns `.`. Reproduced:

```
which output:   []
dirname result: [.]
=> PATH becomes ".:$PATH"
```

Every command then resolves against the working directory first. A file named `ls`, `git`, or
`test` in any repo the agent `cd`s into gets executed instead of the real binary. This is both a
correctness bug and an arbitrary-code-execution path from untrusted repo contents.

**Fix:**

```zsh
_node_bin="$(command -v node 2>/dev/null)"
[[ -n "$_node_bin" ]] && export PATH="${_node_bin:h}:$PATH"
unset _node_bin
```

---

## High

### H1 — `CDPATH` silently relocates `cd` to a different tree

`.zshrc:44` — `export CDPATH=".:~:$HOME/code"`

Reproduced: from a directory with no `config/` subdirectory, `cd config` landed in
`~/code/config` and `ls` showed that tree's contents. The agent believes it is in the project's
`config/`; it is not. **Fix:** unset `CDPATH`, or guard it to interactive shells only.

### H2 — `ls` output carries forced ANSI and Nerd Font glyphs

`.zshrc:184-188`

```zsh
alias ls="eza --color=always --icons"
alias ll="eza -l --color=always --icons"
alias lla="eza -l -a --color=always --icons"
alias la="eza -a --color=always --icons"
alias lt="eza --tree --color=always --icons"
```

`--color=always` is the specific flag that defeats eza's own pipe detection, so escape sequences
land in output an agent parses, and `--icons` adds private-use-area glyphs. `eza` also does not
accept the full `ls` flag set (`ls -A` and `--time-style=` style invocations fail outright).

The repo's own aliases already trip over this — `.zshrc:327-329` pipe the colourised, icon-bearing
`ls` straight into `column`:

```zsh
alias .aero-scripts="ls -1 ~/code/dotfiles/bin/aerospace/ | column"
```

**Fix:** use `--color=auto`, drop `--icons` from the plain `ls` alias, and use `command ls` inside
alias bodies that pipe.

### H3 — interactive-only config loads in non-interactive shells

Consequence of `.zprofile` sourcing `.zshrc` (see above). Concretely:

- `.zshrc:552,578` — `terminal_reminder` prints the ADHD quick-reference banner (or a one-line
  version) to **stdout** at startup whenever `$TMUX` is empty. It prepends noise to captured output.
- `.zshrc:127` — `autoload -U compinit && compinit`. With group-writable completion directories,
  `compinit` prompts *"Ignore insecure directories and continue [y] or abort [n]?"* and reads from
  stdin. In a non-interactive shell that either consumes piped input or stalls. Use `compinit -i`.
- PATH entries at `.zshrc:4-24` are all `export PATH="…:$PATH"` with no dedupe, so the double-source
  doubles `PATH`.

**Fix:** put interactive-only setup behind `[[ -o interactive ]]`, and stop sourcing `.zshrc` from
`.zprofile`.

### H4 — git commands that open an editor block until timeout

`.gitconfig:44` — `editor = code --wait`

`git commit` without `-m`, `git commit --amend` without `--no-edit`, and `git tag -a` launch VS Code
and wait. In an agent session that is a hung call until the tool timeout; on any machine without the
`code` shim (Linux, remote container — confirmed absent here) git errors instead.

**Fix:** keep `code --wait` for humans but let `GIT_EDITOR` / `EDITOR` win, or set
`core.editor = ${GIT_EDITOR:-code --wait}` equivalent via `[core] editor` only in a machine-local
config.

### H5 — a git typo becomes an interactive prompt

`.gitconfig:66` — `autocorrect = prompt`

A mistyped subcommand asks *"Did you mean … ? [y/N]"* on the terminal rather than failing fast.
**Fix:** `autocorrect = 0` (or `immediate` if you want the convenience, though that has its own
risks for an agent).

---

## Medium

| # | Location | Problem |
|---|---|---|
| M1 | `.zshrc:62, 356, 359, 362, 580, 591` | `eval "$(fnm env …)"`, `source /opt/homebrew/share/zsh-syntax-highlighting…`, `…zsh-autosuggestions…`, `eval "$(atuin init zsh …)"`, `eval "$(pyenv init -)"`, `eval "$(direnv hook zsh)"` are all unguarded. On any machine missing them — Linux, or a Mac before `brew bundle` has run — each emits `command not found` / `no such file` on **every** shell start. Verified missing in this container: `eza, bat, gmv, delta, fnm, pyenv, direnv, zsh-syntax-highlighting`. Guard each with `command -v … >/dev/null &&` / `[[ -r … ]] &&`. |
| M2 | `.zshrc:62, 68` | `FNM_STRICT=true` combined with `fnm env --use-on-cd` makes **`cd` itself fail** when a project's `.nvmrc` pins a version that is not installed. |
| M3 | `.zshrc:168-175` | The `cd()` override runs `node -v` twice per `cd` and can print `🔄 Switched Node: …` to stdout, contaminating the output of `cd x && some-command`. |
| M4 | `bin/say` + `.zshrc:13` | `$HOME/code/dotfiles/bin` is prepended to `PATH`, so `bin/say` **shadows macOS `/usr/bin/say`** with an incompatible CLI (`say speak "text"`, not `say "text"`). It also runs `set -euo pipefail`, so the mismatch is a hard failure. |
| M5 | `.zshrc:224` | `alias mv="gmv"` depends on `brew install coreutils`. It is in the Brewfile, but the alias is loaded *before* `brew bundle` can run on a fresh machine, and it does not apply inside scripts — so `mv` behaves differently at the prompt than in any script. |
| M6 | `.gitconfig:63, 79` | `format.pretty = format:%C(auto)%h %d %s %C(black)%C(bold)%cr` and `log.date = relative` change the **default** `git log` output: no author, no absolute timestamp, plus embedded colour directives. An agent reading `git log` cannot recover real dates. |
| M7 | `.gitconfig:45` | `excludesfile = /Users/nathanvale/.gitignore_global` is a hardcoded macOS path. Silently inert on every other machine, including this one. Use `~/.gitignore_global`. |
| M8 | `.gitconfig:46` + `.zshrc:36, 223` | `core.pager = bat --paging=always --pager=less`, `PAGER="bat"`, `alias less="bat"`. `--paging=always` explicitly overrides bat's TTY detection. This does **not** hang an agent Bash tool (git skips the pager when stdout is a pipe — verified), but it does hang git run under a PTY, which is exactly how this repo's own `tx`/tmux workflow runs things. Prefer `--paging=auto`. |
| M9 | `.zshrc:549` | `alias help='show_quick_reference'` shadows the `help` builtin. |

---

## Ruled out

Tested and found **not** to be the problem — recording these so they are not re-investigated:

- **`setopt AUTO_CD` (`.zshrc:152`)** — does not apply to non-interactive command strings.
  `zsh -o autocd -c 'build'` correctly reports `command not found`, in a `zsh -c`, an rc-sourced
  script, and a stdin-fed shell alike. Interactive-only; harmless to agents.
- **The `cat()` override (`.zshrc:192-221`)** — it branches on `[[ -t 1 ]]` and correctly falls
  through to `command cat` whenever stdout is a pipe, which is the agent's path. Safe as written.
- **Pager hangs in the agent Bash tool** — git does not invoke a pager when stdout is not a TTY, so
  `core.pager` cannot hang it. (Still a real problem under a PTY: see M8.)
- **`rg`** — there is no `RIPGREP_CONFIG_PATH`, no `.ripgreprc`, and no `rg`/`grep` alias anywhere in
  the dotfiles. `rg` behaviour is unmodified. Reported `rg` oddities are almost certainly C2/C3
  glob damage to the *arguments*, not to `rg` itself.
- **`bin/` shadowing** — no script in `bin/`, `bin/tmux/`, `bin/env/`, `bin/utils/` shadows a system
  command on Linux. `bin/say` on macOS is the sole exception (M4).
- **`config/claude/`** — `CLAUDE.md` documents it but it does not exist in the tree. Explained: it is
  gitignored (`.gitignore`) as work-specific config. Documentation drift, not a bug.

---

## Recommended fix order

1. **C1–C3** — delete `setopt NULL_GLOB` and `setopt GLOB_DOTS`; move `EXTENDED_GLOB` behind an
   interactive guard. Three lines, and it removes both the silent-wrong-commit class and the
   `rm -rf` data-loss class.
2. **C4** — guard the `dirname $(which node)` PATH line. Removes `.` from `PATH`.
3. **H1** — drop `CDPATH` or make it interactive-only.
4. **H3** — stop sourcing `.zshrc` from `.zprofile`; split interactive setup behind
   `[[ -o interactive ]]`.
5. **H2, H4, H5** — `--color=auto`, editor override, `autocorrect = 0`.
6. **M1** — guard every `eval`/`source` of an optional tool.
