# Created by newuser for 5.
# 设置历史记录文件的路径
HISTFILE=~/.zsh_history

# 设置在会话（内存）中和历史文件中保存的条数，建议设置得大一些
HISTSIZE=1000
SAVEHIST=1000

# 忽略重复的命令，连续输入多次的相同命令只记一次
setopt HIST_IGNORE_DUPS

# 忽略以空格开头的命令（用于临时执行一些你不想保存的敏感命令）
setopt HIST_IGNORE_SPACE

# 在多个终端之间实时共享历史记录 
# 这是实现多终端同步最关键的选项
setopt SHARE_HISTORY

# 让新的历史记录追加到文件，而不是覆盖
setopt APPEND_HISTORY
# 在历史记录中记录命令的执行开始时间和持续时间
setopt EXTENDED_HISTORY

# 自动补全
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# 语法检查
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#开启tab上下左右选择补全
zstyle ':completion:*' menu select
autoload -Uz compinit
compinit

#开启starship
eval "$(starship init zsh)"

#Comfyui 对应的脚本位置
comfy() {
    if [ "$1" = "update" ]; then
        "$HOME/bin/comfy_update"
    else
        "$HOME/bin/start_comfy"
    fi
}
alias llama="$HOME/bin/start_llama"
alias cs="$HOME/bin/character-select"
alias anima="$HOME/bin/start-anima"
alias lora="$HOME/bin/start-lora"
alias am="cd /home/Alexkazx/AI_Workspace/AnimaDex && ./run.sh"
alias mds="$HOME/bin/run_mds.sh"
# Clash Verge 代理配置
proxy() {
    if [ "$1" = "on" ]; then
        # 统一大小写，全部注入，确保 100% 兼容性
        export http_proxy="http://127.0.0.1:7890"
        export https_proxy="http://127.0.0.1:7890"
        export HTTP_PROXY="http://127.0.0.1:7890"
        export HTTPS_PROXY="http://127.0.0.1:7890"
        export all_proxy="socks5h://127.0.0.1:7890"
        export ALL_PROXY="socks5h://127.0.0.1:7890"
        echo "✅ 终端代理已开启 (Port: 7890)"
    elif [ "$1" = "off" ]; then
        # 彻底清除所有相关环境变量，一个不留
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
        echo "❌ 终端代理已关闭"
    else
        # 更加直观的状态查看
        if [ -n "$all_proxy" ]; then
            echo "💡 当前代理状态：已开启"
            echo "   HTTP  代理: $http_proxy"
            echo "   SOCKS 代理: $all_proxy"
        else
            echo "⚪ 当前代理状态：已关闭"
        fi
    fi
}

#默认文本编辑器为nvim
export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
# >>> mamba initialize >>>
# !! Contents within this block are managed by 'micromamba shell init' !!
export MAMBA_EXE='/usr/bin/micromamba';
export MAMBA_ROOT_PREFIX='/home/Alexkazx/micromamba';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"  # Fallback on help from micromamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/Alexkazx/.lmstudio/bin"
# End of LM Studio CLI section

# === 二次元 Miku 看板娘时间问候函数 ===
miku_greet() {
    # 局部变量保护，防止污染你的全局终端环境
    local LANG="zh_CN.UTF-8"
    local LC_ALL="zh_CN.UTF-8"
    local LANGUAGE="zh_Hans:zh_CN:zh"
    local CURRENT_HOUR=${1:-$(date +%-H)}
    local MSG MODE COLOR THEME_CHOICE

    if [ $CURRENT_HOUR -ge 5 ] && [ $CURRENT_HOUR -lt 9 ]; then
        MSG="主人, 早上好! 今天起得真早, 新的一天打算敲点什么呢?"
    elif [ $CURRENT_HOUR -ge 9 ] && [ $CURRENT_HOUR -lt 12 ]; then
        MSG="主人, 上午好! 今天也是元气满满, 打算敲点什么呢?"
    elif [ $CURRENT_HOUR -ge 12 ] && [ $CURRENT_HOUR -lt 14 ]; then
        MSG="主人, 中午好! 午饭吃饱了吗? 休息之余打算敲点什么呢?"
    elif [ $CURRENT_HOUR -ge 14 ] && [ $CURRENT_HOUR -lt 18 ]; then
        MSG="主人, 下午好! 累了就要起来活动一下哦, 现在打算敲点什么呢?"
    elif [ $CURRENT_HOUR -ge 18 ] && [ $CURRENT_HOUR -lt 23 ]; then
        MSG="主人, 晚上好! 欢迎回到终端! 今天打算敲点什么呢?"
    else
        MSG="主人, 夜深了... 怎么还在爆肝? 注意身体, 写完这段就快去睡觉吧, 今晚打算敲点什么呢?"
    fi

    echo ""
    THEME_CHOICE=$((RANDOM % 6))
    MODE="--gradient"

    case $THEME_CHOICE in
        0) MODE="--rainbow" ;;
        1) COLOR="#FFC0CB:#FF1493" ;; # 🌸 猛男樱花粉
        2) COLOR="#39C5BB:#1A7A73" ;; # 🟢 正统大葱绿
        3) COLOR="#00FFFF:#8A2BE2" ;; # 🔮 赛博魅惑紫
        4) COLOR="#FFA07A:#FF4500" ;; # 🍊 活力暖橙
        5) COLOR="#00C6FF:#0072FF" ;; # 🔹 科技冰蓝
    esac

    if [ "$MODE" = "--rainbow" ]; then
        mikusays -s 2 --rainbow "$MSG"
    else
        mikusays -s 2 --gradient "$COLOR" "$MSG"
    fi
    echo ""
}

# 🎯 在终端启动时自动运行一次
miku_greet
export SUDO_ASKPASS="$HOME/.local/bin/askpass.sh"

# >>> Claude Code Haha PATH >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< Claude Code Haha PATH <<<

# npm global dir
export PATH="$HOME/.npm-global/bin:$PATH"

# opencode: 禁用启动时拉取模型目录(3.4MB),避免卡启动
export OPENCODE_DISABLE_MODELS_FETCH=1
