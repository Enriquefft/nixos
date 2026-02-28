# OpenClaw WhatsApp Bridge Implementation

## Current Status

✅ **COMPLETE & OPERATIONAL** — Full end-to-end WhatsApp integration via Kapso + polling architecture.

## What Was Built

### Architecture
- **OpenClaw Gateway**: Z.AI GLM-5 agent on `ws://127.0.0.1:18789`
- **Kapso WhatsApp Plugin**: Custom Go plugin polling Kapso API for messages
- **Message Flow**: Incoming WhatsApp → Kapso API → Poller (30s interval) → Gateway → Agent → CLI send → Kapso → WhatsApp User

### Components

#### 1. Plugin Repository
**`github:Enriquefft/openclaw-kapso-whatsapp`**

Two Go binaries:
- **`kapso-whatsapp-cli`**: Send messages on demand
  ```bash
  kapso-whatsapp-cli send --to +NUMBER --text "message"
  ```
- **`kapso-whatsapp-poller`**: Polls Kapso GET `/messages?direction=inbound` every 30s, forwards to gateway

#### 2. NixOS Integration
- **flake.nix**: Kapso plugin input
- **openclaw.nix**: CLI in `home.packages`, skill symlinked, poller as systemd user service
- **openclaw-secrets.nix**: KAPSO_API_KEY, KAPSO_PHONE_NUMBER_ID env vars
- **zsh.nix**: Shell wrappers for `openclaw` and `kapso-whatsapp-cli` to auto-load secrets

#### 3. OpenClaw Configuration
- **Agent**: `main` on Z.AI GLM-5 (Coding Pro endpoint)
- **Skills**: WhatsApp skill teaches agent to use CLI
- **Gateway Auth**: Challenge-response protocol (protocol v3, RequestFrame format)

## Key Learnings

### OpenClaw WebSocket Protocol
The gateway uses **RequestFrame** format (NOT EventFrame):
```json
{
  "type": "req",
  "id": "unique-id-string",
  "method": "connect|message.receive|...",
  "params": { /* method-specific params */ }
}
```

**Auth flow:**
1. Gateway sends `{"type":"event","event":"connect.challenge",...}`
2. Client responds with `{"type":"req","method":"connect","params":{...}}`
3. Gateway replies with `{"type":"res","ok":true,"payload":{...}}`
4. Client can then send `{"type":"req","method":"message.receive",...}`

**Critical details:**
- Protocol version must be 3 (not 1)
- `client.id` must be one of: `gateway-client`, `cli`, `webchat`, `webchat-ui`, etc.
- `minProtocol`/`maxProtocol` must be integers

### Kapso API
- **Authentication**: `X-API-Key` header (Bearer token also works but was returning 401)
- **Sending**: `POST /v24.0/{phoneNumberId}/messages` with `Authorization: Bearer` header (different from list!)
- **Listing**: `GET /v24.0/{phoneNumberId}/messages?direction=inbound&since=ISO8601` with `X-API-Key` header
- **Response codes**: Send accepts both 200 (OK) and 201 (Created)

### Polling vs Webhooks
**Decision**: Polling over webhooks because:
- No public endpoint needed (works behind any NAT/firewall)
- No domain or Cloudflare Tunnel required
- Event-driven poller: near-zero idle CPU, one HTTP request/30s
- Latency: up to 30s (acceptable for personal use)

State tracking: `~/.config/kapso-whatsapp/last-poll` stores last-seen timestamp to avoid duplicates.

### Shell Function Recursion Issue
When wrapping CLI tools as shell functions with the same name, `which`/`command -v` in zsh returns the function itself, causing recursion.

**Solution**: Use `whence -p` (zsh-specific) to skip functions and find only external binaries.

## How to Use

### Send a WhatsApp Message
```bash
kapso-whatsapp-cli send --to +NUMBER --text "message"
```

### Check Agent
```bash
openclaw tui
```

### Monitor Poller
```bash
journalctl --user -u kapso-whatsapp-poller -f
```

