#!/usr/bin/env bash
# repair-loop.sh — emit structured output markers for issue filing
# The calling Kiro session reads these markers and calls memory_store with its agent tool.
# memory_store is an agent tool, NOT a CLI subcommand — this script cannot call it directly.
#
# Usage: repair-loop.sh "<issue_description>"
# Output: REPAIR_LOOP_KEY and REPAIR_LOOP_ISSUE markers on stdout

set -euo pipefail

ISSUE_DESC="${1:-unknown issue}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
KEY="issue:${TIMESTAMP}"

echo "REPAIR_LOOP_KEY=${KEY}"
echo "REPAIR_LOOP_ISSUE=${ISSUE_DESC}"
echo "REPAIR_LOOP_FILED=pending"
echo ""
echo "ACTION_REQUIRED: Call memory_store(\"${KEY}\", \"${ISSUE_DESC} | filed: ${TIMESTAMP} | status: repair-attempted\") using your agent memory_store tool."
echo "When repair is complete: Call memory_store(\"${KEY}:resolved\", \"Fixed by <what>\") to close the record."
