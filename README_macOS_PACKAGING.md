# WebChimera.js macOS 打包安装指南

## 📋 系统要求

### 必需软件
- **macOS**: 10.15 (Catalina) 或更高版本
- **VLC Media Player**: 3.0.0 或更高版本
- **Electron**: 12.0.9 (推荐) 或兼容版本
- **Node.js**: 14.x 或更高版本

### 硬件要求
- **处理器**: Intel x64 或 Apple Silicon (M1/M2)
- **内存**: 至少 4GB RAM
- **存储**: 至少 500MB 可用空间

## 🛠️ 预安装步骤

### 1. 安装 VLC Media Player

**必须先安装 VLC**，WebChimera.js 依赖系统安装的 VLC：

```bash
# 方式1: 从官网下载
# 访问 https://www.videolan.org/vlc/
# 下载 VLC for macOS 并安装到 /Applications/VLC.app

# 方式2: 使用 Homebrew
brew install --cask vlc

# 方式3: 使用 MacPorts
sudo port install VLC
```

### 2. 验证 VLC 安装

```bash
# 检查 VLC 是否正确安装
ls -la /Applications/VLC.app/Contents/MacOS/
/Applications/VLC.app/Contents/MacOS/VLC --version
```

应该看到类似输出：
```
VLC media player 3.0.21 Vetinari (revision 3.0.21-0-gdd8bfdbabe)
```

## 📦 构建和打包

### 环境设置

```bash
# 克隆项目
git clone <WebChimera.js-repo-url>
cd WebChimera.js

# 如果需要设置代理（国内用户）
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890

# 初始化子模块
git submodule update --init --recursive
```

### 编译 WebChimera.js

```bash
# 安装依赖
npm install

# 编译 (确保已安装 VLC)
./build_electron.sh

# 验证编译结果
ls -la build/Release/WebChimera.js.node
file build/Release/WebChimera.js.node
```

### 创建发布包

```bash
# 运行打包脚本
./build_full_package.sh

# 打包完成后会生成：
# build/Release/WebChimera.js_v0.3.1_electron_v12.0.9_VLC_v3.0.21_arm64_osx.tar.gz
```

## 🚀 安装和使用

### 在 Electron 项目中安装

```bash
# 解压发布包
tar -xzf WebChimera.js_v0.3.1_electron_v12.0.9_VLC_v3.0.21_arm64_osx.tar.gz

# 安装到项目中
npm install ./webchimera.js
```

### 基本使用示例

```javascript
// main.js - Electron 主进程
const { app, BrowserWindow } = require('electron');

app.on('ready', () => {
    const win = new BrowserWindow({
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });
    
    win.loadFile('index.html');
});

// renderer.js - 渲染进程
const wjs = require('webchimera.js');

// 创建播放器
const player = wjs.createPlayer();

// 设置视频输出
const canvas = document.getElementById('video-canvas');
const ctx = canvas.getContext('2d');

player.pixelFormat = player.RV32;
player.onFrameReady = (frame) => {
    if (frame) {
        const imageData = new ImageData(
            new Uint8ClampedArray(frame.pixels), 
            frame.width, 
            frame.height
        );
        canvas.width = frame.width;
        canvas.height = frame.height;
        ctx.putImageData(imageData, 0, 0);
    }
};

// 播放视频
player.play('http://example.com/video.mp4');
```

## 🔧 故障排除

### 常见问题

#### 1. "未找到系统 VLC 安装"

**错误信息**:
```
❌ 错误: 未找到系统 VLC 安装
请从 https://www.videolan.org/vlc/ 下载并安装 VLC
```

**解决方案**:
```bash
# 检查 VLC 安装位置
ls -la /Applications/VLC.app
# 如果不存在，重新安装 VLC
```

#### 2. "Module did not self-register"

**原因**: Electron 版本不匹配

**解决方案**:
```bash
# 检查 Electron 版本
./node_modules/.bin/electron --version
# 确保使用 Electron 12.0.9
npm install electron@12.0.9
```

