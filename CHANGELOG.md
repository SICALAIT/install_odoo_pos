# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-03-10

### Ajouté
- Scripts simplifiés sans caractères accentués pour éviter les problèmes d'encodage
  - `install_odoo_pos_simple.ps1` : Version sans caractères accentués
  - `installer_odoo_pos_simple.bat` : Lanceur pour la version simplifiée
- Mise à jour de la documentation pour inclure les nouvelles options

### Corrigé
- Problème d'ordre de définition des fonctions dans le script PowerShell
- Problèmes d'affichage des caractères accentués dans la console PowerShell

## [1.0.0] - 2025-03-10

### Ajouté
- Script d'installation automatisée pour Odoo POS en mode kiosk
- Téléchargement et installation silencieuse de Google Chrome
- Téléchargement et configuration du webservice pour le tiroir-caisse
- Création d'une tâche planifiée pour lancer le webservice au démarrage
- Téléchargement et instructions pour l'installation de l'extension Chrome
- Création d'un raccourci sur le bureau en mode kiosk
- Documentation complète (README)
- Gestion des erreurs et affichage coloré des messages
- Vérification des privilèges administrateur
- Support pour la personnalisation de l'URL Odoo
- Fichier de configuration pour personnaliser l'installation

### Notes techniques
- Utilisation de PowerShell pour la compatibilité Windows 10/11
- Gestion des différents chemins d'installation possibles de Chrome
- Tentative de conversion automatique de l'icône Odoo
- Nettoyage des fichiers temporaires après installation
