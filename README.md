# ERPNext Docker Setup Guide (Automated Bootstrap)
## 1. Prepare Environment & Volumes
Create the necessary directories for persistent storage.

```Bash
cd /mnt/VM/docker/
sudo rm -rf db-data redis-queue-data sites chromium
sudo mkdir db-data redis-queue-data sites chromium

# Optional: Set permissions if required by your host OS
sudo chown -R 1000:1000 /mnt/VM/docker/sites
sudo chown -R 999:999 /mnt/VM/docker/db-data
sudo chown -R 1000:1000 /mnt/VM/docker/redis-queue-data
sudo chown -R 1000:1000 /mnt/VM/docker/chromium
```

## 2. Build the Image
Build the custom Frappe image containing your defined apps.

Linux / macOS:
```Bash
sudo docker build \
    --no-cache \
    --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
    --build-arg=FRAPPE_BRANCH=version-16 \
    --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
    --tag=makusu:16 \
    --file=images/layered/Containerfile .
```

Windows (PowerShell):
```PowerShell
docker build `
    --no-cache `
    --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe `
    --build-arg=FRAPPE_BRANCH=version-16 `
    --secret=id=apps_json,src=apps.json `
    --tag=makusu:16 `
    --file=images/layered/Containerfile .
```

## 3. Configure Environment Variables
Before starting the cluster, ensure your .env file is set up. This provides the secure passwords and site names for the automated bootstrap process.

```Bash
# Copy the template
cp .env.example .env

# Edit the file with your actual site name and passwords
nano .env 
```

## 4. Start the Cluster
Once your .env and compose.custom.yaml are ready, start all containers.

Note: Because we are using the create-site service, the system will automatically wait for the database, create the site, set up the database user, and install all apps defined in your script.

```Bash
sudo docker compose -p frappe --env-file .env -f compose.yaml up -d
```

## Create Site
```Bash
docker compose -p frappe exec backend bench new-site <sitename> --mariadb-user-host-login-scope='172.%.%.%'
docker compose -p frappe exec backend bench --site <sitename> install-app erpnext
```
## Maintenance & Utility Commands
If you ever need to clear the cache, run migrations, or completely wipe a site:

```Bash
sudo docker compose -p frappe exec backend bash
```

### Create Encryption Key
```Bash
sudo docker compose -p frappe exec backend /home/frappe/frappe-bench/env/bin/python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())";
```
### Install App:
```Bash
sudo docker compose -p frappe exec backend bench --site erpnext.corp.makusu.internal install-app erpnext
sudo docker compose -p frappe exec backend bench --site erpnext.corp.makusu.internal install-app crm
```

### Run Migrations:
```Bash
sudo docker compose -p frappe exec backend bench --site erpnext.corp.makusu.internal migrate
```

### Clear Cache:
```Bash
sudo docker compose -p frappe exec backend bench --site erpnext.corp.makusu.internal clear-cache
sudo docker compose -p frappe exec backend bench --site erpnext.corp.makusu.internal clear-website-cache
```

### Rebuild app
```Bash
sudo docker compose -p frappe exec backend bench build --hard-link
sudo docker compose -p frappe exec backend bench --site all clear-cache
sudo docker compose -p frappe exec backend bench --site all clear-website-cache
sudo docker compose -p frappe restart frontend
```

### Remove/Drop a Site Completely:
```Bash
sudo docker compose -p frappe exec backend bench drop-site erpnext.corp.makusu.internal --force
```
