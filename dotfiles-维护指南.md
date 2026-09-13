# dotfiles 长期维护指南

> 本文件记录 `~/dotfiles` 仓库的结构、工作流与已知坑，供机器（hermes / Claude / 任何 agent）长期维护时参考。**每次改动前先读这里，避免破坏现有约定。**

## 1. 仓库概览

| 项 | 值 |
|---|---|
| 本地路径 | `~/dotfiles` |
| Git remote | `https://github.com/Alxkcx/dotfiles.git`（HTTPS，凭据由 gh 托管，见 4.6） |
| 默认分支 | `main` |
| 本地 user.name | `alexkazx23-beep`（GitHub 账号旧名，2026 已更名为 `Alxkcx`；署名沿用旧名，归属正常） |
| 本地 user.email | `alexkazx23@users.noreply.github.com` |
| 结构 | `config/` → `~/.config/`，`home/` → `~/`，符号链接管理 |

**重要：user.name/user.email 只在仓库本地设置了，全局未配置。** 换机器 clone 后必须重新设置，否则 commit 报"作者身份未知"。

```
~/dotfiles/
├── Makefile               # install / uninstall / update / packages
├── README.md
├── .gitignore
├── config/                # 符号链接到 ~/.config/ 各应用
│   ├── kitty niri fcitx5 fish fuzzel fastfetch btop matugen
│   ├── yazi mpv satty pacseek fontconfig gtk-3.0 gtk-4.0 qt5ct
│   ├── qt6ct xsettingsd environment.d cava nvim xdg-desktop-portal
│   ├── autostart chrome-flags.conf mimeapps.list user-dirs.dirs
│   └── systemd/user/      # 逐文件符号链接（见 4.5）
├── home/                  # 符号链接到 ~/
│   ├── dotfiles + bin/
└── packages/              # 包清单，由 `make packages` 生成
    ├── official.txt       # 官方源，约 218 个
    └── aur.txt            # AUR，约 20 个
```

## 2. 日常 Git 工作流

### 推送本地改动
```bash
cd ~/dotfiles && git add -A && git commit -m "sync: ..." && git push
```

### 从 GitHub 拉取
```bash
cd ~/dotfiles && git pull --rebase
```

### 只看远端
```bash
git fetch
```

### 新增/修改了系统配置后
1. 把文件复制进对应目录（`config/xxx/` 或 `home/`）
2. 检查是否是符号链接目标（避免复制到链接自身）
3. `git add -A && git commit && git push`

## 3. 网络 / 推送问题（重要）

> **2026-09-13 更新**：`origin` 现为 HTTPS `https://github.com/Alxkcx/dotfiles.git`，推送凭据由 `gh` 凭据助手提供（见 4.6），**默认路径已不走 SSH**。下面这段 SSH 假 IP 问题只在仍使用 SSH remote 时才需处理。

**现象**：偶尔会 `Connection closed by fdfe:dcba:9876::1e port 22` 或 push 一直卡住（假 IP 劫持）。

**原因**：Clash Verge Fake-IP 模式偶尔劫持 DNS / 22 端口。DNS 恢复后 SSH 仍可能连不上。

**fallback（用 HTTPS + 已存 token 推送）**：
```bash
cd ~/dotfiles && git -c http.proxy= -c https.proxy= push https://github.com/Alxkcx/dotfiles.git main
```
HTTPS 凭据由 `gh` 托管（`~/.config/gh/hosts.yml`，见 4.6）。SSH 不通时直接用这一条；如果 DNS 也被劫持，先去 Clash 把 `github.com` 加直连或关系统代理。

## 4. 已知的坑与约定（不要破坏）

### 4.1 排除项（.gitignore）
- `**/dank-colors.css` — matugen 生成的 GTK 配色（>100KB）
- `config/fish/fish_variables` — fish 会话状态，勿提交
- `config/yazi/flavors/*/preview.png` — 预览图 1.6MB，主题文件 `flavor.toml`/`tmtheme.xml` **必须保留**（否则 yazi 开不起主题）
- `config/fcitx5/rime/build/` + 字典目录 — rime 构建缓存（73MB+45MB），只跟踪用户配置和 lua 脚本
- `config/fcitx5/conf/cached_layouts` — 缓存

### 4.2 主题 / matugen
matugen 定期重新生成配色，会修改：gtk-3.0/gtk-4.0、kitty、starship、cava、btop、fastfetch、niri 的 `colors`/`settings`/`*.theme`、fuzzel 的 `colors.ini` 等。**这不是错误，是常态**，直接 commit `sync:` 即可。

