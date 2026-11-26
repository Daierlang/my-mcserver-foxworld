#!/usr/bin/env bash
# =============================================================================
# 酒狐 MC 服务器 Linux 启动脚本（与 start.bat 等价）
# 服务端：Minecraft 1.21.1 + NeoForge 21.1.267
#
# 用法：
#   1) 首次使用先加执行权限：chmod +x start.sh
#      （本文件在 Windows 上无法真正 chmod，拷到 Linux 后务必执行一次）
#   2) 启动：./start.sh
#   3) 后台常驻建议用 screen 或 tmux，断开 SSH 服务器不掉线：
#        screen -S mc ./start.sh      # Ctrl+A 再按 D 脱离；screen -r mc 回来
#        tmux new -s mc ./start.sh    # Ctrl+B 再按 D 脱离；tmux attach -t mc 回来
#   4) 直接关服可在控制台输入 stop，或按 Ctrl+C
#
# 注意：
#   - 本文件必须保持 LF 换行、UTF-8 无 BOM。在 Windows 上编辑时请使用
#     VS Code / Notepad++ 等支持 LF 的编辑器，不要用记事本另存。
#   - 启动命令后的额外参数会原样传给 java（与 start.bat 的 %* 一致）。
# =============================================================================
set -euo pipefail

# 始终以脚本所在目录为工作目录（等价于 start.bat 的 cd /d "%~dp0"）
cd "$(dirname "$0")" || exit 1

# 检查 java 是否可用（Linux 端需自行安装 Java 21）
if ! command -v java >/dev/null 2>&1; then
    echo "[错误] 未找到 java 命令。请先安装 Java 21（如 apt install openjdk-21-jre-headless）" >&2
    exit 1
fi

# 确保日志目录存在
mkdir -p logs

echo "[酒狐] 正在启动服务器，输出同时显示在终端并追加写入 logs/start_console.log"

# 临时关闭 errexit 以捕获服务器退出码（pipefail 下管道返回 java 的退出码）
set +e
java @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.267/unix_args.txt nogui "$@" 2>&1 | tee -a logs/start_console.log
EXIT_CODE=$?
set -e

echo
echo "[酒狐] 服务器已退出，退出码：$EXIT_CODE"
echo "[酒狐] 日志请查看：logs/latest.log 与 logs/start_console.log"
exit "$EXIT_CODE"
