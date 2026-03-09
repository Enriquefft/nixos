# gogcli — Google Workspace CLI for OpenClaw

## What is gogcli?

`gogcli` (binary: `gog`) is a Go CLI tool for interacting with Google APIs: Calendar, Gmail, Drive, Docs, Sheets, Chat, Contacts, Tasks, and more. It's developed by Peter Steinberger's tools repo (`github:openclaw/nix-steipete-tools`) and bundled as an OpenClaw plugin.

It's how Kiro reads and manages Enrique's Google Calendar, and potentially Gmail in the future.

---

## How it was enabled

`gogcli` is a bundled plugin in `nix-openclaw`. It was enabled in `module.nix`:

```nix
bundledPlugins = {
  summarize.enable = true;
  gogcli.enable = true;
};
```

This makes the `gog` binary available on PATH and registers its skills with the OpenClaw gateway after `nixos-rebuild switch`.

---

## Authentication

### OAuth flow

`gogcli` uses Google OAuth 2.0. It opens a browser to `accounts.google.com`, you authorize, and it receives a refresh token via a local redirect server on `127.0.0.1`.

Scopes currently authorized for `enriquefft2001@gmail.com`:
- `https://www.googleapis.com/auth/calendar`
- `https://www.googleapis.com/auth/userinfo.email`
- `openid`

To add an account:
```bash
GOG_KEYRING_PASSWORD="openclaw-gog-keyring" gog auth add <email> --services=calendar
```

To add Gmail access too:
```bash
GOG_KEYRING_PASSWORD="openclaw-gog-keyring" gog auth add <email> --services=gmail,calendar
```

To list all authenticated accounts:
```bash
GOG_KEYRING_PASSWORD="openclaw-gog-keyring" gog auth list
```

---

## Keyring — why GOG_KEYRING_PASSWORD is needed

### What it is

`GOG_KEYRING_PASSWORD` is a local encryption password for `gog`'s token storage file. It has nothing to do with Google — Google never sees it. It's the password that locks/unlocks the local file where refresh tokens are saved on disk.

### Why it's needed (the gnome-keyring problem)

By default, `gog` tries to store tokens using the system keyring (gnome-keyring via D-Bus Secret Service). On this system, gnome-keyring responds to D-Bus but `gog`'s Go keyring library fails with:

```
store token: Object does not exist at path "/"
```

This is a bug in how Go's `99designs/keyring` library interacts with gnome-keyring — it tries to create a new named collection and fails. The `libsecret` tool (`secret-tool`) works fine with the same keyring, confirming it's a Go-specific issue.

### Fix applied

Switched to the file backend:
```bash
gog config set keyring_backend file
```

This stores tokens in an encrypted file instead of the D-Bus keyring. The file backend requires a password to unlock it.

Config stored at: `~/.config/gogcli/config.json`
```json
{ "keyring_backend": "file" }
```

### Where the password lives

`GOG_KEYRING_PASSWORD` is stored in sops under `openclaw/gog-keyring-password` and injected into `openclaw.env` at runtime. This means:

- The OpenClaw gateway service always has it in its environment
- The `openclaw()` and `kapso-whatsapp-cli()` shell wrappers in `zsh.nix` load it automatically from `/run/secrets/rendered/openclaw.env`
- You can also call `gog` manually by prepending the var: `GOG_KEYRING_PASSWORD="..." gog calendar events`

### Secret management

| Location | Key |
|----------|-----|
| `/etc/nixos/secrets/openclaw.yaml` | `openclaw.gog-keyring-password` |
| `/etc/nixos/modules/services/openclaw-secrets.nix` | sops secret + env template entry |
| `/run/secrets/rendered/openclaw.env` | `GOG_KEYRING_PASSWORD=...` (rendered at boot) |

---

## Usage

### Calendar

```bash
# List calendars
GOG_KEYRING_PASSWORD="..." gog calendar calendars --account=enriquefft2001@gmail.com

# List upcoming events
GOG_KEYRING_PASSWORD="..." gog calendar events --account=enriquefft2001@gmail.com

# Help
gog calendar --help
```

### How Kiro uses it

Kiro calls `gog` to:
- Check Enrique's schedule before accepting/proposing meetings
- Verify availability for commitments > 20 minutes
- Create calendar events on Enrique's behalf (with approval)

The skill registered by the gogcli plugin is under `skills/gog/` and is available to the gateway automatically after rebuild + auth.

---

## Google Cloud project

`gogcli` uses a shared Google Cloud project (client ID: `470882449544-...`). It requires the relevant APIs to be enabled in that project's Google Cloud Console:

- **Google Calendar API** — must be enabled for `gog calendar` to work
- Enable at: `https://console.developers.google.com/apis/api/calendar-json.googleapis.com/overview?project=470882449544`

---

## Adding more accounts

```bash
# Add a second Google account (calendar only)
GOG_KEYRING_PASSWORD="openclaw-gog-keyring" gog auth add other@gmail.com --services=calendar

# Add with Gmail too
GOG_KEYRING_PASSWORD="openclaw-gog-keyring" gog auth add other@gmail.com --services=gmail,calendar

# List all accounts
GOG_KEYRING_PASSWORD="openclaw-gog-keyring" gog auth list
```

Each account is stored separately in the keyring file. Use `--account=<email>` flag on any command to target a specific account.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `store token: Object does not exist at path "/"` | gnome-keyring Go bug | Switch to file backend: `gog config set keyring_backend file` |
| `no TTY available for keyring file backend password prompt` | File backend needs password but none set | Set `GOG_KEYRING_PASSWORD` env var |
| `403 accessNotConfigured` | Google Calendar API not enabled in Cloud Console | Enable via the URL in the error message |
| `gog: command not found` | Build not activated yet | Run `up` (nixos-rebuild switch) |
| Token expired | Refresh token revoked or expired | Re-run `gog auth add <email> --force-consent` |
