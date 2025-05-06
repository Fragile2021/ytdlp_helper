:: 2025.4.8 ver1.0 TVer format auto-selection added
:: 2025.4.9 ver1.2 Handle MP3-prefixed .URL files for audio-only download
:: 2025.4.9 ver1.3 if a given file name starts with "MP3", download its audio as .MP3 file
@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"
set "file=%~1"

:: .URLファイルの場合、URLを抽出
if /i "%file:~-4%"==".url" (
    set "basename=%~n1"
    for /f "usebackq delims=" %%A in ("%file%") do (
        echo %%A | findstr /B /C:"URL=" >nul && set "url=%%A"
    )

    if defined url (
        set "url=!url:~4!"  & REM "URL=" の最初の4文字を削除

        rem ファイル名が MP3 で始まる場合はMP3出力
        echo File name: !basename!
        echo !basename! | findstr /I "^MP3" >nul
        if !errorlevel! == 0 (
            echo MP3 mode forced by filename.
            yt-dlp -x --audio-quality 0 --audio-format mp3 -o "%%(title)s.%%(ext)s" "!url!"
            goto rename
        )

        rem ドメインごとのフォーマット分岐
        echo URL: !url!
        echo Checking domain...

        :: TVerの場合、自動で最高画質＋音質を取得
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

        echo !url! | findstr /C:"bilibili.com" >nul
        if !errorlevel! == 0 (
            yt-dlp -f 30080+30280 -o "%%(title)s.%%(ext)s" "!url!"
            goto rename
        )

        echo !url! | findstr /C:"youtube.com" >nul
        if !errorlevel! == 0 (
            yt-dlp -f b --merge-output-format mp4 -o "%%(title)s.%%(ext)s" "!url!"
            goto rename
        )

        rem 該当しないドメインはMP3として通常処理
        yt-dlp -x --audio-quality 0 --audio-format mp3 -o "%%(playlist_index|)s- %%(title)s.%%(ext)s" "!url!"
    ) else (
        echo Failed to extract URL from "%file%"
    )

    :rename
    :: ファイル名が " - "で始まっている場合に " - " を削除
    for %%f in (*.*) do (
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
)

:: 通常のURLリストファイルの場合
if exist "%file%" (
    for /f "usebackq delims=" %%A in ("%file%") do (
        set "url=%%A"
        if not "!url!"=="" (
            yt-dlp -x --audio-quality 0 --audio-format mp3 -o "%%(title)s.mp3" "!url!"
        )
    )
) else (
    echo Invalid file or URL shortcut.
)

endlocal