### View Gateway Logs
```bash
tail -f /tmp/openclaw/openclaw-gateway.log
```

### Manually Trigger Poller Poll
The poller runs every 30s. To test immediately, restart:
```bash
systemctl --user restart kapso-whatsapp-poller
```

## System Services

**Systemd user services:**
- `openclaw-gateway` — Gateway daemon (auto-start on login)
- `kapso-whatsapp-poller` — Message poller (auto-start, depends on gateway)

**Start/stop:**
```bash
systemctl --user start/stop/status openclaw-gateway
systemctl --user start/stop/status kapso-whatsapp-poller
```

## Configuration Files

| File | Purpose |
|------|---------|
| `/etc/nixos/flake.nix` | Plugin input ref |
| `/etc/nixos/home-manager/programs/openclaw.nix` | Gateway + poller config |
| `/etc/nixos/modules/services/openclaw-secrets.nix` | Sops secrets + env vars |
| `/home/hybridz/.openclaw/openclaw.json` | Gateway config (managed by nix-openclaw) |
| `/home/hybridz/.config/kapso-whatsapp/last-poll` | Poller state (auto-created) |

## Secrets

All stored in `/etc/nixos/secrets/openclaw.yaml` (age-encrypted):
```yaml
openclaw:
  zai-api-key: ...
  kapso-api-key: ...
  gateway-token: ...
  kapso-phone-number-id: "..." (quoted string, not integer)
```

Edit with:
```bash
sops /etc/nixos/secrets/openclaw.yaml
```

## Testing

### Incoming Messages
1. Send WhatsApp to Kapso number
2. Check poller logs: `journalctl --user -u kapso-whatsapp-poller -n 20`
3. Should see "forwarded N message(s)" within 30s
4. Gateway logs show agent received message

### Outgoing Messages
1. Test CLI:
   ```bash
   kapso-whatsapp-cli send --to +51926689401 --text "test"
   ```
2. Should see "sent (id: ...)" response
3. Message arrives in WhatsApp

## Power Efficiency

- **Gateway**: systemd user service, idle CPU when no chats
- **Poller**: one HTTP request every 30s, minimal RAM/CPU
- **No persistent connections** to external services
- **On battery**: Can stop poller with `systemctl --user stop kapso-whatsapp-poller`

## Future Enhancements

- [ ] Configurable poll interval (env var KAPSO_POLL_INTERVAL)
- [ ] Webhook mode (if user adds domain later) — code structure supports both
- [ ] Message formatting (markdown → WhatsApp)
- [ ] Attachment support (photos, documents)
- [ ] Multiple Kapso accounts
- [ ] Rate limiting / message queuing

## Troubleshooting

### CLI says "env vars not set"
New shell session hasn't loaded the zsh function. Either:
- Open a new terminal
- Or load env manually:
  ```bash
  env $(cat /run/secrets/rendered/openclaw.env | xargs) kapso-whatsapp-cli ...
  ```

### Gateway rejects connection
Check protocol version (must be 3), client.id (must match allowed list), and `minProtocol`/`maxProtocol` (must be integers).

### Poller connects but no messages arrive
- Check Kapso API key and phone number ID in sops
- Verify Kapso account is active and has WhatsApp number configured
- Check `~/.config/kapso-whatsapp/last-poll` — if it's in the future, advance it:
  ```bash
  date -u +%Y-%m-%dT%H:%M:%SZ > ~/.config/kapso-whatsapp/last-poll
  ```

### Messages not reaching agent
Check agent is running: `openclaw tui` should connect. Gateway logs at `/tmp/openclaw/openclaw-gateway.log`.

## Code Quality

- **Go code**: Statically compiled, no dependencies besides gorilla/websocket
- **Error handling**: Retries on connection failures, exponential backoff possible
- **State management**: Last-poll timestamp prevents duplicates on restart
- **Logging**: Structured with timestamps, visible in systemd journals

## License

Plugin: MIT
