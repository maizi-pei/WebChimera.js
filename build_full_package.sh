#!/bin/bash

# WebChimera.js 完整打包脚本
# 模拟官方CI构建，创建包含VLC的完整发布包
# 支持 macOS、Linux、Windows

set -e

# 配置
VLC_VER="3.0.11"
ELECTRON_VER="12.0.9"
BUILD_DIR="./build/Release"
DEPS_DIR="./deps"

# 检测操作系统和架构
detect_system() {
    # 检测操作系统
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_NAME="osx"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        OS_NAME="linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
        OS_NAME="win32"
    else
        echo "警告: 未知操作系统 $OSTYPE，假设为 Linux"
        OS_TYPE="linux"
        OS_NAME="linux"
    fi
    
    # 检测架构
    SYSTEM_ARCH=$(uname -m 2>/dev/null || echo "unknown")
    case "$SYSTEM_ARCH" in
        "arm64"|"aarch64")
            ARCH="arm64"
            ;;
        "x86_64"|"AMD64")
            ARCH="x64"
            ;;
        "i386"|"i686")
            ARCH="ia32"
            ;;
        *)
            echo "警告: 未知架构 $SYSTEM_ARCH，假设为 x64"
            ARCH="x64"
            ;;
    esac
}

# 初始化系统检测
detect_system

# 设置平台特定的VLC下载URL和文件
case "$OS_TYPE" in
    "macos")
        VLC_URL="http://get.videolan.org/vlc/$VLC_VER/macosx/vlc-$VLC_VER.dmg"
        VLC_FILE="$DEPS_DIR/vlc-$VLC_VER.dmg"
        VLC_APP="$DEPS_DIR/VLC.app"
        ;;
    "windows")
        if [[ "$ARCH" == "x64" ]]; then
            VLC_URL="http://get.videolan.org/vlc/$VLC_VER/win64/vlc-$VLC_VER-win64.zip"
            VLC_FILE="$DEPS_DIR/vlc-$VLC_VER-win64.zip"
        else
            VLC_URL="http://get.videolan.org/vlc/$VLC_VER/win32/vlc-$VLC_VER-win32.zip"
            VLC_FILE="$DEPS_DIR/vlc-$VLC_VER-win32.zip"
        fi
        VLC_DIR="$DEPS_DIR/vlc-$VLC_VER"
        ;;
    "linux")
        print_error "Linux 需要通过包管理器安装 VLC，然后手动打包"
        print_info "Ubuntu/Debian: sudo apt-get install libvlc-dev"
        print_info "CentOS/RHEL: sudo yum install vlc-devel"
        exit 1
        ;;
esac

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查依赖
check_dependencies() {
    print_info "检查构建依赖..."
    
    if [[ ! -f "$BUILD_DIR/WebChimera.js.node" ]]; then
        print_error "WebChimera.js.node 不存在，请先运行构建"
        case "$OS_TYPE" in
            "windows")
                print_info "Windows 用户运行: build_electron.cmd 或 ./build_electron.sh"
                ;;
            *)
                print_info "运行: ./build_electron.sh"
                ;;
        esac
        exit 1
    fi
    
    # 验证编译文件的架构
    if command -v file &> /dev/null; then
        BINARY_ARCH=$(file "$BUILD_DIR/WebChimera.js.node" | grep -o "arm64\|x86_64\|i386" | head -1)
        if [[ -n "$BINARY_ARCH" ]]; then
            case "$BINARY_ARCH" in
                "arm64") DETECTED_ARCH="arm64" ;;
                "x86_64") DETECTED_ARCH="x64" ;;
                "i386") DETECTED_ARCH="ia32" ;;
            esac
            
            if [[ "$DETECTED_ARCH" != "$ARCH" ]]; then
                print_warning "检测到架构不匹配："
                print_warning "系统架构: $SYSTEM_ARCH ($ARCH)"
                print_warning "二进制架构: $BINARY_ARCH ($DETECTED_ARCH)"
            fi
        fi
    fi
    
    # 检查平台特定工具
    case "$OS_TYPE" in
        "macos")
            if ! command -v hdiutil &> /dev/null; then
                print_error "hdiutil 命令不存在"
                exit 1
            fi
            ;;
        "windows")
            if ! command -v unzip &> /dev/null; then
                print_warning "unzip 命令不存在，尝试使用其他解压方法"
            fi
            ;;
    esac
    
    print_success "依赖检查通过"
    print_info "目标平台: $OS_TYPE $ARCH ($SYSTEM_ARCH)"
}

