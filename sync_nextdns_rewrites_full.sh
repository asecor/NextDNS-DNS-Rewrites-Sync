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
current_json=$(curl -s -H "X-Api-Key: $API_KEY" "$API_BASE")
declare -A EXISTING
declare -A IDS

# Build EXISTING[domain]=ip and IDS[domain]=id
while read -r line; do
    [[ -z "$line" ]] && continue
    name=$(echo "$line" | awk '{print $1}')
    ip=$(echo "$line" | awk '{print $2}')
    EXISTING["$name"]="$ip"
done <<< "$(echo "$current_json" | jq -r '.data[] | "\(.name) \(.content)"')"

while read -r line; do
    [[ -z "$line" ]] && continue
    name=$(echo "$line" | awk '{print $1}')
    id=$(echo "$current_json" | jq -r --arg NAME "$name" '.data[] | select(.name==$NAME) | .id // empty')
    [[ -n "$id" ]] && IDS["$name"]="$id"
done

# Read desired domains from file
declare -A DESIRED
while read -r line; do
    line=$(echo "$line" | xargs)
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    domain=$(echo "$line" | awk '{print $1}')
    ip=$(echo "$line" | awk '{print $2}')
    DESIRED["$domain"]="$ip"
done < "$DOMAINS_FILE"

# 1️⃣ Add missing rewrites or update IP if different
for domain in "${!DESIRED[@]}"; do
    ip="${DESIRED[$domain]}"
    if [[ "${EXISTING[$domain]+_}" ]]; then
        # Update only if IP changed
        if [[ "${EXISTING[$domain]}" != "$ip" ]]; then
            echo "Updating rewrite: $domain -> $ip"
            id="${IDS[$domain]}"
            response=$(curl -s -X PATCH -H "X-Api-Key: $API_KEY" \
                -H "Content-Type: application/json" \
                -d "{\"content\":\"$ip\"}" \
                "$API_BASE/$id")
            echo "Updated: $domain"
        else
            echo "Skipping existing rewrite: $domain -> $ip"
        fi
    else
        echo "Adding rewrite: $domain -> $ip"
        response=$(curl -s -X POST -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"$domain\",\"content\":\"$ip\"}" \
            "$API_BASE")
        new_id=$(echo "$response" | jq -r '.data.id // empty')
        if [[ -n "$new_id" ]]; then
            echo "Added successfully (ID: $new_id)"
        else
            echo "Failed to add $domain -> $ip"
            echo "$response"
        fi
    fi
done

# 2️⃣ Delete rewrites not in domains.txt
for domain in "${!EXISTING[@]}"; do
    if [[ -z "${DESIRED[$domain]+_}" ]]; then
        echo "Deleting rewrite not in file: $domain"
        id="${IDS[$domain]}"
        response=$(curl -s -X DELETE -H "X-Api-Key: $API_KEY" "$API_BASE/$id")
        echo "Deleted: $domain"
    fi
done

echo "Sync complete."
