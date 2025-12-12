#!/bin/bash
# Upload Devfile Registry zu lokaler Nexus-Instanz
# Verwendet Nexus REST API für Raw Repositories

NEXUS_URL="${NEXUS_URL:-http://nexus.home.lab:8081}"
REPO="${NEXUS_REPO:-devfiles}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nexus Credentials
NEXUS_USER="${NEXUS_USER:-admin}"
NEXUS_PASS="${NEXUS_PASS:-admin123}"

upload_file() {
  local file_path="$1"
  local target_path="$2"
  
  echo "  Uploading ${target_path}..."
  local response=$(curl -s -u "${NEXUS_USER}:${NEXUS_PASS}" \
    -X POST \
    "${NEXUS_URL}/service/rest/v1/components?repository=${REPO}" \
    -F "raw.directory=$(dirname ${target_path})" \
    -F "raw.asset1=@${file_path}" \
    -F "raw.asset1.filename=$(basename ${target_path})" \
    -w "\n%{http_code}")
  
  local http_code=$(echo "$response" | tail -1)
  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    echo "    ✓ OK (HTTP ${http_code})"
  else
    echo "    ✗ FAILED (HTTP ${http_code})"
    echo "$response" | head -n -1
  fi
}

echo "=== Uploading Devfile Registry to Nexus ==="
echo "Nexus URL: ${NEXUS_URL}"
echo "Repository: ${REPO}"
echo ""

# Upload index.json
echo "[1/3] Uploading index.json..."
upload_file "${SCRIPT_DIR}/index.json" "index.json"

# Upload alle Stacks
echo ""
echo "[2/3] Uploading stacks..."
if [ -d "${SCRIPT_DIR}/stacks" ]; then
  find "${SCRIPT_DIR}/stacks" -name "*.yaml" -o -name "*.yml" | while read -r file; do
    relative_path="${file#${SCRIPT_DIR}/}"
    upload_file "$file" "$relative_path"
  done
else
  echo "  Keine stacks/ Verzeichnis gefunden"
fi

# Upload alle Images
echo ""
echo "[3/3] Uploading images..."
if [ -d "${SCRIPT_DIR}/images" ]; then
  find "${SCRIPT_DIR}/images" -type f \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" \) | while read -r file; do
    relative_path="${file#${SCRIPT_DIR}/}"
    upload_file "$file" "$relative_path"
  done
else
  echo "  Keine images/ Verzeichnis gefunden"
fi

echo ""
echo "=== Upload complete ==="
echo ""
echo "Verify uploads:"
echo "  curl ${NEXUS_URL}/repository/${REPO}/index.json"
echo "  curl ${NEXUS_URL}/repository/${REPO}/stacks/"
