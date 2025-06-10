@echo off
setlocal enabledelayedexpansion

REM WebChimera.js Electron Headers Setup - Windows Script
REM 检测Windows环境并运行主脚本

echo [INFO] WebChimera.js Electron Headers Setup - Windows
echo [INFO] 检测Windows环境...

REM 解析命令行参数
set "SCRIPT_ARGS="
set "ELECTRON_VERSION=12.2.3"
set "PROXY_URL="
set "SHOW_HELP="

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="-h" set SHOW_HELP=1
if "%~1"=="--help" set SHOW_HELP=1
if "%~1"=="-v" (
    set "ELECTRON_VERSION=%~2"
    shift
)
if "%~1"=="--version" (
    set "ELECTRON_VERSION=%~2"
    shift
)
if "%~1"=="-p" (
    set "PROXY_URL=%~2"
    shift
)
if "%~1"=="--proxy" (
    set "PROXY_URL=%~2"
    shift
)

set "SCRIPT_ARGS=!SCRIPT_ARGS! %~1"
shift
goto :parse_args

:args_done

REM 显示帮助信息
if defined SHOW_HELP (
    echo.
    echo WebChimera.js Electron Headers Setup Script - Windows
    echo.
    echo 用法:
    echo     %~nx0 [选项]
    echo.
    echo 选项:
    echo     -v, --version VERSION   指定 Electron 版本 ^(默认: 12.0.9^)
    echo     -p, --proxy PROXY_URL   设置代理 ^(格式: http://127.0.0.1:7890^)
    echo     -h, --help             显示此帮助信息
    echo.
    echo 示例:
    echo     %~nx0                                    # 使用默认版本
    echo     %~nx0 -v 11.1.0                        # 使用指定版本
    echo     %~nx0 -v 12.0.9 -p http://127.0.0.1:7890  # 使用代理下载
    echo.
    echo 支持的版本:
    echo     - 12.0.9 ^(推荐^)
    echo     - 11.1.0
    echo     - 16.2.8 ^(可能需要代码修改^)
    echo.
    echo Windows 环境要求:
    echo     - Git for Windows ^(推荐^): https://git-scm.com/download/win
    echo     - 或 WSL ^(Windows Subsystem for Linux^)
    echo     - 或 MSYS2: https://www.msys2.org/
    goto :end
)

echo [INFO] 目标 Electron 版本: %ELECTRON_VERSION%
if defined PROXY_URL echo [INFO] 代理设置: %PROXY_URL%

REM 检查是否在Git Bash环境中
if defined BASH_VERSION (
    echo [INFO] 检测到Git Bash环境，直接运行脚本...
    bash ./setup_electron_headers.sh%SCRIPT_ARGS%
    goto :end
)

REM 检查Git是否可用
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
        if defined PROXY_URL (
            "!bash_path!" ./setup_electron_headers.sh -v %ELECTRON_VERSION% -p "%PROXY_URL%"
        ) else (
            "!bash_path!" ./setup_electron_headers.sh -v %ELECTRON_VERSION%
        )
        goto :check_result
    ) else (
        echo [WARN] 未找到Git Bash可执行文件
    )
)

REM 检查WSL是否可用
where wsl >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] 尝试使用WSL运行脚本...
    if defined PROXY_URL (
        wsl bash ./setup_electron_headers.sh -v %ELECTRON_VERSION% -p "%PROXY_URL%"
    ) else (
        wsl bash ./setup_electron_headers.sh -v %ELECTRON_VERSION%
    )
    goto :check_result
)

REM 检查MSYS2/MinGW是否可用
where bash >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] 尝试使用系统bash运行脚本...
    if defined PROXY_URL (
        bash ./setup_electron_headers.sh -v %ELECTRON_VERSION% -p "%PROXY_URL%"
    ) else (
        bash ./setup_electron_headers.sh -v %ELECTRON_VERSION%
    )
    goto :check_result
)

REM 如果都不可用，显示错误信息
echo [ERROR] 未找到兼容的bash环境
echo [INFO] WebChimera.js 需要Unix工具链来处理Electron头文件
echo.
echo [INFO] 请安装以下任一工具:
echo [INFO] 1. Git for Windows ^(推荐^): https://git-scm.com/download/win
echo [INFO]    - 包含完整的Git Bash环境
echo [INFO]    - 提供curl、tar、unzip等工具
echo [INFO] 2. WSL ^(Windows Subsystem for Linux^)
echo [INFO]    - 运行: wsl --install
echo [INFO]    - 或在Microsoft Store搜索"Ubuntu"
echo [INFO] 3. MSYS2: https://www.msys2.org/
echo [INFO]    - 提供完整的Unix工具链
echo.
echo [INFO] 安装后重新运行: %~nx0
echo [INFO] 或手动运行: npm install
exit /b 1

:check_result
if %errorlevel% == 0 (
    echo [SUCCESS] Electron头文件设置完成!
    echo [INFO] 接下来运行: build_electron.cmd
    echo [INFO] 或手动运行: npm install
) else (
    echo [ERROR] 脚本执行失败，错误代码: %errorlevel%
    echo [INFO] 请检查网络连接和权限设置
    echo [INFO] 或尝试手动运行: npm install
)
goto :end

:end
echo [INFO] 脚本执行完成
pause 