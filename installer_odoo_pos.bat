@echo off
:: Script d'installation Odoo POS en mode kiosk
:: Ce script lance le script PowerShell avec les privilèges d'administrateur

echo ===================================================
echo    Installation Odoo POS en mode kiosk
echo ===================================================
echo.

:: Vérifier si le script est exécuté en tant qu'administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Ce script nécessite des privilèges d'administrateur.
    echo Relancement avec élévation de privilèges...
    
    :: Relancer le script avec élévation de privilèges
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Exécution du script d'installation...
echo.

:: Vérifier si le fichier de configuration existe
if exist "%~dp0config.ini" (
    echo Fichier de configuration trouvé: config.ini
    echo Utilisation des paramètres du fichier de configuration...
) else (
    echo Fichier de configuration non trouvé.
    echo Utilisation des paramètres par défaut...
)

:: Exécuter le script PowerShell avec bypass de la politique d'exécution
powershell -ExecutionPolicy Bypass -File "%~dp0install_odoo_pos.ps1" -ConfigFile "%~dp0config.ini"

echo.
echo Installation terminée. Appuyez sur une touche pour quitter...
pause >nul
