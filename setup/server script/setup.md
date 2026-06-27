## Enable Server Scripts

Server scripts must be enabled before use.

Docs: https://docs.frappe.io/framework/user/en/desk/scripting/server-script

```bash
# Global (all sites)
bench set-config -g server_script_enabled 1

# Site-specific (production)
bench --site erpnext.makusu.in.th set-config server_script_enabled true
```

After enabling, restart bench: `bench restart`

## Available Scripts

| Script | DocType | Event |
|--------|---------|-------|
| [Convert Grand Total to THB - Quotation](Convert%20Grand%20Total%20to%20THB%20-%20Quotation.md) | Quotation | Before Save |
| [Convert Grand Total to THB - Sales Invoice](Convert%20Grand%20Total%20to%20THB%20-%20Sales%20Invoice.md) | Sales Invoice | Before Save |
| [Custom Customer ID](Custom%20Customer%20ID.md) | Customer | Before Insert |
