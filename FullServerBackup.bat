@echo off
REM === Einstellungen ===
set "BACKUP_DIR=PFAD\ZU\DEINEM\BACKUP_VERZEICHNIS"
set "SERVER_DIR=PFAD\ZU\DEINEM\SERVER_VERZEICHNIS"
set "DB_DIR1=PFAD\ZU\DEINER\ERSTEN_DATENBANK"
set "DB_DIR2=PFAD\ZU\DEINER\ZWEITEN_DATENBANK"

REM === Datum im Format YYYY-MM-DD holen ===
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set DATE=%%i
set "BACKUP_NAME=FiveM_Backup_%DATE%.zip"

REM === Backup-Verzeichnis anlegen, falls nicht vorhanden ===
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
    if errorlevel 1 (
        echo Fehler: Backup-Verzeichnis konnte nicht erstellt werden!
        exit /b 1
    )
)

REM === MariaDB-Dienst stoppen ===
net stop MariaDB
if errorlevel 1 (
    echo Fehler: MariaDB-Dienst konnte nicht gestoppt werden!
    exit /b 1
)

REM === Cache-Ordner temporär umbenennen (falls vorhanden) ===
if exist "%SERVER_DIR%\cache" (
    ren "%SERVER_DIR%\cache" cache_temp
    if errorlevel 1 (
        echo Fehler: Cache-Ordner konnte nicht umbenannt werden!
        net start MariaDB
        exit /b 1
    )
)

REM === Backup mit Bordmitteln erstellen ===
powershell -NoProfile -Command "Compress-Archive -Path '%SERVER_DIR%\*','%DB_DIR1%\*','%DB_DIR2%\*' -DestinationPath '%BACKUP_DIR%\%BACKUP_NAME%'"
if errorlevel 1 (
    echo Fehler: Backup konnte nicht erstellt werden!
    if exist "%SERVER_DIR%\cache_temp" ren "%SERVER_DIR%\cache_temp" cache
    net start MariaDB
    exit /b 1
)

REM === Cache-Ordner zurückbenennen ===
if exist "%SERVER_DIR%\cache_temp" (
    ren "%SERVER_DIR%\cache_temp" cache
    if errorlevel 1 (
        echo Warnung: Cache-Ordner konnte nicht zurückbenannt werden!
    )
)

REM === MariaDB-Dienst wieder starten ===
net start MariaDB
if errorlevel 1 (
    echo Warnung: MariaDB-Dienst konnte nicht gestartet werden!
)

REM === Alte Backups löschen (älter als 7 Tage) ===
forfiles /p "%BACKUP_DIR%" /m "FiveM_Backup_*.zip" /d -7 /c "cmd /c del @path"

echo Backup abgeschlossen: %BACKUP_NAME%
