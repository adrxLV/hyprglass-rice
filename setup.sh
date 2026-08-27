#!/usr/bin/env bash
# ==============================================================================
# setup.sh - Instalador "Perfeito" de Dotfiles, Rice, Tide-Island e Dependências
# Suporta: Arch Linux, CachyOS, EndeavourOS, Manjaro e outras distros Arch-based
# ==============================================================================

set -e

# Cores para Saída Elegante no Terminal
BOLD='\030[1m'
GREEN='\030[0;32m'
BLUE='\030[0;34m'
CYAN='\030[0;36m'
YELLOW='\030[1;33m'
RED='\030[0;31m'
NC='\030[0m' # No Color

LOG_FILE="$HOME/.rice_install.log"
exec > >(tee -i "$LOG_FILE") 2>&1

echo -e "${BLUE}====================================================================${NC}"
echo -e "${BOLD}${CYAN}   🚀 INSTALADOR AUTOMÁTICO DE DOTFILES / RICE & TIDE-ISLAND      ${NC}"
echo -e "${BLUE}====================================================================${NC}"
echo -e "${YELLOW}Log de instalação iniciado em: $LOG_FILE${NC}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# ------------------------------------------------------------------------------
# 1. DETECÇÃO DE SISTEMA E HELPER AUR (PARU / YAY)
# ------------------------------------------------------------------------------
detect_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    elif command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    else
        AUR_HELPER=""
    fi
}

install_aur_helper() {
    echo -e "${YELLOW}-> Nenhum AUR helper (yay ou paru) foi encontrado.${NC}"
    read -p "Desejas instalar o 'yay' automaticamente a partir do AUR? (S/n): " confirm_yay
    confirm_yay=${confirm_yay:-S}
    if [[ "$confirm_yay" =~ ^[Ss]$ ]]; then
        echo -e "${CYAN}Instalando dependências base-devel e git...${NC}"
        sudo pacman -S --needed --noconfirm base-devel git
        
        TMP_YAY=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$TMP_YAY"
        (cd "$TMP_YAY" && makepkg -si --noconfirm)
        rm -rf "$TMP_YAY"
        AUR_HELPER="yay"
        echo -e "${GREEN}✓ yay instalado com sucesso!${NC}"
    else
        echo -e "${YELLOW}Aviso: A instalação de pacotes do AUR será ignorada.${NC}"
    fi
}

install_dependencies() {
    if [ -f /etc/os-release ]; source /etc/os-release; fi

    if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* || "$ID" == "cachyos" || "$ID" == "endeavouros" || "$ID" == "manjaro" ]]; then
        echo -e "${GREEN}✓ Sistema baseado em Arch Linux detectado ($NAME).${NC}"
        
        detect_aur_helper
        if [ -z "$AUR_HELPER" ]; then
            install_aur_helper
        else
            echo -e "${GREEN}✓ AUR Helper detectado: $AUR_HELPER${NC}"
        fi

        read -p "Desejas verificar e instalar as dependências de sistema para Hyprland/Quickshell/Tide-Island? (S/n): " install_deps
        install_deps=${install_deps:-S}

        if [[ "$install_deps" =~ ^[Ss]$ ]]; then
            echo -e "\n${CYAN}-> Instalando pacotes oficiais do Pacman...${NC}"
            PACMAN_PKGS=(
                hyprland hyprpaper hyprlock hypridle
                qt6-declarative qt6-5compat qt6-svg qt6-wayland
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                pipewire wireplumber playerctl pamixer brightnessctl
                bluez bluez-utils grim slurp wl-clipboard wf-recorder
                cava kitty alacritty rofi-wayland swaync fastfetch
                ttf-jetbrains-mono-nerd ttf-font-awesome noto-fonts-emoji
                python python-pip python-gobject
            )

            sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || true

            if [ -n "$AUR_HELPER" ]; then
                echo -e "\n${CYAN}-> Instalando pacotes do AUR via $AUR_HELPER...${NC}"
                AUR_PKGS=(
                    quickshell-git
                    hyprpicker
                    spicetify-cli
                )
                $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" || true
            fi
        fi
    else
        echo -e "${YELLOW}Nota: Sistema não-Arch detectado. A instalação automática de pacotes do pacman/AUR foi ignorada.${NC}"
    fi
}

# Executar verificação e instalação de dependências
install_dependencies

# ------------------------------------------------------------------------------
# 2. SISTEMA SAFE BACKUP DE DOTFILES EXISTENTES
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}-> Criando diretório de backup em: ${BACKUP_DIR}${NC}"
mkdir -p "$BACKUP_DIR"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share"
mkdir -p "$HOME/.local/bin"

deploy_item() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo -e "  - Backup de: ${dest#$HOME/}"
        local rel_path="${dest#$HOME/}"
        mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
        mv "$dest" "$BACKUP_DIR/$rel_path" 2>/dev/null || mv "$dest" "$BACKUP_DIR/"
    fi

    echo -e "  ${GREEN}+ Aplicando:${NC} ${dest#$HOME/}"
    mkdir -p "$(dirname "$dest")"
    cp -rf "$src" "$dest"
}

