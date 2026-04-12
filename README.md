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

## 2. Define Custom Apps
Generate a base64-encoded string from your apps.json file to pass into the build context.

Linux / macOS:
```Bash
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)
```

Windows (PowerShell):
```PowerShell
$env:APPS_JSON_BASE64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("apps.json"))
```

## 3. Build the Image
Build the custom Frappe image containing your defined apps.

Linux / macOS:
```Bash
sudo docker build \
    --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
    --build-arg=FRAPPE_BRANCH=version-16 \
    --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
    --tag=makusu:16 \
    --file=images/layered/Containerfile .
```

Windows (PowerShell):
```PowerShell
docker build `
    --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe `
    --build-arg=FRAPPE_BRANCH=version-16 `
    --build-arg=APPS_JSON_BASE64=$env:APPS_JSON_BASE64 `
    --tag=makusu:16 `
    --file=images/layered/Containerfile .
```

## 4. Generate the Final Compose File
Merge the base configuration with your overrides.

```Bash
docker compose --env-file custom.env \
    -f compose.yaml \
    -f overrides/compose.mariadb.yaml \
    -f overrides/compose.redis.yaml \
    -f overrides/compose.noproxy.yaml \
    config > compose.custom.yaml
```

## 5. Configure Environment Variables (Important)
Before starting the cluster, ensure your .env file is set up. This provides the secure passwords and site names for the automated bootstrap process.

```Bash
# Copy the template
cp .env.example .env

# Edit the file with your actual site name and passwords
nano .env 
```

## 6. Start the Cluster (Automated Site Creation)
Once your .env and compose.custom.yaml are ready, start all containers.

Note: Because we are using the create-site service, the system will automatically wait for the database, create the site, set up the database user, and install all apps defined in your script.

```Bash
sudo docker compose -p frappe --env-file .env -f compose.yaml up -d

# You can watch the automated bootstrap process by tailing the logs:
sudo docker compose -p frappe logs create-site -f
```
## Maintenance & Utility Commands
If you ever need to clear the cache, run migrations, or completely wipe a site:

### Install App:
```Bash
sudo docker compose -p frappe exec backend bench --site <your_site_name> install-app erpnext
sudo docker compose -p frappe exec backend bench --site <your_site_name> install-app print_designer
sudo docker compose -p frappe exec backend bench --site <your_site_name> install-app crm
```

### Run Migrations:
```Bash
sudo docker compose -p frappe exec backend bench --site <your_site_name> migrate
```

### Clear Cache:
```Bash
sudo docker compose -p frappe exec backend bench --site <your_site_name> clear-cache
sudo docker compose -p frappe exec backend bench --site <your_site_name> clear-website-cache
```

### Remove/Drop a Site Completely:
```Bash
sudo docker compose -p frappe exec backend bench drop-site <your_site_name> --force
```