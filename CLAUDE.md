# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zilch is a ZSH terminal prompt theme evolved from Agnoster/Powerline. It is a single-file project (`zilch.zsh-theme`) with no build system, tests, or dependencies beyond ZSH and Powerline-patched fonts (or Nerd Fonts).

**License**: GPLv3

## Architecture

The theme file (`zilch.zsh-theme`) follows a segment-based architecture:

- **`prompt_segment(bg, fg, content)`** — Core rendering function that draws a styled Powerline segment with arrow separators
- **`prompt_end()`** — Closes the final segment
- **Segment functions** — Each `prompt_*` function renders one piece of info and calls `prompt_segment` internally. Segments self-hide when they have nothing to show.
- **`ZILCH_PROMPT_SEGMENTS`** array — Controls which segments appear and in what order; this is the main customization point. Users can override this in `.zshrc`.
- **`build_prompt()`** — Iterates over `ZILCH_PROMPT_SEGMENTS` and calls each segment function
- **`PROMPT` / `RPROMPT`** — Left prompt shows segments; right prompt shows command execution time

### Configuration

All config is via `ZILCH_*` environment variables set before sourcing the theme:
- `ZILCH_SOLARIZED` (dark/light), `ZILCH_SHOW_AWS`, `ZILCH_SHOW_KUBECONTEXT`, `ZILCH_SHOW_NODE`, `ZILCH_SHOW_DOCKER`, `ZILCH_CMD_MAX_EXEC_TIME`

### Key design choices

- `prompt_dir()` truncates parent directories to first character using pure ZSH (no subshells)
- `prompt_context()` truncates username to first character
- Git segment shows ahead/behind counts (↑↓) and stash count (≡)
- `print -n` used throughout instead of `echo -n` for ZSH correctness
- Execution timing uses `preexec`/`precmd` hooks via `add-zsh-hook`

## Working with the Code

There are no build, lint, or test commands. To test changes, source the theme in a ZSH shell:

```zsh
source zilch.zsh-theme
```

The segment separator uses Unicode code point `\ue0b0` (Powerline arrow). Do not change this character.
