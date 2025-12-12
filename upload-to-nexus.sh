#!/bin/bash
# Upload Devfile Registry zu lokaler Nexus-Instanz
# Verwendet Nexus REST API für Raw Repositories

NEXUS_URL="http://nexus.home.lab:8081"
REPO="devfiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nexus Credentials (anpassen!)
NEXUS_USER="${NEXUS_USER:-admin}"
NEXUS_PASS="${NEXUS_PASS:-admin123}"

upload_file() {
  local file_path="$1"
  local target_path="$2"
  
  echo "Uploading ${target_path}..."
  curl -u "${NEXUS_USER}:${NEXUS_PASS}" \
    -X POST \
    "${NEXUS_URL}/service/rest/v1/components?repository=${REPO}" \
    -F "raw.directory=$(dirname ${target_path})" \
    -F "raw.asset1=@${file_path}" \
    -F "raw.asset1.filename=$(basename ${target_path})" \
    -w "\nHTTP Status: %{http_code}\n"
}

echo "=== Uploading Devfile Registry to Nexus ==="
echo "Nexus URL: ${NEXUS_URL}"
echo "Repository: ${REPO}"
echo ""

# Upload index.json
upload_file "${SCRIPT_DIR}/index.json" "index.json"

# Upload devfile.yaml
echo ""
upload_file "${SCRIPT_DIR}/stacks/python-workspace/devfile.yaml" "stacks/python-workspace/devfile.yaml"

# Upload Python icon
echo ""
if [ -f "${SCRIPT_DIR}/images/python.svg" ]; then
  upload_file "${SCRIPT_DIR}/images/python.svg" "images/python.svg"
elif [ -f "${SCRIPT_DIR}/images/python.png" ]; then
  upload_file "${SCRIPT_DIR}/images/python.png" "images/python.png"
fi

echo ""
echo "=== Upload complete ==="
echo ""
echo "Verify uploads:"
echo "  curl ${NEXUS_URL}/repository/${REPO}/index.json"
echo "  curl ${NEXUS_URL}/repository/${REPO}/stacks/python-workspace/devfile.yaml"
