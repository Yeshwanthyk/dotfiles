###############################################################################
# FUNCTIONS
###############################################################################
# Source a file if it exists and is readable.
source_if_exists() {
  if [[ -r "$1" ]]; then
    source "$1"
  fi
}


if [ -f ~/.env ]; then
    source ~/.env
fi

###############################################################################
# EXTERNAL SCRIPTS & TOOLS
###############################################################################
# fzf configuration (if available)
source_if_exists ~/.fzf.zsh

# Direnv integration (if installed)
if type "direnv" > /dev/null; then
  eval "$(direnv hook zsh)"
fi

# Homebrew integration (macOS)
eval "$(/opt/homebrew/bin/brew shellenv)"

###############################################################################
# COMPLETION SYSTEM
###############################################################################
# Set the fpath for custom completions
fpath=(~/.zsh/completions $fpath)

# Load necessary functions
autoload -U zmv
autoload -U promptinit && promptinit
autoload -U colors && colors

# Add Homebrew zsh completions if brew exists
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

# Initialize zsh completions with caching (-C) and ignore insecure directories (-i)
autoload -Uz compinit && compinit -i -C

###############################################################################
# ENVIRONMENT VARIABLES
###############################################################################
# User-specific variables
USER_HOME="/Users/yesh"

export VISUAL=nvim
export EDITOR=nvim
export GOBIN="$HOME/go/bin"

# Consolidated PATH (order matters)
export PATH="/opt/homebrew/bin:/usr/local/bin:$USER_HOME/.cargo/bin:$USER_HOME/.local/share/bob/nvim-bin:$USER_HOME/.bun/bin:$HOME/commands:$GOBIN:$PATH"

###############################################################################
# STARSHIP PROMPT
###############################################################################
eval "$(starship init zsh)"

###############################################################################
# ALIASES
###############################################################################
## Tmux
alias ta='tmux attach -t'
alias tzer='bash ~/.tmux/scripts/tmux-sessionizer.sh'

## File and directory listings using eza
alias l='eza -lah --git --all'
alias ll='eza -lh --git'
alias ls='eza'
alias sl='eza'
alias lt='eza -lh --git --all --tree'

function git-file-history() {
  # Step 1: Select a file
  local file=$(git ls-files | fzf --preview 'bat --color=always {} 2>/dev/null || cat {}')
  
  # Step 2: If a file was selected, show its history with delta
  if [[ -n "$file" ]]; then
    echo "Showing history for: $file"
    git log --oneline --follow -- "$file" | fzf --preview "git show {1} -- $file | delta"
  fi
}

## Common commands
alias c='clear'
alias ccc='claude --dangerously-skip-permissions'
alias rm='rm -I'
alias s='source ~/.zshrc'

## Directory navigation shortcuts
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

## HTTP & Notes
alias http="xh"
alias nn="cd ~/notes && ./notes.sh"

###############################################################################
# FZF-BASED NAVIGATION HELPERS
###############################################################################
# Fuzzy change directory (ignores hidden directories)
fcd() { 
  local dir=$(find . -type d -not -path '*/.*' 2>/dev/null | fzf)
  [[ -n "$dir" ]] && cd "$dir" && l
}

# Fuzzy file search and copy filename to clipboard
f() { 
  local file=$(find . -type f -not -path '*/.*' 2>/dev/null | fzf)
  [[ -n "$file" ]] && echo "$file" | pbcopy
}

# Fuzzy file search and open file in nvim
fv() { 
  local file=$(find . -type f -not -path '*/.*' 2>/dev/null | fzf --preview 'bat --color=always {} 2>/dev/null || cat {} 2>/dev/null')
  [[ -n "$file" ]] && nvim "$file"
}

