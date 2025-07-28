#!/bin/bash

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$HOME/backups/vaultwarden_$DATE"

echo "[*] Création dossier de sauvegarde : $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

echo "[*] Arrêt du container Vaultwarden..."
docker stop vaultwarden

echo "[*] Sauvegarde des données Vaultwarden..."
docker cp vaultwarden:/data "$BACKUP_DIR"

echo "[*] Redémarrage du container Vaultwarden..."
docker start vaultwarden

echo "[*] Sauvegarde terminée dans : $BACKUP_DIR"