@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

:: クリップボードからURLを取得
for /f "usebackq delims=" %%A in (`powershell -command "Get-Clipboard"`) do (
    set "url=%%A"
)

if not defined url (
    echo Failed to get URL from clipboard.
    exit /b
)

echo URL: !url!

:: URLの先頭にMP3が含まれる場合はMP3出力
echo !url! | findstr /I "^MP3" >nul
if !errorlevel! == 0 (
    echo MP3 mode forced by clipboard content.
    set "url=!url:~3!"
    yt-dlp -x --audio-quality 0 --audio-format mp3 -o "%%(title)s.%%(ext)s" "!url!"
    goto rename
)

:: TVer対応
echo !url! | findstr /C:"tver.jp" >nul
if !errorlevel! == 0 (
    echo Fetching format info for TVer...
    set "bestvideo="
    set "bestaudio="
    for /f "delims=" %%f in ('yt-dlp --list-formats "!url!" 2^>nul ^| findstr /R "^hls-[0-9]"') do (
        set "line=%%f"
        for /f "tokens=1" %%a in ("!line!") do (
            if not defined bestvideo set "bestvideo=%%a"
        )
    )
    for /f "delims=" %%f in ('yt-dlp --list-formats "!url!" 2^>nul ^| findstr /R "^hls-ts_AUDIO"') do (
        set "line=%%f"
        for /f "tokens=1" %%a in ("!line!") do (
            if not defined bestaudio set "bestaudio=%%a"
        )
    )
    if defined bestvideo if defined bestaudio (
        echo Downloading with: !bestvideo!+!bestaudio!
        yt-dlp -f "!bestvideo!+!bestaudio!" -o "%%(title)s.%%(ext)s" "!url!"
    ) else (
        echo Failed to detect best formats, fallback to default.
        yt-dlp -o "%%(title)s.%%(ext)s" "!url!"
    )
    goto rename
)

:: bilibili対応
echo !url! | findstr /C:"bilibili.com" >nul
if !errorlevel! == 0 (
    yt-dlp -f 30080+30280 -o "%%(title)s.%%(ext)s" "!url!"
    goto rename
)

:: youtube対応
echo !url! | findstr /C:"youtube.com" >nul
if !errorlevel! == 0 (
    yt-dlp -f b --write-sub --write-auto-sub --sub-lang en,ja --merge-output-format mp4 -o "%%(title)s.%%(ext)s" "!url!"
    goto rename
)

:: その他はMP3
yt-dlp -x --audio-quality 0 --audio-format mp3 -o "%%(playlist_index|)s- %%(title)s.%%(ext)s" "!url!"

:rename
for %%f in (*.*) do (
    set "filename=%%f"
    if "!filename:~0,2!"=="- " (
        set "newname=!filename:~2!"
        ren "%%f" "!newname!"
    )
)

endlocal
