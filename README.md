# My_OWN_SERVER
I decide to make my own server who named peanuts server to stock files, get a password manager and host future project

## What’s on the server

Currently, the server hosts two main apps (a third one is planned):

- `Vaultwarden`  A self-hosted password manager (Bitwarden-compatible)
- `Nextcloud` A personal cloud platform for file storage and sharing

## Specificities

All services run using Docker:

- Vaultwarden runs as a standalone Docker container
- It is secured by a **reverse proxy (Nginx)** with an **SSL certificate**
- Nextcloud runs via **Docker Compose**

---
## How recreate it

### Ubuntu server installation

1. Downaload the iso on : https://ubuntu.com/download/server
2. Install on the dedicated machine (via usb bootable)
3. during the installation :
    * Choose an username
    * define a password
    * choose to install or not (to acces the server in distance)
    * no graphic environment needed
    * Connect to internet
---
### Update

execute this command to update: 

```bash
sudo apt update && sudo apt upgrade -y
```
and install some tools:

```bash
sudo apt install -y curl git ufw -y
```
---
### Install docker and docker compose

```bash
#Install docker
curl -fsSL https://get.docker.com | sh

#add current user to docker (to avoid taping sudo)
sudo usermod -aG docker $USER

#install docker compose
sudo apt install docker-compose-plugin -y
```

`Test`
```bash
#to test docker:
docker --version
#or
docker run hello-woorld

#to test docker compose:
docker compose version
```
---
### Install Vaultwarden

* Create a work directory :

```bash
mkdirp -p ~/vaultwarden && cd ~/vaultwarden
```
* Launch waultwarden with docker:

```bash
docker run -d \
  --name vaultwarden \
  -v $PWD/data:/data \
  -p 8080:80 \
  --restart unless-stopped \
  vaultwarden/server:latest
```
Explication:

* `-d` : launch in background (to not black the terminal)
* `--name vaultwarden` : name the container
* `-v $PWD/data:/data` : mount your local folder in the container to keep your data persistent
* `-p 8080:80` : service been accessible on port 8080 of your server
* `--restar unless-stopped` : restart automaticaly after restarting the server
* `-vaultwarden/server:latest` : official image of vaultwarden
---
### Set up a reverse proxy with ssl (Nginx + self-signed certificate)

* Install nginx

```bash
sudo apt update
sudo apt install nginx -y
```

* Install Cerbot (to get a free ssl certificate via Let's Encryt)
```bash
sudo apt install cerbot python3-cerbot-nginx -y
```

* Set up nginx in reverse proxy for vaultwarden
    * Create a ssl certificate self-signed
    ```bash
    sudo mkdir -p /etc/ssl/private
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout vaultwarden.key \
    -out vaultwarden.crt
    ```
    * Create a config file nginx:
    ```bash
    sudo nano /etc/nginx/sites-available/default
    ```
    and put on it:
    ```bash
    server {
    listen 80;
    server_name ip of your server (or your domain name);

    # HTTPS redirection
    return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name ip of your server (or your domain name);

        ssl_certificate /etc/letsencrypt/live/tondomaine/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/tondomaine/privkey.pem;

        location / {
            proxy_pass http://localhost:8080/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    ```
    * copy .crt and .key file in a folder lisable by nginx (/etc/nginx/ssl/)
    ```bash
    sudo mkdir -p /etc/nginx/ssl
    sudo cp vaultwarden.crt /etc/nginx/ssl/vaultwarden.crt
    sudo cp vaultwarden.key /etc/nginx/ssl/vaultwarden.key
    ```
    * Activate th config and test nginx
    ```bash
    sudo ln -s /etc/nginx/sites-available/vaultwarden /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo systemctl restart nginx
    ```
    * Go on navigator and test:
    ```bash
    http://youtdomain.com 
    ```
    *replace yourdomain by your ip address if you haven't domain name*
    * you will see a security aler, but you can ignore the alert and go on vaultwarden to create your account
---
### Next cloud with docker compose

* Create a directory

```bash
mkdir -p ~/nextcloud && cd ~/nextcloud
```
* create a docker-compose.yml file

```yml
version: '3'

services:
  db:
    image: mariadb
    container_name: nextcloud-db
    restart: always
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=superrootpass
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloudpass

  app:
    image: nextcloud
    container_name: nextcloud-app
    restart: always
    ports:
      - "8081:80"
    volumes:
      - nextcloud:/var/www/html
    depends_on:
      - db

volumes:
  db:
  nextcloud:
```
*replace superrootpass ans nextcloudpass by your own password*

* Lauchn nextcloud

```bash
docker compose up -d
```
* Configuration via web interface
go to :
`http://yourip:8081`
create an admin account and fille database info:
    * **Database user**: `nextcloud`
    * **Password**: `nextcloudpass`
    * **Datbase name**: `nextcloud`
    * **Host**: `dp` (*name of the service in docker compose*)

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

---

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

