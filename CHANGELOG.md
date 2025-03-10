# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Notes techniques
- Utilisation de PowerShell pour la compatibilité Windows 10/11
- Gestion des différents chemins d'installation possibles de Chrome
- Tentative de conversion automatique de l'icône Odoo
- Nettoyage des fichiers temporaires après installation