# 下载和安装VLC
download_vlc() {
    print_info "准备VLC $VLC_VER..."
    
    mkdir -p "$DEPS_DIR"
    
    case "$OS_TYPE" in
        "macos")
            download_vlc_macos
            ;;
        "windows")
            download_vlc_windows
            ;;
        "linux")
            print_info "Linux 平台跳过 VLC 下载"
            ;;
    esac
}

# macOS VLC 下载
download_vlc_macos() {
    # 清理可能有问题的代理设置
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    
    if [[ ! -f "$VLC_FILE" ]]; then
        print_info "下载 VLC $VLC_VER for macOS..."
        print_info "URL: $VLC_URL"
        
        # 使用更安全的curl选项
        if curl --version &> /dev/null; then
            if curl -L --fail --retry 3 --retry-delay 5 -o "$VLC_FILE" "$VLC_URL"; then
                print_success "VLC 下载完成"
            else
                print_error "VLC 下载失败"
                print_info "请检查网络连接或手动下载:"
                print_info "$VLC_URL"
                exit 1
            fi
        else
            print_error "curl 命令不可用"
            print_info "请手动下载 VLC 并放置到: $VLC_FILE"
            exit 1
        fi
    else
        print_info "VLC DMG 已存在，跳过下载"
    fi
    
    if [[ ! -d "$VLC_APP" ]]; then
        print_info "挂载和提取 VLC.app..."
        if hdiutil mount "$VLC_FILE"; then
            if cp -R "/Volumes/VLC media player/VLC.app" "$DEPS_DIR/"; then
                print_success "VLC.app 提取完成"
            else
                print_error "VLC.app 复制失败"
                hdiutil unmount "/Volumes/VLC media player" 2>/dev/null || true
                exit 1
            fi
            hdiutil unmount "/Volumes/VLC media player"
        else
            print_error "VLC DMG 挂载失败"
            exit 1
        fi
    else
        print_info "VLC.app 已存在，跳过提取"
    fi
}

# Windows VLC 下载
download_vlc_windows() {
    # 清理可能有问题的代理设置
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    
    if [[ ! -f "$VLC_FILE" ]]; then
        print_info "下载 VLC $VLC_VER for Windows ($ARCH)..."
        print_info "URL: $VLC_URL"
        
        # 使用更安全的curl选项
        if curl --version &> /dev/null; then
            if curl -L --fail --retry 3 --retry-delay 5 -o "$VLC_FILE" "$VLC_URL"; then
                print_success "VLC 下载完成"
            else
                print_error "VLC 下载失败"
                print_info "请检查网络连接或手动下载:"
                print_info "$VLC_URL"
                exit 1
            fi
        else
            print_error "curl 命令不可用"
            print_info "请手动下载 VLC 并放置到: $VLC_FILE"
            exit 1
        fi
    else
        print_info "VLC ZIP 已存在，跳过下载"
    fi
    
    if [[ ! -d "$VLC_DIR" ]]; then
        print_info "解压 VLC..."
        cd "$DEPS_DIR"
        
        # 尝试多种解压方法
        if command -v unzip &> /dev/null; then
            if unzip -q "$(basename "$VLC_FILE")"; then
                print_success "使用 unzip 解压成功"
            else
                print_error "unzip 解压失败"
                exit 1
            fi
        elif command -v 7z &> /dev/null; then
            if 7z x "$(basename "$VLC_FILE")" -y; then
                print_success "使用 7z 解压成功"
            else
                print_error "7z 解压失败"
                exit 1
            fi
        elif command -v tar &> /dev/null && [[ -f /usr/bin/tar ]]; then
            # 某些Windows环境下tar可能支持zip
            if tar -xf "$(basename "$VLC_FILE")" 2>/dev/null; then
                print_success "使用 tar 解压成功"
            else
                print_error "tar 解压失败"
                print_error "无法解压 VLC ZIP 文件"
                print_info "请手动安装 unzip 或 7-Zip"
                exit 1
            fi
        else
            print_error "未找到解压工具 (unzip/7z)"
            print_info "请安装 unzip 或 7-Zip"
            exit 1
        fi
        
        # 重命名解压后的目录
        for dir in vlc-*; do
            if [[ -d "$dir" && "$dir" != "$(basename "$VLC_DIR")" ]]; then
                mv "$dir" "$(basename "$VLC_DIR")"
                break
            fi
        done
        
        cd - > /dev/null
        print_success "VLC 解压完成"
    else
        print_info "VLC 目录已存在，跳过解压"
    fi
}

