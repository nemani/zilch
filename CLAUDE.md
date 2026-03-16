# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zilch is a ZSH terminal prompt theme based on Agnoster and Powerline. It is a single-file project (`zilch.zsh-theme`) with no build system, tests, or dependencies beyond ZSH and Powerline-patched fonts.

**License**: GPLv3

## Architecture

The theme file (`zilch.zsh-theme`) follows a segment-based architecture:

- **`prompt_segment(bg, fg, content)`** — Core rendering function that draws a styled Powerline segment with arrow separators
- **`prompt_end()`** — Closes the final segment
- **Segment functions** — Each `prompt_*` function renders one piece of info (git status, directory, AWS profile, etc.) and calls `prompt_segment` internally
- **`AGNOSTER_PROMPT_SEGMENTS`** array (line ~235) — Controls which segments appear and in what order; this is the main customization point
- **`build_prompt()`** — Iterates over `AGNOSTER_PROMPT_SEGMENTS` and calls each segment function
- **`PROMPT`** — ZSH reads this variable to render the prompt

### Key differences from upstream Agnoster

- `prompt_dir()` truncates parent directories to first character (e.g., `~/p/s/myproject`)
- `prompt_context()` truncates username to first character (`n@hostname`)
- Git dirty status colors are fixed (yellow=dirty, green=clean)
- Supports Solarized light/dark via `SOLARIZED_THEME` env var

## Working with the Code

There are no build, lint, or test commands. To test changes, source the theme in a ZSH shell:

```zsh
source zilch.zsh-theme
```

The segment separator uses Unicode code point `\ue0b0` (Powerline arrow). Do not change this character — see the comment block at lines 22-31 for history.
