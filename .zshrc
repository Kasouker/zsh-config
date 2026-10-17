# Historique
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Complétion avec Tab
autoload -Uz compinit
compinit

# Prompt : utilisateur@machine dossier (branche git)
eval "$(starship init zsh)"

# Mémorise l'heure d'apparition de chaque prompt
zmodload zsh/datetime
_save_prompt_time() { strftime -s _prompt_time '%I:%M:%S %p' $EPOCHSECONDS }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _save_prompt_time

ZLE_RPROMPT_INDENT=0

# Prompt transitoire : les anciennes lignes se réduisent à "❯"
zle-line-init() {
	emulate -L zsh
	[[ $CONTEXT == start ]] || return 0

	while true; do
		zle .recursive-edit
		local -i ret=$?
		[[ $ret == 0 && $KEYS == $'\4' ]] || break
		[[ -o ignore_eof ]] || exit 0
	done

	local saved_prompt=$PROMPT
	local saved_rprompt=$RPROMPT
    PROMPT='%F{137}❯%f '
	RPROMPT="%F{8}${_prompt_time}%f"
    zle .reset-prompt
	PROMPT=$saved_prompt
	RPROMPT=$saved_rprompt

	if (( ret )); then
		zle .send-break
	else
		zle .accept-line
	fi
	return ret
}
zle -N zle-line-init

# --- Outils : fzf, eza, bat, lazygit ---
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --color=bg+:#2B2E36,fg:#CFC9BC,hl:#C9AB6B,fg+:#ECE6D9,hl+:#E2BE70,prompt:#C9AB6B,pointer:#C46B76,info:#8B8E99,border:#4B505C"
export BAT_THEME="ansi"

alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'
command -v batcat >/dev/null && alias bat='batcat'
alias lg='lazygit'

# Suggestion en gris One Dark (doit être avant le source)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5C6370'


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# --- Recherche de fichiers et de dossiers, depuis n'importe où vers n'importe où ---
# Dossiers parcourus : ton dossier personnel + les dossiers utilisateur de Windows (sans AppData).
# Pour en ajouter un, ajoute une ligne "print -r -- /chemin" dans _ff_roots.
_ff_roots() {
	local d
	print -r -- "$HOME"
	for d in /mnt/c/Users/*(N/); do
		case "${d:t}" in
			Public|Default|"Default User"|"All Users") continue ;;
		esac
		print -r -- "$d"
	done
}

# Liste tous les fichiers (cachés compris), sans les dossiers lourds ou inutiles
_ff_files() {
	rg --files --hidden --no-messages \
		-g '!.git' -g '!node_modules' -g '!.cache' -g '!.nvm' -g '!.cargo' -g '!.rustup' \
		-g '!.npm' -g '!AppData' -g '!.local/share' -g '!__pycache__' \
		"${(@f)$(_ff_roots)}" 2>/dev/null
}

# Liste tous les dossiers, avec les mêmes exclusions
_ff_dirs() {
	local fdbin
	fdbin=$(command -v fdfind || command -v fd)
	if [ -n "$fdbin" ]; then
		"$fdbin" --type d --hidden \
			-E .git -E node_modules -E .cache -E .nvm -E .cargo -E .rustup \
			-E .npm -E AppData -E .local -E __pycache__ \
			. "${(@f)$(_ff_roots)}" 2>/dev/null
	else
		find "${(@f)$(_ff_roots)}" \
			\( -name .git -o -name node_modules -o -name .cache -o -name .nvm -o -name .cargo \
			-o -name .rustup -o -name .npm -o -name AppData -o -name .local -o -name __pycache__ \) \
			-prune -o -type d -print 2>/dev/null
	fi
}

# ff [mot] : cherche un fichier n'importe où et l'ouvre dans l'éditeur
ff() {
	local bat file preview
	bat=$(command -v batcat || command -v bat)
	preview="head -200 {}"
	[ -n "$bat" ] && preview="$bat --color=always --style=numbers --line-range=:200 {}"
	file=$(_ff_files | fzf --query "$*" --height=80% --layout=reverse --border \
		--prompt="fichier > " --preview "$preview" --preview-window=right:55%)
	[ -n "$file" ] && ${EDITOR:-nvim} "$file"
}

# fcd [mot] : cherche un dossier n'importe où et s'y rend
fcd() {
	local dir lister
	lister="ls -1A {}"
	command -v eza >/dev/null && lister="eza -1a --icons --color=always {}"
	dir=$(_ff_dirs | fzf --query "$*" --height=80% --layout=reverse --border \
		--prompt="dossier > " --preview "$lister 2>/dev/null | head -50" --preview-window=right:45%)
	[ -n "$dir" ] && cd "$dir"
}

# Raccourcis clavier : Ctrl+F = ff, Ctrl+G = fcd
_ff_widget() { BUFFER="ff"; zle accept-line }
_fcd_widget() { BUFFER="fcd"; zle accept-line }
zle -N _ff_widget
zle -N _fcd_widget
bindkey '^f' _ff_widget
bindkey '^g' _fcd_widget

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Aliasi
alias v='nvim'
alias home='cd /mnt/c/Users/gazou/Projet_Perso/'
alias Plouf='cd /mnt/c/Users/gazou/Projet_Perso/42/Piscine/'
alias Wahou='cd /mnt/c/Users/gazou/Projet_Perso/TDVN°4/'
alias gccc='cc -g -Wall -Wextra -Werror'
export EDITOR=nvim

# Yazi : "y" ouvre le gestionnaire et te laisse dans le dernier dossier visité
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

eval "$(dircolors -b)"
export LS_COLORS="$LS_COLORS:ow=1;34:tw=1;34"

# Created by `pipx` on 2026-10-07 02:37:54
export PATH="$PATH:/home/mpignon/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Masque les dépendances dans tree (projet TDVN°4)
alias tree="tree -I 'installation|node_modules'"
