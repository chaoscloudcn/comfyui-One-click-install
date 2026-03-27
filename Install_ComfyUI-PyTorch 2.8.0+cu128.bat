@echo off&&cd /d %~dp0
chcp 65001>nul
set "version_title=ComfyUI 一键便携部署脚本 v2.7 (纯净基础底座版)"
Title %version_title%

REM 1. 设置颜色与全局变量
set warning=[33m
set     red=[91m
set   green=[92m
set  yellow=[93m
set   reset=[0m

REM 全局网络加速配置
set "PYPI_MIRROR=https://mirrors.aliyun.com/pypi/simple/"

REM ✨ 定义离线包统一收纳目录
set "OFFLINE_DIR=%~dp0offline_packages"

REM 2. 清理系统 Python 环境变量，防止冲突
set PYTHONPATH=
set PYTHONHOME=
set PYTHON=
set PYTHONSTARTUP=
set PYTHONUSERBASE=
set PIP_CONFIG_FILE=
set PIP_REQUIRE_VIRTUALENV=
set VIRTUAL_ENV=

echo %green%====================================================%reset%
echo %yellow%       欢迎使用 ComfyUI 全自动离线缓存与部署脚本%reset%
echo %green%====================================================%reset%
echo.

REM 创建离线包目录（如果不存在）
if not exist "%OFFLINE_DIR%" mkdir "%OFFLINE_DIR%"

REM 3. 智能处理 Git (无则下载，有则直接解压)
if exist "git\cmd\git.exe" (
    echo %green%[INFO]%reset% Git 已存在，跳过解压。
) else (
    if not exist "%OFFLINE_DIR%\MinGit.zip" (
        echo %yellow%[DOWNLOAD]%reset% 未找到 Git 离线包，正在自动下载入库...
        curl.exe -L --ssl-no-revoke -o "%OFFLINE_DIR%\MinGit.zip" https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/MinGit-2.46.0-64-bit.zip
    )
    echo %green%[STEP]%reset% 正在从离线包解压本地 Git...
    mkdir git
    tar.exe -xf "%OFFLINE_DIR%\MinGit.zip" -C git
)
set "PATH=%~dp0git\cmd;%PATH%"

REM 4. 智能处理 Python (无则下载，有则直接解压)
if exist "python\python.exe" (
    echo %green%[INFO]%reset% Python 主程序已存在，跳过解压。
) else (
    if not exist "%OFFLINE_DIR%\python-embed.zip" (
        echo %yellow%[DOWNLOAD]%reset% 未找到 Python 离线包，正在自动下载入库...
        curl.exe -L --ssl-no-revoke -o "%OFFLINE_DIR%\python-embed.zip" https://www.python.org/ftp/python/3.12.8/python-3.12.8-embed-amd64.zip
    )
    echo %green%[STEP]%reset% 正在从离线包解压本地 Python 3.12...
    mkdir python
    tar.exe -xf "%OFFLINE_DIR%\python-embed.zip" -C python

    echo %green%[STEP]%reset% 正在配置 Python 环境变量...
    echo ../ComfyUI> "python\python312._pth"
    echo Lib/site-packages>> "python\python312._pth"
    echo python312.zip>> "python\python312._pth"
    echo .>> "python\python312._pth"
    echo import site>> "python\python312._pth"
)

REM 4.1 智能处理 pip
if exist "python\Scripts\pip.exe" (
    echo %green%[INFO]%reset% pip 模块已存在，跳过安装。
) else (
    if not exist "%OFFLINE_DIR%\get-pip.py" (
        echo %yellow%[DOWNLOAD]%reset% 未找到 pip 安装脚本，正在自动下载入库...
        curl.exe -L --ssl-no-revoke -o "%OFFLINE_DIR%\get-pip.py" https://bootstrap.pypa.io/get-pip.py
    )
    echo %green%[STEP]%reset% 正在为环境离线注入 pip 管理器...
    "%~dp0python\python.exe" "%OFFLINE_DIR%\get-pip.py" --no-warn-script-location --find-links="%OFFLINE_DIR%" -i %PYPI_MIRROR%
)
set "PATH=%~dp0python;%~dp0python\Scripts;%PATH%"

REM 5. 智能处理 UV 加速器
echo %green%[STEP]%reset% 正在检测/补充 uv 加速器离线包...
"%~dp0python\python.exe" -m pip download -d "%OFFLINE_DIR%" uv -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%" >nul 2>&1
"%~dp0python\python.exe" -m pip install uv --find-links="%OFFLINE_DIR%" -i %PYPI_MIRROR%

REM 6. 智能处理 PyTorch 底层库 (巨无霸包)
echo %green%[STEP]%reset% 正在检测/补充 PyTorch 离线包 (首次运行将自动下载约 3GB，此后秒装)...
"%~dp0python\python.exe" -m pip download -d "%OFFLINE_DIR%" torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128 --find-links="%OFFLINE_DIR%"
"%~dp0python\python.exe" -m uv pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --find-links="%OFFLINE_DIR%" --index-url https://download.pytorch.org/whl/cu128

REM 7. 获取最新的 ComfyUI 本体 (必须在线拉取，保持最新)
if exist "ComfyUI\main.py" (
    echo %green%[INFO]%reset% ComfyUI 目录已存在，跳过拉取。
) else (
    echo %green%[STEP]%reset% 正在从官方源拉取 ComfyUI 最新源码...
    git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
)

REM 8. 智能处理 ComfyUI 依赖
echo %green%[STEP]%reset% 正在检测/补充 ComfyUI 依赖离线包...
"%~dp0python\python.exe" -m pip download -d "%OFFLINE_DIR%" -r ComfyUI\requirements.txt -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%"
"%~dp0python\python.exe" -m uv pip install -r ComfyUI\requirements.txt --find-links="%OFFLINE_DIR%" --index-url %PYPI_MIRROR%

REM 8.1 修复 requests 库的依赖冲突警告
echo %green%[STEP]%reset% 正在检测/补充 urllib3 离线包并修复警告...
"%~dp0python\python.exe" -m pip download -d "%OFFLINE_DIR%" urllib3==2.2.2 chardet==5.2.0 -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%" >nul 2>&1
.\python\python.exe -m uv pip install urllib3==2.2.2 chardet==5.2.0 --find-links="%OFFLINE_DIR%" --index-url %PYPI_MIRROR%

REM 9. 智能处理 Manager 依赖
echo %green%[STEP]%reset% 正在检测/补充官方 Manager 依赖离线包...
if exist "manager_requirements.txt" (
    "%~dp0python\python.exe" -m pip download -d "%OFFLINE_DIR%" -r manager_requirements.txt -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%"
    "%~dp0python\python.exe" -m uv pip install -r manager_requirements.txt --find-links="%OFFLINE_DIR%" --index-url %PYPI_MIRROR%
    copy /y "manager_requirements.txt" "ComfyUI\manager_requirements.txt" >nul
) else if exist "ComfyUI\manager_requirements.txt" (
    "%~dp0python\python.exe" -m pip download -d "%OFFLINE_DIR%" -r ComfyUI\manager_requirements.txt -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%"
    "%~dp0python\python.exe" -m uv pip install -r ComfyUI\manager_requirements.txt --find-links="%OFFLINE_DIR%" --index-url %PYPI_MIRROR%
)

REM 10. 生成基础的 ComfyUI 启动脚本 (Run_ComfyUI.bat)
set "bat_file_name=Run_ComfyUI.bat"
echo %green%[STEP]%reset% 正在生成启动脚本 %bat_file_name% ...

echo @echo off> "%bat_file_name%"
echo chcp 65001 ^>nul>> "%bat_file_name%"
echo setlocal>> "%bat_file_name%"
echo.>> "%bat_file_name%"
echo REM 动态获取根目录路径>> "%bat_file_name%"
echo set "ROOT_DIR=%%~dp0">> "%bat_file_name%"
echo set "COMFYUI_DIR=%%ROOT_DIR%%ComfyUI">> "%bat_file_name%"
echo set "PYTHON_DIR=%%ROOT_DIR%%python">> "%bat_file_name%"
echo set "GIT_DIR=%%ROOT_DIR%%git">> "%bat_file_name%"
echo.>> "%bat_file_name%"
echo REM 将便携版 Python 和 Git 强行置入环境变量最前方>> "%bat_file_name%"
echo set "PATH=%%PYTHON_DIR%%;%%PYTHON_DIR%%\Scripts;%%GIT_DIR%%\cmd;%%PATH%%">> "%bat_file_name%"
echo.>> "%bat_file_name%"
echo cd /d "%%COMFYUI_DIR%%">> "%bat_file_name%"
echo echo 正在启动 ComfyUI 基础核心...>> "%bat_file_name%"
echo "%%PYTHON_DIR%%\python.exe" -s main.py --windows-standalone-build --enable-manager --listen 127.0.0.1 --port 8188 --enable-cors-header "*">> "%bat_file_name%"
echo pause>> "%bat_file_name%"

REM 11. 完成提示
echo.
echo %green%====================================================%reset%
echo %yellow%       母盘与基础离线缓存库构建完成！%reset%
echo %yellow%       离线包已全部存入: %OFFLINE_DIR% %reset%
echo %yellow%       你可以双击运行目录下的 %bat_file_name% 来启动。%reset%
echo %green%====================================================%reset%
echo.
pause