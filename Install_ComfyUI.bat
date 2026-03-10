@echo off&&cd /d %~dp0
chcp 65001>nul
set "version_title=ComfyUI 一键便携安装脚本 v1.8 (官方原生管理器增强版)"
Title %version_title%

REM 1. 设置颜色变量
set warning=[33m
set     red=[91m
set   green=[92m
set  yellow=[93m
set   reset=[0m

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
echo %yellow%       欢迎使用 ComfyUI 一键便携安装脚本%reset%
echo %green%====================================================%reset%
echo.

REM 3. 下载并配置便携版 Git (MinGit)
if exist "git\cmd\git.exe" (
    echo %green%[INFO]%reset% Git 已存在，跳过安装。
) else (
    echo %green%[STEP]%reset% 正在下载便携版 Git...
    mkdir git
    curl.exe -L --ssl-no-revoke -o git.zip https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/MinGit-2.46.0-64-bit.zip
    tar.exe -xf git.zip -C git
    del git.zip
)
REM 将本地 Git 加入临时环境变量
set "PATH=%~dp0git\cmd;%PATH%"

REM 4. 下载并配置嵌入式 Python 3.12
if exist "python\python.exe" (
    echo %green%[INFO]%reset% Python 已存在，跳过安装。
) else (
    echo %green%[STEP]%reset% 正在下载 Python 3.12 嵌入版...
    mkdir python
    curl.exe -L --ssl-no-revoke -o python.zip https://www.python.org/ftp/python/3.12.8/python-3.12.8-embed-amd64.zip
    tar.exe -xf python.zip -C python
    del python.zip

    echo %green%[STEP]%reset% 正在配置 Python 环境变量与 pip...
    echo ../ComfyUI> "python\python312._pth"
    echo Lib/site-packages>> "python\python312._pth"
    echo python312.zip>> "python\python312._pth"
    echo .>> "python\python312._pth"
    echo import site>> "python\python312._pth"

    curl.exe -L --ssl-no-revoke -o get-pip.py https://bootstrap.pypa.io/get-pip.py
    "%~dp0python\python.exe" get-pip.py --no-warn-script-location -i https://pypi.org/simple
    del get-pip.py
)
REM 将本地 Python 加入临时环境变量
set "PATH=%~dp0python;%~dp0python\Scripts;%PATH%"

REM 5. 安装 UV 加速器与 PyTorch 2.8.0+cu128
echo %green%[STEP]%reset% 准备深度学习环境 (安装 PyTorch)...
"%~dp0python\python.exe" -m pip install uv --no-warn-script-location -i https://pypi.org/simple
"%~dp0python\python.exe" -m uv pip install torch==2.8.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

REM 6. 下载 ComfyUI 本体
if exist "ComfyUI\main.py" (
    echo %green%[INFO]%reset% ComfyUI 目录已存在，跳过克隆。
) else (
    echo %green%[STEP]%reset% 正在拉取最新的 ComfyUI 源码...
    git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
)

REM 7. 安装 ComfyUI 依赖 (多源策略优化)
echo %green%[STEP]%reset% 正在安装 ComfyUI 核心依赖包...
"%~dp0python\python.exe" -m uv pip install -r ComfyUI\requirements.txt --index-url https://pypi.org/simple --extra-index-url https://mirrors.aliyun.com/pypi/simple/ --index-strategy unsafe-best-match

REM 8. 智能识别并安装 Manager 依赖
echo %green%[STEP]%reset% 正在安装官方 Manager 依赖包...
if exist "manager_requirements.txt" (
    echo %green%[INFO]%reset% 在根目录找到 manager_requirements.txt，正在安装...
    "%~dp0python\python.exe" -m uv pip install -r manager_requirements.txt --index-url https://pypi.org/simple --extra-index-url https://mirrors.aliyun.com/pypi/simple/ --index-strategy unsafe-best-match
    REM 自动复制一份到 ComfyUI 目录里保持结构完整
    copy /y "manager_requirements.txt" "ComfyUI\manager_requirements.txt" >nul
) else if exist "ComfyUI\manager_requirements.txt" (
    echo %green%[INFO]%reset% 在 ComfyUI 目录找到 manager_requirements.txt，正在安装...
    "%~dp0python\python.exe" -m uv pip install -r ComfyUI\manager_requirements.txt --index-url https://pypi.org/simple --extra-index-url https://mirrors.aliyun.com/pypi/simple/ --index-strategy unsafe-best-match
) else (
    echo %warning%[WARN]%reset% 未找到 manager_requirements.txt，跳过此步。
)

REM 9. 生成带有官方管理器参数的启动脚本 (Run_ComfyUI.bat)
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
echo echo 正在启动 ComfyUI...>> "%bat_file_name%"
echo "%%PYTHON_DIR%%\python.exe" -s main.py --windows-standalone-build --enable-manager --listen 127.0.0.1 --port 8188 --enable-cors-header "*">> "%bat_file_name%"
echo pause>> "%bat_file_name%"

REM 10. 完成提示
echo.
echo %green%====================================================%reset%
echo %yellow%       安装全部完成！%reset%
echo %yellow%       你可以双击运行目录下的 %bat_file_name% 来启动。%reset%
echo %green%====================================================%reset%
echo.
pause
