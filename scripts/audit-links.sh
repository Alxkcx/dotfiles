#!/usr/bin/env bash
# 审计：Makefile 白名单里的每一项，在系统侧是否真的是指向仓库的软链。
# 附带报出「仓库有、系统侧没挂」和「被外部程序打回普通文件」的情况。
# 用法：bash scripts/audit-links.sh

set -u
DOTFILES="${HOME}/dotfiles"
cd "$DOTFILES" || { echo "找不到 $DOTFILES"; exit 1; }

CONFIGS="kitty niri fish fuzzel fastfetch btop matugen yazi mpv satty pacseek \
fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct xsettingsd xdg-desktop-portal \
environment.d cava fcitx5 nvim starship.toml autostart chrome-flags.conf \
mimeapps.list user-dirs.dirs"
# .gtkrc-2.0 故意不在 HOMEFILES 里（会被 kde-gtk-config 打回普通文件，见维护指南 4.5）
HOMEFILES=".zshrc .zprofile .bash_profile .profile .gitconfig .Xresources bin"

total=0; bad=0
check() { # $1=系统侧路径 $2=期望指向的仓库路径 $3=描述
    total=$((total + 1))
    if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then
        return 0
    elif [ -L "$1" ]; then
        echo "  [错误] $3 指向别处：$1 -> $(readlink "$1")"; bad=$((bad + 1))
    elif [ -e "$1" ]; then
        echo "  [错误] $3 是普通文件/目录，不是软链：$1"; bad=$((bad + 1))
    else
        echo "  [缺失] $3 系统侧不存在：$1"; bad=$((bad + 1))
    fi
}

for c in $CONFIGS; do
    [ -e "config/$c" ] || continue
    check "$HOME/.config/$c" "$DOTFILES/config/$c" "~/.config/$c"
done
for f in $HOMEFILES; do
    [ -e "home/$f" ] || continue
    check "$HOME/$f" "$DOTFILES/home/$f" "~/$f"
done
while IFS= read -r x; do
    rel="${x#config/systemd/}"
    check "$HOME/.config/systemd/$rel" "$DOTFILES/$x" "~/.config/systemd/$rel"
done < <(find config/systemd -type f | sort)

echo "审计 $total 项，异常 $bad 项"

# 仓库有、但白名单没管到的目录（systemd 走逐文件链接；greetd 真身在 /etc/greetd，只能手动快照）
echo -n "仓库内未纳管项："
for d in config/*; do
    n="${d#config/}"
    [ "$n" = "systemd" ] && continue
    case " $CONFIGS " in *" $n "*) continue ;; esac
    printf '%s ' "$n"
done; echo

exit $((bad > 0))
