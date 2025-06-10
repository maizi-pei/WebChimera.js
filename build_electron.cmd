set npm_config_wcjs_runtime=electron
set npm_config_wcjs_runtime_version=12.2.3
set npm_config_wcjs_arch=x64

echo [INFO] 开始构建 WebChimera.js for Electron...
echo [INFO] 运行时: %npm_config_wcjs_runtime%
echo [INFO] 版本: %npm_config_wcjs_runtime_version%
echo [INFO] 架构: %npm_config_wcjs_arch%

npm install
