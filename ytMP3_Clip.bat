@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

:: クリップボードからURLを取得
for /f "usebackq delims=" %%A in (`powershell -command "Get-Clipboard"`) do set "url=%%A"

:: URLが空または"http"で始まっていない場合は終了
echo %url% | findstr /b /i "http" >nul
if errorlevel 1 (
    echo クリップボードに動画のURLをコピーしてください。
    timeout /t 5 >nul
    exit /b
)

:: 実行処理
echo URLを確認しました：%url%

:: yt-dlpで処理を実行
yt-dlp -x --audio-quality 0 --audio-format mp3 -o "%%(playlist_index|)s- %%(title)s.%%(ext)s" "%url%"

:: ファイル名が " - "で始まっている場合に " - " を削除
for %%f in (*.mp3) do (
    echo Processing: %%f

    set "filename=%%f"
    if "!filename:~0,2!"=="- " (
        echo "' - ' found, renaming"
        set "newname=!filename:~2!"
        ren "%%f" "!newname!"
    )
)

endlocal
exit /b
