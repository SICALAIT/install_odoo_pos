# 🛒 Installation Automatisée Odoo POS en Mode Kiosk

Ce projet fournit un script PowerShell pour automatiser l'installation et la configuration d'un poste de vente Odoo POS en mode kiosk sur Windows 10/11.

## 📋 Fonctionnalités

Le script effectue automatiquement les opérations suivantes :

- ✅ Téléchargement et installation silencieuse de Google Chrome
- ✅ Téléchargement du webservice pour le tiroir-caisse
- ✅ Configuration d'une tâche planifiée pour lancer le webservice au démarrage
- ✅ Téléchargement et instructions pour l'installation des extensions Chrome :
  - Extension pour le tiroir-caisse
  - Extension pour l'échéancier
- ✅ Création d'un raccourci sur le bureau public en mode kiosk avec l'URL Odoo configurée
- ✅ Ouverture automatique de l'assistant de configuration du webservice

## 🚀 Prérequis

- Windows 10 ou Windows 11
- Droits d'administrateur sur le poste
- Connexion Internet active
- PowerShell 5.1 ou supérieur (préinstallé sur Windows 10/11)

## 💻 Installation

### Méthode simple

1. Téléchargez tous les fichiers de ce dépôt
2. Faites un clic droit sur le fichier `installer_odoo_pos_simple.bat` et sélectionnez "Exécuter en tant qu'administrateur"
3. Suivez les instructions à l'écran

### Méthode alternative

Si vous rencontrez des problèmes avec le script principal, utilisez les scripts simplifiés :
- `install_odoo_pos_simple.ps1` : Version sans caractères accentués
- `installer_odoo_pos_simple.bat` : Lanceur pour la version simplifiée

### Méthode avancée (avec paramètres personnalisés)

Pour personnaliser l'URL Odoo, ouvrez PowerShell en tant qu'administrateur et exécutez :

```powershell
.\install_odoo_pos.ps1 -OdooURL "https://votre-instance-odoo.com"
```

Ou pour la version simplifiée :

```powershell
.\install_odoo_pos_simple.ps1 -OdooURL "https://votre-instance-odoo.com"
```

## 🔧 Configuration

### Paramètres de ligne de commande

Le script PowerShell accepte les paramètres suivants :

| Paramètre  | Description | Valeur par défaut |
|------------|-------------|-------------------|
| OdooURL    | URL de l'instance Odoo POS | https://redirect.groupe-sicalait.fr/5NjIN |
| ConfigFile | Chemin vers le fichier de configuration | config.ini |

### Fichier de configuration

Pour une personnalisation plus avancée, vous pouvez modifier le fichier `config.ini` :

```ini
; Configuration pour l'installation Odoo POS
; Modifiez ce fichier pour personnaliser l'installation

[General]
; URL de l'instance Odoo POS
OdooURL=https://redirect.groupe-sicalait.fr/5NjIN

[Options]
; Activer/désactiver certaines fonctionnalités (true/false)
InstallChrome=true
InstallWebservice=true
CreateScheduledTask=true
InstallExtension=true
CreateShortcut=true

[Advanced]
; Options avancées pour les utilisateurs expérimentés
; Chemin d'installation personnalisé (laisser vide pour utiliser le chemin par défaut)
CustomInstallPath=

; Nom personnalisé pour le raccourci sur le bureau
ShortcutName=Odoo POS

; Arguments supplémentaires pour Chrome en mode kiosk
AdditionalChromeArgs=--disable-translate --disable-infobars --noerrdialogs --disable-session-crashed-bubble
```

#### Options disponibles

| Section  | Option               | Description                                       | Valeur par défaut |
|----------|----------------------|---------------------------------------------------|-------------------|
| General  | OdooURL              | URL de l'instance Odoo POS                        | https://redirect.groupe-sicalait.fr/5NjIN |
| Options  | InstallChrome        | Installer Google Chrome                           | true |
| Options  | InstallWebservice    | Installer le webservice pour le tiroir-caisse     | true |
| Options  | CreateScheduledTask  | Créer une tâche planifiée pour le webservice      | true |
| Options  | InstallExtension     | Installer l'extension Chrome                      | true |
| Options  | CreateShortcut       | Créer un raccourci sur le bureau                  | true |
| Advanced | CustomInstallPath    | Chemin d'installation personnalisé                | (vide) |
| Advanced | ShortcutName         | Nom du raccourci sur le bureau                    | Odoo POS |
| Advanced | AdditionalChromeArgs | Arguments supplémentaires pour Chrome             | --disable-translate --disable-infobars --noerrdialogs --disable-session-crashed-bubble |

## 📝 Notes importantes

### Dossier d'installation

Le script installe maintenant tous les composants dans le dossier `C:\OdooPOS` au lieu de `%ProgramFiles%\OdooPOS`. Ce changement offre une meilleure compatibilité et un accès plus direct aux fichiers d'installation, notamment pour les utilisateurs sans droits administrateur qui pourraient avoir besoin d'accéder aux fichiers.

### Installation des extensions Chrome

En raison des restrictions de sécurité de Chrome, l'installation automatique des extensions nécessite des étapes manuelles. Le script télécharge les extensions suivantes et fournit des instructions détaillées pour leur installation :

- Extension pour le tiroir-caisse : permet de contrôler le tiroir-caisse depuis l'interface Odoo POS
- Extension pour l'échéancier : améliore la gestion des paiements échelonnés dans Odoo POS

### Webservice non signé

Le webservice n'étant pas signé numériquement, le script l'exécute une première fois pour permettre à l'utilisateur de valider l'accès via les boîtes de dialogue de sécurité Windows.

### Conversion de l'icône

Le script utilise l'icône Odoo incluse dans le dépôt. Si cette icône n'est pas disponible, une icône par défaut de Windows sera utilisée.

### Configuration automatique

À la fin de l'installation, le script ouvre automatiquement l'assistant de configuration du webservice dans Chrome à l'adresse http://localhost:22548/config pour faciliter la configuration du tiroir-caisse.

## ⚠️ Résolution des problèmes

### Le script ne s'exécute pas

Si vous rencontrez une erreur d'exécution de scripts, exécutez la commande suivante dans PowerShell en tant qu'administrateur :

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Puis relancez le script.

### Problèmes d'encodage des caractères

Si vous rencontrez des problèmes d'affichage des caractères accentués dans la console PowerShell, utilisez les scripts simplifiés :
- `install_odoo_pos_simple.ps1`
- `installer_odoo_pos_simple.bat`

Ces versions n'utilisent pas de caractères accentués et sont plus robustes sur différentes configurations Windows.

### Chrome n'est pas installé correctement

Si l'installation de Chrome échoue, vous pouvez l'installer manuellement depuis [le site officiel](https://www.google.com/chrome/) puis relancer le script.

### Le webservice ne démarre pas

Vérifiez que la tâche planifiée a bien été créée en ouvrant le Planificateur de tâches Windows et en recherchant "OdooPOSCashdrawerService".

### Les extensions ne s'installent pas

Si le téléchargement des extensions échoue, vous pouvez les installer manuellement en téléchargeant les fichiers depuis les dépôts GitHub suivants :
- Extension tiroir-caisse : https://github.com/SICALAIT/chrome_extention_odoo_pos_cashdrawer
- Extension échéancier : https://github.com/SICALAIT/chrome_extension_odoo_pos_echeancier

## 📞 Support

Pour toute question ou problème, veuillez créer une issue sur ce dépôt GitHub.

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier LICENSE pour plus de détails.
