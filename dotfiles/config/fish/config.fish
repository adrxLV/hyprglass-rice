source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end


# Added by Antigravity CLI installer
set -gx PATH "/home/adrxlv/.local/bin" $PATH
# Atalho para a dashboard musical
alias musica="kitty --session ~/.config/kitty/music.session"

fish_add_path /home/adrxlv/.spicetify
