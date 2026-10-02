# Dotfiles

我的个人配置文件，通过符号链接管理。基于 [CachyOS](https://cachyos.org/) (Arch Linux)，使用 [niri](https://github.com/YaLTeR/niri) 作为窗口管理器。

## 目录结构

```
~/dotfiles/
├── Makefile          # install / uninstall / update / packages / check
├── packages/         # 包清单 (official.txt + aur.txt + flatpak.txt)
├── scripts/          # 辅助脚本
├── config/           # → ~/.config/
│   ├── kitty/        # 终端模拟器
│   ├── niri/         # 窗口管理器 + dms + scripts
│   ├── fcitx5/       # 输入法 (Rime)
│   ├── fish/         # Fish shell
│   ├── fuzzel/       # 应用启动器
│   ├── fastfetch/    # 系统信息
│   ├── btop/         # 系统监控
│   ├── matugen/      # 配色生成器（模板）
│   ├── yazi/         # 文件管理器
│   ├── mpv/          # 媒体播放器
│   ├── satty/        # 截图工具
│   ├── pacseek/      # Pacman 前端
│   ├── fontconfig/   # 字体配置
│   ├── gtk-3.0/      # GTK3 主题
│   ├── gtk-4.0/      # GTK4 主题
│   ├── qt5ct/        # Qt5 主题
│   ├── qt6ct/        # Qt6 主题
│   ├── xsettingsd/   # X 设置
│   ├── xdg-desktop-portal/ # Portal 路由 (FileChooser→KDE, Screenshot→GNOME)
│   ├── environment.d/# 环境变量
│   ├── cava/         # 音频可视化
│   ├── nvim/         # Neovim (LazyVim)
│   └── starship.toml # Shell 提示符
└── home/             # → ~/
    ├── .zshrc
    ├── .zprofile
    ├── .gitconfig
    ├── bin/          # 个人脚本
    └── ...
```

## 安装

```bash
git clone https://github.com/Alxkcx/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install
```

`make install` 会将配置文件符号链接到对应位置。如果目标位置已有文件，会自动备份（添加 `.bak.时间戳` 后缀）。

## 卸载

```bash
cd ~/dotfiles
make uninstall
```

只会删除指向本仓库的符号链接，不会影响其他文件。

## 更新

```bash
cd ~/dotfiles
make update
```

相当于 `git pull && make install`。

## 全新装机流程

```bash
# 1. 克隆 dotfiles
git clone https://github.com/Alxkcx/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. 恢复所有包 (官方 + AUR + Flatpak)
bash scripts/restore-packages.sh

# 3. 创建符号链接
make install

# 4. 生成主题配色
matugen image /path/to/your/wallpaper.png
```

### 导出当前包列表

当安装了新包后，更新包清单：

```bash
make packages
```

这会将当前系统上显式安装的包导出到三个清单：

| 文件 | 内容 | 导出命令 |
|---|---|---|
| `packages/official.txt` | 官方源显式包 | `pacman -Qqen` |
| `packages/aur.txt` | AUR 显式包 | `pacman -Qqem` |
| `packages/flatpak.txt` | Flatpak 应用，每行 `app_id<TAB>origin` | `flatpak list --app` |

系统上没装 flatpak 时会跳过、不生成 `flatpak.txt`。三份清单都由 `scripts/restore-packages.sh` 依次恢复（flatpak 层会先补 `flathub` remote 再逐个 `flatpak install -y`）。

> 注：`flatpak list` 不带 `--no-headers` 选项（1.18 实测会报「未知选项」），且在没有 UTF-8 locale 时**不打印列头**，所以不能用 `tail -n +2` 去表头——会误删第一条应用。导出规则按 app id 必含 `.` 过滤。

## 首次安装后需要做的事

### Matugen（配色生成）

运行 matugen 来根据当前壁纸生成所有主题配色：

```bash
matugen image /path/to/your/wallpaper.png
```

这会更新 starship、gtk、fuzzel、btop、cava、fastfetch 等所有 matugen 管理的配色文件。

### Rime 输入法

Rime 配置在 `config/fcitx5/rime/`。首次使用需要安装 rime-ice 字典：

```bash
# 安装 rime-ice 字典到 ~/.local/share/fcitx5/rime/
# 参考: https://github.com/iDvel/rime-ice
```

### Yazi 文件管理器

安装 flavors：

```bash
cd ~/.config/yazi
ya pack -i
```

### Neovim

首次启动 nvim 时 LazyVim 会自动安装插件。
