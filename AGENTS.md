# Repository Guidelines

## Project Overview

Makusu ERPNext is a **Docker deployment repository** for a self-hosted ERPNext v16 instance (site: `erpnext.makusu.in.th`). It contains **no custom Frappe app code** — all application logic comes from upstream apps installed at build time. Customization is done via ERPNext's UI (Customize Form, Print Format) and Jinja2 HTML templates.

## Architecture & Data Flow

```
┌─────────────────────────────────────────────────────┐
│                  Docker Build                       │
│  Containerfile (multi-stage)                        │
│  apps.json → base64 → bench init → makusu:16 image  │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Docker Compose Stack (12 services)      │
│                                                     │
│  db (MariaDB 11.8) ──► configurator (bench set-config)
│       │                        │
│       ▼                        ▼
│  redis-cache ──► create-site (bootstrap Frappe site)
│  redis-queue         │
│       │              ▼
│       └──► backend (gunicorn :8000)                  │
│            frontend (nginx :8080)                    │
│            websocket (socketio :9000)                │
│            scheduler                                 │
│            queue-short / queue-long                  │
└─────────────────────────────────────────────────────┘
```

**Startup flow:** db + redis → configurator (writes bench config) → create-site (installs erpnext + print_designer, creates site) → all application services come up.

**Customization strategy:** UI-configured custom fields (not code) + Jinja2 print templates in `component/`. No hooks.py, no controllers, no whitelisted APIs.

## Key Directories

| Path | Purpose |
|------|---------|
| `images/layered/Containerfile` | Multi-stage Docker build (builder → backend with fonts/Chromium) |
| `compose.yaml` | Base compose: all 12 services, volumes, x-anchor defaults |
| `overrides/` | 17 compose override files for proxy, DB, SSL, multi-bench scenarios |
| `component/` | Jinja2 HTML print format templates (Thai language) |
| `setup/` | Manual setup instructions (custom fields) |
| `*.env` | Environment configuration (secrets in `.env`, build vars in `custom.env`) |

## Development Commands

### Build

```bash
# Encode apps.json for Docker build arg
base64 -w 0 apps.json > apps.json.base64    # Linux
certutil -encodehex apps.json apps.json.base64 -n 0   # Windows

# Build custom image
docker build -t makusu:16 -f images/layered/Containerfile .

# Or use compose (with custom.env)
docker compose --env-file custom.env build
```

### Run

```bash
# Merge base compose with overrides
docker compose -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.noproxy.yaml \
  up -d

# View logs
docker compose logs -f backend
docker compose logs -f create-site
```

### Maintenance (exec into backend container)

```bash
bench --site erpnext.makusu.in.th migrate
bench --site erpnext.makusu.in.th clear-cache
bench --site erpnext.makusu.in.th build
bench --site erpnext.makusu.in.th backup
bench --site erpnext.makusu.in.th drop-site
bench clear-cache
bench build --app erpnext
```

### App Management

```bash
bench --site erpnext.makusu.in.th install-app print_designer
bench --site erpnext.makusu.in.th uninstall-app crm
```

## Code Conventions & Common Patterns

### This Repo Has No Application Code

There are no Python files, no `hooks.py`, no `setup.py`, no `pyproject.toml`. All ERPNext customization happens through:

1. **Custom Fields** — Added via ERPNext's Customize Form UI (see `setup/custom field.md`)
2. **Print Formats** — Jinja2 HTML templates in `component/` using `doc.items` loops
3. **Upstream Apps** — Installed unmodified from `apps.json`

### Template Patterns (`component/*.html`)

```jinja2
<!-- Standard item table pattern -->
{% for item in doc.items %}
<tr>
  <td>{{ item.item_code }}</td>
  <td>{{ item.item_name }}</td>
  <td>{{ item.qty }} {{ item.uom }}</td>
  <td>{{ item.rate }}</td>
  <td>{{ item.amount }}</td>
</tr>
{% endfor %}
```

- Thai column headers: รหัสรายการ, ชื่อรายการ, ปริมาณ, อัตรา/ราคา, จำนวน
- Discount variant: conditionally shows `item.discount_percentage` + strikethrough `item.price_list_rate`

### Compose Override Pattern

Base `compose.yaml` defines services; overrides add/modify for specific deployments:

- `compose.mariadb.yaml` — Built-in MariaDB
- `compose.redis.yaml` — Built-in Redis
- `compose.noproxy.yaml` — Direct port exposure (dev)
- `compose.proxy.yaml` / `compose.https.yaml` — Traefik reverse proxy
- `compose.multi-bench.yaml` — Multiple ERPNext sites shared DB/Redis
- `compose.backup-cron.yaml` — Ofelia cron for automated backups

## Important Files

| File | Role |
|------|------|
| `compose.yaml` | Main orchestration — all 12 services |
| `images/layered/Containerfile` | Multi-stage image build |
| `apps.json` | Frappe app manifest (erpnext, print_designer, crm, erpnext_thailand) |
| `.env` | Runtime secrets (SITE_NAME, MYSQL_ROOT_PASSWORD, ADMIN_PASSWORD) |
| `custom.env` | Build-time vars (ERPNEXT_VERSION, CUSTOM_IMAGE, DB/Redis hosts) |
| `component/item.html` | Sales document item list template |
| `component/item discount.html` | Item list with discount display |
| `setup/custom field.md` | Custom field setup instructions |
| `README.md` | Full deployment guide |

## Runtime/Tooling Preferences

- **Runtime:** Docker (no local Python/Node required)
- **Base image:** Frappe v16 (`frappe/build:version-16`, `frappe/base:version-16`)
- **Database:** MariaDB 11.8 (primary) or PostgreSQL 13.5 (alternative)
- **Cache/Queue:** Redis 6.2 Alpine
- **Web server:** nginx (frontend), gunicorn (backend, 4 workers, gthread)
- **Fonts:** Thai (Sarabun, Noto Sans Thai), CJK, Noto (baked into image)
- **Chromium:** Installed in image for PDF generation
- **No package manager** — no npm, pip, or bench commands outside containers
- **No CI/CD** — builds and deploys manually

## Testing & QA

**There are no tests in this repository.** This is a deployment/infrastructure repo, not application code.

Verification approach:
- `docker compose up` and confirm services start
- Check `docker compose logs create-site` for successful site bootstrap
- Access frontend at `http://localhost:8080`
- Verify custom fields appear in Quotation/Sales Order/Sales Invoice forms
- Test print format rendering with Thai content

## Upstream Apps (installed, not modified)

| App | Version | Purpose |
|-----|---------|---------|
| erpnext | v16 | Core ERP system |
| print_designer | main | Visual print format designer |
| crm | main | Customer relationship management |
| erpnext_thailand | main | Thailand localization (tax, VAT, language) |
