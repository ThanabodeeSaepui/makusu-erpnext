Script Type: DocType Event
Reference Document Type: Customer
DocType Event: Before Insert

Script
```py
key = doc.customer_name or ""

# Strip Thai company prefixes
prefixes = ["บริษัท", "หจก.", "บจก."]
for p in prefixes:
    if key.startswith(p):
        key = key.replace(p, "", 1).strip()
        break

if not key:
    key = doc.customer_name or "X"

first_char = key[0]

# Get highest existing counter for this first character
result = frappe.db.sql("""
    SELECT MAX(CAST(SUBSTRING(name, 2, 3) AS UNSIGNED))
    FROM `tabCustomer`
    WHERE name REGEXP %s
""", (f"^{first_char}[0-9]{{3}}",))

counter = (result[0][0] or 0) + 1
running = str(counter).zfill(3)

# Take first 3 chars of name after prefix stripping as "short name"
short_name = key[:3]

doc.name = f"{first_char}{running}{short_name}"
doc.flags.name_set = True
```
