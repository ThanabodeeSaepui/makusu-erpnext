```bash
cd /mnt/VM/docker/
sudo rm -rf db-data redis-queue-data sites
sudo mkdir db-data redis-queue-data sites
```

## Define custom apps

Then generate a base64-encoded string from this file:
```bash
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)

$env:APPS_JSON_BASE64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("apps.json"))
```

## Creating the final compose file
```bash
docker compose --env-file custom.env \
    -f compose.yaml \
    -f overrides/compose.mariadb.yaml \
    -f overrides/compose.redis.yaml \
    -f overrides/compose.noproxy.yaml \
    config > compose.custom.yaml
```

## Build the image

```bash
docker build \
 --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
 --build-arg=FRAPPE_BRANCH=version-16 \
 --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
 --tag=makusu:16 \
 --file=images/layered/Containerfile .

docker build `
 --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe `
 --build-arg=FRAPPE_BRANCH=version-16 `
 --build-arg=APPS_JSON_BASE64=$env:APPS_JSON_BASE64 `
 --tag=makusu:16 `
 --file=images/layered/Containerfile .
```

## start Container

Once your compose file is ready, start all containers with a single command:

```bash
docker compose -p frappe -f compose.custom.yaml up -d
```


## Basic site creation

```bash
docker compose -p frappe exec backend bench new-site erpnext.makusu.in.th
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th install-app erpnext
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th install-app print_designer
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th install-app crm

docker compose -p frappe exec backend bench --site erpnext.makusu.in.th migrate
docker compose -p frappe exec backend bench --site erpnext.makusu.in.th clear-cache
```