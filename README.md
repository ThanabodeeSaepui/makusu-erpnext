```bash
sudo rm -rf db-data logs redis-queue-data sites
sudo mkdir db-data logs redis-queue-data sites

bench --site frontend install-app print_designer;
bench --site frontend migrate;
bench --site frontend clear-cache;
```