# ERPNext Docker Setup Guide (Automated Bootstrap)
## 1. Prepare Environment & Volumes
Create the necessary directories for persistent storage.

```Bash
cd /mnt/VM/docker/
sudo rm -rf db-data redis-queue-data sites
sudo mkdir db-data redis-queue-data sites

# Optional: Set permissions if required by your host OS
sudo chown -R 1000:1000 /mnt/VM/docker/sites
sudo chown -R 999:999 /mnt/VM/docker/db-data
sudo chown -R 1000:1000 /mnt/VM/docker/redis-queue-data
```

## 2. Build the Image
Build the custom Frappe image containing your defined apps.

Linux / macOS:
```Bash
sudo docker build \
 --no-cache \
 --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
 --build-arg=FRAPPE_BRANCH=version-16 \
 --secret=id=apps_json,src=apps.json \
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
Once your `.env` and `compose.yaml` are ready, start all containers.

Note: `create-site` waits for the database and Redis, creates a missing site, and installs ERPNext. Install the other apps from `apps.json` with the commands below when needed.

```Bash
sudo docker compose -p frappe --env-file .env -f compose.yaml up -d
```

Startup is gated: `create-site` completes first, then `migrator` runs
`bench --site all migrate`. Backend, worker, scheduler, and websocket services
start only after migration succeeds. Set `MIGRATE_SITES=false` only when
intentionally bypassing migration for recovery.

## Create Site
```Bash
docker compose -p frappe exec backend bench new-site <sitename> --mariadb-user-host-login-scope='172.%.%.%'
docker compose -p frappe exec backend bench --site <sitename> install-app erpnext
```
## Maintenance & Utility Commands
If you ever need to clear the cache, run migrations, or completely wipe a site:

```Bash
sudo docker compose -p frappe exec -u frappe backend bash
```

### Create Encryption Key
```Bash
sudo docker compose -p frappe exec backend /home/frappe/frappe-bench/env/bin/python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())";

uv run python -c "import os, base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())"
```

### Install App:
```Bash
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th install-app erpnext
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th install-app crm
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th install-app payments
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th install-app webshop
```

### Run Migrations:
```Bash
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th migrate
```

### Clear Cache:
```Bash
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th clear-cache
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th clear-website-cache
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
sudo docker compose -p frappe exec backend bench drop-site erpnext.makusu.in.th --force
```

## 5. Backups

Ofelia runs a full backup every six hours by default:

```Bash
bench --site all backup --with-files --compress
```

Backups persist under `./sites/<site>/private/backups`. Frappe removes backup
files older than `BACKUP_RETENTION_HOURS` (default: 168 hours) on the next
backup run. Change the schedule with `BACKUP_CRONSTRING`.

Run an immediate backup with:

```Bash
docker compose -p frappe exec backend bench --site all backup --with-files --compress
```

These backups share the same host filesystem as the live deployment. Copy them
to separate storage for protection from host or disk failure.
