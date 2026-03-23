@echo off
cd /d "%~dp0"
chcp 65001>nul
set "version_title=ComfyUI 一键便携部署脚本 v3.1 (逻辑重构版)"
Title %version_title%

REM ==========================================
REM 全局变量与核心路径配置
REM ==========================================
set warning=[33m
set     red=[91m
set   green=[92m
set  yellow=[93m
set   reset=[0m

REM 全局网络加速源
set "PYPI_MIRROR=https://mirrors.aliyun.com/pypi/simple/"
REM ✨ 定义离线包的绝对核心缓存目录
set "OFFLINE_DIR=offline_packages"
REM 定义独立的 Python 执行路径
set "PY=.\python\python.exe"

echo %green%====================================================%reset%
echo %yellow%       欢迎使用 ComfyUI 全自动离线缓存与部署脚本%reset%
echo %green%====================================================%reset%
echo.

REM 【核心逻辑 0】：初始化离线缓存文件夹
if not exist "%OFFLINE_DIR%" (
    echo %green%[INFO]%reset% 创建离线缓存目录: %OFFLINE_DIR%
    mkdir "%OFFLINE_DIR%"
)

REM ==========================================
REM 阶段一：基础环境构建 (Git & Python)
REM ==========================================

REM 【核心逻辑 1】：智能处理 Git
if exist "git\cmd\git.exe" (
    echo %green%[INFO]%reset% Git 环境已存在，跳过。
) else (
    REM 查缓存 -> 无则下载入库
    if not exist "%OFFLINE_DIR%\MinGit.zip" (
        echo %yellow%[DOWNLOAD]%reset% 未命中 Git 缓存，正在下载并存入 %OFFLINE_DIR% ...
        curl.exe -L --ssl-no-revoke -o "%OFFLINE_DIR%\MinGit.zip" https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/MinGit-2.46.0-64-bit.zip
    )
    REM 统一从缓存库解压安装
    echo %green%[STEP]%reset% 正在从离线缓存解压 Git...
    mkdir git
    tar.exe -xf "%OFFLINE_DIR%\MinGit.zip" -C git
)
set "PATH=%~dp0git\cmd;%PATH%"

REM 【核心逻辑 2】：智能处理 Python
if exist "python\python.exe" (
    echo %green%[INFO]%reset% Python 主程序已存在，跳过。
) else (
    REM 查缓存 -> 无则下载入库
    if not exist "%OFFLINE_DIR%\python-embed.zip" (
        echo %yellow%[DOWNLOAD]%reset% 未命中 Python 缓存，正在下载并存入 %OFFLINE_DIR% ...
        curl.exe -L --ssl-no-revoke -o "%OFFLINE_DIR%\python-embed.zip" https://www.python.org/ftp/python/3.12.8/python-3.12.8-embed-amd64.zip
    )
    REM 统一从缓存库解压安装
    echo %green%[STEP]%reset% 正在从离线缓存解压 Python...
    mkdir python
    tar.exe -xf "%OFFLINE_DIR%\python-embed.zip" -C python

    echo %green%[STEP]%reset% 正在配置 Python 环境变量...
    echo ../ComfyUI> "python\python312._pth"
    echo Lib/site-packages>> "python\python312._pth"
    echo python312.zip>> "python\python312._pth"
    echo .>> "python\python312._pth"
    echo import site>> "python\python312._pth"
)

REM 【核心逻辑 3】：智能处理 pip 安装脚本
if exist "python\Scripts\pip.exe" (
    echo %green%[INFO]%reset% pip 模块已存在，跳过。
) else (
    REM 查缓存 -> 无则下载入库
    if not exist "%OFFLINE_DIR%\get-pip.py" (
        echo %yellow%[DOWNLOAD]%reset% 未命中 pip 脚本缓存，正在下载并存入 %OFFLINE_DIR% ...
        curl.exe -L --ssl-no-revoke -o "%OFFLINE_DIR%\get-pip.py" https://bootstrap.pypa.io/get-pip.py
    )
    REM 统一从缓存库读取脚本执行
    echo %green%[STEP]%reset% 正在从缓存注入 pip...
    %PY% "%OFFLINE_DIR%\get-pip.py" --no-warn-script-location --find-links="%OFFLINE_DIR%" -i %PYPI_MIRROR%
)
set "PATH=%~dp0python;%~dp0python\Scripts;%PATH%"

REM ==========================================
REM 阶段二：算力核心与引擎依赖
REM (利用 pip download 查缓存, --no-index 纯离线安装)
REM ==========================================

REM 智能处理 UV 加速器
echo %green%[STEP]%reset% 正在扫描/缓存 uv 加速器...
%PY% -m pip download -d "%OFFLINE_DIR%" uv -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%" >nul 2>&1
%PY% -m pip install uv --find-links="%OFFLINE_DIR%" --no-index

REM 智能处理 PyTorch 底层库
echo %green%[STEP]%reset% 正在扫描/缓存 PyTorch (如无缓存将自动下载约 3GB)...
%PY% -m pip download -d "%OFFLINE_DIR%" torch==2.10.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 --find-links="%OFFLINE_DIR%"
echo %green%[STEP]%reset% 正在从离线库秒装 PyTorch...
%PY% -m uv pip install torch==2.10.0 torchvision torchaudio --find-links="%OFFLINE_DIR%" --no-index

REM 获取最新的 ComfyUI 本体
if exist "ComfyUI\main.py" (
    echo %green%[INFO]%reset% ComfyUI 目录已存在，跳过拉取。
) else (
    echo %green%[STEP]%reset% 正在拉取 ComfyUI 最新源码...
    git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
)

REM 智能处理 ComfyUI 依赖
echo %green%[STEP]%reset% 正在扫描/缓存 ComfyUI 依赖包...
%PY% -m pip download -d "%OFFLINE_DIR%" -r ComfyUI\requirements.txt -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%" >nul 2>&1
echo %green%[STEP]%reset% 正在从离线库秒装 ComfyUI 依赖...
%PY% -m uv pip install -r ComfyUI\requirements.txt --find-links="%OFFLINE_DIR%" --no-index

REM 修复 requests 库的依赖冲突警告
echo %green%[STEP]%reset% 正在处理版本冲突修正补丁...
%PY% -m pip download -d "%OFFLINE_DIR%" urllib3==2.2.2 chardet==5.2.0 -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%" >nul 2>&1
%PY% -m uv pip install urllib3==2.2.2 chardet==5.2.0 --find-links="%OFFLINE_DIR%" --no-index

REM ==========================================
REM 阶段三：核心插件与管理器部署
REM ==========================================

REM 获取并安装 ComfyUI-Manager 本体
if exist "ComfyUI\custom_nodes\ComfyUI-Manager\__init__.py" (
    echo %green%[INFO]%reset% ComfyUI-Manager 源码已存在，跳过。
) else (
    echo %green%[STEP]%reset% 正在拉取官方 ComfyUI-Manager 源码...
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git ComfyUI\custom_nodes\ComfyUI-Manager
)

REM 智能处理 Manager 依赖
echo %green%[STEP]%reset% 正在扫描/缓存 Manager 依赖包...
if exist "ComfyUI\custom_nodes\ComfyUI-Manager\requirements.txt" (
    %PY% -m pip download -d "%OFFLINE_DIR%" -r ComfyUI\custom_nodes\ComfyUI-Manager\requirements.txt -i %PYPI_MIRROR% --find-links="%OFFLINE_DIR%" >nul 2>&1
    echo %green%[STEP]%reset% 正在从离线库秒装 Manager 依赖...
    %PY% -m uv pip install -r ComfyUI\custom_nodes\ComfyUI-Manager\requirements.txt --find-links="%OFFLINE_DIR%" --no-index
)

REM ==========================================
REM 阶段四：启动器生成
REM ==========================================
set "bat_file_name=Run_ComfyUI.bat"
echo %green%[STEP]%reset% 正在生成启动脚本 %bat_file_name% ...

echo @echo off> "%bat_file_name%"
echo chcp 65001 ^>nul>> "%bat_file_name%"
echo setlocal>> "%bat_file_name%"
echo.>> "%bat_file_name%"
echo set "ROOT_DIR=%%~dp0">> "%bat_file_name%"
echo set "COMFYUI_DIR=%%ROOT_DIR%%ComfyUI">> "%bat_file_name%"
echo set "PYTHON_DIR=%%ROOT_DIR%%python">> "%bat_file_name%"
echo set "GIT_DIR=%%ROOT_DIR%%git">> "%bat_file_name%"
echo set "PATH=%%PYTHON_DIR%%;%%PYTHON_DIR%%\Scripts;%%GIT_DIR%%\cmd;%%PATH%%">> "%bat_file_name%"
echo cd /d "%%COMFYUI_DIR%%">> "%bat_file_name%"
echo echo 正在启动 ComfyUI 基础核心...>> "%bat_file_name%"
echo "%%PYTHON_DIR%%\python.exe" -s main.py --windows-standalone-build --enable-manager --listen 127.0.0.1 --port 8188 --enable-cors-header "*">> "%bat_file_name%"
echo pause>> "%bat_file_name%"

REM 完成提示
echo.
echo %green%====================================================%reset%
echo %yellow%       母盘与基础离线缓存库构建完成！%reset%
echo %yellow%       你可以双击运行目录下的 %bat_file_name% 来启动。%reset%
echo %green%====================================================%reset%
echo.
pause
