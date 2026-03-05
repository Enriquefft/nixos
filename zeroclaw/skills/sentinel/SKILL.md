---
name: sentinel
description: Error sentinel — scan ZeroClaw memory every 2 hours for unresolved issues, run repair_loop for each, escalate to Enrique via WhatsApp immediately if repair fails. Invoked by cron.
---

# Sentinel Protocol

You are executing the scheduled error sentinel check. This runs every 2 hours via cron. Follow these steps exactly and in order.

## Steps

### Step 1: Scan for Unresolved Issues

Call `memory_recall("issue:")` to retrieve all keys prefixed with "issue:".

From the results, identify **unresolved** issues: entries that have a key matching `issue:<timestamp>` but do NOT have a corresponding `issue:<timestamp>:resolved` entry in the same recall results.

If no issue keys are found at all: exit silently. No message needed.

### Step 2: For Each Unresolved Issue

For each unresolved `issue:<timestamp>` key:

1. Invoke the `repair_loop` tool with the issue description from the stored value.
2. After `repair_loop` returns, call `memory_store` with the `REPAIR_LOOP_KEY` from its output to file the repair attempt.
3. Attempt to resolve the issue based on the description. Use available tools (shell commands, file edits, service restarts).

### Step 3: On Successful Repair

After the issue is resolved:

Call `memory_store("issue:<timestamp>:resolved", "Auto-resolved by sentinel at <current_timestamp>. Method: <what was done>")`.

No message to Enrique needed for successful repairs.

### Step 4: On Repair Failure

If the repair attempt fails or the issue cannot be fixed:

Send an immediate WhatsApp message to Enrique using:
```
kapso-whatsapp-cli send --to +51926689401 --text "Sentinel alert: repair-loop ran for [issue key]. Issue: [issue description]. Attempted: [what was tried]. Result: failed. Your input needed."
```

Do NOT defer this to the EOD summary. Send immediately.

### Step 5: If Nothing to Do

If Step 1 found no unresolved issues: exit. Do not send a "nothing found" message. Silent exit is correct behavior.

## Constraints

- Never skip Step 1 — always scan memory first before assuming there is nothing to do.
- Never trigger repair for an issue that already has a `:resolved` record — check both sides of the pair.
- Never defer escalation to the EOD summary when a repair fails — immediate WhatsApp only.
- Enrique's WhatsApp number is +51 926 689 401. Cross-check with USER.md if needed.
