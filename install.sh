#!/bin/bash
set -e

echo "🌙 nosleepclub 安装中..."
echo ""

INSTALL_DIR="${HOME}/.local/bin"
TMP_DIR=$(mktemp -d)
REPO="https://github.com/haoxli0412-spec/nosleepclub.git"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$INSTALL_DIR"

if ! command -v swift &>/dev/null; then
    echo "❌ 需要 Swift 编译器。请先安装 Xcode Command Line Tools："
    echo "   xcode-select --install"
    exit 1
fi

SW_VER=$(sw_vers -productVersion | cut -d. -f1)
if [ "$SW_VER" -lt 14 ]; then
    echo "❌ 需要 macOS 14 (Sonoma) 或更高版本，当前版本：$(sw_vers -productVersion)"
    exit 1
fi

echo "📥 下载源码..."
git clone --depth 1 "$REPO" "$TMP_DIR/nosleepclub" 2>/dev/null

echo "🔨 编译中..."
cd "$TMP_DIR/nosleepclub"
swift build -c release 2>/dev/null

echo "📦 安装到 $INSTALL_DIR..."
cp .build/release/nosleepclub "$INSTALL_DIR/nosleepclub"
chmod +x "$INSTALL_DIR/nosleepclub"
codesign --force --sign - "$INSTALL_DIR/nosleepclub" 2>/dev/null

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    SHELL_RC=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    if [ -n "$SHELL_RC" ] && ! grep -q '.local/bin' "$SHELL_RC" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        echo "📝 已将 ~/.local/bin 添加到 PATH（$SHELL_RC）"
    fi
    export PATH="$INSTALL_DIR:$PATH"
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "使用方法："
echo "  nosleepclub          # 启动（然后可以合盖）"
echo "  nosleepclub &        # 后台运行"
echo "  pkill -f nosleepclub # 停止"
echo ""
echo "⚠️  记得接上电源，macOS clamshell 模式需要电源。"
