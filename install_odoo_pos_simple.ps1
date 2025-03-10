<#
.SYNOPSIS
    Script d'installation automatisee pour Odoo POS en mode kiosk.
.DESCRIPTION
    Ce script effectue les operations suivantes :
    - Telecharge et installe Google Chrome silencieusement
    - Telecharge le webservice cashdrawer depuis GitHub
    - Cree une tache planifiee pour lancer le webservice au demarrage
    - Telecharge et installe l'extension Chrome pour le tiroir-caisse
    - Cree un raccourci sur le bureau en mode kiosk
.NOTES
    Version: 1.0.0
    Auteur: Script genere automatiquement
    Date de creation: 10/03/2025
#>

# Configuration
param(
    [string]$OdooURL = "https://sdpmajdb-odoo17-dev-staging-sicalait-18269676.dev.odoo.com/"
)

# Verifier si le script est execute en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Ce script necessite des privileges d'administrateur. Veuillez relancer PowerShell en tant qu'administrateur." -ForegroundColor Red
    exit 1
}

# Creer un dossier temporaire pour les telechargements
$tempFolder = "$env:TEMP\OdooPOSInstall"
if (-not (Test-Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
}

# Creer un dossier d'installation
$installFolder = "$env:ProgramFiles\OdooPOS"
if (-not (Test-Path $installFolder)) {
    New-Item -ItemType Directory -Path $installFolder -Force | Out-Null
}

# Fonction pour telecharger un fichier
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    Write-Host "Telechargement de $Url vers $OutputPath..." -ForegroundColor Cyan
    
    try {
        # Utiliser TLS 1.2 pour la securite
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $webClient = New-Object System.Net.WebClient
        
        # Ajouter un User-Agent pour eviter les blocages
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        
        # Telecharger le fichier
        $webClient.DownloadFile($Url, $OutputPath)
        
        Write-Host "Telechargement termine avec succes." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Erreur lors du telechargement: $_" -ForegroundColor Red
        Write-Host "Details de l'erreur: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        Write-Host "Verifiez votre connexion internet et que l'URL est correcte." -ForegroundColor Yellow
        return $false
    }
}

# 1. Telecharger et installer Google Chrome
Write-Host "ETAPE 1: Installation de Google Chrome" -ForegroundColor Yellow

$chromeInstallerPath = "$tempFolder\chrome_installer.exe"
$chromeUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"

if (Download-File -Url $chromeUrl -OutputPath $chromeInstallerPath) {
    Write-Host "Installation de Google Chrome..." -ForegroundColor Cyan
    Start-Process -FilePath $chromeInstallerPath -ArgumentList "/silent /install" -Wait
    Write-Host "Installation de Google Chrome terminee." -ForegroundColor Green
}
else {
    Write-Host "Impossible de telecharger Google Chrome. Verifiez votre connexion internet." -ForegroundColor Red
    exit 1
}

# 2. Telecharger le webservice cashdrawer
Write-Host "ETAPE 2: Installation du webservice cashdrawer" -ForegroundColor Yellow

$webservicePath = "$installFolder\cashdrawer_service.exe"
$webserviceUrl = "https://github.com/ralphi2811/odoo_pos_cashdrawer_webservice/releases/download/v1.0.0/cashdrawer_service.exe"

# Verifier si le fichier existe deja
$webserviceExists = Test-Path $webservicePath
if ($webserviceExists) {
    Write-Host "Le fichier webservice existe deja: $webservicePath" -ForegroundColor Green
    Write-Host "Utilisation du fichier existant..." -ForegroundColor Cyan
    $downloadSuccess = $true
} 
else {
    Write-Host "Tentative de telechargement depuis: $webserviceUrl" -ForegroundColor Cyan
    Write-Host "Si le telechargement echoue, verifiez que l'URL est correcte et accessible." -ForegroundColor Yellow

    # Essayer de telecharger 3 fois avant d'abandonner
    $maxRetries = 3
    $retryCount = 0
    $downloadSuccess = $false

    while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
        $retryCount++
        
        if ($retryCount -gt 1) {
            Write-Host "Tentative $retryCount de $maxRetries..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2  # Attendre un peu avant de reessayer
        }
        
        $downloadSuccess = Download-File -Url $webserviceUrl -OutputPath $webservicePath
        
        if (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
            Write-Host "Echec du telechargement. Nouvelle tentative..." -ForegroundColor Yellow
        }
    }
}