# 创建完整包
create_full_package() {
    print_info "创建完整发布包..."
    
    # 设置输出目录
    PACKAGE_NAME="WebChimera.js_v0.3.1_electron_v${ELECTRON_VER}_VLC_v${VLC_VER}_${ARCH}_${OS_NAME}"
    OUT_DIR="$BUILD_DIR/webchimera.js"
    
    case "$OS_TYPE" in
        "windows")
            ARCHIVE_PATH="$BUILD_DIR/${PACKAGE_NAME}.zip"
            ;;
        *)
            ARCHIVE_PATH="$BUILD_DIR/${PACKAGE_NAME}.tar.gz"
            ;;
    esac
    
    # 清理旧的输出目录
    rm -rf "$OUT_DIR"
    mkdir -p "$OUT_DIR"
    
    print_info "复制 WebChimera.js.node..."
    cp -f "$BUILD_DIR/WebChimera.js.node" "$OUT_DIR/"
    
    print_info "创建 index.js..."
    echo "module.exports = require('./WebChimera.js.node')" > "$OUT_DIR/index.js"
    
    case "$OS_TYPE" in
        "macos")
            create_package_macos
            ;;
        "windows")
            create_package_windows
            ;;
        "linux")
            create_package_linux
            ;;
    esac
    
    print_info "创建 package.json..."
    cat > "$OUT_DIR/package.json" << EOF
{
  "name": "webchimera.js",
  "version": "0.3.1",
  "description": "libvlc binding for Electron - Full Package with VLC $VLC_VER",
  "main": "index.js",
  "keywords": ["vlc", "libvlc", "video", "player", "electron"],
  "license": "LGPL-2.1",
  "engines": {
    "electron": "^$ELECTRON_VER"
  },
  "os": ["$OS_NAME"],
  "cpu": ["$ARCH"]
}
EOF
    
    # 打包
    print_info "创建发布包..."
    case "$OS_TYPE" in
        "windows")
            create_zip_package
            ;;
        *)
            create_tar_package
            ;;
    esac
    
    # 计算文件大小
    ARCHIVE_SIZE=$(wc -c < "$ARCHIVE_PATH" 2>/dev/null || stat -c%s "$ARCHIVE_PATH" 2>/dev/null || echo "0")
    ARCHIVE_SIZE_MB=$((ARCHIVE_SIZE / 1024 / 1024))
    
    print_success "完整包创建成功!"
    print_info "文件: $ARCHIVE_PATH"
    print_info "大小: ${ARCHIVE_SIZE_MB} MB"
    print_info "平台: $OS_TYPE $ARCH (检测自 $SYSTEM_ARCH)"
    
    # 显示包内容
    print_info "包内容预览:"
    case "$OS_TYPE" in
        "windows")
            if command -v unzip &> /dev/null; then
                unzip -l "$ARCHIVE_PATH" | head -20
            else
                print_info "安装 unzip 以查看包内容"
            fi
            ;;
        *)
            tar -tzf "$ARCHIVE_PATH" | head -20
            if [[ $(tar -tzf "$ARCHIVE_PATH" | wc -l) -gt 20 ]]; then
                echo "... 还有 $(($(tar -tzf "$ARCHIVE_PATH" | wc -l) - 20)) 个文件"
            fi
            ;;
    esac
}

