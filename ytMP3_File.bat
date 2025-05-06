:: 2025.4.7 ver1.2 Suppressed the white space to cope with silly windows file name rules
@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

set "file=%~1"

:: .URLファイルの場合、URLを抽出
if /i "%file:~-4%"==".url" (
    for /f "usebackq delims=" %%A in ("%file%") do (
        echo %%A | findstr /B /C:"URL=" >nul && set "url=%%A"
    )

    if defined url (
        set "url=!url:~4!"  & REM "URL=" の最初の4文字を削除
		yt-dlp -x --audio-quality 0 --audio-format mp3 -o "%%(playlist_index|)s- %%(title)s.%%(ext)s" "!url!"
    ) else (
        echo Failed to extract URL from "%file%"
    )

	:: ファイル名が " - "で始まっている場合に " - " を削除
	for %%f in (*.mp3) do (
		echo Processing: %%f

		:: ファイル名の先頭に " - " があるか確認
		set "filename=%%f"
		if "!filename:~0,2!"=="- " (
			echo "' - ' found, renaming"
			
			rem " - " があれば、" - " を取り除く
			set "newname=!filename:~2!"
			ren "%%f" "!newname!"
		) else (
			rem echo "No ' - ' at the beginning"
			rem " - " が無ければ、そのままの名前にする
			ren "%%f" "%%f"
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
