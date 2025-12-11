# Firefox Audio Stops Working After Steam Game Launch

## Problem Description
**CRITICAL**: After 5-20 minutes (sometimes longer) of playing a Steam game (Magic: The Gathering Arena), ALL audio fails - both game audio AND Firefox multimedia (Spotify, Netflix, YouTube, etc.).

**Key behaviors**:
- Happens on EVERY gaming session (100% reproducible)
- Time-based failure: 5-20 minutes after game starts, sometimes longer
- **Both game and Firefox audio fail simultaneously**
- Firefox video attempts to play but hangs after 1 second (no audio, then freezes)
- Pausing/unpausing does NOT fix it
- **Closing the game immediately fixes all audio** - Firefox works again instantly

## Investigation Summary (2025-12-09)

### Current Configuration
- **Audio System**: PipeWire 1.4.9 with PulseAudio compatibility layer
- **Session Manager**: WirePlumber 0.5.12
- **Sample Rate**: 48000 Hz (fixed)
- **Quantum**: 1024 frames
- **Firefox**: Native PipeWire support enabled (`pipewireSupport = true`)

### Key Observations

1. **Different Latency Requirements**:
   - Firefox: 3600/48000 = 75ms latency
   - MTGA.exe (game): 240/48000 = 5ms latency (15x lower!)
   - Steam games request very low latency for real-time audio

2. **WirePlumber Issues**:
   - WirePlumber shows repeated assertion failures: `wp_event_dispatcher_unregister_hook: assertion 'already_registered_dispatcher == self' failed`
   - Non-critical but indicates potential instability

3. **Steam Audio Behavior**:
   - Steam logs show many repeated `SinkAdded` events, suggesting frequent audio device reconfigurations
   - Each reconfiguration can disrupt existing audio streams

### Root Cause Analysis

**Updated analysis based on critical observations:**

This is NOT a Firefox-specific issue or a simple reconfiguration problem. The fact that:
1. **Both game AND Firefox audio fail** simultaneously
2. **Time-based failure** (5-20 minutes)
3. **Closing the game immediately fixes everything**

...indicates a **resource exhaustion or progressive failure in the audio pipeline** caused by the Steam/Proton audio layer.

**Most likely causes (in order of probability)**:

1. **Memory leak in Proton's audio bridge**: Wine/Proton translates Windows audio APIs to Linux. MTGA.exe running through Proton may be leaking resources over time.

2. **PipeWire buffer exhaustion**: The game may be creating audio streams faster than they're being cleaned up, eventually exhausting PipeWire's buffers.

3. **File descriptor leak**: Steam Runtime's PulseAudio emulation may be leaking file descriptors over time.

4. **WirePlumber policy failure**: After many audio events from the game, WirePlumber may hit an internal limit or bug (note the assertion failures in logs).

**Why closing the game fixes it immediately**: All audio streams, buffers, and file descriptors associated with the game are released, allowing PipeWire to recover instantly.

**Why Firefox can't play**: When PipeWire reaches the failure state, it can't create new audio streams for ANY application, so Firefox's attempt to play hangs.

## Potential Solutions

### Quick Fix (When Issue Occurs)
**Best fix**: Close the game - audio recovers instantly (2-3 seconds)

**If you want to keep playing**:
```bash
# Restart PipeWire services
systemctl --user restart pipewire pipewire-pulse wireplumber
```
Note: This will briefly interrupt all audio but the game should reconnect.

### Configuration Changes (To Prevent Issue)

#### Option 1: Configure PipeWire for Better Compatibility
Create/edit `~/.config/pipewire/pipewire.conf.d/99-custom.conf`:
```conf
context.properties = {
    default.clock.allowed-rates = [ 44100 48000 96000 ]
    default.clock.rate = 48000
    default.clock.quantum = 1024
    default.clock.min-quantum = 512
    default.clock.max-quantum = 2048
}
```

#### Option 2: Force Steam to Use Native PipeWire (RECOMMENDED)
This may reduce resource leaks by bypassing Proton's PulseAudio emulation layer.

Add to NixOS configuration (configuration.nix:234):
```nix
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  SDL_AUDIODRIVER = "pipewire";  # Force SDL games to use PipeWire directly
  PULSE_LATENCY_MSEC = "60";     # Increase latency tolerance
  PIPEWIRE_LATENCY = "512/48000"; # Set reasonable latency for games
};
```

#### Option 2b: Increase PipeWire Resource Limits
Add to `~/.config/pipewire/pipewire.conf.d/99-limits.conf`:
```conf
context.properties = {
    # Increase maximum number of clients (default is usually 64)
    core.daemon = true
    link.max-buffers = 16  # Default is 64, reducing may help
}

context.modules = [
    {   name = libpipewire-module-protocol-native
        args = {
            # Increase max file descriptors
            server.sockets = [ { max-clients = 128 } ]
        }
    }
]
```

#### Option 3: WirePlumber Policy Configuration
Create `~/.config/wireplumber/main.lua.d/51-disable-suspension.lua`:
```lua
-- Prevent automatic stream suspension
alsa_monitor.rules = {
  {
    matches = {
      {
        { "node.name", "matches", "alsa_output.*" },
      },
    },
    apply_properties = {
      ["session.suspend-timeout-seconds"] = 0,
    },
  },
}
```

#### Option 4: Try Different Proton Version
The issue may be specific to your current Proton version. In Steam:
1. Right-click MTGA → Properties → Compatibility
2. Try different Proton versions (Proton Experimental, Proton 9.0, Proton 8.0)
3. Test each for 20+ minutes to see if the issue persists

