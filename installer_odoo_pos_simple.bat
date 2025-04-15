@echo off
:: Script d'installation Odoo POS en mode kiosk
:: Ce script télécharge la dernière version depuis GitHub, l'extrait et lance le script PowerShell avec les privileges d'administrateur

echo ===================================================
echo    Installation Odoo POS en mode kiosk
echo ===================================================
echo.

:: Verifier si le script est execute en tant qu'administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Ce script necessite des privileges d'administrateur.
    echo Relancement avec elevation de privileges...
    
    :: Relancer le script avec elevation de privileges
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Preparation de l'installation...
echo.

:: Créer un dossier temporaire
set TEMP_DIR=%TEMP%\odoo_pos_install
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
echo Dossier temporaire cree: %TEMP_DIR%

:: Télécharger la dernière version depuis GitHub
echo Telechargement de la derniere version depuis GitHub...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/SICALAIT/install_odoo_pos/archive/refs/heads/main.zip' -OutFile '%TEMP_DIR%\main.zip'"
if %errorLevel% neq 0 (
    echo Erreur lors du telechargement. Verifiez votre connexion internet.
    goto :cleanup
)
echo Telechargement termine avec succes.

:: Extraire l'archive
echo Extraction des fichiers...
powershell -Command "Expand-Archive -Path '%TEMP_DIR%\main.zip' -DestinationPath '%TEMP_DIR%'"
if %errorLevel% neq 0 (
    echo Erreur lors de l'extraction de l'archive.
    goto :cleanup
)
echo Extraction terminee avec succes.

:: Trouver le dossier extrait
for /d %%d in ("%TEMP_DIR%\*") do (
    set EXTRACT_DIR=%%d
)
echo Dossier extrait: %EXTRACT_DIR%

:: Definir l'URL Odoo (peut etre modifiee ici)
set ODOO_URL=https://redirect.groupe-sicalait.fr/5NjIN

:: Executer le script PowerShell avec bypass de la politique d'execution
echo Execution du script d'installation...
echo.
powershell -ExecutionPolicy Bypass -File "%EXTRACT_DIR%\install_odoo_pos_simple.ps1" -OdooURL "%ODOO_URL%"

:cleanup
:: Nettoyage des fichiers temporaires
echo Nettoyage des fichiers temporaires...
rmdir /s /q "%TEMP_DIR%"
echo Nettoyage termine.

echo.
echo Installation terminee. Appuyez sur une touche pour quitter...
pause >nul
