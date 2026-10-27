#!/usr/bin/env bash
# install.sh : installe la config zsh sous Linux, sans sudo (tout dans ~/.local) :
# les outils absents (starship, fzf, eza, bat, ripgrep, fd, yazi, lazygit), les suggestions grises et la coloration
# des commandes, le prompt (starship-config), puis le lien ~/.zshrc. L'ancien ~/.zshrc est gardé en ~/.zshrc.bak.
# À lancer après le clone : bash ~/.config/zsh/install.sh (peut être relancé sans risque).
set -euo pipefail

BIN="$HOME/.local/bin"
mkdir -p "$BIN"
export PATH="$BIN:$PATH"

step() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# dl <dépôt GitHub> <fin du nom de l'archive> <programmes...> : la dernière version, dans ~/.local/bin
dl() {
	local repo=$1 end=$2 url tmp b
	shift 2
	url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | grep -o "https://[^\"]*$end" | head -1)
	tmp=$(mktemp -d)
	curl -fsSL "$url" -o "$tmp/archive"
	mkdir "$tmp/x"
	case "$url" in
		*.zip) unzip -q "$tmp/archive" -d "$tmp/x" ;;
		*) tar -xf "$tmp/archive" -C "$tmp/x" ;;
	esac
	for b in "$@"; do install -m 755 "$(find "$tmp/x" -type f -name "$b" | head -1)" "$BIN/"; done
	rm -rf "$tmp"
	echo "$1 installé"
}

# Vrai si fzf est là et en version 0.48 ou plus (`fzf --zsh` n'existe pas avant)
fzf_ok() {
	local v
	v=$(fzf --version 2>/dev/null | sed -n 's/^\([0-9]*\)\.\([0-9]*\).*/\1 \2/p')
	[ -n "$v" ] && set -- $v && { [ "$1" -gt 0 ] || [ "$2" -ge 48 ]; }
}

step "Outils"
have starship || dl starship/starship starship-x86_64-unknown-linux-musl.tar.gz starship
fzf_ok || dl junegunn/fzf linux_amd64.tar.gz fzf
have eza || dl eza-community/eza eza_x86_64-unknown-linux-musl.tar.gz eza
have bat || have batcat || dl sharkdp/bat x86_64-unknown-linux-musl.tar.gz bat
have rg || dl BurntSushi/ripgrep x86_64-unknown-linux-musl.tar.gz rg
have fd || have fdfind || dl sharkdp/fd x86_64-unknown-linux-musl.tar.gz fd
have yazi || dl sxyazi/yazi yazi-x86_64-unknown-linux-musl.zip yazi ya
have lazygit || dl jesseduffield/lazygit linux_x86_64.tar.gz lazygit
echo "outils prêts"

step "Suggestions grises et coloration des commandes"
mkdir -p "$HOME/.local/share/zsh"
for p in zsh-autosuggestions zsh-syntax-highlighting; do
	[ -d "$HOME/.local/share/zsh/$p" ] || git clone -q --depth 1 "https://github.com/zsh-users/$p" "$HOME/.local/share/zsh/$p"
done
echo "prêtes"

step "Le prompt (starship-config)"
[ -d "$HOME/.config/starship" ] || git clone -q https://github.com/Kasouker/starship-config.git "$HOME/.config/starship"
ln -sfn "$HOME/.config/starship/starship.toml" "$HOME/.config/starship.toml"
echo "prêt"

step "~/.zshrc"
if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
	mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
	echo "ancien ~/.zshrc gardé en ~/.zshrc.bak (recopie tes alias dans ~/.zshrc.local)"
fi
ln -sfn "$HOME/.config/zsh/.zshrc" "$HOME/.zshrc"
echo "~/.zshrc -> ~/.config/zsh/.zshrc"

step "Terminé"
echo "Lance : exec zsh"