# macOS 包创建
create_package_macos() {
    print_info "复制 VLC 动态库..."
    mkdir -p "$OUT_DIR/lib"
    cp -R "$VLC_APP/Contents/MacOS/lib"/*.dylib "$OUT_DIR/lib/" 2>/dev/null || true
    
    print_info "复制 VLC 插件..."
    mkdir -p "$OUT_DIR/lib/vlc"
    cp -R "$VLC_APP/Contents/MacOS/plugins" "$OUT_DIR/lib/vlc/" 2>/dev/null || true
    
    print_info "复制 VLC Lua 脚本..."
    mkdir -p "$OUT_DIR/lib/vlc/share/lua"
    if [[ -d "$VLC_APP/Contents/MacOS/share/lua" ]]; then
        cp -R "$VLC_APP/Contents/MacOS/share/lua/extensions" "$OUT_DIR/lib/vlc/share/lua/" 2>/dev/null || true
        cp -R "$VLC_APP/Contents/MacOS/share/lua/modules" "$OUT_DIR/lib/vlc/share/lua/" 2>/dev/null || true
        cp -R "$VLC_APP/Contents/MacOS/share/lua/playlist" "$OUT_DIR/lib/vlc/share/lua/" 2>/dev/null || true
    fi
    
    print_info "创建符号链接..."
    mkdir -p "$OUT_DIR/lib/vlc/lib"
    if [[ -f "$OUT_DIR/lib/libvlccore.9.dylib" ]]; then
        ln -sf ../../libvlccore.9.dylib "$OUT_DIR/lib/vlc/lib/libvlccore.9.dylib"
    fi
}

# Windows 包创建
create_package_windows() {
    if [[ -d "$VLC_DIR" ]]; then
        print_info "复制 VLC DLL 文件..."
        
        # 复制主要的VLC DLL文件到根目录（与正确结构一致）
        if [[ -f "$VLC_DIR/libvlc.dll" ]]; then
            cp "$VLC_DIR/libvlc.dll" "$OUT_DIR/"
            print_info "复制 libvlc.dll"
        fi
        if [[ -f "$VLC_DIR/libvlccore.dll" ]]; then
            cp "$VLC_DIR/libvlccore.dll" "$OUT_DIR/"
            print_info "复制 libvlccore.dll"
        fi
        
        print_info "复制 VLC 插件..."
        if [[ -d "$VLC_DIR/plugins" ]]; then
            # 插件直接复制到 plugins/ 目录（与正确结构一致）
            cp -R "$VLC_DIR/plugins" "$OUT_DIR/"
            print_info "复制插件目录到 plugins/"
        fi
        
        # 不复制其他 DLL 文件和 Lua 脚本，保持简洁结构
        print_info "Windows 包结构:"
        print_info "- WebChimera.js.node"
        print_info "- index.js"
        print_info "- package.json"
        print_info "- libvlc.dll"
        print_info "- libvlccore.dll"
        print_info "- plugins/ (VLC 插件目录)"
    else
        print_warning "VLC 目录不存在，跳过 VLC 文件复制"
    fi
}

# Linux 包创建
create_package_linux() {
    print_info "Linux 平台: 创建最小包（不包含VLC）"
    print_warning "用户需要自行安装 VLC: sudo apt-get install vlc"
}

# 创建 ZIP 包（Windows）
create_zip_package() {
    if command -v zip &> /dev/null; then
        print_info "使用 zip 创建包..."
        cd "$BUILD_DIR"
        zip -r "$(basename "$ARCHIVE_PATH")" webchimera.js/
        cd - > /dev/null
    elif command -v 7z &> /dev/null; then
        print_info "使用 7z 创建包..."
        7z a "$ARCHIVE_PATH" "$OUT_DIR"
    else
        # 在 Windows 上查找常见的 7-Zip 安装路径
        SEVENZIP_PATHS=(
            "/c/Program Files/7-Zip/7z.exe"
            "/c/Program Files (x86)/7-Zip/7z.exe"
            "C:/Program Files/7-Zip/7z.exe"
            "C:/Program Files (x86)/7-Zip/7z.exe"
            "/mnt/c/Program Files/7-Zip/7z.exe"
            "/mnt/c/Program Files (x86)/7-Zip/7z.exe"
        )
        
        SEVENZIP_FOUND=""
        for path in "${SEVENZIP_PATHS[@]}"; do
            if [[ -f "$path" ]]; then
                SEVENZIP_FOUND="$path"
                break
            fi
        done
        
        if [[ -n "$SEVENZIP_FOUND" ]]; then
            print_info "找到 7-Zip: $SEVENZIP_FOUND"
            print_info "使用 7-Zip 创建包..."
            "$SEVENZIP_FOUND" a "$ARCHIVE_PATH" "$OUT_DIR"
        elif [[ "$OS_TYPE" == "windows" ]]; then
            # 尝试使用 PowerShell 的 Compress-Archive（Windows 10+）
            print_info "尝试使用 PowerShell Compress-Archive..."
            
            # 转换路径格式
            WIN_ARCHIVE_PATH=$(echo "$ARCHIVE_PATH" | sed 's|^/c/|C:/|' | sed 's|/|\\|g')
            WIN_OUT_DIR=$(echo "$OUT_DIR" | sed 's|^/c/|C:/|' | sed 's|/|\\|g')
            
            if powershell.exe -Command "Compress-Archive -Path '$WIN_OUT_DIR' -DestinationPath '$WIN_ARCHIVE_PATH' -Force" 2>/dev/null; then
                print_success "使用 PowerShell 创建包成功"
            else
                print_error "PowerShell 压缩失败"
                print_error "未找到打包工具"
                print_info "请安装以下任一工具:"
                print_info "1. 7-Zip: https://www.7-zip.org/"
                print_info "2. WinRAR"
                print_info "3. 或添加 7z.exe 到 PATH 环境变量"
                exit 1
            fi
        else
            print_error "未找到打包工具 (zip/7z)"
            print_info "请安装 zip 或 7-Zip"
            exit 1
        fi
    fi
}

# 创建 TAR.GZ 包（macOS/Linux）
create_tar_package() {
    tar -czf "$ARCHIVE_PATH" -C "$BUILD_DIR" webchimera.js
}

# 清理函数
cleanup() {
    if [[ -d "$OUT_DIR" ]]; then
        print_info "清理临时目录..."
        rm -rf "$OUT_DIR"
    fi
}

# 主函数
main() {
    print_info "开始创建 WebChimera.js 完整发布包..."
    print_info "目标: Electron $ELECTRON_VER + VLC $VLC_VER ($OS_TYPE $ARCH)"
    
    trap cleanup EXIT
    
    check_dependencies
    download_vlc
    create_full_package
    
    print_success "构建完成! 🎉"
    print_info "使用方法:"
    case "$OS_TYPE" in
        "windows")
            print_info "1. 解压: unzip $ARCHIVE_PATH"
            print_info "2. 在Electron项目中: npm install ./webchimera.js"
            ;;
        *)
            print_info "1. 解压: tar -xzf $ARCHIVE_PATH"
            print_info "2. 在Electron项目中: npm install ./webchimera.js"
            ;;
    esac
}

# 显示帮助
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat << EOF
WebChimera.js 完整打包脚本

用法: $0

功能:
- 自动检测系统架构和平台 (macOS/Linux/Windows)
- 下载指定版本的VLC
- 创建包含VLC库的完整发布包
- 生成可直接使用的发布包

支持平台:
- macOS (Intel/ARM64) - tar.gz
- Linux (x64/ARM64) - tar.gz (不包含VLC)
- Windows (x64/ia32) - zip

要求:
- 已编译的 WebChimera.js.node
- 网络连接 (下载VLC)
- Windows: Git Bash/WSL + unzip/7z

输出:
- build/Release/WebChimera.js_v0.3.1_electron_v${ELECTRON_VER}_VLC_v${VLC_VER}_[arch]_[platform].[ext]

当前系统信息:
- 平台: $(uname -s 2>/dev/null || echo "Unknown")
- 架构: $(uname -m 2>/dev/null || echo "Unknown")
- 环境: $OSTYPE
EOF
    exit 0
fi

main "$@" 