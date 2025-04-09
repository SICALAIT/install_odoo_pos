# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6] - 2025-04-09

### Modifié
- Mise à jour de l'URL Odoo POS dans tous les fichiers de configuration pour utiliser l'URL de redirection (https://redirect.groupe-sicalait.fr/5NjIN)
- Modification de l'URL de l'extension Chrome du tiroir-caisse pour utiliser le dépôt SICALAIT au lieu du dépôt ralphi2811

### Ajouté
- Installation d'une nouvelle extension Chrome pour l'échéancier depuis le dépôt SICALAIT

## [1.0.5] - 2025-03-10

### Modifié
- Changement de la méthode pour la récupération de l'icône : utilisation de l'icône locale incluse dans le dépôt au lieu de la télécharger
- Renommage du dossier "log" en "logs" pour assurer la compatibilité avec le webservice

## [1.0.4] - 2025-03-10

### Corrigé
- Correction du problème de blocage du script lors du lancement du webservice (suppression de l'option `-Wait` qui empêchait le script de continuer)
- Ajout d'une vérification du démarrage du webservice avec un délai de 5 secondes
- Arrêt propre du webservice après vérification pour permettre au script de continuer

### Ajouté
- Création automatique du dossier "log" et du fichier "cashdrawer.log" nécessaires au fonctionnement du webservice
- Messages informatifs supplémentaires pour indiquer clairement les étapes du processus

### Modifié
- Changement de la méthode d'installation de l'extension Chrome : téléchargement du code source (ZIP) depuis GitHub, extraction et installation en tant qu'extension non empaquetée au lieu d'utiliser le fichier .crx

## [1.0.3] - 2025-03-10

### Amélioré
- Vérification de l'existence des fichiers avant de tenter de les télécharger
- Utilisation des fichiers existants si disponibles
- Meilleure gestion des erreurs et des cas où les fichiers existent déjà

## [1.0.2] - 2025-03-10

### Amélioré
- Gestion améliorée des erreurs de téléchargement
- Ajout de tentatives multiples pour les téléchargements (3 essais)
- Ajout d'informations détaillées sur les erreurs
- Option pour continuer l'installation même si le téléchargement du webservice échoue
- Utilisation de TLS 1.2 pour la sécurité des téléchargements
- Ajout d'un User-Agent pour éviter les blocages lors des téléchargements

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
