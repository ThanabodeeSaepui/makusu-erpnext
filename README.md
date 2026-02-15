```bash
cd /mnt/VM/docker/
sudo rm -rf db-data redis-queue-data sites
sudo mkdir db-data redis-queue-data sites
```

# Define custom apps

Then generate a base64-encoded string from this file:
```bash
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)
```

# Build the image

```bash
docker build \
 --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
 --build-arg=FRAPPE_BRANCH=version-16 \
 --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
 --tag=makusu:16 \
 --file=images/layered/Containerfile .
```

# Creating the final compose file
```bash
docker compose --env-file custom.env \
    -f compose.yaml \
    -f overrides/compose.mariadb.yaml \
    -f overrides/compose.redis.yaml \
    -f overrides/compose.noproxy.yaml \
    config > compose.custom.yaml
```

# start Container

Once your compose file is ready, start all containers with a single command:

```bash
docker compose -p frappe -f compose.custom.yaml up -d
```


## Basic site creation

```bash
docker compose -p frappe exec backend bench new-site <site-domain> --mariadb-user-host-login-scope='172.%.%.%'
docker compose -p frappe exec backend bench --site <site-domain> install-app erpnext
docker compose -p frappe exec backend bench --site <site-domain> install-app print_designer

docker compose -p frappe exec backend bench --site <site-domain> migrate;
docker compose -p frappe exec backend bench --site <site-domain> clear-cache;
```