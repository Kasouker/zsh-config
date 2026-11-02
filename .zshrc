# Les outils installés sans sudo (~/.local/bin) : avant tout le reste, starship et fzf sont appelés juste après
export PATH="$HOME/.local/bin:$PATH"

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

# Couleur des fichiers dans ls selon le langage (les mêmes que les icônes de Neovim)
export EZA_COLORS="\
*.html=38;2;228;77;38:*.css=38;2;66;165;245:*.scss=38;2;245;83;133:*.svg=38;2;255;177;59:*.xml=38;2;227;121;51:\
*.js=38;2;203;203;65:*.mjs=38;2;241;224;90:*.jsx=38;2;32;194;227:*.ts=38;2;81;154;186:*.tsx=38;2;19;84;191:\
*.vue=38;2;141;193;73:*.svelte=38;2;255;62;0:*.php=38;2;160;116;196:*.json=38;2;203;203;65:\
*.c=38;2;89;158;255:*.h=38;2;160;116;196:*.cpp=38;2;81;154;186:*.hpp=38;2;160;116;196:\
*.py=38;2;255;188;3:*.lua=38;2;81;160;207:*.java=38;2;204;62;68:*.go=38;2;0;173;216:*.rs=38;2;222;165;132:*.rb=38;2;204;52;45:\
*.sh=38;2;137;224;81:*.zsh=38;2;137;224;81:*.sql=38;2;218;216;216:*.md=38;2;221;221;221:*.txt=38;2;137;224;81:\
*.yml=38;2;215;0;0:*.yaml=38;2;215;0;0:*.toml=38;2;156;66;33:*.env=38;2;250;247;67:*.lock=38;2;187;187;187:\
Makefile=38;2;109;128;134:Dockerfile=38;2;69;142;230"
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

# Plugins : ceux du système, sinon ceux installés sans sudo dans ~/.local/share/zsh
for _p in zsh-autosuggestions zsh-syntax-highlighting; do
	for _d in /usr/share/$_p ~/.local/share/zsh/$_p; do
		[ -f $_d/$_p.zsh ] && { source $_d/$_p.zsh; break; }
	done
done
unset _p _d

# Aliasi
alias v='nvim'
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


# Ce qui est propre à cette machine (alias de projets, chemins…) : ~/.zshrc.local, qui n'est pas dans le dépôt
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
