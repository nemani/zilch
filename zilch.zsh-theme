# vim:ft=zsh ts=2 sw=2 sts=2
#
# Zilch
# A Powerline-inspired theme for ZSH, evolved from Agnoster
#
# Requires a Powerline-patched font: https://github.com/powerline/fonts
# Or a Nerd Font: https://www.nerdfonts.com/

# --- Configuration ---
# Override these in your .zshrc BEFORE sourcing the theme:
#   ZILCH_SOLARIZED=dark|light      (default: dark)
#   ZILCH_SHOW_AWS=true|false        (default: true)
#   ZILCH_SHOW_KUBECONTEXT=true|false (default: false)
#   ZILCH_SHOW_NODE=true|false       (default: false)
#   ZILCH_SHOW_DOCKER=true|false     (default: false)
#   ZILCH_CMD_MAX_EXEC_TIME=5        (seconds, default: 5)
#   DEFAULT_USER                     (suppress user@host when matching)

ZILCH_CURRENT_BG='NONE'

case ${ZILCH_SOLARIZED:-${SOLARIZED_THEME:-dark}} in
  light) ZILCH_CURRENT_FG='white' ;;
  *)     ZILCH_CURRENT_FG='black' ;;
esac

# --- Powerline Glyphs ---
# Do not change these code points. See Powerline code point history.
() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  ZILCH_SEPARATOR=$'\ue0b0'
  ZILCH_BRANCH=$'\ue0a0'
}

# --- Core Rendering ---

# Begin a segment. Args: $1=background, $2=foreground, $3=content
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $ZILCH_CURRENT_BG != 'NONE' && $1 != $ZILCH_CURRENT_BG ]]; then
    print -n " %{$bg%F{$ZILCH_CURRENT_BG}%}$ZILCH_SEPARATOR%{$fg%} "
  else
    print -n "%{$bg%}%{$fg%} "
  fi
  ZILCH_CURRENT_BG=$1
  [[ -n $3 ]] && print -n "$3"
}

prompt_end() {
  if [[ -n $ZILCH_CURRENT_BG ]]; then
    print -n " %{%k%F{$ZILCH_CURRENT_BG}%}$ZILCH_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  ZILCH_CURRENT_BG=''
}

# --- Segments ---

# Status: error code, root, background jobs
prompt_status() {
  local -a symbols
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"
  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

# Python virtualenv
prompt_virtualenv() {
  if [[ -n "$VIRTUAL_ENV" && -n "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
    prompt_segment blue black "(${VIRTUAL_ENV:t:gs/%/%%})"
  fi
}

# AWS profile with production safety highlight
prompt_aws() {
  [[ "${ZILCH_SHOW_AWS:-${SHOW_AWS_PROMPT:-true}}" = false ]] && return
  [[ -z "$AWS_PROFILE" ]] && return
  case "$AWS_PROFILE" in
    *-prod|*production*) prompt_segment red yellow "AWS: ${AWS_PROFILE:gs/%/%%}" ;;
    *) prompt_segment green black "AWS: ${AWS_PROFILE:gs/%/%%}" ;;
  esac
}

# Kubernetes context
prompt_kubecontext() {
  [[ "${ZILCH_SHOW_KUBECONTEXT:-false}" = true ]] || return
  (( $+commands[kubectl] )) || return
  local ctx
  ctx=$(kubectl config current-context 2>/dev/null) || return
  [[ -z "$ctx" ]] && return
  case "$ctx" in
    *prod*) prompt_segment red yellow "⎈ ${ctx:gs/%/%%}" ;;
    *)      prompt_segment cyan black "⎈ ${ctx:gs/%/%%}" ;;
  esac
}

# Docker context (non-default only)
prompt_docker() {
  [[ "${ZILCH_SHOW_DOCKER:-false}" = true ]] || return
  (( $+commands[docker] )) || return
  local ctx="${DOCKER_CONTEXT:-$(docker context show 2>/dev/null)}"
  [[ -z "$ctx" || "$ctx" = "default" ]] && return
  prompt_segment magenta white "🐳 ${ctx:gs/%/%%}"
}

# Node.js version (only inside projects with package.json)
prompt_node() {
  [[ "${ZILCH_SHOW_NODE:-false}" = true ]] || return
  [[ -f package.json || -f .nvmrc || -f .node-version ]] || return
  local node_version=""
  if (( $+commands[node] )); then
    node_version=$(node -v 2>/dev/null)
  fi
  [[ -z "$node_version" ]] && return
  prompt_segment green white "⬢ ${node_version:gs/%/%%}"
}

# Context: user@hostname
prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)${USER:0:1}@${HOST}"
  fi
}

