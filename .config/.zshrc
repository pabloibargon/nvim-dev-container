# =============================================================================
# PATH CONFIGURATION
# =============================================================================
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$HOME/.cargo/bin:$PATH"
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
PORT=8989
function open() {
    local target="$1"
    # If target is a local file
    if [ -f "$target" ]; then
	    # Get absolute path inside container
	    local abs_path=$(realpath "$target")
	    local host_file_path=""
	    if [[ -n "$HOST_PWD" ]] && \
	       [[ -n "$VOLUME_TARGET_PATH" ]] && \
	       [[ "$abs_path" == "$VOLUME_TARGET_PATH"* ]]; then
		local rel_path="${abs_path#$VOLUME_TARGET_PATH}"
		if [[ "$HOST_OS" != "wsl" ]]; then
		# Check if port is free (lsof returns 1 if nothing is found)
		if ! lsof -i :$PORT > /dev/null; then
		    # Start server, hide output, run in background
		    (cd $VOLUME_TARGET_PATH && python -m http.server $PORT > /dev/null 2>&1) &!
		fi
			gdbus call --session --dest org.freedesktop.portal.Desktop \
			    --object-path /org/freedesktop/portal/desktop \
			    --method org.freedesktop.portal.OpenURI.OpenURI \
			    "" "http://localhost:$PORT$rel_path" "{}" > /dev/null
			return
	         else
                 /mnt/c/Windows/explorer.exe "$target"
		fi
	    # TODO: WSL path translation
	fi
    elif [[ "$HOST_OS" == "wsl" ]]; then
        # WSL: Directly call the Windows binary. 
        # The Kernel's binfmt_misc handles the magic.
        /mnt/c/Windows/explorer.exe "$target"
    else
        # LINUX: Use standard DBus call to host
        xdg-open "$target" > /dev/null 2>&1
    fi
}
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
