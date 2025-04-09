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
    [string]$OdooURL = "https://redirect.groupe-sicalait.fr/5NjIN"
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
    
    # Créer le dossier logs et le fichier cashdrawer.log nécessaires au webservice
    $logFolder = "$installFolder\logs"
    $logFile = "$logFolder\cashdrawer.log"
    
    if (-not (Test-Path $logFolder)) {
        Write-Host "Création du dossier logs..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
        Write-Host "Dossier logs créé avec succès." -ForegroundColor Green
    }
    
    if (-not (Test-Path $logFile)) {
        Write-Host "Création du fichier cashdrawer.log..." -ForegroundColor Cyan
        New-Item -ItemType File -Path $logFile -Force | Out-Null
        Write-Host "Fichier cashdrawer.log créé avec succès." -ForegroundColor Green
    }
    
    # Executer le webservice une premiere fois pour valider l'acces
    Write-Host "Lancement du webservice pour la premiere fois pour valider l'acces..." -ForegroundColor Cyan
    $webserviceProcess = Start-Process -FilePath $webservicePath -PassThru
    
    # Attendre quelques secondes pour que le webservice démarre
    Start-Sleep -Seconds 5
    
    # Vérifier si le processus est toujours en cours d'exécution
    if (Get-Process -Id $webserviceProcess.Id -ErrorAction SilentlyContinue) {
        Write-Host "Le webservice a démarré avec succès." -ForegroundColor Green
        
        # Arrêter le processus pour continuer l'installation
        Write-Host "Arrêt du webservice pour continuer l'installation..." -ForegroundColor Cyan
        Stop-Process -Id $webserviceProcess.Id -Force
        Write-Host "Webservice arrêté. Il sera redémarré automatiquement au prochain démarrage." -ForegroundColor Green
    } else {
        Write-Host "Le webservice semble s'être arrêté de manière inattendue." -ForegroundColor Yellow
        Write-Host "Vérifiez les journaux pour plus d'informations." -ForegroundColor Yellow
    }
    
    Write-Host "Validation du webservice terminée." -ForegroundColor Green
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

$extensionZipPath = "$tempFolder\chrome_extension_odoo_pos_cashdrawer.zip"
$extensionUrl = "https://github.com/SICALAIT/chrome_extention_odoo_pos_cashdrawer/archive/refs/tags/1.0.zip"
$extensionExtractPath = "$installFolder\chrome_extension_odoo_pos_cashdrawer"

# Verifier si le dossier d'extension existe deja
$extensionExists = Test-Path $extensionExtractPath
if ($extensionExists) {
    Write-Host "Le dossier d'extension existe deja: $extensionExtractPath" -ForegroundColor Green
    Write-Host "Utilisation de l'extension existante..." -ForegroundColor Cyan
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
        
        $downloadSuccess = Download-File -Url $extensionUrl -OutputPath $extensionZipPath
        
        if (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
            Write-Host "Echec du telechargement. Nouvelle tentative..." -ForegroundColor Yellow
        }
    }

    if ($downloadSuccess) {
        Write-Host "Extension telechargee avec succes." -ForegroundColor Green
        
        # Extraire le fichier ZIP
        Write-Host "Extraction de l'extension..." -ForegroundColor Cyan
        
        try {
            # Créer le dossier d'extraction s'il n'existe pas
            if (-not (Test-Path $extensionExtractPath)) {
                New-Item -ItemType Directory -Path $extensionExtractPath -Force | Out-Null
            }
            
            # Extraire le ZIP
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($extensionZipPath, $tempFolder)
            
            # Le ZIP extrait crée un dossier avec le nom du projet et le tag, déplacer son contenu
            $extractedFolder = Get-ChildItem -Path $tempFolder -Directory | Where-Object { $_.Name -like "chrome_extention_odoo_pos_cashdrawer*" } | Select-Object -First 1
            
            if ($extractedFolder) {
                # Copier le contenu du dossier extrait vers le dossier d'installation
                Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $extensionExtractPath -Recurse -Force
                Write-Host "Extension extraite avec succes dans: $extensionExtractPath" -ForegroundColor Green
            } else {
                Write-Host "Impossible de trouver le dossier extrait." -ForegroundColor Red
                $downloadSuccess = $false
            }
        }
        catch {
            Write-Host "Erreur lors de l'extraction de l'extension: $_" -ForegroundColor Red
            $downloadSuccess = $false
        }
    }
}

if ($downloadSuccess) {
    # Instructions pour installer l'extension non empaquetée
    Write-Host "Pour installer l'extension, veuillez suivre ces etapes manuelles:" -ForegroundColor Magenta
    Write-Host "1. Ouvrez Chrome" -ForegroundColor White
    Write-Host "2. Allez a chrome://extensions/" -ForegroundColor White
    Write-Host "3. Activez le 'Mode developpeur' en haut a droite" -ForegroundColor White
    Write-Host "4. Cliquez sur 'Charger l'extension non empaquetee'" -ForegroundColor White
    Write-Host "5. Naviguez et selectionnez le dossier suivant:" -ForegroundColor White
    Write-Host "   $extensionExtractPath" -ForegroundColor Cyan
    
    # Alternative: Utiliser les politiques de groupe pour installer l'extension
    Write-Host "Alternative pour les administrateurs systeme:" -ForegroundColor Magenta
    Write-Host "Vous pouvez utiliser les politiques de groupe pour deployer l'extension." -ForegroundColor White
    Write-Host "Consultez: https://support.google.com/chrome/a/answer/7517525" -ForegroundColor White
}
else {
    Write-Host "Impossible de telecharger ou d'extraire l'extension Chrome. Verifiez votre connexion internet." -ForegroundColor Red
}

