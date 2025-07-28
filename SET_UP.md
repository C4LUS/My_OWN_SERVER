## How recreate it

### Ubuntu server installation

1. Download the ISO from: https://ubuntu.com/download/server  
2. Install it on the dedicated machine (via bootable USB)  
3. During the installation:
  * Choose a username  
  * Define a password  
  * Choose whether to install SSH (to access the server remotely)  
  * No graphic environment needed  
  * Connect to the internet  
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

#Add current user to docker (to avoid taping sudo)
sudo usermod -aG docker $USER

#Install docker compose
sudo apt install docker-compose-plugin -y
```

`Test`
```bash
#To test docker:
docker --version
#or
docker run hello-woorld

#To test docker compose:
docker compose version
```
---
### Install Vaultwarden

* Create a work directory and go to it :

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

* `-d` : launch in background (so it doesn’t block the terminal)
* `--name vaultwarden` : name the container
* `-v $PWD/data:/data` : mount your local folder in the container to keep your data persistent
* `-p 8080:80` : service been accessible on port 8080 of your server
* `--restar unless-stopped` : automatically restarts after server reboot
* `-vaultwarden/server:latest` : official Vaultwarden image
---
### Set up a reverse proxy with ssl (Nginx + self-signed certificate)

* Install Nginx

```bash
sudo apt update
sudo apt install nginx -y
```

* Install Cerbot (to get a free ssl certificate via Let's Encryt)
```bash
sudo apt install cerbot python3-cerbot-nginx -y
```

* Set up nginx in reverse proxy for vaultwarden
    For this, you'll need `vaultwarden.conf` file.

    Open it and replace all the part quoted with your information

    * Create a self-signed ssl certificate 
    ```bash
    sudo mkdir -p /etc/ssl/private
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout vaultwarden.key \
    -out vaultwarden.crt
    ```
   
    * copy .crt and .key file in a folder lisable by Nginx (/etc/nginx/ssl/)
    ```bash
    sudo mkdir -p /etc/nginx/ssl
    sudo cp vaultwarden.crt /etc/nginx/ssl/vaultwarden.crt
    sudo cp vaultwarden.key /etc/nginx/ssl/vaultwarden.key
    ```
    * Activate the config and test Nginx
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
    * you will see a security aler--you can ignore it and go on vaultwarden to create your account
---
### Next cloud with docker compose

* Create a directory

```bash
mkdir -p ~/nextcloud && cd ~/nextcloud
```
* For this you'll need `docker-compose.yml` file

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
  
## Backup for VaultWarden

* For this part, you'll need `auto_save_vaultwarden.sh` file
* opne crontab using :
```bash
crontab -e
```

and add this line at the end:

```bash
0 3 * * * /home/ton_nom_utilisateur/sauvegarde_vaultwarden.sh >> /home/ton_nom_utilisateur/log_sauvegarde.txt 2>&1
```
*Replace `/home/your_user_name` by your user path (you can see it using echo $HOME)*

--- 
And now, you're free to do whatever you want with your server — add an SSH key to work on it remotely, run more Docker containers with new services... it's your playground!