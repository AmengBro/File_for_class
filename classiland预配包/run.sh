#!/bin/bash
# ============================================================
# 脚本：安装 ClassIsland 并恢复配置文件
# 功能：
#   1. 使用 sudo 安装 cn.classisland.app
#   2. 备份现有配置（如果有）
#   3. 解压 clc.tar 到 /home/uos/.config/ClassIsland
#      自动剥离压缩包内的顶层 "ClassIsland" 目录
#   4. 修复解压后文件的所有者（确保 uos 用户可写）
# ============================================================

set -e  # 遇到错误立即退出

# ---------- 颜色定义（便于阅读） ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ---------- 配置变量 ----------
USER_HOME="/home/uos"          # 目标用户主目录（可根据需要改为 $HOME）
CONFIG_DIR="$USER_HOME/.config/ClassIsland"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d%H%M%S)"
TAR_FILE="./clc.tar"           # 压缩包路径（相对于脚本执行目录）

# ---------- 函数：打印带颜色信息 ----------
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- 1. 提权准备 ----------
info "第一步：安装 ClassIsland"
info "正在获取 root 权限（请在弹出的提示中输入密码）"
sudo -v || error "无法获取 sudo 权限，请检查用户是否在 sudo 组中"

# ---------- 2. 安装软件包 ----------
info "从 apt 下载并安装 cn.classisland.app ..."
sudo apt update || warn "apt update 失败，但继续尝试安装"
sudo apt install -y cn.classisland.app || error "安装 cn.classisland.app 失败"

# ---------- 3. 备份已有配置 ----------
if [ -d "$CONFIG_DIR" ]; then
    BACKUP_DIR="${CONFIG_DIR}${BACKUP_SUFFIX}"
    warn "检测到已有配置目录，备份到：$BACKUP_DIR"
    mv "$CONFIG_DIR" "$BACKUP_DIR" || error "备份失败"
fi

# ---------- 4. 准备目标目录 ----------
info "创建配置目录：$CONFIG_DIR"
mkdir -p "$CONFIG_DIR" || error "无法创建目录 $CONFIG_DIR"

# ---------- 5. 检查并解压配置文件 ----------
if [ ! -f "$TAR_FILE" ]; then
    error "找不到压缩包 $TAR_FILE，请确保它与脚本在同一目录"
fi

info "正在解压配置文件到 $CONFIG_DIR ..."
# 使用 --strip-components=1 自动去除压缩包内的顶层目录（即 ClassIsland/）
tar -xf "$TAR_FILE" -C "$CONFIG_DIR" --strip-components=1 || error "解压失败"

# ---------- 6. 修复文件所有者（确保 uos 用户可读写） ----------
# 如果当前用户是 root 或者使用 sudo 运行，解压出来的文件可能属于 root
# 改为 uos 用户所有，保证桌面应用能正常读写配置
if [ -d "$CONFIG_DIR" ]; then
    info "修正文件所有者为 uos:uos ..."
    sudo chown -R uos:uos "$CONFIG_DIR" || warn "更改所有者失败，请手动执行：sudo chown -R uos:uos $CONFIG_DIR"
fi

# ---------- 7. 完成 ----------
info "✅ 安装与配置恢复完成！"
info "新配置位于：$CONFIG_DIR"
if [ -n "$BACKUP_DIR" ]; then
    info "旧配置备份于：$BACKUP_DIR"
fi
echo ""
echo "按 Enter 键退出此脚本（若通过启动器运行，启动器会等待）"
read -r