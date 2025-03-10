@echo off
:: Script d'installation Odoo POS en mode kiosk
:: Ce script lance le script PowerShell avec les privileges d'administrateur

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

echo Execution du script d'installation...
echo.

:: Definir l'URL Odoo (peut etre modifiee ici)
set ODOO_URL=https://sdpmajdb-odoo17-dev-staging-sicalait-18269676.dev.odoo.com/

:: Executer le script PowerShell avec bypass de la politique d'execution
powershell -ExecutionPolicy Bypass -File "%~dp0install_odoo_pos_simple.ps1" -OdooURL "%ODOO_URL%"

echo.
echo Installation terminee. Appuyez sur une touche pour quitter...
pause >nul
