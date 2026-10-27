# zsh-config

Ma config zsh : le prompt [starship](https://github.com/Kasouker/starship-config), un historique partagé, des
suggestions grises et la coloration des commandes, `ls` avec icônes (eza), recherche de fichiers et de dossiers
partout (`ff`, `fcd`, `Ctrl+F`, `Ctrl+G`), le gestionnaire de fichiers yazi (`y`).

L'installation ci-dessous met **tout dans ton dossier personnel** (`~/.local`) : elle marche **sans sudo**.

## Prérequis

`zsh`, `git`, `curl`, `tar`, `unzip` (presque toujours déjà là). Vérifie :

```bash
zsh --version && git --version && curl --version | head -1 && unzip -v | head -1
```

## 1. Installer les outils (sans sudo)

Copie-colle tout le bloc dans un terminal (Linux x86_64). Un outil déjà installé est sauté.

```bash
mkdir -p ~/.local/bin && export PATH="$HOME/.local/bin:$PATH"

# dl <dépôt GitHub> <fin du nom de l'archive> <programmes...> : télécharge la dernière version dans ~/.local/bin
dl() {
	local repo=$1 end=$2 url tmp
	shift 2
	url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | grep -o "https://[^\"]*$end" | head -1)
	tmp=$(mktemp -d)
	curl -fsSL "$url" -o "$tmp/archive"
	mkdir "$tmp/x"
	case "$url" in
		*.zip) unzip -q "$tmp/archive" -d "$tmp/x" ;;
		*) tar -xf "$tmp/archive" -C "$tmp/x" ;;
	esac
	for b in "$@"; do install -m 755 "$(find "$tmp/x" -type f -name "$b" | head -1)" ~/.local/bin/; done
	rm -rf "$tmp"
}

command -v starship >/dev/null || curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
command -v fzf >/dev/null || dl junegunn/fzf linux_amd64.tar.gz fzf
command -v eza >/dev/null || dl eza-community/eza eza_x86_64-unknown-linux-musl.tar.gz eza
command -v bat >/dev/null || command -v batcat >/dev/null || dl sharkdp/bat x86_64-unknown-linux-musl.tar.gz bat
command -v rg >/dev/null || dl BurntSushi/ripgrep x86_64-unknown-linux-musl.tar.gz rg
command -v fd >/dev/null || command -v fdfind >/dev/null || dl sharkdp/fd x86_64-unknown-linux-musl.tar.gz fd
command -v yazi >/dev/null || dl sxyazi/yazi yazi-x86_64-unknown-linux-musl.zip yazi ya
command -v lazygit >/dev/null || dl jesseduffield/lazygit linux_x86_64.tar.gz lazygit

# Les suggestions grises et la coloration des commandes
mkdir -p ~/.local/share/zsh
for p in zsh-autosuggestions zsh-syntax-highlighting; do
	[ -d ~/.local/share/zsh/$p ] || git clone -q --depth 1 https://github.com/zsh-users/$p ~/.local/share/zsh/$p
done
```

> `fzf` doit être en version **0.48 ou plus** (`fzf --version`) : une version plus ancienne déjà installée sur la
> machine affichera une erreur au lancement. Dans ce cas, lance `dl junegunn/fzf linux_amd64.tar.gz fzf` (dans le
> même terminal que le bloc ci-dessus) pour avoir la dernière dans `~/.local/bin`.

## 2. Installer la config

Si tu as déjà un `~/.zshrc`, mets-le de côté (tu pourras recopier tes alias dans `~/.zshrc.local`, voir plus bas) :

```bash
[ -f ~/.zshrc ] && [ ! -L ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
```

Puis :

```bash
git clone https://github.com/Kasouker/zsh-config.git ~/.config/zsh
ln -sf ~/.config/zsh/.zshrc ~/.zshrc
git clone https://github.com/Kasouker/starship-config.git ~/.config/starship
ln -sf ~/.config/starship/starship.toml ~/.config/starship.toml
exec zsh
```

Les icônes demandent une **Nerd Font** dans le terminal (voir [starship-config](https://github.com/Kasouker/starship-config)).

## Les commandes

| Commande | Action |
|---|---|
| `ls`, `ll`, `lt` | Lister (avec icônes), en détail, en arbre |
| `ff [mot]` ou `Ctrl+F` | Chercher un fichier n'importe où et l'ouvrir dans nvim |
| `fcd [mot]` ou `Ctrl+G` | Chercher un dossier n'importe où et y aller |
| `y` | Yazi (gestionnaire de fichiers) ; en le quittant, tu restes dans le dernier dossier visité |
| `lg` | LazyGit |
| `v` | nvim |
| `gccc` | `cc -g -Wall -Wextra -Werror` |

## Ce qui est propre à une machine

Les alias de projets, les chemins et tout ce qui ne sert que sur un ordi vont dans `~/.zshrc.local`. Ce fichier est
chargé à la fin de `.zshrc`, mais il n'est **pas dans le dépôt** : il reste sur la machine.

```sh
echo "alias projet='cd ~/mon/projet'" >> ~/.zshrc.local
```
