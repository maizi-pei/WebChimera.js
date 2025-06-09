# WebChimera.js 快速编译指南

## 🚀 一键解决方案

由于 Atom 项目归档，直接构建会失败。使用我们的自动化脚本即可解决：

```bash
# 使用推荐版本 (Electron 12.0.9)
./setup_electron_headers.sh

# 或指定其他版本
./setup_electron_headers.sh -v 11.1.0

# 需要代理时
./setup_electron_headers.sh -p http://127.0.0.1:7890
```

## ⚡ 手动步骤（3分钟）

如果不想用脚本，手动执行：

```bash
# 1. 设置代理（可选）
export https_proxy=http://127.0.0.1:7890

# 2. 下载头文件
VERSION="12.0.9"
mkdir -p ~/.cmake-js/electron/v${VERSION}
cd ~/.cmake-js/electron/v${VERSION}
curl -L -o node-v${VERSION}.tar.gz \
  https://electronjs.org/headers/v${VERSION}/node-v${VERSION}-headers.tar.gz
tar -xzf node-v${VERSION}.tar.gz

# 3. ARM64 Mac 额外步骤
if [[ $(uname -m) == "arm64" ]]; then
    mkdir -p ~/.cmake-js/electron-arm64/v${VERSION}/src
    cp node-v${VERSION}.tar.gz ~/.cmake-js/electron-arm64/v${VERSION}/
    cd ~/.cmake-js/electron-arm64/v${VERSION}
    tar -xzf node-v${VERSION}.tar.gz
    cp -r node_headers src/
fi

# 4. 构建
cd /path/to/WebChimera.js
export npm_config_wcjs_runtime="electron"
export npm_config_wcjs_runtime_version="12.0.9"
npm install
```

## ✅ 验证成功

看到这些说明构建成功：

- 无 `atom.io` 下载错误
- 显示 `[100%] Built target WebChimera.js`
- 生成 `build/Release/WebChimera.js.node`
- 退出码为 0

## 🐛 常见问题

**Q: 仍然尝试从网络下载？**
A: 检查 ARM64 Mac 是否创建了 `electron-arm64` 目录

**Q: V8 API 错误？**
A: 使用 Electron 12.0.9（最佳兼容性）

**Q: 下载太慢？**
A: 使用代理参数 `-p http://127.0.0.1:7890`

## 📋 版本推荐

| 版本 | 兼容性 | 推荐度 |
|------|--------|--------|
| 12.0.9 | ✅ 完美 | 🌟 推荐 |
| 11.1.0 | ⚠️ 可用 | 备选 |
| 16.2.8+ | ❌ 需修改 | 不推荐 |

---

**总耗时：** 2-5分钟  
**成功率：** 近100%（网络正常时） 