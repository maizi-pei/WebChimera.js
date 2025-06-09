# WebChimera.js - Windows 快速上手 🪟

> 一键解决 WebChimera.js 在 Windows 环境下的编译问题

## ⚡ 超快开始（3分钟）

### 1️⃣ 准备环境
```cmd
REM 确保已安装 Node.js 和 Git for Windows
node --version
git --version
```

### 2️⃣ 一键设置
```cmd
REM 下载并配置 Electron 头文件
setup_electron_headers.cmd

REM 编译 WebChimera.js
build_electron.cmd

REM 创建完整发布包
build_full_package.cmd
```

### 3️⃣ 完成！
生成的文件：
- `build/Release/WebChimera.js.node` - 编译结果
- `build/Release/WebChimera.js_v0.3.1_electron_v12.0.9_VLC_v3.0.11_x64_win32.zip` - 完整包

## 🎯 命令对照表

| 功能 | Windows 命令 | Git Bash 命令 |
|------|-------------|--------------|
| 设置头文件 | `setup_electron_headers.cmd` | `./setup_electron_headers.sh` |
| 编译项目 | `build_electron.cmd` | `./build_electron.sh` |
| 创建完整包 | `build_full_package.cmd` | `./build_full_package.sh` |

## 🔧 常用选项

```cmd
REM 指定 Electron 版本
setup_electron_headers.cmd -v 11.1.0

REM 使用代理下载
setup_electron_headers.cmd -p http://127.0.0.1:7890

REM 查看帮助
setup_electron_headers.cmd --help
build_full_package.cmd --help
```

## 🚨 故障排除

### 问题：找不到 Git Bash
**解决**：安装 [Git for Windows](https://git-scm.com/download/win)

### 问题：编译失败
**解决**：安装 [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)

### 问题：网络下载失败
**解决**：设置代理
```cmd
setup_electron_headers.cmd -p http://127.0.0.1:7890
```

## 📚 详细文档

- **完整指南**: [WINDOWS_SETUP.md](WINDOWS_SETUP.md)
- **技术文档**: [BUILD_README.md](BUILD_README.md)
- **快速开始**: [QUICK_START.md](QUICK_START.md)

---

**提示**: 推荐在 **命令提示符** 或 **PowerShell** 中运行 `.cmd` 文件，获得最佳体验。 