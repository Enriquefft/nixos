#!/usr/bin/env bash
set -euo pipefail

CRON_DIR="/etc/nixos/openclaw/cron"
DEFAULTS="$CRON_DIR/defaults.yaml"
JOBS_DIR="$CRON_DIR/jobs"
JOBS_JSON="$HOME/.openclaw/cron/jobs.json"
DRY_RUN=false
REMOVE_MISSING=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --remove-missing) REMOVE_MISSING=true ;;
    -h|--help)
      echo "Usage: cron-sync [--dry-run] [--remove-missing]"
      echo ""
      echo "Syncs YAML job definitions to OpenClaw cron scheduler."
      echo ""
      echo "  --dry-run          Show what would change without applying"
      echo "  --remove-missing   Remove jobs not defined in YAML files"
      exit 0
      ;;
  esac
done

# Load env vars for openclaw CLI
export $(cat /run/secrets/rendered/openclaw.env | xargs)

# Load defaults
DEFAULT_TZ=$(yq -r '.timezone' "$DEFAULTS")
DEFAULT_SESSION=$(yq -r '.session' "$DEFAULTS")

# Build lookup of existing jobs: name -> id
declare -A EXISTING_IDS
declare -A EXISTING_NAMES
if [[ -f "$JOBS_JSON" ]]; then
  while IFS=$'\t' read -r id name; do
    EXISTING_IDS["$name"]="$id"
    EXISTING_NAMES["$id"]="$name"
  done < <(jq -r '.jobs[] | [.id, .name] | @tsv' "$JOBS_JSON")
fi

# Track which names we process (for removal detection)
declare -A PROCESSED_NAMES

added=0
updated=0
unchanged=0
removed=0

for yaml_file in "$JOBS_DIR"/*.yaml; do
  [[ -f "$yaml_file" ]] || continue

  name=$(yq -r '.name' "$yaml_file")
  schedule=$(yq -r '.schedule' "$yaml_file")
  tz=$(yq -r ".timezone // \"$DEFAULT_TZ\"" "$yaml_file")
  session=$(yq -r ".session // \"$DEFAULT_SESSION\"" "$yaml_file")
  prompt=$(yq -r '.prompt' "$yaml_file")
  enabled=$(yq -r '.enabled // true' "$yaml_file")

  PROCESSED_NAMES["$name"]=1

  # Build payload flag based on session type
  if [[ "$session" == "isolated" ]]; then
    payload_flag="--message"
  else
    payload_flag="--system-event"
  fi

  if [[ -n "${EXISTING_IDS[$name]:-}" ]]; then
    # Job exists — check if update needed
    job_id="${EXISTING_IDS[$name]}"

    # Read current values from jobs.json
    current_schedule=$(jq -r --arg id "$job_id" '.jobs[] | select(.id == $id) | .schedule.expr' "$JOBS_JSON")
    current_tz=$(jq -r --arg id "$job_id" '.jobs[] | select(.id == $id) | .schedule.tz // ""' "$JOBS_JSON")
    current_prompt=$(jq -r --arg id "$job_id" '.jobs[] | select(.id == $id) | (.payload.message // .payload.text) // ""' "$JOBS_JSON")

    # Build edit args for changed fields
    edit_args=()
    if [[ "$schedule" != "$current_schedule" ]]; then edit_args+=(--cron "$schedule"); fi
    if [[ "$tz" != "$current_tz" ]]; then edit_args+=(--tz "$tz"); fi
    if [[ "$prompt" != "$current_prompt" ]]; then edit_args+=("$payload_flag" "$prompt"); fi

    if [[ ${#edit_args[@]} -gt 0 ]]; then
      if $DRY_RUN; then
        echo "UPDATE: $name"
      else
        openclaw cron edit "$job_id" "${edit_args[@]}" > /dev/null
        echo "Updated: $name"
      fi
      updated=$((updated + 1))
    else
      unchanged=$((unchanged + 1))
    fi
  else
    # New job — add via CLI
    if $DRY_RUN; then
      echo "ADD: $name ($schedule, $session)"
    else
      openclaw cron add \
        --name "$name" \
        --cron "$schedule" \
        --tz "$tz" \
        --session "$session" \
        "$payload_flag" "$prompt" > /dev/null
      echo "Added: $name"
    fi
    added=$((added + 1))
  fi
done

# Handle jobs in runtime but not in YAML
for id in "${!EXISTING_NAMES[@]}"; do
  name="${EXISTING_NAMES[$id]}"
  if [[ -z "${PROCESSED_NAMES[$name]:-}" ]]; then
    if $REMOVE_MISSING; then
      if $DRY_RUN; then
        echo "REMOVE: $name ($id)"
      else
        openclaw cron rm "$id" > /dev/null
        echo "Removed: $name"
      fi
      removed=$((removed + 1))
    else
      echo "WARNING: '$name' exists in runtime but not in YAML. Use --remove-missing to delete." >&2
    fi
  fi
done

echo ""
echo "Sync complete: $added added, $updated updated, $unchanged unchanged, $removed removed"
