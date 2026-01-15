#!/usr/bin/env bash
set -euo pipefail

# -------- CONFIG --------
API_KEY="YOUR_API_KEY"          # Replace with your NextDNS API key
PROFILE_ID="YOUR_PROFILE_ID"    # Replace with your NextDNS profile ID
DOMAINS_FILE="domains.txt"      # File containing "domain IP" pairs
API_BASE="https://api.nextdns.io/profiles/$PROFILE_ID/rewrites"
# ------------------------

# Check dependencies
command -v jq >/dev/null 2>&1 || { echo "jq required but not installed"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl required but not installed"; exit 1; }

echo "Fetching current rewrites..."
current=$(curl -s -H "X-Api-Key: $API_KEY" "$API_BASE" | jq -r '.data[] | "\(.name) \(.content)"')

declare -A EXISTING
while read -r line; do
    [[ -z "$line" ]] && continue
    name=$(echo "$line" | awk '{print $1}')
    ip=$(echo "$line" | awk '{print $2}')
    EXISTING["$name"]="$ip"
done <<< "$current"

echo "Processing domains from $DOMAINS_FILE..."

while read -r line; do
    line=$(echo "$line" | xargs) # trim whitespace
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    domain=$(echo "$line" | awk '{print $1}')
    ip=$(echo "$line" | awk '{print $2}')

    if [[ "${EXISTING[$domain]+_}" ]]; then
        echo "Skipping existing rewrite: $domain -> ${EXISTING[$domain]}"
        continue
    fi

    echo "Adding rewrite: $domain -> $ip"
    response=$(curl -s -X POST -H "X-Api-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$domain\",\"content\":\"$ip\"}" \
        "$API_BASE")

    id=$(echo "$response" | jq -r '.data.id // empty')
    if [[ -n "$id" ]]; then
        echo "Added successfully (ID: $id)"
    else
        echo "Failed to add $domain -> $ip"
        echo "$response"
    fi
done < "$DOMAINS_FILE"

echo "All done."