# ------------------------------------------------------------------------------
# 3. APLICAÇÃO DOS FICHEIROS DO RICE & TIDE-ISLAND
# ------------------------------------------------------------------------------
# 3.1 Aplicar ~/.config/
if [ -d "$SCRIPT_DIR/dotfiles/config" ]; then
    echo -e "\n${YELLOW}-> Aplicando configurações em ~/.config/...${NC}"
    for item in "$SCRIPT_DIR/dotfiles/config/"*; do
        if [ -e "$item" ]; then
            deploy_item "$item" "$HOME/.config/$(basename "$item")"
        fi
    done
fi

# 3.2 Aplicar ~/.local/share/ (QMLs do Tide-Island)
if [ -d "$SCRIPT_DIR/dotfiles/local_share" ]; then
    echo -e "\n${YELLOW}-> Aplicando motores QML e assets em ~/.local/share/...${NC}"
    for item in "$SCRIPT_DIR/dotfiles/local_share/"*; do
        if [ -e "$item" ]; then
            deploy_item "$item" "$HOME/.local/share/$(basename "$item")"
        fi
    done
fi

# 3.3 Aplicar ~/.local/bin/ (Executáveis e scripts)
if [ -d "$SCRIPT_DIR/dotfiles/local_bin" ]; then
    echo -e "\n${YELLOW}-> Aplicando scripts executáveis em ~/.local/bin/...${NC}"
    for item in "$SCRIPT_DIR/dotfiles/local_bin/"*; do
        if [ -e "$item" ]; then
            deploy_item "$item" "$HOME/.local/bin/$(basename "$item")"
            chmod +x "$HOME/.local/bin/$(basename "$item")" 2>/dev/null || true
        fi
    done
fi

# 3.4 Aplicar Dotfiles no Home (~/)
if [ -d "$SCRIPT_DIR/dotfiles/home" ]; then
    echo -e "\n${YELLOW}-> Aplicando dotfiles na raiz do HOME (~/)...${NC}"
    for item in "$SCRIPT_DIR/dotfiles/home/"*; do
        if [ -e "$item" ]; then
            deploy_item "$item" "$HOME/$(basename "$item")"
        fi
    done
fi

# 3.5 Aplicar Wallpapers / Imagens
WP_SRC=""
if [ -d "$SCRIPT_DIR/wallpapers" ]; then
    WP_SRC="$SCRIPT_DIR/wallpapers"
elif [ -d "$SCRIPT_DIR/dotfiles/wallpapers" ]; then
    WP_SRC="$SCRIPT_DIR/dotfiles/wallpapers"
fi

if [ -n "$WP_SRC" ]; then
    echo -e "\n${YELLOW}-> Copiando coleção de wallpapers para ~/Imagens/Wallpapers/...${NC}"
    mkdir -p "$HOME/Imagens/Wallpapers"
    mkdir -p "$HOME/Pictures/Wallpapers"
    cp -rf "$WP_SRC/"* "$HOME/Imagens/Wallpapers/" 2>/dev/null || true
    cp -rf "$WP_SRC/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
    mkdir -p "$HOME/imagens"
    ln -sfn "$HOME/Imagens/Wallpapers" "$HOME/imagens/wallpapers" 2>/dev/null || true
    echo -e "  ${GREEN}+ Wallpapers instalados com sucesso!${NC}"
fi

# ------------------------------------------------------------------------------
# 4. CONFIGURAÇÃO DE AMBIENTE & SERVIÇOS
# ------------------------------------------------------------------------------

# Garantir que ~/.local/bin está no PATH do utilizador
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo -e "\n${YELLOW}-> Adicionando ~/.local/bin ao PATH no .bashrc e .zshrc...${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi
fi

# Ativar serviço do Bluetooth se o bluez estiver instalado
if command -v bluetoothctl >/dev/null 2>&1; then
    echo -e "${CYAN}-> Verificando serviço do Bluetooth...${NC}"
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
fi

# Atualizar cache de fontes
if [ -d "$HOME/.local/share/fonts" ] && command -v fc-cache >/dev/null 2>&1; then
    echo -e "\n${YELLOW}-> Atualizando cache de fontes do sistema...${NC}"
    fc-cache -fv "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
fi

# Reload de Hyprland se estiver em execução numa sessão ativa
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl >/dev/null 2>&1; then
    echo -e "\n${CYAN}-> Recarregando sessão ativa do Hyprland...${NC}"
    hyprctl reload || true
fi

# ------------------------------------------------------------------------------
# 5. RESUMO E CONCLUSÃO
# ------------------------------------------------------------------------------
echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${BOLD}${GREEN}   ✨ RICE & TIDE-ISLAND INSTALADOS COM SUCESSO PERFEITO!          ${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "${CYAN}• Configurações aplicadas em: ~/.config/ e ~/.local/share/${NC}"
echo -e "${CYAN}• Scripts do Tide-Island em: ~/.local/bin/${NC}"
echo -e "${CYAN}• Backup da sua configuração anterior guardado em:${NC}"
echo -e "  ${YELLOW}$BACKUP_DIR${NC}"
echo -e "${CYAN}• Ficheiro de log salvo em: $LOG_FILE${NC}"
echo -e "${GREEN}====================================================================${NC}\n"
