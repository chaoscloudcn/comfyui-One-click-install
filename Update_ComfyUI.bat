@echo off&&cd /d %~dp0
chcp 65001>nul
set "version_title=ComfyUI 一键便携更新脚本 v1.0"
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
echo %yellow%       欢迎使用 ComfyUI 一键便携更新脚本%reset%
echo %green%====================================================%reset%
echo.

REM 3. 检查核心组件是否存在
if not exist "ComfyUI\main.py" (
    echo %red%[ERROR]%reset% 未找到 ComfyUI 目录！请先运行 Install_ComfyUI.bat 进行安装。
    pause
    exit /b
)
if not exist "git\cmd\git.exe" (
    echo %red%[ERROR]%reset% 未找到便携版 Git！
    pause
    exit /b
)
if not exist "python\python.exe" (
    echo %red%[ERROR]%reset% 未找到便携版 Python！
    pause
    exit /b
)

REM 4. 配置临时环境变量
set "PATH=%~dp0python;%~dp0python\Scripts;%~dp0git\cmd;%PATH%"

REM 5. 更新 ComfyUI 源码
echo %green%[STEP]%reset% 正在拉取 ComfyUI 最新源码...
cd /d "%~dp0ComfyUI"
git pull

REM 6. 更新 ComfyUI 核心依赖
echo.
echo %green%[STEP]%reset% 正在检查并更新 ComfyUI 核心依赖包...
"%~dp0python\python.exe" -m uv pip install -r requirements.txt --index-url https://pypi.org/simple --extra-index-url https://mirrors.aliyun.com/pypi/simple/ --index-strategy unsafe-best-match

REM 7. 更新 ComfyUI 官方 Manager 依赖
echo.
echo %green%[STEP]%reset% 正在检查并更新官方 Manager 依赖包...
if exist "manager_requirements.txt" (
    "%~dp0python\python.exe" -m uv pip install -r manager_requirements.txt --index-url https://pypi.org/simple --extra-index-url https://mirrors.aliyun.com/pypi/simple/ --index-strategy unsafe-best-match
) else (
    echo %warning%[WARN]%reset% 未在 ComfyUI 目录找到 manager_requirements.txt，跳过此步。
)

REM 8. 完成提示
echo.
echo %green%====================================================%reset%
echo %yellow%       更新全部完成！%reset%
echo %green%====================================================%reset%
echo.
pause