# WebChimera.js Windows 支持指南

本指南详细说明如何在 Windows 环境下编译和打包 WebChimera.js。

## 🔧 环境要求

### 必需工具

1. **Node.js** (推荐 LTS 版本)
   - 下载: https://nodejs.org/
   - 选择 "Windows Installer (.msi)"

2. **Visual Studio Build Tools**
   - 下载: https://visualstudio.microsoft.com/visual-cpp-build-tools/
   - 或安装完整版 Visual Studio 2019/2022

3. **Git for Windows** (推荐)
   - 下载: https://git-scm.com/download/win
   - 包含 Git Bash 环境

### 可选工具

4. **7-Zip** 或 **WinRAR**
   - 用于解压 VLC 压缩包
   - 7-Zip: https://www.7-zip.org/

5. **WSL (Windows Subsystem for Linux)**
   - 作为 Git Bash 的替代方案

## 📋 支持的架构

- **x64** (64位) - 主要支持
- **ia32** (32位) - 有限支持

## 🚀 快速开始

### 1. 环境验证

在命令提示符或 PowerShell 中检查：

```cmd
node --version
npm --version
git --version
```

### 2. 设置 Electron 头文件

**方法1: 使用命令提示符 (推荐)**
```cmd
REM 默认版本
setup_electron_headers.cmd

REM 指定版本
setup_electron_headers.cmd -v 12.0.9

REM 使用代理
setup_electron_headers.cmd -v 12.0.9 -p http://127.0.0.1:7890
```

**方法2: 使用 Git Bash**
```bash
# 在 Git Bash 中运行
./setup_electron_headers.sh -v 12.0.9
```

### 3. 编译 WebChimera.js

**Git Bash:**
```bash
./build_electron.sh
```

**命令提示符:**
```cmd
set npm_config_wcjs_runtime=electron
set npm_config_wcjs_runtime_version=12.0.9
npm install
```

### 4. 创建完整包

**Git Bash:**
```bash
./build_full_package.sh
```

**命令提示符:**
```cmd
build_full_package.cmd
```

## 🔍 故障排除

### 常见问题

#### 1. "python 不是内部或外部命令"

**解决方案:**
```cmd
# 安装 Python (cmake-js 需要)
npm install -g windows-build-tools
# 或手动安装 Python 3.x
```

#### 2. "MSBuild 不是内部或外部命令"

**解决方案:**
- 确保安装了 Visual Studio Build Tools
- 或在 Visual Studio Installer 中添加 "C++ build tools"

#### 3. VLC 下载失败

**解决方案:**
```bash
# 设置代理
./setup_electron_headers.sh -p http://127.0.0.1:7890
```

#### 4. 解压工具不可用

**解决方案:**
```cmd
# 安装 7-Zip 后重试
# 或在 Git Bash 中运行（包含 unzip）
```

### 环境检测

运行环境检测脚本：

```cmd
REM 检查 Git Bash
where git

REM 检查 WSL
where wsl

REM 检查构建工具
where cl
where msbuild
```

## 📁 目录结构

Windows 环境下的文件布局：

```
WebChimera.js/
├── setup_electron_headers.cmd  # 头文件设置（Windows）
├── setup_electron_headers.sh   # 头文件设置（Git Bash）
├── build_electron.cmd          # 编译脚本（Windows）
├── build_electron.sh           # 编译脚本（Git Bash）
├── build_full_package.cmd      # 完整打包（Windows）
├── build_full_package.sh       # 完整打包（Git Bash）
├── deps/
│   ├── vlc-3.0.11-win64.zip    # VLC Windows 包
│   └── vlc-3.0.11/             # 解压后的 VLC
├── build/Release/
│   ├── WebChimera.js.node      # 编译结果
│   └── WebChimera.js_v0.3.1_electron_v12.0.9_VLC_v3.0.11_x64_win32.zip
└── node_modules/
```

## 🔧 高级配置

### 手动指定架构

```cmd
REM 强制 32 位编译
set npm_config_wcjs_arch=ia32
npm install

REM 强制 64 位编译
set npm_config_wcjs_arch=x64
npm install
```

### 使用本地 VLC

如果已安装 VLC，可以设置环境变量：

```cmd
set VLC_ROOT=C:\Program Files\VideoLAN\VLC
npm install
```

### 代理设置

```cmd
REM 设置 npm 代理
npm config set proxy http://127.0.0.1:7890
npm config set https-proxy http://127.0.0.1:7890

REM 或使用环境变量
set https_proxy=http://127.0.0.1:7890
set http_proxy=http://127.0.0.1:7890
```

## 📦 发布包格式

Windows 平台生成 ZIP 格式的发布包：

```
WebChimera.js_v0.3.1_electron_v12.0.9_VLC_v3.0.11_x64_win32.zip
├── WebChimera.js.node          # Node.js 原生模块
├── index.js                    # 模块入口
├── package.json                # 包信息
└── lib/                        # VLC 库文件
    ├── libvlc.dll              # VLC 核心库
    ├── libvlccore.dll          # VLC 核心库
    ├── plugins/                # VLC 插件
    └── vlc/
        ├── plugins/            # VLC 插件目录
        └── share/lua/          # Lua 脚本
```

## ⚡ 性能优化

### 编译优化

```cmd
REM 启用并行编译
set CL=/MP
npm install

REM 使用 Release 模式
set CMAKE_BUILD_TYPE=Release
npm install
```

### 缓存优化

```cmd
REM 清理缓存
npm cache clean --force
rmdir /s /q node_modules
rmdir /s /q build

REM 重新编译
npm install
```

## 🤝 社区支持

- **GitHub Issues**: 报告 Windows 特定问题
- **文档**: 参考 BUILD_README.md 了解详细技术信息
- **示例**: 查看 QUICK_START.md 快速上手

## 📚 相关链接

- [Node.js Windows 编译指南](https://github.com/nodejs/node-gyp#on-windows)
- [cmake-js 文档](https://github.com/cmake-js/cmake-js)
- [VLC Windows 开发文档](https://wiki.videolan.org/Win32Compile/)
- [Electron 原生模块指南](https://www.electronjs.org/docs/latest/tutorial/using-native-node-modules)

---

**注意**: Windows 环境下推荐使用 Git Bash，它提供了完整的 Unix 工具链，使脚本运行更加稳定。 