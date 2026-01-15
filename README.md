# NextDNS DNS Rewrites Sync

Sync your NextDNS profile rewrites with a local `domains.txt` file.

This repository provides **Bash scripts** to:

* Fetch existing rewrites from your NextDNS profile
* Add missing rewrites
* Update IP addresses if changed
* Optionally remove rewrites not present in your file

The scripts use the **official NextDNS API**: [https://nextdns.io/api](https://nextdns.io/api).

---

## Files

* `sync_nextdns_rewrites.sh` — Adds missing rewrites from `domains.txt`
* `sync_nextdns_rewrites_full.sh` — Full sync: add/update/delete to match `domains.txt`
* `domains.txt` — Example file containing domain → IP mappings

---

## Requirements

* Bash (Linux/macOS)
* `curl`
* `jq`

---

## Setup

1. Clone the repository:

```bash
git clone https://github.com/<your-username>/nextdns-rewrites-sync.git
cd nextdns-rewrites-sync
```

2. Create a `domains.txt` file (space-separated):

```
mail.example.com 10.10.1.25
photos.example.com 10.10.1.10
music.example.com 10.10.1.251
```

3. Edit the script(s) and add your NextDNS credentials:

```bash
API_KEY="YOUR_API_KEY"
PROFILE_ID="YOUR_PROFILE_ID"
```

---

## Usage

### Add missing rewrites only

```bash
chmod +x sync_nextdns_rewrites.sh
./sync_nextdns_rewrites.sh
```

### Full sync (add/update/delete)

```bash
chmod +x sync_nextdns_rewrites_full.sh
./sync_nextdns_rewrites_full.sh
```

---

## Behavior

* **Skip existing rewrites** if IP matches
* **Update IP** if the IP differs
* **Delete rewrites** not listed in `domains.txt` (full sync version only)
* Safe to run repeatedly

---

## Notes

* Only supports **A-record rewrites**.
* The script uses the official NextDNS API endpoint:

```
https://api.nextdns.io/profiles/<PROFILE_ID>/rewrites
```

* No Python dependencies; everything runs in Bash.

---

## License

MIT License — free to use and modify.

---
