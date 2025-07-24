# My_OWN_SERVER
I decide to make my own server who named peanuts server to stock files, get a password manager and host future project

## What’s on the server

Currently, the server hosts two main apps (a third one is planned):

- `Vaultwarden` – A self-hosted password manager (Bitwarden-compatible)
- `Nextcloud` – A personal cloud platform for file storage and sharing

## Specificities

All services run using Docker:

- Vaultwarden runs as a standalone Docker container
- It is secured by a **reverse proxy (Nginx)** with an **SSL certificate**
- Nextcloud runs via **Docker Compose**

---

### How to Connect to the Services

⚠️ ***you need to be on the same network as the server to connect tot it***

---

### Vaultwarden
**URL** :

```
https://192.168.29.121
```

#### Why is there no port?

Vaultwarden is behind an Nginx reverse proxy listening on ports **80** and **443**. The proxy:

- Redirects HTTP/HTTPS requests to the Vaultwarden container (running on port `8080`)
- Uses a **self-signed SSL certificate** to secure the connection

 When you visit `https://192.168.29.121`, you're actually accessing Vaultwarden **through the proxy**, with **encrypted HTTPS**.

⚠️ The first time, your browser will warn you about the self-signed certificate — you must **accept it manually**.

---

### Nextcloud
`URL :`

```
http://192.168.29.121:8081
```
Nextcloud runs directly on port `8081` without a reverse proxy (for now). To access it:

- Use the IP and port directly in your browser.
- No HTTPS yet → use HTTP for now.

A reverse proxy and SSL setup for Nextcloud could be added later to secure the connection, just like Vaultwarden.


### Backup

VaultWarden has an automated backup that copies the data volume from docker.\
and stock it in a folder


here is the script : 

```bash
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
```
This script is call every morning at 3am using a `crontab` job.