### 4.3 文件管理器（DMS 接管已放弃）
试过让 DMS shell 接管文件管理器，**回退了**。当前仍走默认；Dolphin + KDE；包括：
- `portals.conf` 保留 `default=kde`、`FileChooser=kde`、`OpenURI=kde`
- `mimeapps.list` 默认 `org.kde.dolphin.desktop`
- systemd override 保留 `XDG_CURRENT_DESKTOP=KDE`
**不要**再试图改成 DMS shell，Chrome 走 gio 那套拦不住。

### 4.4 代理
`~/.config/environment.d/proxy.conf` **已删除**——用 systemd 强设代理会忽略 Clash 的系统代理开关。代理由 Clash Verge 自己管理，zshrc 里有 `proxy()` 函数手动开。

### 4.5 其他
- `~/.config/systemd/` 目录**不能整个符号链接**（里面有 pipewire 等系统链接）。`config/systemd/user/` 下的文件（`tt-sync.service`、`plasma-xdg-desktop-portal-kde.service.d/override.conf`）由 Makefile 的 install/uninstall **逐文件符号链接**，新增 unit 时把文件放进 `config/systemd/user/` 即可，不要改回整目录链接
- `config/mimeapps.list` 是符号链接（2026-08 起纳管），KDE 会不时重写它，产生 `sync:` 提交属正常 churn
- `config/starship.toml` 是 matugen 输出但**保留提交**（模板在 `config/matugen/templates/starship-colors.toml`）
- **KDE 应用配置刻意不进仓库**（2026-08 决定）：`kwinrc`/`kwinrulesrc`/`konsolerc`/`dolphinrc`/`kdeglobals`/`kcmfonts`/`plasmashellrc` 等——KDE 频繁重写导致 churn，且含会话状态（`kactivitymanagerdrc` 等）。维持现状，勿主动建议纳管

### 4.6 密钥存放约定（重要）
**本仓库是 public，任何 token / 私钥 / 密码都不得写进 `home/` 或 `config/`。**

- GitHub token 存放在 `~/.config/gh/hosts.yml`（权限 `0600`），**不在仓库内**。`gh` 自己读它，`git` 通过 `~/.gitconfig` 里的 `credential.https://github.com.helper = !gh auth git-credential` 也读它，所以 HTTPS 推送不需要任何环境变量
- **不要**再往 `.zshrc` 里写 `export GH_TOKEN=...`。2026-09-13 已移除，此前它明文躺在权限 0644 的文件里
- `gh` 在有 keyring 的机器上默认把 token 存 keyring；若要让它落到文件（跨环境更稳），直接把 `oauth_token` 写进 `hosts.yml` 即可，`gh auth status` 会显示来源为该文件路径
- 想确认凭据到底来自哪里：把 `~/.config/gh/hosts.yml` 临时移走再跑 `gh auth status`，若立刻显示未登录，说明文件才是真实来源
- **推送前体检**：
  ```bash
  cd ~/dotfiles
  grep -rInE "ghp_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9]{20,}|BEGIN [A-Z ]*PRIVATE KEY" . --exclude-dir=.git
  git log --all -S"ghp_" --oneline
  ```
- `.zshrc` 自 2026-09-13 起是符号链接 → `~/dotfiles/home/.zshrc`，与 `home/` 下其他文件一致，由 `make install` 维护。**直接编辑 `~/.zshrc` 等于编辑仓库文件**，注意别再把密钥写进去

## 5. 全新装机

```bash
git clone https://github.com/alexkazx23-beep/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash scripts/restore-packages.sh   # 装所有包（官方 + AUR）
make install                        # 符号链接
matugen image /path/to/wallpaper.png  # 生成主题
```
Rime 字典 / yazi 包等需要重新装（包清单不包含构建产物）。

## 6. Makefile 目标速查

| 命令 | 作用 |
|---|---|
| `make install` | 符号链接；已存在的目标文件自动备份 `.bak.时间戳` |
| `make uninstall` | 只删指向本仓库的链接 |
| `make update` | `git pull && make install` |
| `make packages` | 导出包清单到 `packages/` |

## 7. 部署后

无自动任务，仅手动 `make install`。首装后需 `matugen`、yazi `ya pack -i`、nvim 首启装插件。桌面可能要登录重登才生效。