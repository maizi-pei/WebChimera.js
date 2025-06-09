@echo off
setlocal enabledelayedexpansion

REM WebChimera.js Windows 打包脚本
REM 检测Git Bash并运行主脚本

echo [INFO] WebChimera.js Windows 打包脚本
echo [INFO] 检测Windows环境...

REM 检查是否在Git Bash环境中
if defined BASH_VERSION (
    echo [INFO] 检测到Git Bash环境
    bash ./build_full_package.sh %*
    goto :end
)

REM 检查Git Bash是否可用
where git >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] 尝试使用Git Bash运行脚本...
    git bash -c "./build_full_package.sh %*"
    goto :end
)

REM 检查WSL是否可用
where wsl >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] 尝试使用WSL运行脚本...
    wsl bash ./build_full_package.sh %*
    goto :end
)

REM 检查MSYS2/MinGW是否可用
where bash >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] 尝试使用系统bash运行脚本...
    bash ./build_full_package.sh %*
    goto :end
)

REM 如果都不可用，显示错误信息
echo [ERROR] 未找到兼容的bash环境
echo [INFO] 请安装以下任一工具:
echo [INFO] 1. Git for Windows (推荐): https://git-scm.com/download/win
echo [INFO] 2. WSL (Windows Subsystem for Linux)
echo [INFO] 3. MSYS2: https://www.msys2.org/
echo [INFO] 然后重新运行此脚本
exit /b 1

:end
echo [INFO] 脚本执行完成 