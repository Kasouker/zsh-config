# zsh-config

Installation :

```sh
git clone https://github.com/Kasouker/zsh-config.git ~/.config/zsh
ln -sf ~/.config/zsh/.zshrc ~/.zshrc
```

## Ce qui est propre à une machine

Les alias de projets, les chemins et tout ce qui ne sert que sur un ordi vont dans `~/.zshrc.local`. Ce fichier est
chargé à la fin de `.zshrc`, mais il n'est **pas dans le dépôt** : il reste sur la machine.

```sh
echo "alias projet='cd ~/mon/projet'" >> ~/.zshrc.local
```
