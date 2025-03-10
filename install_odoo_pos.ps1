<#
.SYNOPSIS
    Script d'installation automatisée pour Odoo POS en mode kiosk.
.DESCRIPTION
    Ce script effectue les opérations suivantes :
    - Télécharge et installe Google Chrome silencieusement
    - Télécharge le webservice cashdrawer depuis GitHub
    - Crée une tâche planifiée pour lancer le webservice au démarrage
    - Télécharge et installe l'extension Chrome pour le tiroir-caisse
    - Crée un raccourci sur le bureau en mode kiosk
.NOTES
    Version: 1.0.0
    Auteur: Script généré automatiquement
    Date de création: 10/03/2025
#>

# Configuration
param(
    [string]$OdooURL = "https://sdpmajdb-odoo17-dev-staging-sicalait-18269676.dev.odoo.com/",
    [string]$ConfigFile = "config.ini"
)

# Fonction pour lire le fichier de configuration INI
function Get-IniContent {
    param(
        [string]$FilePath
    )
    
    $ini = @{}
    
    if (Test-Path $FilePath) {
        Write-ColorOutput "Lecture du fichier de configuration: $FilePath" -ForegroundColor "Cyan"
        
        $section = "Default"
        $ini[$section] = @{}
        
        switch -regex -file $FilePath {
            "^\[(.+)\]" {
                $section = $matches[1]
                $ini[$section] = @{}
            }
            "(.+?)\s*=\s*(.*)" {
                $name, $value = $matches[1..2]
                $ini[$section][$name] = $value
            }
        }
    }
    else {
        Write-ColorOutput "Fichier de configuration non trouvé: $FilePath. Utilisation des valeurs par défaut." -ForegroundColor "Yellow"
    }
    
    return $ini
}

# Charger la configuration depuis le fichier INI
$config = Get-IniContent -FilePath $ConfigFile

# Appliquer les paramètres de configuration
if ($config["General"] -and $config["General"]["OdooURL"]) {
    # Ne pas écraser le paramètre de ligne de commande s'il est fourni
    if ($PSBoundParameters.ContainsKey('OdooURL') -eq $false) {
        $OdooURL = $config["General"]["OdooURL"]
    }
}

# Options d'installation
$installChrome = $true
$installWebservice = $true
$createScheduledTask = $true
$installExtension = $true
$createShortcut = $true
$customInstallPath = ""
$shortcutName = "Odoo POS"
$additionalChromeArgs = "--disable-translate --disable-infobars --noerrdialogs --disable-session-crashed-bubble"

# Appliquer les options depuis le fichier de configuration
if ($config["Options"]) {
    if ($null -ne $config["Options"]["InstallChrome"]) {
        $installChrome = [System.Convert]::ToBoolean($config["Options"]["InstallChrome"])
    }
    if ($null -ne $config["Options"]["InstallWebservice"]) {
        $installWebservice = [System.Convert]::ToBoolean($config["Options"]["InstallWebservice"])
    }
    if ($null -ne $config["Options"]["CreateScheduledTask"]) {
        $createScheduledTask = [System.Convert]::ToBoolean($config["Options"]["CreateScheduledTask"])
    }
    if ($null -ne $config["Options"]["InstallExtension"]) {
        $installExtension = [System.Convert]::ToBoolean($config["Options"]["InstallExtension"])
    }
    if ($null -ne $config["Options"]["CreateShortcut"]) {
        $createShortcut = [System.Convert]::ToBoolean($config["Options"]["CreateShortcut"])
    }
}

# Options avancées
if ($config["Advanced"]) {
    if ($config["Advanced"]["CustomInstallPath"]) {
        $customInstallPath = $config["Advanced"]["CustomInstallPath"]
    }
    if ($config["Advanced"]["ShortcutName"]) {
        $shortcutName = $config["Advanced"]["ShortcutName"]
    }
    if ($config["Advanced"]["AdditionalChromeArgs"]) {
        $additionalChromeArgs = $config["Advanced"]["AdditionalChromeArgs"]
    }
}

# Fonction pour afficher les messages avec couleur
function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Fonction pour vérifier si l'exécution est en mode administrateur
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $user
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Vérifier si le script est exécuté en tant qu'administrateur
if (-not (Test-Administrator)) {
    Write-ColorOutput "Ce script nécessite des privilèges d'administrateur. Veuillez relancer PowerShell en tant qu'administrateur." -ForegroundColor "Red"
    exit 1
}

# Créer un dossier temporaire pour les téléchargements
$tempFolder = "$env:TEMP\OdooPOSInstall"
if (-not (Test-Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
}

# Créer un dossier d'installation
$installFolder = if ($customInstallPath -and $customInstallPath -ne "") {
    $customInstallPath
} else {
    "$env:ProgramFiles\OdooPOS"
}

if (-not (Test-Path $installFolder)) {
    New-Item -ItemType Directory -Path $installFolder -Force | Out-Null
}

# Fonction pour télécharger un fichier
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    Write-ColorOutput "Téléchargement de $Url vers $OutputPath..." -ForegroundColor "Cyan"
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        Write-ColorOutput "Téléchargement terminé avec succès." -ForegroundColor "Green"
        return $true
    }
    catch {
        Write-ColorOutput "Erreur lors du téléchargement: $_" -ForegroundColor "Red"
        return $false
    }
}

