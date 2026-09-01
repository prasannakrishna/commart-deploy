#!/bin/bash
# Provisions the "scm" Keycloak realm + scm-backend client (with its custom
# claim mappers: roleType, domainType, tenantId, orgId, subscriptionType)
# on a Keycloak instance that doesn't have it yet.
#
# Safe to re-run: if the "scm" realm already exists, this is a no-op and
# does NOT touch or overwrite it. Use this after a fresh Keycloak container
# comes up on a new host (or after a volume wipe) instead of manually
# recreating the realm/client through the admin console.
#
# Usage: ./provision-realm.sh [keycloak-base-url] [admin-password]
#   defaults: http://localhost:8080, admin123

set -e

KC_URL="${1:-http://localhost:8080}"
KC_ADMIN_PASSWORD="${2:-admin123}"
REALM_FILE="$(dirname "$0")/import/scm-realm.json"

echo "Waiting for Keycloak at $KC_URL to be ready..."
for i in $(seq 1 30); do
    if curl -sf "$KC_URL/realms/master" > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

TOKEN=$(curl -sf -X POST "$KC_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password&client_id=admin-cli&username=admin&password=${KC_ADMIN_PASSWORD}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

if [ -z "$TOKEN" ]; then
    echo "Could not authenticate to Keycloak admin API." >&2
    exit 1
fi

EXISTING=$(curl -sf -o /dev/null -w "%{http_code}" "$KC_URL/admin/realms/scm" \
    -H "Authorization: Bearer $TOKEN")

if [ "$EXISTING" = "200" ]; then
    echo "Realm 'scm' already exists — leaving it untouched."
    exit 0
fi

echo "Realm 'scm' not found — importing from $REALM_FILE"
curl -sf -X POST "$KC_URL/admin/realms" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @"$REALM_FILE"

echo "✅ Realm 'scm' and client 'scm-backend' provisioned."
