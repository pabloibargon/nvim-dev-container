# =============================================================================
# PATH CONFIGURATION
# =============================================================================
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.config/commands:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# HISTORY CONFIGURATION (Fixes "no history")
# =============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY      # Write the history file in the ":start:elapsed;command" format.
setopt SHARE_HISTORY         # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS      # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS  # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS     # Do not display a line previously found.
setopt HIST_SAVE_NO_DUPS     # Don't write duplicate entries in the history file.

# =============================================================================
# 3. COMPLETION SYSTEM
# =============================================================================
# Initialize the auto-completion system
autoload -Uz compinit
compinit

# =============================================================================
# PROMPT CONFIGURATION
# =============================================================================
# Enable colors
autoload -U colors && colors

# Prompt format: User@Host CurrentDir $
# %n = user, %m = host, %~ = current directory
PROMPT="%{$fg[green]%}%n@%m %{$fg[blue]%}%~ %{$reset_color%}%# "

# =============================================================================
# ALIASES & FUNCTIONS
# =============================================================================
alias dev="bash ~/projects/nvim-dev-container/run.sh"
alias copy='xsel -ib'

# render an Rmd to HTML
rmd2html() {
    command="rmarkdown::render(\"$1\", output_format='html_document')"
    Rscript -e "$command"
}

# =============================================================================
# PLUGINS (FZF & Zoxide)
# =============================================================================

# Initialize FZF if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Initialize Zoxide (Replaces the huge block of code)
# This checks if zoxide is installed, initializes it, and sets the cd alias
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
    alias cd=z
fi
#
# =============================================================================
# Zoxide Widget (Ctrl+f to launch zi)
# =============================================================================
function zi-widget() {
    zi                  # Run the zoxide interactive command
    zle reset-prompt    # Refresh the prompt to show the new directory
}

# Register the widget
zle -N zi-widget

# Bind it to Ctrl+f
bindkey '^f' zi-widget
