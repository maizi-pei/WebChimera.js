@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM WebChimera.js Windows 打包脚本
REM 检测Git Bash并运行主脚本

echo [INFO] WebChimera.js Windows 打包脚本
echo [INFO] 检测Windows环境...

REM 设置代理环境变量（如果需要）
REM 取消可能有问题的代理设置
set HTTP_PROXY=
set HTTPS_PROXY=
set http_proxy=
set https_proxy=

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
    REM 查找Git安装目录下的bash.exe
    for /f "tokens=*" %%i in ('where git') do (
        set "git_path=%%i"
        goto :found_git
    )
    :found_git
    set "git_dir=!git_path:\cmd\git.exe=!"
    set "bash_path=!git_dir!\bin\bash.exe"
    
    if exist "!bash_path!" (
        REM 清除代理设置并运行bash
        set HTTP_PROXY=
        set HTTPS_PROXY=
        set http_proxy=
        set https_proxy=
        "!bash_path!" ./build_full_package.sh %*
        goto :end
    ) else (
        echo [WARN] 未找到Git Bash可执行文件
    )
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