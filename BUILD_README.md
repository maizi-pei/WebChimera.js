# WebChimera.js 编译指南 - 绕过下载问题

由于 Atom 项目已于 2022年12月15日 被 GitHub 正式归档，原本从 `atom.io` 下载 Electron 头文件的链接已失效，导致 cmake-js 构建失败。本指南提供了一套完整的解决方案。

## 问题背景

**原始错误：**
```
http DIST - https://atom.io/download/atom-shell/v12.0.9/node-v12.0.9.tar.gz
ERR! OMG incorrect header check
```

**根本原因：** Atom 项目归档后，`atom.io` 的下载服务已停止，cmake-js 无法获取 Electron 构建头文件。

## 解决方案：手动下载头文件

### 步骤 1：设置代理（可选）

如果网络访问受限，先设置代理：

```bash
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890
```

### 步骤 2：确定目标 Electron 版本

根据你的项目需求选择 Electron 版本。经测试，以下版本兼容性较好：
- **Electron 12.0.9** ✅ （推荐，API兼容性最佳）
- Electron 11.1.0 ⚠️ （有部分V8 API兼容问题）
- Electron 16.2.8+ ❌ （V8 API变更较大，需要代码修改）

### 步骤 3：创建 cmake-js 缓存目录

```bash
# 替换 VERSION 为你的目标版本，如 12.0.9
VERSION="12.0.9"

# 创建缓存目录（根据系统架构）
mkdir -p ~/.cmake-js/electron/v${VERSION}
mkdir -p ~/.cmake-js/electron-arm64/v${VERSION}  # ARM64 Mac 需要
```

### 步骤 4：下载 Electron 头文件

从官方 Electron 仓库下载头文件：

```bash
# 进入缓存目录
cd ~/.cmake-js/electron/v${VERSION}

# 下载头文件
curl -L -o node-v${VERSION}.tar.gz \
  https://electronjs.org/headers/v${VERSION}/node-v${VERSION}-headers.tar.gz

# 验证下载
ls -la node-v${VERSION}.tar.gz
file node-v${VERSION}.tar.gz
```

### 步骤 5：解压和复制文件

```bash
# 解压头文件
tar -xzf node-v${VERSION}.tar.gz

# 为 ARM64 Mac 创建必要的目录结构
if [[ $(uname -m) == "arm64" ]]; then
    # 复制到 ARM64 目录
    cp node-v${VERSION}.tar.gz ~/.cmake-js/electron-arm64/v${VERSION}/
    
    # 进入 ARM64 目录并解压
    cd ~/.cmake-js/electron-arm64/v${VERSION}
    tar -xzf node-v${VERSION}.tar.gz
    
    # 创建 cmake-js 期望的目录结构
    mkdir -p src
    cp -r node_headers src/
fi
```

### 步骤 6：配置构建脚本

修改 `build_electron.sh`：

```bash
#!/bin/sh

export npm_config_wcjs_runtime="electron"
export npm_config_wcjs_runtime_version="12.0.9"  # 使用你的版本

npm install
```

### 步骤 7：执行构建

```bash
# 清理之前的构建
rm -rf node_modules build

# 执行构建
./build_electron.sh
```

## 🎁 创建官方风格的完整发布包

如果你想创建类似官方 `WebChimera.js_v0.5.2_electron_v12.0.9_VLC_v3.0.11_x64_osx.tar.gz` 的完整包，可以使用我们提供的打包脚本。

### 完整打包流程

**1. 运行完整打包脚本：**
```bash
./build_full_package.sh
```

**2. 手动指定版本：**
```bash
# 编辑 build_full_package.sh 中的版本配置
VLC_VER="3.0.11"
ELECTRON_VER="12.0.9"
```

### 打包过程说明

官方的完整包包含以下组件：

1. **WebChimera.js.node** - 编译的原生模块
2. **VLC 动态库** - 所有必需的 `.dylib` 文件
3. **VLC 插件** - 解码器和过滤器插件
4. **VLC Lua 脚本** - 扩展和播放列表支持
5. **package.json** - 包信息和依赖