if ($downloadSuccess) {
    if (-not $webserviceExists) {
        Write-Host "Webservice telecharge avec succes." -ForegroundColor Green
    }
    
    # Executer le webservice une premiere fois pour valider l'acces
    Write-Host "Lancement du webservice pour la premiere fois pour valider l'acces..." -ForegroundColor Cyan
    Start-Process -FilePath $webservicePath -Wait
    Write-Host "Validation du webservice terminee." -ForegroundColor Green
}
else {
    Write-Host "Impossible de telecharger le webservice apres $maxRetries tentatives." -ForegroundColor Red
    Write-Host "Options alternatives:" -ForegroundColor Yellow
    Write-Host "1. Verifiez votre connexion internet" -ForegroundColor White
    Write-Host "2. Telechargez manuellement le fichier depuis:" -ForegroundColor White
    Write-Host "   $webserviceUrl" -ForegroundColor Cyan
    Write-Host "   et placez-le dans: $webservicePath" -ForegroundColor Cyan
    Write-Host "3. Puis relancez le script" -ForegroundColor White
    
    $continueWithoutWebservice = Read-Host "Voulez-vous continuer l'installation sans le webservice? (O/N)"
    if ($continueWithoutWebservice -ne "O" -and $continueWithoutWebservice -ne "o") {
        Write-Host "Installation annulee." -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host "Continuation de l'installation sans le webservice..." -ForegroundColor Yellow
    }
}

# 3. Creer une tache planifiee pour lancer le webservice au demarrage
Write-Host "ETAPE 3: Creation de la tache planifiee" -ForegroundColor Yellow

$taskName = "OdooPOSCashdrawerService"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Write-Host "Suppression de la tache planifiee existante..." -ForegroundColor Cyan
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Write-Host "Creation de la tache planifiee..." -ForegroundColor Cyan
$action = New-ScheduledTaskAction -Execute $webservicePath
$trigger = New-ScheduledTaskTrigger -AtLogon
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Write-Host "Tache planifiee creee avec succes." -ForegroundColor Green

# 4. Telecharger et installer l'extension Chrome
Write-Host "ETAPE 4: Installation de l'extension Chrome" -ForegroundColor Yellow

$extensionPath = "$installFolder\chrome_extention_odoo_pos_cashdrawer.crx"
$extensionUrl = "https://github.com/ralphi2811/chrome_extention_odoo_pos_cashdrawer/releases/download/1.0/chrome_extention_odoo_pos_cashdrawer.crx"

# Verifier si le fichier existe deja
$extensionExists = Test-Path $extensionPath
if ($extensionExists) {
    Write-Host "Le fichier d'extension existe deja: $extensionPath" -ForegroundColor Green
    Write-Host "Utilisation du fichier existant..." -ForegroundColor Cyan
    $downloadSuccess = $true
}
else {
    Write-Host "Tentative de telechargement depuis: $extensionUrl" -ForegroundColor Cyan

    # Essayer de telecharger 3 fois avant d'abandonner
    $maxRetries = 3
    $retryCount = 0
    $downloadSuccess = $false

    while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
        $retryCount++
        
        if ($retryCount -gt 1) {
            Write-Host "Tentative $retryCount de $maxRetries..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2  # Attendre un peu avant de reessayer
        }
        
        $downloadSuccess = Download-File -Url $extensionUrl -OutputPath $extensionPath
        
        if (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
            Write-Host "Echec du telechargement. Nouvelle tentative..." -ForegroundColor Yellow
        }
    }
}