#### 3. 播放器创建成功但视频无法播放

**检查步骤**:
```bash
# 1. 检查 VLC 插件
ls -la /Applications/VLC.app/Contents/MacOS/plugins/

# 2. 检查网络连接
curl -I http://example.com/video.mp4

# 3. 检查视频格式支持
/Applications/VLC.app/Contents/MacOS/VLC --intf dummy --list
```

#### 4. 权限问题

```bash
# 给予 VLC 执行权限
chmod +x /Applications/VLC.app/Contents/MacOS/VLC

# 检查应用安全性设置
# 系统偏好设置 > 安全性与隐私 > 通用 > 允许从以下位置下载的应用
```

### 环境变量验证

创建测试脚本 `test_env.js`:

```javascript
// 检查环境变量
console.log('=== WebChimera.js 环境检查 ===');
console.log('VLC_PATH:', process.env.VLC_PATH);
console.log('LIBVLC_PATH:', process.env.LIBVLC_PATH);
console.log('VLC_PLUGIN_PATH:', process.env.VLC_PLUGIN_PATH);

// 检查文件存在性
const fs = require('fs');
const paths = [
    '/Applications/VLC.app/Contents/MacOS',
    '/Applications/VLC.app/Contents/MacOS/lib',
    '/Applications/VLC.app/Contents/MacOS/plugins'
];

paths.forEach(path => {
    const exists = fs.existsSync(path);
    console.log(`${exists ? '✅' : '❌'} ${path}`);
});

// 尝试加载 WebChimera.js
try {
    const wjs = require('webchimera.js');
    console.log('✅ WebChimera.js 加载成功');
    console.log('VLC 版本:', wjs.vlcVersion);
} catch (error) {
    console.log('❌ WebChimera.js 加载失败:', error.message);
}
```

运行测试：
```bash
node test_env.js
```

## 📋 版本兼容性

| WebChimera.js | Electron | VLC | macOS |
|---------------|----------|-----|-------|
| 0.3.1 | 12.0.9 | 3.0.21+ | 10.15+ |
| 0.3.1 | 11.x | 3.0.x | 10.14+ |
| 0.3.1 | 10.x | 3.0.x | 10.13+ |

## 🔍 调试信息

### 启用详细日志

```javascript
// 在加载 webchimera.js 之前设置
process.env.VLC_VERBOSE = '2';
process.env.DEBUG = 'webchimera*';

const wjs = require('webchimera.js');
```

### 性能监控

```javascript
const player = wjs.createPlayer();

// 监控播放状态
player.onMediaChanged = () => console.log('媒体已更改');
player.onOpening = () => console.log('正在打开...');
player.onBuffering = (percent) => console.log(`缓冲中: ${percent}%`);
player.onPlaying = () => console.log('开始播放');
player.onPaused = () => console.log('已暂停');
player.onStopped = () => console.log('已停止');
player.onEncounteredError = () => console.error('播放错误');
```

## 📞 技术支持

### 日志收集

发生问题时，请收集以下信息：

```bash
# 系统信息
sw_vers
uname -a

# VLC 信息
/Applications/VLC.app/Contents/MacOS/VLC --version
ls -la /Applications/VLC.app/Contents/MacOS/

# Electron 信息  
./node_modules/.bin/electron --version
node --version
npm --version

# WebChimera.js 信息
ls -la node_modules/webchimera.js/
otool -L node_modules/webchimera.js/WebChimera.js.node
```

### 常用命令

```bash
# 重新安装 WebChimera.js
rm -rf node_modules/webchimera.js
npm install ./webchimera.js

# 清理编译缓存
rm -rf build/
npm run clean

# 重新编译
./build_electron.sh

# 重新打包
./build_full_package.sh
```

## 📄 许可证

WebChimera.js 使用 LGPL-2.1 许可证。使用前请确保了解相关许可证要求。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**注意**: 此文档基于 WebChimera.js v0.3.1 和 VLC 3.0.21。不同版本可能存在差异，请以实际情况为准。 