**目录结构：**
```
webchimera.js/
├── WebChimera.js.node          # 主模块
├── index.js                    # 入口文件
├── package.json                # 包配置
└── lib/                        # VLC 库文件
    ├── *.dylib                 # VLC 动态库
    └── vlc/
        ├── plugins/            # VLC 插件
        ├── lib/               # 符号链接
        └── share/lua/         # Lua 脚本
```

### 使用完整包

**解压和安装：**
```bash
# 解压
tar -xzf WebChimera.js_v0.3.1_electron_v12.0.9_VLC_v3.0.11_x64_osx.tar.gz

# 在 Electron 项目中安装
npm install ./webchimera.js
```

**在 Electron 中使用：**
```javascript
const wcjs = require('webchimera.js');
const player = wcjs.createPlayer();
```

## 核心原理

### 为什么这个方法有效？

1. **cmake-js 缓存机制：** cmake-js 会首先检查本地缓存目录 `~/.cmake-js/` 是否存在所需文件
2. **正确的目录结构：** 通过将文件放置在 cmake-js 期望的路径，让其误以为文件已被下载
3. **官方源替代：** 使用 `electronjs.org` 替代已失效的 `atom.io`

### 目录结构说明

```
~/.cmake-js/
├── electron/                    # Intel/通用架构
│   └── v12.0.9/
│       ├── node-v12.0.9.tar.gz
│       └── node_headers/
└── electron-arm64/              # ARM64 架构（Apple Silicon）
    └── v12.0.9/
        ├── node-v12.0.9.tar.gz
        ├── node_headers/
        └── src/
            └── node_headers/    # cmake-js 期望的结构
```

## 验证成功

构建成功的标志：

1. **无下载错误：** 不再出现 `atom.io` 相关错误
2. **cmake-js 日志：** 显示使用本地缓存
   ```
   info DIST Downloading distribution files to: ~/.cmake-js/electron-arm64/v12.0.9
   http DIST - https://artifacts.electronjs.org/headers/dist/v12.0.9/node-v12.0.9.tar.gz
   ```
3. **构建完成：** 生成 `build/Release/WebChimera.js.node`
4. **退出码为 0：** `Exit code: 0`

## 故障排除

### 问题：仍然尝试从网络下载
**解决：** 检查目录结构是否正确，特别是 ARM64 Mac 需要 `electron-arm64` 目录

### 问题：V8 API 兼容性错误
**解决：** 降低 Electron 版本，推荐使用 12.0.9

### 问题：权限错误
**解决：** 确保对 `~/.cmake-js/` 目录有写权限

### 问题：VLC 库链接错误
**解决：** 确保 VLC 动态库的路径正确，检查符号链接

## 支持的平台

- ✅ macOS (Intel & Apple Silicon)
- ✅ Windows
- ✅ Linux

## 版本兼容性矩阵

| Electron 版本 | WebChimera.js | V8 API 兼容性 | 推荐程度 |
|---------------|---------------|---------------|----------|
| 11.1.0        | 0.3.1         | ⚠️ 部分问题   | 可用     |
| **12.0.9**    | **0.3.1**     | ✅ **兼容**   | **推荐** |
| 16.2.8        | 0.3.1         | ❌ 需要修改   | 不推荐   |

## 构建类型比较

| 构建类型 | 文件大小 | VLC 依赖 | 分发方式 |
|----------|----------|----------|----------|
| 基础构建 | ~300KB | 需要系统安装 | WebChimera.js.node |
| 完整包 | ~50-100MB | 自包含 | tar.gz 压缩包 |

## 贡献

如果你在其他 Electron 版本上测试成功，欢迎更新此文档。

---

**最后更新：** 2025年6月9日
**测试环境：** macOS 14.5.0 (Apple Silicon), Electron 12.0.9 