###############################################################################
# GIT ALIASES & FUNCTIONS
###############################################################################
alias gc='git commit -m'
alias ga='git add .'
alias gst='git status'
alias gb='git branch'
alias gba='git branch --all'
alias gcp='git cherry-pick'
alias gp='git push'
alias ff='gpr && git pull --ff-only'
alias grd='git fetch origin && git rebase origin/master'
alias gl='pretty_git_log'
alias gla='pretty_git_log_all'
alias gg='git branch | fzf | xargs git checkout'
alias gup='git branch --set-upstream-to=origin/$(git-current-branch) $(git-current-branch)'
alias lg='lazygit'
alias kvim="NVIM_APPNAME=kvim nvim"

# Git log and branch functions
show_git_head() {
  pretty_git_log -1
  git show -p --pretty="tformat:"
}

pretty_git_log() {
  git log --since="6 months ago" --graph --pretty="tformat:${LOG_FORMAT}" "$@" | pretty_git_format | git_page_maybe
}

pretty_git_log_all() {
  git log --all --since="6 months ago" --graph --pretty="tformat:${LOG_FORMAT}" "$@" | pretty_git_format | git_page_maybe
}

pretty_git_branch() {
  git branch -v --color=always --format="${BRANCH_FORMAT}" "$@" | pretty_git_format
}

pretty_git_branch_sorted() {
  git branch -v --color=always --format="${BRANCH_FORMAT}" --sort=-committerdate "$@" | pretty_git_format
}

###############################################################################
# DOCKER COMMANDS & ALIASES
###############################################################################
alias dc='docker-compose'
alias dkill="pgrep 'Docker' | xargs kill -9"
alias docker-clear='dclear'

dclear() {
  docker ps -a -q | xargs docker kill -f
  docker ps -a -q | xargs docker rm -f
  docker images | grep "api\|none" | awk '{print $3}' | xargs docker rmi -f
  docker volume prune -f
}