# 1. Télécharger et installer Google Chrome
if ($installChrome) {
    Write-ColorOutput "ÉTAPE 1: Installation de Google Chrome" -ForegroundColor "Yellow"

    $chromeInstallerPath = "$tempFolder\chrome_installer.exe"
    $chromeUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"

    if (Download-File -Url $chromeUrl -OutputPath $chromeInstallerPath) {
        Write-ColorOutput "Installation de Google Chrome..." -ForegroundColor "Cyan"
        Start-Process -FilePath $chromeInstallerPath -ArgumentList "/silent /install" -Wait
        Write-ColorOutput "Installation de Google Chrome terminée." -ForegroundColor "Green"
    }
    else {
        Write-ColorOutput "Impossible de télécharger Google Chrome. Vérifiez votre connexion internet." -ForegroundColor "Red"
        exit 1
    }
}
else {
    Write-ColorOutput "ÉTAPE 1: Installation de Google Chrome [IGNORÉE]" -ForegroundColor "Gray"
}

# 2. Télécharger le webservice cashdrawer
if ($installWebservice) {
    Write-ColorOutput "ÉTAPE 2: Téléchargement du webservice cashdrawer" -ForegroundColor "Yellow"

    $webservicePath = "$installFolder\cashdrawer_service.exe"
    $webserviceUrl = "https://github.com/ralphi2811/odoo_pos_cashdrawer_webservice/releases/download/v1.0.0/cashdrawer_service.exe"

    if (Download-File -Url $webserviceUrl -OutputPath $webservicePath) {
        Write-ColorOutput "Webservice téléchargé avec succès." -ForegroundColor "Green"
        
        # Exécuter le webservice une première fois pour valider l'accès
        Write-ColorOutput "Lancement du webservice pour la première fois pour valider l'accès..." -ForegroundColor "Cyan"
        Start-Process -FilePath $webservicePath -Wait
        Write-ColorOutput "Validation du webservice terminée." -ForegroundColor "Green"
    }
    else {
        Write-ColorOutput "Impossible de télécharger le webservice. Vérifiez votre connexion internet." -ForegroundColor "Red"
        exit 1
    }
}
else {
    Write-ColorOutput "ÉTAPE 2: Téléchargement du webservice cashdrawer [IGNORÉE]" -ForegroundColor "Gray"
}

