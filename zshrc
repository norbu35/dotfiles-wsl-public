#!/bin/bash
source $XDG_CONFIG_HOME/.aliases

export BROWSER=wslview
export ZSH="$XDG_DATA_HOME/.oh-my-zsh"
export PATH=$HOME/bin:/usr/local/bin:/home/norbu/.local/bin:$PATH
export PNPM_HOME="/home/norbu/.local/share/pnpm"
export PATH="/usr/bin/java/jdk-19.0.2/bin:$PATH"
export FLYCTL_INSTALL="/home/norbu/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"
export PATH="$PNPM_HOME:$PATH"

setopt EXTENDED_GLOB

# opam
[[ ! -r /home/norbu/.opam/opam-init/init.zsh ]] ||
source /home/norbu/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

# rust
. "$HOME/.cargo/env"

# remove PATH duplicates
PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')

source $ZSH/oh-my-zsh.sh
ZSH_THEME='gruvbox'
SOLARIZED_THEME='dark'

# Completion
source $ZDOTDIR/.completion.zsh
_comp_options+=(globdots) # With hidden files
COMPLETION_WAITING_DOTS=true

# Options
setopt AUTO_PUSHD           # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.
HIST_STAMPS='dd/mm-%HH:%MM'
set -o noclobber

# Plugins
plugins=(
    docker
    git
    sudo
    fzf
    zsh-syntax-highlighting
    zsh-autosuggestions
    conda-zsh-completion
)

# keybindings
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
zle -N autosuggest-accept
bindkey '^Y' autosuggest-accept
export FZF_DEFAULT_OPTS='--bind ctrl-y:accept'

# Cursor mode
cursor_mode() {
    # See https://ttssh2.osdn.jp/manual/4/en/usage/tips/vim.html for cursor shapes
    cursor_block='\e[2 q'
    cursor_beam='\e[6 q'

    function zle-keymap-select {
        if [[ ${KEYMAP} == vicmd ]] ||
        [[ $1 = 'block' ]]; then
            echo -ne $cursor_block
        elif [[ ${KEYMAP} == main ]] ||
        [[ ${KEYMAP} == viins ]] ||
        [[ ${KEYMAP} = '' ]] ||
        [[ $1 = 'beam' ]]; then
            echo -ne $cursor_beam
        fi
    }

    zle-line-init() {
        echo -ne $cursor_beam
    }

    zle -N zle-keymap-select
    zle -N zle-line-init
}

cursor_mode

# Edit commands in Vim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Text objects
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
    bindkey -M $km -- '-' vi-up-line-or-history
    for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
        bindkey -M $km $c select-quoted
    done
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
        bindkey -M $km $c select-bracketed
    done
done

# Surrounding
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround
# cs (change surrounding)
# ds (delete surrounding)
# ys (add surrounding)

# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# exercism bash testing
exercism () {
    local out
    # readarray -t out < <(command exercism "$@")
    out < ("${(@f)$(command exercism "$@")}")
    printf '%s\n' "${out[@]}"
    if [[ $1 == "download" && -d "${out[-1]}" ]]; then
        cd "${out[-1]}" || return 1
    fi
}

# bats run all tests
bats() {
    BATS_RUN_SKIPPED=true command bats *.bats
}

# autostart tmux
source ~/.oh-my-zsh/oh-my-zsh.sh
[ -z "$TMUX"  ] && { tmux -f ~/.config/tmux/tmux.conf attach || exec tmux -f ~/.config/tmux/tmux.conf new-session;}
autoload -U compinit && compinit

## run neofetch on first instance only
LIVE_COUNTER=$(ps a | awk '{print $2}' | grep -vi "tty*" | uniq | wc -l);
if [ $LIVE_COUNTER -eq 3 ]; then
    neofetch --gtk2 off --gtk3 off --gpu_brand off
fi

## timestamps
RPROMPT="[%D{%f/%m/%y} | %D{%L:%M:%S}]"

# AWS
export AWS_CLI_AUTO_PROMPT=on

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/norbu/stuff/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/norbu/stuff/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/norbu/stuff/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/norbu/stuff/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
# conda tab completion
zstyle ':completion::complete:*' use-cache 1
zstyle ":conda_zsh_completion:*" use-groups true
zstyle ":conda_zsh_completion:*" show-unnamed true
zstyle ":conda_zsh_completion:*" sort-envs-by-time true

# zsh startup time
timezsh() {
    shell=${1-$SHELL}
    for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

# terminal colors 
# autoload -U colors && colors
# PS1="%{$fg[red]%}%n%{$reset_color%}@%{$fg[blue]%}%m %{$fg[yellow]%}%~ %{$reset_color%}%% "