dreset() {
  dclear
  docker images -q | xargs docker rmi -f
  docker volume rm $(docker volume ls | awk '{print $2}')
  rm -rf ~/Library/Containers/com.docker.docker/Data/*
  docker system prune -a
}

alias unmount_all_and_exit='unmount_all && exit'

###############################################################################
# FZF & COMPLETION CONFIGURATION
###############################################################################
# Enable tab completion options
setopt hash_list_all
bindkey '^i' expand-or-complete-prefix

# Set ripgrep as the default command for fzf
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# earl grey theme
export FZF_DEFAULT_OPTS='--color=fg:#605A52,bg:#ffffff,hl:#83577D --color=fg+:#605A52,bg+:#CBD2E1,hl+:#83577D --color=info:#747B4D,prompt:#747B4D,pointer:#83577D --color=marker:#83577D,spinner:#747B4D,header:#9C958B'

###############################################################################
# ZOXIDE (DIRECTORY JUMPING)
###############################################################################
eval "$(zoxide init zsh)"

###############################################################################
# HISTORY CONFIGURATION
###############################################################################
function omz_history {
  local clear list
  zparseopts -E c=clear l=list

  if [[ -n "$clear" ]]; then
    echo -n >| "$HISTFILE"
    echo >&2 "History file deleted. Reload the session to see its effects."
  elif [[ -n "$list" ]]; then
    builtin fc "$@"
  else
    [[ ${@[-1]-} = *[0-9]* ]] && builtin fc -l "$@" || builtin fc -l "$@" 1
  fi
}

case ${HIST_STAMPS-} in
  "mm/dd/yyyy") alias history='omz_history -f' ;;
  "dd.mm.yyyy") alias history='omz_history -E' ;;
  "yyyy-mm-dd") alias history='omz_history -i' ;;
  "") alias history='omz_history' ;;
  *) alias history="omz_history -t '$HIST_STAMPS'" ;;
esac

[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=100000

setopt extended_history       # record timestamps in history
setopt hist_expire_dups_first  # expire duplicates first when history exceeds limit
setopt hist_ignore_dups        # ignore duplicate commands
setopt hist_ignore_space       # ignore commands starting with a space
setopt hist_verify             # verify history expansion before execution
setopt inc_append_history      # append commands to history immediately
setopt share_history           # share history between sessions

###############################################################################
# LF FILE MANAGER ICONS
###############################################################################
export LF_ICONS="tw=:st=:ow=:dt=:di=:fi=:ln=:or=:ex=:*.c=:*.cc=:*.clj=:*.coffee=:*.cpp=:*.css=:*.d=:*.dart=:*.erl=:*.exs=:*.fs=:*.go=:*.h=:*.hh=:*.hpp=:*.hs=:*.html=:*.java=:*.jl=:*.js=:*.json=:*.lua=:*.md=:*.php=:*.pl=:*.pro=:*.py=:*.rb=:*.rs=:*.scala=:*.ts=:*.vim=:*.cmd=:*.ps1=:*.sh=:*.bash=:*.zsh=:*.fish=:*.tar=:*.tgz=:*.arc=:*.arj=:*.taz=:*.lha=:*.lz4=:*.lzh=:*.lzma=:*.tlz=:*.txz=:*.tzo=:*.t7z=:*.zip=:*.z=:*.dz=:*.gz=:*.lrz=:*.lz=:*.lzo=:*.xz=:*.zst=:*.tzst=:*.bz2=:*.bz=:*.tbz=:*.tbz2=:*.tz=:*.deb=:*.rpm=:*.jar=:*.war=:*.ear=:*.sar=:*.rar=:*.alz=:*.ace=:*.zoo=:*.cpio=:*.7z=:*.rz=:*.cab=:*.wim=:*.swm=:*.dwm=:*.esd=:*.jpg=:*.jpeg=:*.mjpg=:*.mjpeg=:*.gif=:*.bmp=:*.pbm=:*.pgm=:*.ppm=:*.tga=:*.xbm=:*.xpm=:*.tif=:*.tiff=:*.png=:*.svg=:*.svgz=:*.mng=:*.pcx=:*.mov=:*.mpg=:*.mpeg=:*.m2v=:*.mkv=:*.webm=:*.ogm=:*.mp4=:*.m4v=:*.mp4v=:*.vob=:*.qt=:*.nuv=:*.wmv=:*.asf=:*.rm=:*.rmvb=:*.flc=:*.avi=:*.fli=:*.flv=:*.gl=:*.dl=:*.xcf=:*.xwd=:*.yuv=:*.cgm=:*.emf=:*.ogv=:*.ogx=:*.aac=:*.au=:*.flac=:*.m4a=:*.mid=:*.midi=:*.mka=:*.mp3=:*.mpc=:*.ogg=:*.ra=:*.wav=:*.oga=:*.opus=:*.spx=:*.xspf=:*.pdf=:*.nix=:"

###############################################################################
# PLUGIN SOURCING
###############################################################################
# Zsh Syntax Highlighting
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Zsh Autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# FZF Tab Plugin
source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

###############################################################################
# NODE VERSION MANAGER (NVM)
###############################################################################
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

###############################################################################
# PYTHON ENVIRONMENTS (pyenv)
###############################################################################
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

###############################################################################
# ADDITIONAL BINARIES (e.g., pipx)
###############################################################################
export PATH="$PATH:$USER_HOME/.local/bin"

# Delta theme switching based on macOS appearance
delta_theme_switch() {
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
        # Dark mode
        git config delta.features "woolly-mammoth"
    else
        # Light mode  
        git config delta.features "earl-grey"
    fi
}

# Auto-switch delta theme on shell startup
delta_theme_switch

# Manual theme switching aliases
alias delta-dark='git config delta.features "woolly-mammoth"'
alias delta-light='git config delta.features "earl-grey"'

#### Yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Additional PATH exports
export PATH="$PATH:$USER_HOME/.lmstudio/bin:/opt/homebrew/opt/postgresql@17/bin"

# bun completions
[ -s "$USER_HOME/.bun/_bun" ] && source "$USER_HOME/.bun/_bun"

eval "$(atuin init zsh)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/yesh/.lmstudio/bin"
# End of LM Studio CLI section