# 3. Créer une tâche planifiée pour lancer le webservice au démarrage
if ($createScheduledTask -and $installWebservice) {
    Write-ColorOutput "ÉTAPE 3: Création de la tâche planifiée" -ForegroundColor "Yellow"

    $taskName = "OdooPOSCashdrawerService"
    $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($taskExists) {
        Write-ColorOutput "Suppression de la tâche planifiée existante..." -ForegroundColor "Cyan"
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    Write-ColorOutput "Création de la tâche planifiée..." -ForegroundColor "Cyan"
    $action = New-ScheduledTaskAction -Execute $webservicePath
    $trigger = New-ScheduledTaskTrigger -AtLogon
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
    Write-ColorOutput "Tâche planifiée créée avec succès." -ForegroundColor "Green"
}
else {
    Write-ColorOutput "ÉTAPE 3: Création de la tâche planifiée [IGNORÉE]" -ForegroundColor "Gray"
}

# 4. Télécharger et installer l'extension Chrome
if ($installExtension) {
    Write-ColorOutput "ÉTAPE 4: Installation de l'extension Chrome" -ForegroundColor "Yellow"

    $extensionPath = "$installFolder\chrome_extention_odoo_pos_cashdrawer.crx"
    $extensionUrl = "https://github.com/ralphi2811/chrome_extention_odoo_pos_cashdrawer/releases/download/1.0/chrome_extention_odoo_pos_cashdrawer.crx"

    if (Download-File -Url $extensionUrl -OutputPath $extensionPath) {
        Write-ColorOutput "Extension téléchargée avec succès." -ForegroundColor "Green"
        
        # Installer l'extension Chrome
        Write-ColorOutput "Installation de l'extension Chrome..." -ForegroundColor "Cyan"
        
        # Créer le dossier pour les préférences Chrome si nécessaire
        $chromePrefsFolder = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
        if (-not (Test-Path $chromePrefsFolder)) {
            New-Item -ItemType Directory -Path $chromePrefsFolder -Force | Out-Null
        }
        
        # Copier l'extension dans le dossier d'extensions Chrome
        # Note: Cette méthode est simplifiée, l'installation réelle d'extensions .crx nécessite des étapes supplémentaires
        # qui varient selon la version de Chrome et les politiques de sécurité
        
        Write-ColorOutput "Pour installer l'extension, veuillez suivre ces étapes manuelles:" -ForegroundColor "Magenta"
        Write-ColorOutput "1. Ouvrez Chrome" -ForegroundColor "White"
        Write-ColorOutput "2. Allez à chrome://extensions/" -ForegroundColor "White"
        Write-ColorOutput "3. Activez le 'Mode développeur' en haut à droite" -ForegroundColor "White"
        Write-ColorOutput "4. Faites glisser le fichier suivant dans la fenêtre:" -ForegroundColor "White"
        Write-ColorOutput "   $extensionPath" -ForegroundColor "Cyan"
        Write-ColorOutput "5. Confirmez l'installation" -ForegroundColor "White"
        
        # Alternative: Utiliser les politiques de groupe pour installer l'extension
        Write-ColorOutput "Alternative pour les administrateurs système:" -ForegroundColor "Magenta"
        Write-ColorOutput "Vous pouvez utiliser les politiques de groupe pour déployer l'extension." -ForegroundColor "White"
        Write-ColorOutput "Consultez: https://support.google.com/chrome/a/answer/7517525" -ForegroundColor "White"
    }
    else {
        Write-ColorOutput "Impossible de télécharger l'extension Chrome. Vérifiez votre connexion internet." -ForegroundColor "Red"
    }
}
else {
    Write-ColorOutput "ÉTAPE 4: Installation de l'extension Chrome [IGNORÉE]" -ForegroundColor "Gray"
}

# 5. Télécharger l'icône Odoo POS
Write-ColorOutput "ÉTAPE 5: Téléchargement de l'icône Odoo POS" -ForegroundColor "Yellow"

$iconUrl = "https://www.odoo.com/web/image/res.users/752553/image_1024?unique=a98f5c5"
$iconPath = "$installFolder\odoo_pos_icon.ico"
$tempIconPath = "$tempFolder\odoo_pos_icon.png"

if (Download-File -Url $iconUrl -OutputPath $tempIconPath) {
    Write-ColorOutput "Icône téléchargée avec succès." -ForegroundColor "Green"
    
    # Conversion de l'image en icône (nécessite PowerShell 7 ou supérieur avec le module System.Drawing)
    try {
        Add-Type -AssemblyName System.Drawing
        $image = [System.Drawing.Image]::FromFile($tempIconPath)
        $icon = [System.Drawing.Icon]::FromHandle($image.GetHicon())
        $fileStream = New-Object System.IO.FileStream($iconPath, [System.IO.FileMode]::Create)
        $icon.Save($fileStream)
        $fileStream.Close()
        $icon.Dispose()
        $image.Dispose()
        Write-ColorOutput "Conversion de l'icône terminée." -ForegroundColor "Green"
    }
    catch {
        Write-ColorOutput "Erreur lors de la conversion de l'icône: $_" -ForegroundColor "Red"
        Write-ColorOutput "Utilisation d'une icône par défaut..." -ForegroundColor "Yellow"
        $iconPath = "$env:SystemRoot\System32\shell32.dll,22"  # Icône par défaut de Windows
    }
}
else {
    Write-ColorOutput "Impossible de télécharger l'icône. Utilisation d'une icône par défaut." -ForegroundColor "Yellow"
    $iconPath = "$env:SystemRoot\System32\shell32.dll,22"  # Icône par défaut de Windows
}

# 6. Créer un raccourci sur le bureau en mode kiosk
if ($createShortcut) {
    Write-ColorOutput "ÉTAPE 6: Création du raccourci sur le bureau" -ForegroundColor "Yellow"

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktopPath\$shortcutName.lnk"
    $chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    if (-not (Test-Path $chromePath)) {
        $chromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
    }

    $kioskArguments = "--kiosk --app=$OdooURL $additionalChromeArgs"

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $chromePath
    $Shortcut.Arguments = $kioskArguments
    $Shortcut.IconLocation = $iconPath
    $Shortcut.Description = "Odoo Point of Sale en mode kiosk"
    $Shortcut.Save()

    Write-ColorOutput "Raccourci créé avec succès sur le bureau." -ForegroundColor "Green"
}
else {
    Write-ColorOutput "ÉTAPE 6: Création du raccourci sur le bureau [IGNORÉE]" -ForegroundColor "Gray"
}

# Nettoyage
Write-ColorOutput "Nettoyage des fichiers temporaires..." -ForegroundColor "Cyan"
Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue

# Fin de l'installation
Write-ColorOutput "Installation terminée avec succès!" -ForegroundColor "Green"
Write-ColorOutput "Vous pouvez maintenant lancer Odoo POS en mode kiosk en utilisant le raccourci sur le bureau." -ForegroundColor "White"
Write-ColorOutput "URL configurée: $OdooURL" -ForegroundColor "Cyan"