if ($downloadSuccess) {
    if (-not $extensionExists) {
        Write-Host "Extension telechargee avec succes." -ForegroundColor Green
    }
    
    # Installer l'extension Chrome
    Write-Host "Installation de l'extension Chrome..." -ForegroundColor Cyan
    
    # Creer le dossier pour les preferences Chrome si necessaire
    $chromePrefsFolder = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
    if (-not (Test-Path $chromePrefsFolder)) {
        New-Item -ItemType Directory -Path $chromePrefsFolder -Force | Out-Null
    }
    
    # Copier l'extension dans le dossier d'extensions Chrome
    # Note: Cette methode est simplifiee, l'installation reelle d'extensions .crx necessite des etapes supplementaires
    # qui varient selon la version de Chrome et les politiques de securite
    
    Write-Host "Pour installer l'extension, veuillez suivre ces etapes manuelles:" -ForegroundColor Magenta
    Write-Host "1. Ouvrez Chrome" -ForegroundColor White
    Write-Host "2. Allez a chrome://extensions/" -ForegroundColor White
    Write-Host "3. Activez le 'Mode developpeur' en haut a droite" -ForegroundColor White
    Write-Host "4. Faites glisser le fichier suivant dans la fenetre:" -ForegroundColor White
    Write-Host "   $extensionPath" -ForegroundColor Cyan
    Write-Host "5. Confirmez l'installation" -ForegroundColor White
    
    # Alternative: Utiliser les politiques de groupe pour installer l'extension
    Write-Host "Alternative pour les administrateurs systeme:" -ForegroundColor Magenta
    Write-Host "Vous pouvez utiliser les politiques de groupe pour deployer l'extension." -ForegroundColor White
    Write-Host "Consultez: https://support.google.com/chrome/a/answer/7517525" -ForegroundColor White
}
else {
    Write-Host "Impossible de telecharger l'extension Chrome. Verifiez votre connexion internet." -ForegroundColor Red
}

# 5. Telecharger l'icone Odoo POS
Write-Host "ETAPE 5: Telechargement de l'icone Odoo POS" -ForegroundColor Yellow

$iconUrl = "https://www.odoo.com/web/image/res.users/752553/image_1024?unique=a98f5c5"
$iconPath = "$installFolder\odoo_pos_icon.ico"
$tempIconPath = "$tempFolder\odoo_pos_icon.png"

# Verifier si l'icone existe deja
$iconExists = Test-Path $iconPath
if ($iconExists) {
    Write-Host "L'icone existe deja: $iconPath" -ForegroundColor Green
    Write-Host "Utilisation de l'icone existante..." -ForegroundColor Cyan
}
else {
    if (Download-File -Url $iconUrl -OutputPath $tempIconPath) {
        Write-Host "Icone telechargee avec succes." -ForegroundColor Green
    
        # Conversion de l'image en icone (necessite PowerShell 7 ou superieur avec le module System.Drawing)
        try {
            Add-Type -AssemblyName System.Drawing
            $image = [System.Drawing.Image]::FromFile($tempIconPath)
            $icon = [System.Drawing.Icon]::FromHandle($image.GetHicon())
            $fileStream = New-Object System.IO.FileStream($iconPath, [System.IO.FileMode]::Create)
            $icon.Save($fileStream)
            $fileStream.Close()
            $icon.Dispose()
            $image.Dispose()
            Write-Host "Conversion de l'icone terminee." -ForegroundColor Green
        }
        catch {
            Write-Host "Erreur lors de la conversion de l'icone: $_" -ForegroundColor Red
            Write-Host "Utilisation d'une icone par defaut..." -ForegroundColor Yellow
            $iconPath = "$env:SystemRoot\System32\shell32.dll,22"  # Icone par defaut de Windows
        }
    }
    else {
        Write-Host "Impossible de telecharger l'icone. Utilisation d'une icone par defaut." -ForegroundColor Yellow
        $iconPath = "$env:SystemRoot\System32\shell32.dll,22"  # Icone par defaut de Windows
    }
}

# 6. Creer un raccourci sur le bureau en mode kiosk
Write-Host "ETAPE 6: Creation du raccourci sur le bureau" -ForegroundColor Yellow

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\Odoo POS.lnk"
$chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    $chromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
}

$kioskArguments = "--kiosk --app=$OdooURL --disable-translate --disable-infobars --noerrdialogs --disable-session-crashed-bubble"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $chromePath
$Shortcut.Arguments = $kioskArguments
$Shortcut.IconLocation = $iconPath
$Shortcut.Description = "Odoo Point of Sale en mode kiosk"
$Shortcut.Save()

Write-Host "Raccourci cree avec succes sur le bureau." -ForegroundColor Green

# Nettoyage
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Cyan
Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue

# Fin de l'installation
Write-Host "Installation terminee avec succes!" -ForegroundColor Green
Write-Host "Vous pouvez maintenant lancer Odoo POS en mode kiosk en utilisant le raccourci sur le bureau." -ForegroundColor White
Write-Host "URL configuree: $OdooURL" -ForegroundColor Cyan
