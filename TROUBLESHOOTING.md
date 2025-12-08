# Troubleshooting

Documented issues and solutions for this NixOS configuration.

## Bluetooth: Dual-boot key mismatch (SOLVED)

**Problem:** Headset fails to connect with `br-connection-key-missing` error after switching from Windows.

**Cause:** Windows and Linux store different pairing keys for the same device.

**Solution:** Extract pairing key from Windows registry and sync to Linux:
```bash
# 1. In Windows PowerShell (Admin):
(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Keys\<adapter_mac>").<device_mac>

# 2. In Linux, update the key:
sudo sed -i 's/Key=OLD_KEY/Key=NEW_KEY/' /var/lib/bluetooth/<adapter_mac>/<device_mac>/info
sudo systemctl restart bluetooth
```

**Files modified:** `/var/lib/bluetooth/4C:49:6C:AC:5F:CF/E0:49:ED:04:7A:64/info`

---