# 4b. Telecharger et installer l'extension Chrome pour l'échéancier
Write-Host "ETAPE 4b: Installation de l'extension Chrome pour l'échéancier" -ForegroundColor Yellow

$echeancierZipPath = "$tempFolder\chrome_extension_odoo_pos_echeancier.zip"
$echeancierUrl = "https://github.com/SICALAIT/chrome_extension_odoo_pos_echeancier/archive/refs/tags/1.0.0.zip"
$echeancierExtractPath = "$installFolder\chrome_extension_odoo_pos_echeancier"

# Verifier si le dossier d'extension existe deja
$echeancierExists = Test-Path $echeancierExtractPath
if ($echeancierExists) {
    Write-Host "Le dossier d'extension pour l'échéancier existe deja: $echeancierExtractPath" -ForegroundColor Green
    Write-Host "Utilisation de l'extension existante..." -ForegroundColor Cyan
    $echeancierDownloadSuccess = $true
}
else {
    Write-Host "Tentative de telechargement depuis: $echeancierUrl" -ForegroundColor Cyan

    # Essayer de telecharger 3 fois avant d'abandonner
    $maxRetries = 3
    $retryCount = 0
    $echeancierDownloadSuccess = $false

    while (-not $echeancierDownloadSuccess -and $retryCount -lt $maxRetries) {
        $retryCount++
        
        if ($retryCount -gt 1) {
            Write-Host "Tentative $retryCount de $maxRetries..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2  # Attendre un peu avant de reessayer
        }
        
        $echeancierDownloadSuccess = Download-File -Url $echeancierUrl -OutputPath $echeancierZipPath
        
        if (-not $echeancierDownloadSuccess -and $retryCount -lt $maxRetries) {
            Write-Host "Echec du telechargement. Nouvelle tentative..." -ForegroundColor Yellow
        }
    }

    if ($echeancierDownloadSuccess) {
        Write-Host "Extension échéancier telechargee avec succes." -ForegroundColor Green
        
        # Extraire le fichier ZIP
        Write-Host "Extraction de l'extension échéancier..." -ForegroundColor Cyan
        
        try {
            # Créer le dossier d'extraction s'il n'existe pas
            if (-not (Test-Path $echeancierExtractPath)) {
                New-Item -ItemType Directory -Path $echeancierExtractPath -Force | Out-Null
            }
            
            # Extraire le ZIP
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($echeancierZipPath, $tempFolder)
            
            # Le ZIP extrait crée un dossier avec le nom du projet et le tag, déplacer son contenu
            $extractedFolder = Get-ChildItem -Path $tempFolder -Directory | Where-Object { $_.Name -like "chrome_extension_odoo_pos_echeancier*" } | Select-Object -First 1
            
            if ($extractedFolder) {
                # Copier le contenu du dossier extrait vers le dossier d'installation
                Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $echeancierExtractPath -Recurse -Force
                Write-Host "Extension échéancier extraite avec succes dans: $echeancierExtractPath" -ForegroundColor Green
            } else {
                Write-Host "Impossible de trouver le dossier extrait pour l'extension échéancier." -ForegroundColor Red
                $echeancierDownloadSuccess = $false
            }
        }
        catch {
            Write-Host "Erreur lors de l'extraction de l'extension échéancier: $_" -ForegroundColor Red
            $echeancierDownloadSuccess = $false
        }
    }
}

if ($echeancierDownloadSuccess) {
    # Instructions pour installer l'extension non empaquetée
    Write-Host "Pour installer l'extension échéancier, veuillez suivre ces etapes manuelles:" -ForegroundColor Magenta
    Write-Host "1. Ouvrez Chrome" -ForegroundColor White
    Write-Host "2. Allez a chrome://extensions/" -ForegroundColor White
    Write-Host "3. Activez le 'Mode developpeur' en haut a droite" -ForegroundColor White
    Write-Host "4. Cliquez sur 'Charger l'extension non empaquetee'" -ForegroundColor White
    Write-Host "5. Naviguez et selectionnez le dossier suivant:" -ForegroundColor White
    Write-Host "   $echeancierExtractPath" -ForegroundColor Cyan
}
else {
    Write-Host "Impossible de telecharger ou d'extraire l'extension Chrome pour l'échéancier. Verifiez votre connexion internet." -ForegroundColor Red
}

# 5. Utiliser l'icone Odoo POS incluse dans le dépôt
Write-Host "ETAPE 5: Utilisation de l'icone Odoo POS" -ForegroundColor Yellow

# Chemin du script actuel
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$iconSourcePath = Join-Path -Path $scriptPath -ChildPath "icon-odoo-POS.ico"
$iconPath = "$installFolder\odoo_pos_icon.ico"

# Vérifier si l'icône existe déjà dans le dossier d'installation
$iconExists = Test-Path $iconPath
if ($iconExists) {
    Write-Host "L'icone existe deja dans le dossier d'installation: $iconPath" -ForegroundColor Green
    Write-Host "Utilisation de l'icone existante..." -ForegroundColor Cyan
}
else {
    # Vérifier si l'icône source existe
    if (Test-Path $iconSourcePath) {
        Write-Host "Copie de l'icone depuis: $iconSourcePath" -ForegroundColor Cyan
        Copy-Item -Path $iconSourcePath -Destination $iconPath -Force
        Write-Host "Icone copiée avec succès." -ForegroundColor Green
    }
    else {
        Write-Host "Icone source introuvable: $iconSourcePath" -ForegroundColor Red
        Write-Host "Utilisation d'une icone par defaut..." -ForegroundColor Yellow
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