# Directory: truncated path using pure ZSH (no subshells)
prompt_dir() {
  local current_path="${PWD/#$HOME/~}"
  if [[ "$current_path" = "~" ]]; then
    prompt_segment blue $ZILCH_CURRENT_FG "$current_path"
    return
  fi
  # Truncate each parent component to its first character
  local parts=("${(@s:/:)current_path}")
  local short_path=""
  local i
  for (( i=1; i < $#parts; i++ )); do
    if [[ -n "${parts[$i]}" ]]; then
      short_path+="${parts[$i][1]}/"
    else
      short_path+="/"
    fi
  done
  short_path+="${parts[-1]}"
  # Preserve leading ~ or /
  if [[ "$current_path" = ~* ]]; then
    short_path="~/${short_path#\~/}"
  elif [[ "$current_path" = /* ]]; then
    short_path="/${short_path}"
  fi
  prompt_segment blue $ZILCH_CURRENT_FG "$short_path"
}

# Git: branch, dirty status, ahead/behind, stash count
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi

  [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]] || return

  local repo_path ref dirty mode info=""
  repo_path=$(git rev-parse --git-dir 2>/dev/null)
  dirty=$(parse_git_dirty)
  ref=$(git symbolic-ref HEAD 2>/dev/null) || ref="➦ $(git rev-parse --short HEAD 2>/dev/null)"

  if [[ "$dirty" = "*" ]]; then
    prompt_segment yellow black
  else
    prompt_segment green $ZILCH_CURRENT_FG
  fi

  # Detect special git states
  if [[ -e "${repo_path}/BISECT_LOG" ]]; then
    mode=" <B>"
  elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
    mode=" >M<"
  elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" ]]; then
    mode=" >R>"
  fi

  setopt promptsubst
  autoload -Uz vcs_info
  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' get-revision true
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr '✚'
  zstyle ':vcs_info:*' unstagedstr '±'
  zstyle ':vcs_info:*' formats ' %u%c'
  zstyle ':vcs_info:*' actionformats ' %u%c'
  vcs_info

  info="${${ref:gs/%/%%}/refs\/heads\//$ZILCH_BRANCH }${vcs_info_msg_0_%% }${mode}"

  # Ahead/behind upstream
  local ahead behind
  ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
  behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
  [[ "$ahead" -gt 0 ]] 2>/dev/null && info+=" ↑${ahead}"
  [[ "$behind" -gt 0 ]] 2>/dev/null && info+=" ↓${behind}"

  # Stash count
  local stash_count
  stash_count=$(git stash list 2>/dev/null | wc -l)
  [[ "$stash_count" -gt 0 ]] 2>/dev/null && info+=" ≡${stash_count}"

  print -n "$info"
}

# Mercurial
prompt_hg() {
  (( $+commands[hg] )) || return
  local rev st branch
  hg id >/dev/null 2>&1 || return

  if hg prompt >/dev/null 2>&1; then
    if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
      prompt_segment red white
      st='±'
    elif [[ -n $(hg prompt "{status|modified}") ]]; then
      prompt_segment yellow black
      st='±'
    else
      prompt_segment green $ZILCH_CURRENT_FG
    fi
    print -n "${$(hg prompt "☿ {rev}@{branch}"):gs/%/%%} $st"
  else
    st=""
    rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
    branch=$(hg id -b 2>/dev/null)
    if hg st | grep -q "^\?"; then
      prompt_segment red black
      st='±'
    elif hg st | grep -q "^[MA]"; then
      prompt_segment yellow black
      st='±'
    else
      prompt_segment green $ZILCH_CURRENT_FG
    fi
    print -n "☿ ${rev:gs/%/%%}@${branch:gs/%/%%} $st"
  fi
}

# --- Execution Time (RPROMPT) ---

_zilch_preexec() {
  _zilch_cmd_start=$EPOCHSECONDS
}

_zilch_precmd() {
  local stop=$EPOCHSECONDS
  local start=${_zilch_cmd_start:-$stop}
  (( _zilch_cmd_duration = stop - start ))
  unset _zilch_cmd_start
}

prompt_exec_time() {
  local max_time=${ZILCH_CMD_MAX_EXEC_TIME:-5}
  (( _zilch_cmd_duration >= max_time )) || return
  local d=$_zilch_cmd_duration
  local human=""
  if (( d >= 3600 )); then
    human+="$((d / 3600))h "
    (( d %= 3600 ))
  fi
  if (( d >= 60 )); then
    human+="$((d / 60))m "
    (( d %= 60 ))
  fi
  human+="${d}s"
  print -n "%F{yellow}${human}%f"
}

# --- Segment Registry ---

typeset -ag ZILCH_PROMPT_SEGMENTS=(
  prompt_status
  prompt_virtualenv
  prompt_aws
  prompt_kubecontext
  prompt_docker
  prompt_node
  prompt_context
  prompt_dir
  prompt_git
  prompt_hg
  prompt_end
)

# --- Main ---

build_prompt() {
  RETVAL=$?
  ZILCH_CURRENT_BG='NONE'
  local seg
  for seg in "${ZILCH_PROMPT_SEGMENTS[@]}"; do
    [[ -n $seg ]] && $seg
  done
}

# Hook into preexec/precmd for execution timing
autoload -Uz add-zsh-hook
add-zsh-hook preexec _zilch_preexec
add-zsh-hook precmd _zilch_precmd

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='$(prompt_exec_time)'
