# zsh-config

Ma config zsh : le prompt [starship](https://github.com/Kasouker/starship-config), un historique partagé, des
suggestions grises et la coloration des commandes, `ls` avec icônes (eza), recherche de fichiers et de dossiers
partout (`ff`, `fcd`, `Ctrl+F`, `Ctrl+G`), le gestionnaire de fichiers yazi (`y`).

L'installation ci-dessous met **tout dans ton dossier personnel** (`~/.local`) : elle marche **sans sudo**.

## Installation (Linux, sans sudo)

Une seule ligne à copier (elle marche aussi pour mettre à jour : relance-la quand tu veux) :

```bash
{ [ -f ~/.config/zsh/install.sh ] || git clone https://github.com/Kasouker/zsh-config.git ~/.config/zsh; } && git -C ~/.config/zsh pull -q && bash ~/.config/zsh/install.sh
```

Le script `install.sh` met tout dans ton dossier personnel (`~/.local`) et saute ce qui est déjà là :

- **les outils** : starship, fzf (0.48 ou plus), eza, bat, ripgrep, fd, yazi, lazygit ;
- **les suggestions grises** et **la coloration des commandes** ;
- **le prompt** ([starship-config](https://github.com/Kasouker/starship-config)) ;
- **le lien `~/.zshrc`** vers cette config. Ton ancien `~/.zshrc` est gardé en `~/.zshrc.bak` : recopie les alias
  que tu veux garder dans `~/.zshrc.local` (voir plus bas).

Ensuite : `exec zsh`.

> Il faut `zsh`, `git`, `curl`, `tar` et `unzip` (presque toujours déjà là). Les icônes demandent une **Nerd Font**
> dans le terminal (voir [starship-config](https://github.com/Kasouker/starship-config)).

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
