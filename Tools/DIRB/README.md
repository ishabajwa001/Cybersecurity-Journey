# DIRB

DIRB = **DIR**ectory **B**uster. The name describes exactly what it does: it brute-forces a target with a wordlist of common directory/file names and reports what actually exists based on the HTTP response.

## Why it's used
A lot of an app's real structure isn't linked from anywhere visible — old admin panels, backup files, dev endpoints. Developers tend to assume that if nothing links to a page, no one will find it. DIRB tests that assumption by trying thousands of common path names and checking the response code for each one.

It's a *content* scanner, not a vulnerability scanner — it tells you what exists, not whether it's exploitable. Interpreting what it finds (like a `/ftp` directory or a `.bak` file) is a separate step.

## Why I'm using it
First tool I'm learning for web recon. Goal is to get comfortable reading its output and understanding what each HTTP status code is telling me before moving on to faster tools like Gobuster.

## Install
```bash
# Kali (usually preinstalled)
dirb --help

# Ubuntu/Debian
sudo apt-get install dirb
```

## Basic usage
```bash
# Standard scan
dirb http://target

# Save output to a file
dirb http://target -o scan-output.txt

# Check for backup/config file extensions too
dirb http://target -X .bak,.old,.txt
```

## Reading the output
```
+ URL (CODE:XXX|SIZE:NNN)
```
- `200` — exists and accessible
- `301` — redirect, something's there, follow it
- `403` — exists but blocked
- `404` — not found (most of the wordlist will be this)
- `500` — server error, often leaks info in the response (worth a look)

## Scans I've run
| Target | Date | Notes |
|---|---|---|
| [OWASP Juice Shop](OWASP-Juice-shop/README.md) | 2026-06-21 | First scan, found `/ftp` directory with backup files |