export PATH="$HOME/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export LANGUAGE="zh_Hans:zh_CN:zh"
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin"
# 不手写 XDG_DATA_DIRS：交给 /etc/profile.d/flatpak.sh 动态计算
# （手写容易漏掉 flatpak installation 的 exports/share 路径，会导致
#   flatpak 报 "目录不在 XDG_DATA_DIRS 搜索路径中" 警告）
export TERMINAL=kitty