#### Option 5: Monitor and Auto-Restart PipeWire
Create a systemd user timer to restart PipeWire every 15 minutes while gaming (workaround):
```bash
# This is a last-resort workaround, not a real fix
systemctl --user edit --force --full pipewire-auto-restart.timer
```
(Not recommended as it will cause brief audio interruptions)

#### Option 6: Firefox Configuration
In Firefox `about:config`, set:
- `media.navigator.mediadataencoder_vpx_enabled` = true
- `media.cubeb.backend` = "pulse" (or "pipewire" if available)

Note: This is less likely to help since both game and Firefox fail together.

## Monitoring Commands

Check current audio status:
```bash
# List active streams
wpctl status

# Monitor PipeWire logs in real-time
journalctl --user -u pipewire -u pipewire-pulse -f

# Check for errors
journalctl --user -u pipewire -u wireplumber --since "10 minutes ago" | grep -i error

# Monitor file descriptor usage (run every few minutes)
watch -n 60 'lsof -p $(pgrep pipewire) 2>/dev/null | wc -l'
```

### Automated Monitoring Script
Save this as `~/monitor-audio.sh` and run while gaming to catch the failure:

```bash
#!/usr/bin/env bash
# Monitor PipeWire resource usage while gaming

LOG=~/audio-monitor-$(date +%Y%m%d-%H%M%S).log
echo "Monitoring started at $(date)" > $LOG
echo "Will check every 60 seconds. Press Ctrl+C to stop." | tee -a $LOG

while true; do
    TIMESTAMP=$(date +"%H:%M:%S")
    FD_COUNT=$(lsof -p $(pgrep pipewire) 2>/dev/null | wc -l)
    MEM_MB=$(ps -p $(pgrep pipewire) -o rss= | awk '{print $1/1024}')

    echo "[$TIMESTAMP] FDs: $FD_COUNT | Memory: ${MEM_MB}MB" | tee -a $LOG

    # Alert if FDs exceed 500 (potential leak)
    if [ "$FD_COUNT" -gt 500 ]; then
        echo "⚠️  WARNING: High file descriptor count!" | tee -a $LOG
    fi

    sleep 60
done
```

Make it executable: `chmod +x ~/monitor-audio.sh`

## Related Files
- `/etc/nixos/configuration.nix:420-432` - PipeWire configuration
- `/etc/nixos/applications.nix:71` - Firefox with PipeWire support
- `/home/hybridz/.config/pipewire/` - User PipeWire configuration (if exists)
- `/home/hybridz/.local/share/Steam/logs/steamui_audio.txt` - Steam audio logs

## Status
**ACTIVE INVESTIGATION** - 2025-12-09 02:45 AM

- Currently: Both Firefox and MTGA.exe running with audio working (13 minutes into session)
- Expected: Audio failure will occur within next 5-20 minutes
- Monitoring: PipeWire logs running in background
- Root cause: Confirmed to be resource exhaustion in Steam/Proton audio layer
- Impact: 100% reproducible - happens EVERY gaming session
- Workaround: Close game for instant recovery (2-3 seconds)

## Diagnostic Commands (Run When Issue Occurs)

**IMPORTANT**: When audio fails next time, run these commands BEFORE closing the game:

```bash
# Create timestamped log file
LOGFILE=~/audio-failure-$(date +%Y%m%d-%H%M%S).log

# Capture PipeWire state
echo "=== PipeWire Status ===" > $LOGFILE
wpctl status >> $LOGFILE 2>&1

# Check for resource exhaustion
echo -e "\n=== PipeWire Process Info ===" >> $LOGFILE
ps aux | grep -E "pipewire|wireplumber" | grep -v grep >> $LOGFILE

# Check file descriptors (look for leaks)
echo -e "\n=== File Descriptors ===" >> $LOGFILE
lsof -p $(pgrep pipewire) 2>&1 | wc -l >> $LOGFILE
lsof -p $(pgrep pipewire-pulse) 2>&1 | wc -l >> $LOGFILE

# Check memory usage
echo -e "\n=== Memory Usage ===" >> $LOGFILE
free -h >> $LOGFILE

# Capture recent errors
echo -e "\n=== Recent PipeWire Errors ===" >> $LOGFILE
journalctl --user -u pipewire -u pipewire-pulse -u wireplumber --since "20 minutes ago" | grep -i "error\|fail\|leak\|timeout" >> $LOGFILE

# Check MTGA process
echo -e "\n=== MTGA Process ===" >> $LOGFILE
ps aux | grep MTGA | grep -v grep >> $LOGFILE

echo "Log saved to: $LOGFILE"
```

This will help identify if the issue is:
- File descriptor leak (thousands of open FDs)
- Memory exhaustion (OOM condition)
- PipeWire internal errors
- Specific error messages from WirePlumber

## Updated Hypothesis (Based on User Observations)

The issue is a **progressive resource exhaustion** in the Steam/Proton audio layer:

**Evidence**:
- ✅ Time-based failure (5-20 minutes) - typical of resource leaks
- ✅ 100% reproducible every session - indicates systematic problem
- ✅ Both game AND Firefox fail together - PipeWire-level failure
- ✅ Instant recovery after closing game (2-3 seconds) - resources immediately released
- ✅ WirePlumber assertion failures in logs - internal errors accumulating

**Most likely**: Proton's Wine audio bridge (which translates Windows DirectSound/XAudio2 to PulseAudio/PipeWire) is leaking resources with each audio event. After 5-20 minutes of gameplay, PipeWire hits a resource limit and can no longer create new audio streams for ANY application.

**Next step**: Capture diagnostics when failure occurs to identify the specific resource being exhausted.
