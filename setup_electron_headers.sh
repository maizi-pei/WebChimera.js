#!/bin/bash

# WebChimera.js Electron Headers Setup Script
# 自动下载并配置 Electron 头文件，绕过 atom.io 下载问题

set -e

# 默认配置
DEFAULT_VERSION="12.0.9"
CACHE_DIR="$HOME/.cmake-js"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 帮助函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助
show_help() {
    cat << EOF
WebChimera.js Electron Headers Setup Script

用法:
    $0 [选项]

选项:
    -v, --version VERSION   指定 Electron 版本 (默认: $DEFAULT_VERSION)
    -p, --proxy PROXY_URL   设置代理 (格式: http://127.0.0.1:7890)
    -h, --help             显示此帮助信息

示例:
    $0                                    # 使用默认版本 $DEFAULT_VERSION
    $0 -v 11.1.0                        # 使用指定版本
    $0 -v 12.0.9 -p http://127.0.0.1:7890  # 使用代理下载

支持的版本:
    - 12.0.9 (推荐)
    - 11.1.0
    - 16.2.8 (可能需要代码修改)
EOF
}

# 解析命令行参数
ELECTRON_VERSION="$DEFAULT_VERSION"
PROXY_URL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            ELECTRON_VERSION="$2"
            shift 2
            ;;
        -p|--proxy)
            PROXY_URL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

print_info "开始设置 Electron $ELECTRON_VERSION 头文件..."

# 设置代理
if [[ -n "$PROXY_URL" ]]; then
    print_info "设置代理: $PROXY_URL"
    export https_proxy="$PROXY_URL"
    export http_proxy="$PROXY_URL"
    export all_proxy="$PROXY_URL"
fi

# 检测系统架构
ARCH=$(uname -m)
print_info "检测到系统架构: $ARCH"

# 创建目录结构
print_info "创建缓存目录结构..."
mkdir -p "$CACHE_DIR/electron/v$ELECTRON_VERSION"

if [[ "$ARCH" == "arm64" ]]; then
    mkdir -p "$CACHE_DIR/electron-arm64/v$ELECTRON_VERSION"
fi

# 下载头文件
DOWNLOAD_URL="https://electronjs.org/headers/v$ELECTRON_VERSION/node-v$ELECTRON_VERSION-headers.tar.gz"
TARGET_FILE="$CACHE_DIR/electron/v$ELECTRON_VERSION/node-v$ELECTRON_VERSION.tar.gz"

print_info "从官方源下载头文件..."
print_info "URL: $DOWNLOAD_URL"

if curl -L -f -o "$TARGET_FILE" "$DOWNLOAD_URL"; then
    print_success "头文件下载成功"
else
    print_error "下载失败，请检查网络连接和版本号"
    exit 1
fi

# 验证下载的文件
FILE_SIZE=$(wc -c < "$TARGET_FILE")
if [[ $FILE_SIZE -lt 10000 ]]; then
    print_error "下载的文件太小，可能下载失败"
    exit 1
fi

print_success "文件大小: $(($FILE_SIZE / 1024)) KB"

# 解压文件
print_info "解压头文件..."
cd "$CACHE_DIR/electron/v$ELECTRON_VERSION"
tar -xzf "node-v$ELECTRON_VERSION.tar.gz"
print_success "解压完成"

# ARM64 特殊处理
if [[ "$ARCH" == "arm64" ]]; then
    print_info "配置 ARM64 架构特定目录..."
    
    ARM64_DIR="$CACHE_DIR/electron-arm64/v$ELECTRON_VERSION"
    cp "node-v$ELECTRON_VERSION.tar.gz" "$ARM64_DIR/"
    
    cd "$ARM64_DIR"
    tar -xzf "node-v$ELECTRON_VERSION.tar.gz"
    
    # 创建 cmake-js 期望的目录结构
    mkdir -p src
    cp -r node_headers src/
    
    print_success "ARM64 目录配置完成"
fi

# 更新构建脚本
print_info "更新构建脚本..."
BUILD_SCRIPT="build_electron.sh"

cat > "$BUILD_SCRIPT" << EOF
#!/bin/sh

export npm_config_wcjs_runtime="electron"
export npm_config_wcjs_runtime_version="$ELECTRON_VERSION"

npm install
EOF

chmod +x "$BUILD_SCRIPT"
print_success "构建脚本已更新: $BUILD_SCRIPT"

# 显示目录结构
print_info "验证目录结构..."
if [[ "$ARCH" == "arm64" ]]; then
    MAIN_DIR="$CACHE_DIR/electron-arm64/v$ELECTRON_VERSION"
else
    MAIN_DIR="$CACHE_DIR/electron/v$ELECTRON_VERSION"
fi

if [[ -f "$MAIN_DIR/node-v$ELECTRON_VERSION.tar.gz" ]] && [[ -d "$MAIN_DIR/node_headers" ]]; then
    print_success "目录结构验证通过"
else
    print_error "目录结构验证失败"
    exit 1
fi

# 完成提示
print_success "Electron $ELECTRON_VERSION 头文件设置完成！"
echo ""
print_info "接下来的步骤:"
print_info "1. 运行构建: ./build_electron.sh"
print_info "2. 或者直接运行: npm install"
print_info "3. 检查生成的文件: ls -la build/Release/"
echo ""
print_warning "注意: 如果遇到 V8 API 兼容性问题，建议使用 Electron 12.0.9" 