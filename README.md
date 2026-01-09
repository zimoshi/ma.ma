# 妈.妈 (xn--hvs.xn--hvs)

**妈.妈** is a local, offline-first productivity portal that runs entirely on your own machine and is accessed via a real IDN domain:  
**http://妈.妈/**

No cloud. No accounts. No trackers. Just localhost done properly.

---

## What is this?

妈.妈 is a personal “local OS portal”:
- A single local domain
- A tab-based web UI
- Multiple small everyday tools (clock, notes, calculator, etc.)
- All served from **your own machine**

It uses **proper macOS DNS routing**, not browser hacks.

---

## Features

- 🌐 **Real IDN domain** (`妈.妈`)
- 🔁 **Punycode-safe** (`xn--hvs.xn--hvs`)
- 🧭 macOS-native DNS (`dnsmasq + /etc/resolver`)
- 🌍 IPv4 + IPv6 support
- 🖥 Runs entirely on `localhost`
- 🚫 No frameworks, no cloud, no telemetry
- ⚡ Instant load, works offline forever

---

## Requirements

- macOS
- Homebrew
- `sudo` access (for DNS + port 80)

---

## Installation

Clone the repository, then run the installer:

```bash
bash install.sh
````

The installer will:

* Append required entries to `/etc/hosts` (non-destructive)
* Install and configure `dnsmasq`
* Create `/etc/resolver/xn--hvs.xn--hvs`
* Flush DNS caches
* Create the site directory
* Generate a placeholder `index.html`

---

## Starting the server (macOS)

### ⚠️ Important macOS note about `sudo`

On macOS, **background processes started with `sudo` will be suspended**
if `sudo` tries to prompt for a password after forking.

**Always warm the sudo credential cache first.**

### ✅ Recommended command

```bash
sudo -v && sudo python3 -m http.server 80 --bind :: >/dev/null 2>&1 &
```

This:

* Refreshes sudo credentials
* Starts the server cleanly in the background
* Avoids job-control suspension
* Works reliably in zsh + Terminal

---

## Accessing the site

Open any browser and go to:

```
http://妈.妈/
```

Internally this resolves to:

```
xn--hvs.xn--hvs → 127.0.0.1 / ::1
```

---

## Stopping the server

```bash
sudo pkill -f "http.server 80"
```

---

## Verifying the setup

```bash
ping xn--hvs.xn--hvs
dig xn--hvs.xn--hvs
sudo lsof -nP -iTCP:80
```

Expected:

* DNS resolves to localhost
* Python is listening on port 80 (IPv6)
* Browser loads instantly

---

## Project structure

```text
mama-site/
├── install.sh        # Full macOS installer
├── README.md
```

---

## Design philosophy

* Prefer **OS-native solutions** over hacks
* Use **real DNS**, not browser overrides
* Keep tools **small and composable**
* Zero runtime dependencies
* Everything should work offline

---

## Known limitations

* Requires `sudo` (DNS + privileged port)
* HTTPS not enabled by default (can be added via `mkcert`)
* macOS-specific (by design)

---

## Future ideas

* Tab-based UI shell
* Tool registry (dynamic modules)
* Keyboard shortcuts
* Auto-start on login (launchd)
* Optional HTTPS
* Replace Python server with a tiny custom server

---

## Why the name?

“妈.妈” is easy to type, easy to remember, and very hard to fake on the internet.
It only exists on *your* machine.

---

## License

MIT (or whatever you decide later)

---

> “Your local machine only works when you use it correctly.”
